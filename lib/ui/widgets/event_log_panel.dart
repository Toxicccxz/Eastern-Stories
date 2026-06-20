import 'package:flutter/material.dart';

import 'shared/panel.dart';

class EventLogPanel extends StatelessWidget {
  const EventLogPanel({
    super.key,
    required this.messages,
    this.title = '江湖回响',
    this.maxMessages = 5,
  });

  final List<String> messages;
  final String title;
  final int maxMessages;

  @override
  Widget build(BuildContext context) {
    final recentMessages =
        messages.reversed.take(maxMessages).toList().reversed;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final message in recentMessages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('· $message'),
            ),
        ],
      ),
    );
  }
}
