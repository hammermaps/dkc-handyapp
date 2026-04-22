import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../data/klima_repository.dart';
import '../../data/models/klima_model.dart';

final _klimaDevicesProvider =
    StreamProvider.autoDispose<List<KlimaDevice>>((ref) {
  return ref.watch(klimaRepositoryProvider).getDevices();
});

class KlimaScreen extends ConsumerWidget {
  const KlimaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(_klimaDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klimaanlage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_klimaDevicesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Warning banner about RMI hardware
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Echtzeit-Temperaturen und Live-Steuerbefehle erfordern '
                    'eine aktive RMI-Hardwareverbindung',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber[800],
                        ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: devicesAsync.when(
              loading: () =>
                  const AppLoadingWidget(label: 'Lade Geräte…'),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(_klimaDevicesProvider),
              ),
              data: (devices) => devices.isEmpty
                  ? const Center(child: Text('Keine Geräte gefunden'))
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(_klimaDevicesProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: devices.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) =>
                            _DeviceCard(device: devices[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final KlimaDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: device.enabled
                    ? Colors.cyan.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.ac_unit_outlined,
                color: device.enabled ? Colors.cyan : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Adresse: ${device.address}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (device.operatingMode != null)
                    Text(
                      'Modus: ${device.operatingMode}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (!device.enabled)
              const Text('Deaktiviert',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
