import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/logger_service.dart';

class DebugConsolePage extends StatelessWidget {
  const DebugConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Debug Console", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2C2C2C),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => LoggerService().clear(),
            tooltip: "Clear Logs",
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final text = LoggerService().logs.value.join("\n");
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logs copied to clipboard")),
              );
            },
            tooltip: "Copy All",
          ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: LoggerService().logs,
        builder: (context, logs, child) {
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                "No logs yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: logs.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final log = logs[index];
              Color textColor = Colors.white;
              if (log.contains("Error") || log.contains("Exception") || log.contains("Fail")) {
                textColor = Colors.redAccent;
              } else if (log.contains("DEBUG")) {
                textColor = Colors.lightBlueAccent;
              } else if (log.contains("Warning")) {
                textColor = Colors.orangeAccent;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: SelectableText(
                  log,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
