import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/themes.dart';

/// Onboarding Screen - Multi-step onboarding flow
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Welcome to TuTu',
      description: 'Your personal AI agent manager with persistent memory and offline capabilities.',
      icon: '🐧',
    ),
    const OnboardingPage(
      title: 'Create AI Companions',
      description: 'Build custom agents - from friendly companions to professional assistants. Each with unique personalities.',
      icon: '🤖',
    ),
    const OnboardingPage(
      title: 'Persistent Memory',
      description: 'Your agents remember conversations, learn your preferences, and build meaningful relationships over time.',
      icon: '🧠',
    ),
    const OnboardingPage(
      title: 'Privacy First',
      description: 'All data stays on your device. Face recognition, voice synthesis, and memories work offline.',
      icon: '🔒',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, Routes.apiSetup);
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacementNamed(context, Routes.apiSetup);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text('Skip'),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? context.colors.primary
                              : context.colors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Next button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(
                page.icon,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            page.title,
            style: context.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            page.description,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Onboarding page data
class OnboardingPage {
  final String title;
  final String description;
  final String icon;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
