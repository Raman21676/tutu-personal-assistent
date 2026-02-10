import 'package:flutter/material.dart';

/// App Themes - Light and Dark theme configurations
class AppThemes {
  // Private constructor to prevent instantiation
  AppThemes._();

  // Brand Colors
  static const Color primaryColor = Color(0xFF7C3AED); // Purple
  static const Color secondaryColor = Color(0xFF3B82F6); // Blue
  static const Color accentColor = Color(0xFFF59E0B); // Amber

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightDivider = Color(0xFFE2E8F0);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF334155);

  // Message Bubble Colors
  static const Color userBubbleLight = Color(0xFF7C3AED);
  static const Color userBubbleDark = Color(0xFF8B5CF6);
  static const Color agentBubbleLight = Color(0xFFF1F5F9);
  static const Color agentBubbleDark = Color(0xFF334155);

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightText,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: lightSurface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightText,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkSurface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkText,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: darkTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// Get message bubble colors
  static MessageBubbleColors getMessageBubbleColors(bool isDark) {
    return MessageBubbleColors(
      userBubble: isDark ? userBubbleDark : userBubbleLight,
      userText: Colors.white,
      agentBubble: isDark ? agentBubbleDark : agentBubbleLight,
      agentText: isDark ? darkText : lightText,
    );
  }
}

/// Message bubble color configuration
class MessageBubbleColors {
  final Color userBubble;
  final Color userText;
  final Color agentBubble;
  final Color agentText;

  MessageBubbleColors({
    required this.userBubble,
    required this.userText,
    required this.agentBubble,
    required this.agentText,
  });
}

/// Gradient decorations
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppThemes.primaryColor,
      AppThemes.secondaryColor,
    ],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF7C3AED),
      Color(0xFF4F46E5),
      Color(0xFF2563EB),
    ],
  );

  static LinearGradient cardGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF1E293B),
              const Color(0xFF334155),
            ]
          : [
              Colors.white,
              const Color(0xFFF1F5F9),
            ],
    );
  }
}
