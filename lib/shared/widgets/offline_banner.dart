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
      // The ConnectivityService emits the current state on construction, but
      // use a FutureBuilder as the initial-data fallback for the first frame.
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return FutureBuilder<bool>(
            future: connectivityService.checkConnectivity(),
            builder: (_, futureSnap) {
              final isConnected = futureSnap.data ?? true;
              if (isConnected) return const SizedBox.shrink();
              return _OfflineBannerContent();
            },
          );
        }

        final isConnected = snapshot.data!;
        if (isConnected) return const SizedBox.shrink();
        return _OfflineBannerContent();
      },
    );
  }
}

class _OfflineBannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
  }
}
