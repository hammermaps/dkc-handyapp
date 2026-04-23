import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../data/keys_repository.dart';
import '../../data/models/key_model.dart';

final _inventoryProvider = StreamProvider.autoDispose<List<KeyItem>>(
  (ref) => ref.watch(keysRepositoryProvider).getInventory(),
);
final _issuedProvider = StreamProvider.autoDispose<List<KeyIssued>>(
  (ref) => ref.watch(keysRepositoryProvider).getIssued(),
);

class KeysScreen extends ConsumerWidget {
  const KeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schlüsselverwaltung'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Inventar'), Tab(text: 'Ausgegeben')],
          ),
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: TabBarView(
                children: [
                  _InventoryTab(),
                  _IssuedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_inventoryProvider);
    return async.when(
      loading: () => const AppLoadingWidget(label: 'Lade Inventar…'),
      error: (e, _) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(_inventoryProvider)),
      data: (keys) => keys.isEmpty
          ? const Center(child: Text('Kein Inventar'))
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(_inventoryProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: keys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.key_outlined),
                    title: Text(keys[i].name),
                    subtitle: Text(keys[i].number != null ? 'Nr: ${keys[i].number}' : 'Gesamt: ${keys[i].totalCount}'),
                    trailing: !keys[i].enabled ? const Text('Deaktiviert', style: TextStyle(fontSize: 11)) : null,
                  ),
                ),
              ),
            ),
    );
  }
}

class _IssuedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_issuedProvider);
    return async.when(
      loading: () => const AppLoadingWidget(label: 'Lade ausgegebene Schlüssel…'),
      error: (e, _) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(_issuedProvider)),
      data: (issued) => issued.isEmpty
          ? const Center(child: Text('Keine ausgegeben'))
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(_issuedProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: issued.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(issued[i].recipientName),
                    subtitle: Text('${issued[i].keyName ?? issued[i].keyId} – ${issued[i].issuedAt}'),
                    trailing: issued[i].issuedBy != null ? Text(issued[i].issuedBy!, style: const TextStyle(fontSize: 11)) : null,
                  ),
                ),
              ),
            ),
    );
  }
}
