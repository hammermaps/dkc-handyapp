import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../nea/data/models/nea_system_model.dart';
import '../../data/nea_repository.dart';

final _neaSystemsProvider =
    StreamProvider.autoDispose.family<List<NeaSystemModel>, int?>(
  (ref, projectId) => ref.watch(neaRepositoryProvider).getSystems(projectId),
);

class NeaSystemsScreen extends ConsumerWidget {
  const NeaSystemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(_neaSystemsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEA Systeme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_neaSystemsProvider),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: systemsAsync.when(
              loading: () => const AppLoadingWidget(label: 'Lade Systeme…'),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(_neaSystemsProvider),
              ),
              data: (systems) => systems.isEmpty
                  ? const Center(child: Text('Keine NEA Systeme gefunden'))
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(_neaSystemsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: systems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) =>
                            _NeaSystemCard(system: systems[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeaSystemCard extends StatelessWidget {
  const _NeaSystemCard({required this.system});

  final NeaSystemModel system;

  @override
  Widget build(BuildContext context) {
    final resultColor = _resultColor(system.lastInspectionResult);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/nea/inspections',
            extra: {'systemId': system.id, 'systemName': system.name}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      system.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (system.lastInspectionResult != null)
                    _ResultBadge(
                      result: system.lastInspectionResult!,
                      color: resultColor,
                    ),
                ],
              ),
              if (system.location != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(system.location!,
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ],
              if (system.lastInspectionDate != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text('Letzte Prüfung: ${system.lastInspectionDate}',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ],
              if (!system.enabled) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Deaktiviert',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _resultColor(String? result) {
    switch (result?.toLowerCase()) {
      case 'passed':
      case 'bestanden':
        return Colors.green;
      case 'failed':
      case 'nicht bestanden':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result, required this.color});

  final String result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        result,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
