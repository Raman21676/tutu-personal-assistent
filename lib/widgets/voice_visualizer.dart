import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Voice Waveform Visualizer - Animated sound waves for voice mode
class VoiceVisualizer extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final double intensity;
  final Color? color;
  final double height;

  const VoiceVisualizer({
    super.key,
    this.isListening = false,
    this.isSpeaking = false,
    this.intensity = 0.5,
    this.color,
    this.height = 60,
  });

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [];
  final int _barCount = 30;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateBars);
    
    // Initialize bar heights
    for (int i = 0; i < _barCount; i++) {
      _barHeights.add(0.2);
    }
    
    if (widget.isListening || widget.isSpeaking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isListening || widget.isSpeaking) != 
        (oldWidget.isListening || oldWidget.isSpeaking)) {
      if (widget.isListening || widget.isSpeaking) {
        _controller.repeat();
      } else {
        _controller.stop();
        _resetBars();
      }
    }
  }

  void _updateBars() {
    if (!mounted) return;
    
    setState(() {
      for (int i = 0; i < _barCount; i++) {
        if (widget.isListening) {
          // Microphone input simulation
          _barHeights[i] = 0.2 + (_random.nextDouble() * 0.8 * widget.intensity);
        } else if (widget.isSpeaking) {
          // Speech output visualization
          final wave = math.sin(_controller.value * math.pi * 4 + (i * 0.3));
          _barHeights[i] = (0.3 + (wave.abs() * 0.7 * widget.intensity)).clamp(0.1, 1.0);
        }
      }
    });
  }

  void _resetBars() {
    setState(() {
      for (int i = 0; i < _barCount; i++) {
        _barHeights[i] = 0.2;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (index) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: widget.height * _barHeights[index],
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Circular voice pulse animation (like Gemini's listening indicator)
class VoicePulseIndicator extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final double size;
  final Color? color;

  const VoicePulseIndicator({
    super.key,
    this.isListening = false,
    this.isSpeaking = false,
    this.size = 120,
    this.color,
  });

  @override
  State<VoicePulseIndicator> createState() => _VoicePulseIndicatorState();
}

class _VoicePulseIndicatorState extends State<VoicePulseIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.isListening || widget.isSpeaking) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(VoicePulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isListening || widget.isSpeaking) != 
        (oldWidget.isListening || oldWidget.isSpeaking)) {
      if (widget.isListening || widget.isSpeaking) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _rotationController.stop();
    _pulseController.reset();
    _rotationController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final isListening = widget.isListening;
    
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse rings
          if (isListening)
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final delay = index * 0.3;
                  final value = (_pulseController.value + delay) % 1.0;
                  return Container(
                    width: widget.size * (0.8 + (value * 0.7)),
                    height: widget.size * (0.8 + (value * 0.7)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: (1 - value) * 0.5),
                        width: 2,
                      ),
                    ),
                  );
                },
              );
            }),
          
          // Rotating gradient ring
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.3),
                        color,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Inner circle with icon
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size * 0.85,
                  height: widget.size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isListening ? Icons.mic : Icons.volume_up,
                      size: widget.size * 0.35,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Voice activity dots (like Gemini's voice indicator)
class VoiceActivityDots extends StatefulWidget {
  final bool isActive;
  final Color? color;
  final double size;

  const VoiceActivityDots({
    super.key,
    this.isActive = false,
    this.color,
    this.size = 40,
  });

  @override
  State<VoiceActivityDots> createState() => _VoiceActivityDotsState();
}

class _VoiceActivityDotsState extends State<VoiceActivityDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    
    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(VoiceActivityDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted && widget.isActive) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            final height = widget.size * (0.3 + (_controllers[index].value * 0.7));
            return Container(
              width: widget.size * 0.15,
              height: height,
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.05),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(widget.size * 0.075),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Voice mode status card
class VoiceModeStatusCard extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final String? recognizedText;
  final String agentName;
  final String? agentAvatar;
  final VoidCallback? onCancel;

  const VoiceModeStatusCard({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    this.recognizedText,
    required this.agentName,
    this.agentAvatar,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = isListening || isSpeaking;
    
    if (!isActive && recognizedText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isListening
              ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
              : [const Color(0xFF11998e), const Color(0xFF38ef7d)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isListening ? const Color(0xFF667eea) : const Color(0xFF11998e))
                .withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    agentAvatar ?? '🤖',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isListening 
                          ? 'Listening...' 
                          : isSpeaking 
                              ? 'Speaking...' 
                              : 'Voice Mode Active',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                VoiceActivityDots(
                  isActive: true,
                  color: Colors.white,
                  size: 30,
                ),
              if (onCancel != null)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
            ],
          ),
          
          // Visualizer
          if (isActive) ...[
            const SizedBox(height: 20),
            VoiceVisualizer(
              isListening: isListening,
              isSpeaking: isSpeaking,
              height: 50,
              color: Colors.white,
            ),
          ],
          
          // Recognized text preview
          if (recognizedText != null && recognizedText!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"$recognizedText"',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    ).animate(
      effects: [
        FadeEffect(duration: 300.ms),
        ScaleEffect(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
        ),
      ],
    );
  }
}

/// Simple random helper
class Random {
  final _math = math.Random();
  
  double nextDouble() => _math.nextDouble();
}
