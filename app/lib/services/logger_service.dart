import 'package:flutter/foundation.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final ValueNotifier<List<String>> logs = ValueNotifier([]);

  void log(String message) {
    // Print to system console for IDE
    if (kDebugMode) {
      print("[AppLog] $message");
    }
    
    // Add to in-memory logs for UI
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final newLogs = List<String>.from(logs.value);
    newLogs.insert(0, "[$timestamp] $message");
    
    // Keep max 1000 logs
    if (newLogs.length > 1000) {
      newLogs.removeLast();
    }
    
    logs.value = newLogs;
  }

  void clear() {
    logs.value = [];
  }
}
