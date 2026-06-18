import 'package:flutter/material.dart';

import 'shared/panel.dart';

class EventLogPanel extends StatelessWidget {
  const EventLogPanel({super.key, required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final recentMessages = messages.reversed.take(5).toList().reversed;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('江湖回响', style: Theme.of(context).textTheme.titleMedium),
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
