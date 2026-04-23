import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../data/mm_repository.dart';
import '../../data/models/mm_model.dart';

final _mmStatusFilterProvider = StateProvider.autoDispose<int?>((_) => null);
final _mmStreetFilterProvider = StateProvider.autoDispose<String>((_) => '');

final _mmListProvider = StreamProvider.autoDispose<List<MmListItem>>((ref) {
  final statusFilter = ref.watch(_mmStatusFilterProvider);
  final streetFilter = ref.watch(_mmStreetFilterProvider);
  return ref.watch(mmRepositoryProvider).getList(
        status: statusFilter,
        street: streetFilter.isEmpty ? null : streetFilter,
      );
});

class MmListScreen extends ConsumerStatefulWidget {
  const MmListScreen({super.key});

  @override
  ConsumerState<MmListScreen> createState() => _MmListScreenState();
}

class _MmListScreenState extends ConsumerState<MmListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mmAsync = ref.watch(_mmListProvider);
    final statusFilter = ref.watch(_mmStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mängelmeldungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_mmListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Straße suchen…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(_mmStreetFilterProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(_mmStreetFilterProvider.notifier).state = v,
            ),
          ),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _StatusChip(
                  label: 'Alle',
                  selected: statusFilter == null,
                  color: Colors.grey,
                  onSelected: () => ref
                      .read(_mmStatusFilterProvider.notifier)
                      .state = null,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Ausstehend',
                  selected: statusFilter == 0,
                  color: Colors.grey,
                  onSelected: () =>
                      ref.read(_mmStatusFilterProvider.notifier).state = 0,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Freigegeben',
                  selected: statusFilter == 1,
                  color: Colors.blue,
                  onSelected: () =>
                      ref.read(_mmStatusFilterProvider.notifier).state = 1,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Erledigt',
                  selected: statusFilter == 2,
                  color: Colors.green,
                  onSelected: () =>
                      ref.read(_mmStatusFilterProvider.notifier).state = 2,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Gesperrt',
                  selected: statusFilter == 3,
                  color: Colors.red,
                  onSelected: () =>
                      ref.read(_mmStatusFilterProvider.notifier).state = 3,
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: mmAsync.when(
              loading: () =>
                  const AppLoadingWidget(label: 'Lade Mängelmeldungen…'),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(_mmListProvider),
              ),
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text('Keine Mängelmeldungen gefunden'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(_mmListProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _MmCard(item: items[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: selected
          ? TextStyle(color: color, fontWeight: FontWeight.w600)
          : null,
    );
  }
}

class _MmCard extends StatelessWidget {
  const _MmCard({required this.item});

  final MmListItem item;

  static const _statusLabels = {
    0: 'Ausstehend',
    1: 'Freigegeben',
    2: 'Erledigt',
    3: 'Gesperrt',
  };

  static const _statusColors = {
    0: Colors.grey,
    1: Colors.blue,
    2: Colors.green,
    3: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        _statusLabels[item.status] ?? 'Status ${item.status}';
    final statusColor = _statusColors[item.status] ?? Colors.grey;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/mm/${item.uid}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.uid,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                  _Badge(label: statusLabel, color: statusColor),
                  if (item.dringlichkeit != null) ...[
                    const SizedBox(width: 6),
                    _Badge(
                      label: item.dringlichkeit!,
                      color: item.dringlichkeit!.toLowerCase() == 'hoch' ||
                              item.dringlichkeit!.toLowerCase() == 'dringend'
                          ? Colors.deepOrange
                          : Colors.orange,
                    ),
                  ],
                ],
              ),
              if (item.betreff != null) ...[
                const SizedBox(height: 6),
                Text(
                  item.betreff!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (item.street != null || item.whg != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      [item.street, item.whg]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (item.datetime != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      item.datetime!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
