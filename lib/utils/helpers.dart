import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper functions and extensions
class Helpers {
  /// Format date for display
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return DateFormat.jm().format(date); // e.g., "2:30 PM"
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.EEEE().format(date); // e.g., "Monday"
    } else {
      return DateFormat.MMMd().format(date); // e.g., "Jan 15"
    }
  }

  /// Format full date with time
  static String formatDateTime(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  /// Format relative time (e.g., "2 minutes ago")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return formatDate(date);
    }
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Mask API key for display
  static String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '••••••••';
    return '${apiKey.substring(0, 4)}••••••••${apiKey.substring(apiKey.length - 4)}';
  }

  /// Format number with commas
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Get initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Generate a color from string (consistent hashing)
  static Color colorFromString(String text) {
    final hash = text.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
  }

  /// Show a snackbar with consistent styling
  static void showSnackbar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.white : null,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade700 : theme.colorScheme.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
                textColor: theme.colorScheme.primary,
              )
            : null,
      ),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Calculate reading time
  static String calculateReadingTime(String text) {
    final wordCount = text.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    if (minutes < 1) return '< 1 min read';
    return '$minutes min read';
  }

  /// Get file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Scroll to bottom of list
  static void scrollToBottom(ScrollController controller, {bool animate = true}) {
    if (!controller.hasClients) return;
    
    final position = controller.position.maxScrollExtent;
    if (animate) {
      controller.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      controller.jumpTo(position);
    }
  }
}

/// Extension on BuildContext for easy theme access
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  NavigatorState get navigator => Navigator.of(this);
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Extension on String for common operations
extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  String get truncateWithEllipsis {
    if (length <= 100) return this;
    return '${substring(0, 100)}...';
  }
}

/// Extension on DateTime for common operations
extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }

  String get formatted => Helpers.formatDate(this);
  String get formattedWithTime => Helpers.formatDateTime(this);
}
