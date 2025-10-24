import 'dart:convert';
import 'dart:math';

class Helpers {
  // Generate a random string of specified length
  static String generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (i) => chars[random.nextInt(chars.length)]).join();
  }

  // Generate code verifier for PKCE
  static String generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (i) => chars[random.nextInt(chars.length)]).join();
  }

  // Format duration in milliseconds to MM:SS
  static String formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Format large numbers (e.g., 1000 -> 1K)
  static String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Sanitize string for database storage
  static String sanitizeString(String input) {
    return input.trim().replaceAll(RegExp(r'[^\w\s-]'), '');
  }

  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // Check if string is null or empty
  static bool isNullOrEmpty(String? value) {
    return value == null || value.isEmpty;
  }

  // Deep clone a map
  static Map<String, dynamic> deepCloneMap(Map<String, dynamic> map) {
    return jsonDecode(jsonEncode(map));
  }

  // Calculate percentage
  static double calculatePercentage(int current, int total) {
    if (total == 0) return 0.0;
    return (current / total) * 100;
  }

  // Debounce function for search
  static void debounce(Function() callback, Duration delay) {
    // This is a simplified debounce - in a real app you'd use a proper debounce utility
    Future.delayed(delay, callback);
  }
}
