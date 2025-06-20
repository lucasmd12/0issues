import 'package:flutter/foundation.dart';

/// Basic Logger class to replace simple print statements.
class Logger {
  // Static methods for easy access without instantiation

  /// Logs an informational message.
  static void info(String message) {
    // Only print in debug mode to avoid cluttering release logs
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  /// Logs a warning message.
  static void warning(String message) {
    if (kDebugMode) {
      print('[WARN] ⚠️ $message');
    }
  }

  /// Logs an error message, optionally including an error object and stack trace.
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[ERROR] ❌ $message');
      if (error != null) {
        print('  Error: $error');
      }
      if (stackTrace != null) {
        print('  StackTrace: $stackTrace');
      }
    }
    // In a real app, you might send errors to a reporting service (e.g., Sentry, Crashlytics)
  }
}

