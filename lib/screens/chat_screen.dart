import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/agent_model.dart';
import '../models/message_model.dart';
import '../services/storage_service.dart';
import '../services/local_llm_service.dart';
import '../services/rag_service.dart';
import '../services/offline_qa_service.dart';
import '../services/voice_service.dart';
import '../services/face_recognition_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/themes.dart';
import '../widgets/message_bubble.dart';
import '../widgets/custom_app_bar.dart';

/// Chat Screen - Full-featured chat interface with an agent
class ChatScreen extends StatefulWidget {
  final Agent agent;

  const ChatScreen({
    super.key,
    required this.agent,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final StorageService _storage = StorageService();
  final RAGService _ragService = RAGService();
  final OfflineQAService _qaService = OfflineQAService();
  final VoiceService _voiceService = VoiceService();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _uuid = const Uuid();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  bool _autoSpeak = false;
  String _generationStatus = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadSettings();
    _initializeLLM();
  }

  Future<void> _initializeLLM() async {
    final llmService = context.read<LocalLLMService>();
    if (llmService.state == LLMServiceState.uninitialized) {
      await llmService.initialize();
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _storage.getMessagesByAgent(
        widget.agent.id,
        limit: 100,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _loadSettings() {
    final prefs = _storage.getUserPreferences();
    setState(() {
      _autoSpeak = prefs['auto_speak'] ?? false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Create user message
    final userMessage = Message(
      id: _uuid.v4(),
      agentId: widget.agent.id,
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    // Save user message
    await _storage.saveMessage(userMessage);
    await _storage.updateAgentInteraction(widget.agent.id);

    // Process with RAG
    await _ragService.processConversation(
      agent: widget.agent,
      messages: _messages,
    );

    // Get response
    await _getResponse(text);
  }

  Future<void> _getResponse(String userText) async {
    final llmService = context.read<LocalLLMService>();
    
    try {
      // For TuTu (default agent), try offline QA first
      if (widget.agent.isDefault) {
        final qaResult = await _qaService.findAnswer(userText);
        if (qaResult != null && qaResult.isMatch) {
          _addAgentMessage(qaResult.entry.answer, isOffline: true);
          return;
        }
      }

      // Check if LLM is ready
      if (!llmService.isReady) {
        setState(() => _generationStatus = 'Loading AI model...');
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 500));
        if (!llmService.isReady) {
          _addAgentMessage(
            'I\'m still setting up. Please wait a moment and try again.',
            isOffline: true,
          );
          return;
        }
      }

      setState(() => _generationStatus = 'Thinking...');

      // Generate response using local LLM
      final response = await llmService.sendMessage(
        content: userText,
        agent: widget.agent,
        conversationHistory: _messages,
      );

      _addAgentMessage(
        response.content,
        isOffline: false,
        metadata: response.metadata,
      );

    } catch (e) {
      // Fallback to offline QA for default agent
      if (widget.agent.isDefault) {
        final answer = await _qaService.getAnswerOrFallback(userText);
        _addAgentMessage(answer, isOffline: true);
      } else {
        _addErrorMessage('I\'m having trouble thinking right now. Please try again.');
      }
    } finally {
      setState(() => _generationStatus = '');
    }
  }

  void _addAgentMessage(String content, {bool isOffline = false, Map<String, dynamic>? metadata}) {
    final message = Message(
      id: _uuid.v4(),
      agentId: widget.agent.id,
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
      isOfflineResponse: isOffline,
      metadata: metadata,
    );

    setState(() {
      _messages.add(message);
      _isTyping = false;
    });
    _scrollToBottom();

    // Save message
    _storage.saveMessage(message);

    // Auto speak if enabled
    if (_autoSpeak) {
      _speakMessage(content);
    }
  }

  void _addErrorMessage(String error) {
    final message = Message(
      id: _uuid.v4(),
      agentId: widget.agent.id,
      role: 'assistant',
      content: 'Sorry, I encountered an issue.',
      timestamp: DateTime.now(),
      errorMessage: error,
    );

    setState(() {
      _messages.add(message);
      _isTyping = false;
    });
    _scrollToBottom();

    _storage.saveMessage(message);
  }

  void _speakMessage(String text) {
    _voiceService.speak(text, widget.agent);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    // Navigate to camera screen
    Navigator.pushNamed(
      context,
      Routes.camera,
      arguments: widget.agent.id,
    );
  }

  void _toggleAutoSpeak() {
    setState(() => _autoSpeak = !_autoSpeak);
    _storage.saveUserPreferences({
      ..._storage.getUserPreferences(),
      'auto_speak': _autoSpeak,
    });
    
    Helpers.showSnackbar(
      context,
      message: _autoSpeak ? 'Auto-speak enabled' : 'Auto-speak disabled',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _voiceService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AgentAppBar(
        agentName: widget.agent.name,
        agentAvatar: widget.agent.avatar,
        isTyping: _isTyping,
        subtitle: widget.agent.isDefault ? 'Offline AI • Local Processing' : null,
        onSettings: () {
          // Show agent settings
        },
      ),
      body: Column(
        children: [
          // LLM Status indicator
          _buildLLMStatusBar(),
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildWelcomeMessage()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final showDate = index == 0 ||
                              _messages[index - 1].dateString != message.dateString;

                          return Column(
                            children: [
                              if (showDate)
                                DateSeparator(date: message.dateString),
                              MessageBubble(
                                message: message,
                                agentAvatar: widget.agent.avatar,
                                onSpeak: () => _speakMessage(message.content),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          // Typing indicator
          if (_isTyping) const TypingIndicator(),
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLLMStatusBar() {
    return Consumer<LocalLLMService>(
      builder: (context, llmService, child) {
        if (llmService.state == LLMServiceState.ready) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.offline_bolt, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text(
                  'Running locally on your device',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else if (llmService.state == LLMServiceState.loading) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Loading AI model...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else if (llmService.state == LLMServiceState.error) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.red.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'AI Error: ${llmService.error ?? "Unknown"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  widget.agent.avatar,
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hi, I\'m ${widget.agent.name}!',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.agent.isDefault
                  ? DefaultMessages.welcomeMessage
                  : 'I\'m your ${AgentRoles.getDisplayName(widget.agent.role).toLowerCase()}. How can I help you today?',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Offline badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_bolt, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 6),
                  Text(
                    '100% Offline • No Internet Needed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.agent.isDefault && 
                AgentRoles.getDefaultPersonality(widget.agent.role) != widget.agent.personality) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.agent.personality,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Camera button
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _pickImage,
              color: context.colors.onSurface.withOpacity(0.6),
            ),
            // Auto-speak toggle
            IconButton(
              icon: Icon(_autoSpeak ? Icons.volume_up : Icons.volume_off),
              onPressed: _toggleAutoSpeak,
              color: _autoSpeak
                  ? context.colors.primary
                  : context.colors.onSurface.withOpacity(0.6),
            ),
            // Text input
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Message ${widget.agent.name}...',
                  filled: true,
                  fillColor: context.colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
