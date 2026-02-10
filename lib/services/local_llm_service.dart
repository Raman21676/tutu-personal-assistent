/// local_llm_service.dart - High-level service for local LLM inference
/// 
/// This service manages the local LLM model, handles inference,
/// and provides a clean API for the chat interface.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/agent_model.dart';
import '../models/message_model.dart';
import 'llama_bindings.dart';
import 'storage_service.dart';

/// Service state
enum LLMServiceState {
  uninitialized,
  loading,
  ready,
  generating,
  error,
}

/// Local LLM Service - Manages on-device inference
class LocalLLMService extends ChangeNotifier {
  static final LocalLLMService _instance = LocalLLMService._internal();
  factory LocalLLMService() => _instance;
  LocalLLMService._internal();
  
  // Dependencies
  final LlamaBindings _bindings = LlamaBindings();
  final StorageService _storage = StorageService();
  
  // State
  LLMServiceState _state = LLMServiceState.uninitialized;
  String? _error;
  String? _modelPath;
  bool _isModelExtracted = false;
  
  // Generation state
  bool _isGenerating = false;
  StreamController<String>? _generationController;
  
  // Model info
  String _modelName = 'SmolLM2-360M-Instruct';
  int _contextSize = 2048;
  int _vocabSize = 49152;
  
  // Configuration
  static const String _defaultModelAsset = 'assets/models/SmolLM2-360M-Instruct-Q4_K_M.gguf';
  static const String _modelFileName = 'SmolLM2-360M-Instruct-Q4_K_M.gguf';
  
  // Getters
  LLMServiceState get state => _state;
  String? get error => _error;
  bool get isReady => _state == LLMServiceState.ready;
  bool get isGenerating => _isGenerating;
  bool get isModelExtracted => _isModelExtracted;
  
  String get modelName => _modelName;
  int get contextSize => _contextSize;
  int get vocabSize => _vocabSize;
  String? get modelPath => _modelPath;
  
  bool get hasGpuSupport => _bindings.hasGpuSupport;
  String get systemInfo => _bindings.systemInfo;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_state != LLMServiceState.uninitialized) return;
    
    _setState(LLMServiceState.loading);
    
    try {
      // Check if FFI is available
      if (!LlamaBindings.isAvailable) {
        throw Exception('Native library not available. Please rebuild with native support.');
      }
      
      // Initialize bindings
      _bindings.initialize();
      
      // Extract model from assets if needed
      await _ensureModelExtracted();
      
      // Load the model
      await _loadModel();
      
      _setState(LLMServiceState.ready);
    } catch (e) {
      _error = e.toString();
      _setState(LLMServiceState.error);
      debugPrint('LocalLLMService initialization error: $e');
    }
  }
  
  /// Extract model from assets to app documents
  Future<void> _ensureModelExtracted() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(path.join(appDir.path, 'models'));
    
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    
    final modelFile = File(path.join(modelDir.path, _modelFileName));
    _modelPath = modelFile.path;
    
    if (await modelFile.exists()) {
      _isModelExtracted = true;
      return;
    }
    
    // Extract model from assets
    debugPrint('Extracting model from assets...');
    try {
      final byteData = await rootBundle.load(_defaultModelAsset);
      final bytes = byteData.buffer.asUint8List();
      await modelFile.writeAsBytes(bytes);
      _isModelExtracted = true;
      debugPrint('Model extracted successfully (${bytes.length ~/ 1024 ~/ 1024} MB)');
    } catch (e) {
      throw Exception('Failed to extract model: $e');
    }
  }
  
  /// Load the model into memory
  Future<void> _loadModel() async {
    if (_modelPath == null) {
      throw Exception('Model path not set');
    }
    
    final params = LLMModelParams.allocate(
      modelPath: _modelPath!,
      nCtx: 2048,
      nThreads: _getOptimalThreadCount(),
      nBatch: 512,
    );
    
    final success = _bindings.loadModel(params);
    
    if (!success) {
      throw Exception('Failed to load model: ${_bindings.getLastError()}');
    }
    
    // Get model info
    _contextSize = _bindings.contextSize;
    _vocabSize = _bindings.vocabSize;
    
    debugPrint('Model loaded successfully');
    debugPrint('Context size: $_contextSize');
    debugPrint('Vocab size: $_vocabSize');
  }
  
  /// Get optimal thread count based on device
  int _getOptimalThreadCount() {
    final processors = Platform.numberOfProcessors;
    // Use 75% of available cores, max 4
    return math.min(4, math.max(1, processors * 3 ~/ 4));
  }
  
  /// Send a message and get a response
  Future<Message> sendMessage({
    required String content,
    required Agent agent,
    required List<Message> conversationHistory,
  }) async {
    if (!isReady) {
      throw Exception('LLM Service not ready. Current state: $_state');
    }
    
    if (_isGenerating) {
      throw Exception('Already generating a response');
    }
    
    _isGenerating = true;
    notifyListeners();
    
    try {
      // Build the prompt
      final prompt = _buildPrompt(
        content: content,
        agent: agent,
        history: conversationHistory,
      );
      
      // Check prompt length
      final tokenCount = _bindings.tokenize(prompt);
      if (tokenCount > _contextSize - 256) {
        throw Exception('Input too long ($tokenCount tokens). Maximum: ${_contextSize - 256}');
      }
      
      // Generate response
      final params = LLMGenerateParams.allocate(
        nPredict: 512,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.1,
        repeatLastN: 64,
        stopSequences: '["<|im_end|>", "User:", "<|endoftext|>"]',
      );
      
      final response = await compute(_generateInIsolate, {
        'prompt': prompt,
        'modelPath': _modelPath,
      });
      
      // Clean up the response
      final cleanedResponse = _cleanResponse(response);
      
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        agentId: agent.id,
        role: 'assistant',
        content: cleanedResponse,
        timestamp: DateTime.now(),
        metadata: {
          'model': _modelName,
          'tokens_generated': _bindings.tokenize(response),
          'local': true,
        },
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
  
  /// Build the chat prompt
  String _buildPrompt({
    required String content,
    required Agent agent,
    required List<Message> history,
  }) {
    final buffer = StringBuffer();
    
    // System prompt
    buffer.writeln('<|im_start|>system');
    buffer.writeln(agent.systemPrompt);
    buffer.writeln('<|im_end|>');
    
    // Conversation history (last 10 messages)
    final recentHistory = history.length > 10 
        ? history.sublist(history.length - 10) 
        : history;
    
    for (final msg in recentHistory) {
      final role = msg.role == 'user' ? 'user' : 'assistant';
      buffer.writeln('<|im_start|>$role');
      buffer.writeln(msg.content);
      buffer.writeln('<|im_end|>');
    }
    
    // Current message
    buffer.writeln('<|im_start|>user');
    buffer.writeln(content);
    buffer.writeln('<|im_end|>');
    
    // Assistant prefix
    buffer.write('<|im_start|>assistant\n');
    
    return buffer.toString();
  }
  
  /// Clean up the model response
  String _cleanResponse(String response) {
    // Remove special tokens
    var cleaned = response
        .replaceAll('<|im_end|>', '')
        .replaceAll('<|im_start|>', '')
        .replaceAll('<|endoftext|>', '')
        .replaceAll('assistant', '')
        .replaceAll('user', '');
    
    // Trim whitespace
    cleaned = cleaned.trim();
    
    return cleaned;
  }
  
  /// Generate response in isolate (for performance)
  static String _generateInIsolate(Map<String, dynamic> args) {
    final prompt = args['prompt'] as String;
    final modelPath = args['modelPath'] as String?;
    
    // This is a placeholder - in production, this would:
    // 1. Load the model in the isolate
    // 2. Generate tokens
    // 3. Return the result
    
    // For now, return a placeholder response
    return '''I'm running locally on your device using SmolLM2-360M! 

I can help you with:
• General questions
• Creative writing
• Analysis and explanations
• Coding help
• And much more!

All processing happens on your device - no data is sent to any server.'''.trim();
  }
  
  /// Stream generation (for real-time token streaming)
  Stream<String> generateStream({
    required String content,
    required Agent agent,
    required List<Message> conversationHistory,
  }) async* {
    if (!isReady) {
      throw Exception('LLM Service not ready');
    }
    
    _isGenerating = true;
    notifyListeners();
    
    try {
      final prompt = _buildPrompt(
        content: content,
        agent: agent,
        history: conversationHistory,
      );
      
      // Simulate streaming (replace with actual implementation)
      final words = [
        "I'm",
        " running",
        " locally",
        " on",
        " your",
        " device!",
        " ",
        "No",
        " internet",
        " connection",
        " needed",
        "."
      ];
      
      for (final word in words) {
        await Future.delayed(const Duration(milliseconds: 50));
        yield word;
      }
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
  
  /// Unload model and free resources
  Future<void> unload() async {
    _bindings.unloadModel();
    _setState(LLMServiceState.uninitialized);
  }
  
  /// Dispose the service
  @override
  void dispose() {
    _generationController?.close();
    _bindings.dispose();
    super.dispose();
  }
  
  /// Set state and notify listeners
  void _setState(LLMServiceState newState) {
    _state = newState;
    notifyListeners();
  }
  
  /// Get estimated memory usage
  String get estimatedMemoryUsage {
    // SmolLM2-360M Q4_K_M is about 258MB on disk
    // Loaded in memory it's about 400-500MB
    return '~450 MB';
  }
  
  /// Check if model needs to be re-extracted (e.g., after app update)
  Future<bool> checkModelIntegrity() async {
    if (_modelPath == null) return false;
    
    final file = File(_modelPath!);
    if (!await file.exists()) return false;
    
    final size = await file.length();
    // SmolLM2-360M Q4_K_M should be around 258MB
    const expectedSize = 258 * 1024 * 1024;
    
    return (size - expectedSize).abs() < 10 * 1024 * 1024; // Within 10MB
  }
}

/// Exception for LLM service errors
class LLMServiceException implements Exception {
  final String message;
  final LLMServiceState state;
  
  LLMServiceException(this.message, {required this.state});
  
  @override
  String toString() => 'LLMServiceException: $message (state: $state)';
}
