import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/offline_qa_service.dart';
import '../utils/constants.dart';
import '../utils/themes.dart';

/// Splash Screen - Initial loading screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final StorageService _storage = StorageService();
  final OfflineQAService _qaService = OfflineQAService();

  bool _isLoading = true;
  String _loadingText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeApp();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize storage
      setState(() => _loadingText = 'Setting up database...');
      await _storage.initialize();

      // Initialize QA bank
      setState(() => _loadingText = 'Loading knowledge base...');
      await _qaService.initialize();

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 800));

      // Check if onboarding is completed
      final isOnboardingCompleted = _storage.isOnboardingCompleted;
      final hasApiKey = await _storage.hasApiKey();

      if (mounted) {
        if (!isOnboardingCompleted) {
          Navigator.pushReplacementNamed(context, Routes.onboarding);
        } else {
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      }
    } catch (e) {
      setState(() {
        _loadingText = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.splashGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '🐧',
                              style: TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // App name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Loading indicator
                if (_isLoading) ...[
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _loadingText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
