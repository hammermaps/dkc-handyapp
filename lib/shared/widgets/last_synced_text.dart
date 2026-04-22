import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays a small "Zuletzt aktualisiert: <DateTime>" text.
class LastSyncedText extends StatelessWidget {
  const LastSyncedText({super.key, this.syncedAt});

  final DateTime? syncedAt;

  @override
  Widget build(BuildContext context) {
    if (syncedAt == null) return const SizedBox.shrink();

    final formatted = DateFormat('dd.MM.yyyy HH:mm', 'de').format(syncedAt!);

    return Text(
      'Zuletzt aktualisiert: $formatted',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
