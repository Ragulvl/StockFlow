import 'package:flutter/foundation.dart';

/// Centralized Logger Service for StockFlow POS Application
class AppLogger {
  AppLogger._();

  static void info(String message, [String? tag]) {
    final prefix = tag != null ? '[$tag]' : '[INFO]';
    if (kDebugMode) {
      print('ℹ️ $prefix ${DateTime.now().toIso8601String()}: $message');
    }
  }

  static void warning(String message, [dynamic error, String? tag]) {
    final prefix = tag != null ? '[$tag]' : '[WARN]';
    if (kDebugMode) {
      print('⚠️ $prefix ${DateTime.now().toIso8601String()}: $message');
      if (error != null) print('   Error: $error');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    final prefix = tag != null ? '[$tag]' : '[ERROR]';
    if (kDebugMode) {
      print('❌ $prefix ${DateTime.now().toIso8601String()}: $message');
      if (error != null) print('   Error: $error');
      if (stackTrace != null) print('   StackTrace:\n$stackTrace');
    }
  }
}
