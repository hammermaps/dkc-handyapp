import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../data/building_repository.dart';
import '../../data/models/building_model.dart';

final _buildingsProvider =
    StreamProvider.autoDispose<List<BuildingModel>>((ref) {
  return ref.watch(buildingRepositoryProvider).getBuildings(null);
});

class BuildingListScreen extends ConsumerWidget {
  const BuildingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(_buildingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gebäude'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_buildingsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: buildingsAsync.when(
              loading: () =>
                  const AppLoadingWidget(label: 'Lade Gebäude…'),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(_buildingsProvider),
              ),
              data: (buildings) => buildings.isEmpty
                  ? const Center(child: Text('Keine Gebäude gefunden'))
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(_buildingsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: buildings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) =>
                            _BuildingCard(building: buildings[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  const _BuildingCard({required this.building});

  final BuildingModel building;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/building/${building.id}/inspections'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      building.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              if (building.address != null) ...[
                const SizedBox(height: 4),
                Text(building.address!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (building.description != null) ...[
                const SizedBox(height: 4),
                Text(building.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if (!building.enabled) ...[
                const SizedBox(height: 8),
                Text('Deaktiviert',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
