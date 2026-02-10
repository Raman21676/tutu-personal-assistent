import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/message_model.dart';
import '../utils/themes.dart';

/// Gemini-style Chat Bubble with modern design
class GeminiChatBubble extends StatelessWidget {
  final Message message;
  final String? agentAvatar;
  final String? agentName;
  final VoidCallback? onSpeak;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final bool isLatest;

  const GeminiChatBubble({
    super.key,
    required this.message,
    this.agentAvatar,
    this.agentName,
    this.onSpeak,
    this.onCopy,
    this.onShare,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context),
          if (!isUser) const SizedBox(width: 12),
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Name label
                if (!isUser && agentName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      agentName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser 
                        ? AppGradients.primaryGradient
                        : null,
                    color: isUser 
                        ? null 
                        : theme.brightness == Brightness.dark
                            ? const Color(0xFF2D2D2D)
                            : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(context, isUser),
                ).animate(
                  effects: isLatest
                      ? [
                          FadeEffect(duration: 300.ms),
                          SlideEffect(
                            begin: const Offset(0, 0.2),
                            end: const Offset(0, 0),
                            duration: 300.ms,
                          ),
                        ]
                      : null,
                ),
                
                // Action buttons
                if (!isUser) _buildActionButtons(context),
              ],
            ),
          ),
          
          if (isUser) const SizedBox(width: 12),
          if (isUser) _buildUserAvatar(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppThemes.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          agentAvatar ?? '🤖',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 20, color: Colors.grey),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    
    if (message.hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.errorMessage ?? 'An error occurred',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      );
    }

    return SelectableText(
      message.content,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isUser ? Colors.white : theme.colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.volume_up,
            onTap: onSpeak,
            tooltip: 'Read aloud',
          ),
          _ActionButton(
            icon: Icons.copy,
            onTap: onCopy,
            tooltip: 'Copy',
          ),
          _ActionButton(
            icon: Icons.share,
            onTap: onShare,
            tooltip: 'Share',
          ),
        ],
      ),
    );
  }
}

/// Action button for chat bubble
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gemini-style Typing Indicator
class GeminiTypingIndicator extends StatelessWidget {
  final String agentName;
  final String? agentAvatar;

  const GeminiTypingIndicator({
    super.key,
    required this.agentName,
    this.agentAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                agentAvatar ?? '🤖',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Typing animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$agentName is thinking',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                _buildDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(delay: 0),
        _Dot(delay: 200),
        _Dot(delay: 400),
      ],
    );
  }
}

/// Animated dot for typing indicator
class _Dot extends StatelessWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).scale(
      duration: 600.ms,
      delay: delay.ms,
      begin: const Offset(0.5, 0.5),
      end: const Offset(1, 1),
    );
  }
}

/// Shimmer loading effect for messages
class MessageShimmer extends StatelessWidget {
  const MessageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action chips (like Gemini's suggestions)
class QuickActionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;

  const QuickActionChips({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          avatar: const Icon(Icons.lightbulb_outline, size: 16),
          label: Text(suggestion),
          onPressed: () => onTap(suggestion),
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}

/// Reaction bar for messages
class MessageReactionBar extends StatelessWidget {
  final Function(String) onReaction;

  const MessageReactionBar({
    super.key,
    required this.onReaction,
  });

  static const List<String> _reactions = ['👍', '❤️', '😂', '😮', '😢', '👏'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _reactions.map((emoji) {
          return InkWell(
            onTap: () => onReaction(emoji),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
