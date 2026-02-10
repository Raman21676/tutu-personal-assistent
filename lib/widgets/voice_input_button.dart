import 'package:flutter/material.dart';
import '../utils/themes.dart';

/// Voice Input Button - Animated microphone button for voice input
class VoiceInputButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const VoiceInputButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.size = 56,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.isListening) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.red;
    final inactiveColor = widget.inactiveColor ?? AppThemes.primaryColor;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse effect when listening
              if (widget.isListening)
                Container(
                  width: widget.size * _pulseAnimation.value,
                  height: widget.size * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor.withValues(alpha: 0.2),
                  ),
                ),
              // Main button
              Transform.scale(
                scale: widget.isListening ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: widget.isListening
                        ? LinearGradient(
                            colors: [
                              activeColor,
                              activeColor.withValues(alpha: 0.8),
                            ],
                          )
                        : AppGradients.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.isListening ? activeColor : inactiveColor)
                                .withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: widget.size * 0.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Voice Status Indicator - Shows current voice state
class VoiceStatusIndicator extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final String? recognizedText;

  const VoiceStatusIndicator({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    this.recognizedText,
  });

  @override
  Widget build(BuildContext context) {
    if (!isListening && !isSpeaking) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isListening
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isListening
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isListening ? Colors.red : Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isListening ? Icons.mic : Icons.volume_up,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isListening ? 'Listening...' : 'Speaking...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isListening ? Colors.red : Colors.green,
                  ),
                ),
                if (recognizedText != null && recognizedText!.isNotEmpty)
                  Text(
                    recognizedText!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isListening) const _AudioWaveform(),
        ],
      ),
    );
  }
}

/// Audio waveform animation
class _AudioWaveform extends StatefulWidget {
  const _AudioWaveform();

  @override
  State<_AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<_AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final height =
                8 + (16 * (value < 0.5 ? value * 2 : (1 - value) * 2));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Voice conversation mode toggle
class VoiceModeToggle extends StatelessWidget {
  final bool isVoiceModeEnabled;
  final ValueChanged<bool> onChanged;

  const VoiceModeToggle({
    super.key,
    required this.isVoiceModeEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVoiceModeEnabled
            ? AppThemes.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 16,
            color: isVoiceModeEnabled ? AppThemes.primaryColor : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            'Voice Mode',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isVoiceModeEnabled ? AppThemes.primaryColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Switch(
            value: isVoiceModeEnabled,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
