import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message_model.dart';
import '../utils/helpers.dart';
import '../utils/themes.dart';

/// Message Bubble Widget - Displays a chat message
class MessageBubble extends StatelessWidget {
  final Message message;
  final String? agentAvatar;
  final VoidCallback? onSpeak;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    this.agentAvatar,
    this.onSpeak,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemes.getMessageBubbleColors(context.isDarkMode);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? colors.userBubble : colors.agentBubble,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.hasError)
                          _buildErrorContent(context)
                        else
                          _buildMessageContent(context, isUser ? colors.userText : colors.agentText),
                      ],
                    ),
                  ),
                ),
                if (showTimestamp) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.formattedTime,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurface.withAlpha((0.4 * 255).round()),
                          fontSize: 11,
                        ),
                      ),
                      if (!isUser && onSpeak != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onSpeak,
                          child: Icon(
                            Icons.volume_up,
                            size: 14,
                            color: context.colors.onSurface.withAlpha((0.4 * 255).round()),
                          ),
                        ),
                      ],
                      if (message.isOfflineResponse) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.offline_bolt,
                          size: 14,
                          color: Colors.orange.shade400,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          agentAvatar ?? '🤖',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color textColor) {
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: context.textTheme.bodyMedium?.copyWith(
          color: textColor,
        ),
        code: context.textTheme.bodyMedium?.copyWith(
          backgroundColor: Colors.black.withAlpha(26),
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.black.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      selectable: true,
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red.shade400,
          size: 16,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message.errorMessage ?? 'An error occurred',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade400,
            ),
          ),
        ),
      ],
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                Helpers.showSnackbar(
                  context,
                  message: 'Copied to clipboard',
                );
              },
            ),
            if (!message.isUser)
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Read aloud'),
                onTap: () {
                  Navigator.pop(context);
                  onSpeak?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // Share functionality would go here
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing Indicator - Shows when agent is typing
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                '🤖',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: context.isDarkMode 
                  ? AppThemes.agentBubbleDark 
                  : AppThemes.agentBubbleLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = (_controller.value + delay) % 1.0;
        final scale = 0.5 + (0.5 * (value < 0.5 ? value * 2 : (1 - value) * 2));
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.colors.onSurface.withAlpha((0.4 * 255).round()),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// Date Separator - Shows date between messages
class DateSeparator extends StatelessWidget {
  final String date;

  const DateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: context.isDarkMode 
              ? Colors.white.withAlpha(26) 
              : Colors.black.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          date,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurface.withAlpha(153),
          ),
        ),
      ),
    );
  }
}
