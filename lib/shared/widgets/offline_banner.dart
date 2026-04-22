import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';

/// A banner displayed at the top of the screen when the device is offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityService = ref.watch(connectivityServiceProvider);

    return StreamBuilder<bool>(
      stream: connectivityService.isConnectedStream,
      builder: (context, snapshot) {
        // Default to online if no data yet; FutureBuilder handles initial check.
        final isConnected = snapshot.data ?? true;
        if (isConnected) return const SizedBox.shrink();

        return MaterialBanner(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline – zeige zwischengespeicherte Daten',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: const [SizedBox.shrink()],
        );
      },
    );
  }
}
