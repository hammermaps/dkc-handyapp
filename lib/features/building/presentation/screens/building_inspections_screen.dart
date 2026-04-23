import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../data/building_repository.dart';
import '../../data/models/building_model.dart';

final _buildingInspectionsProvider =
    StreamProvider.autoDispose.family<List<BuildingInspectionModel>, int?>(
  (ref, buildingId) =>
      ref.watch(buildingRepositoryProvider).getInspections(buildingId: buildingId),
);

class BuildingInspectionsScreen extends ConsumerWidget {
  const BuildingInspectionsScreen({required this.buildingId, super.key});

  final int buildingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionsAsync =
        ref.watch(_buildingInspectionsProvider(buildingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Begehungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(_buildingInspectionsProvider(buildingId)),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: inspectionsAsync.when(
              loading: () =>
                  const AppLoadingWidget(label: 'Lade Begehungen…'),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref
                    .invalidate(_buildingInspectionsProvider(buildingId)),
              ),
              data: (inspections) => inspections.isEmpty
                  ? const Center(child: Text('Keine Begehungen gefunden'))
                  : RefreshIndicator(
                      onRefresh: () async => ref
                          .invalidate(_buildingInspectionsProvider(buildingId)),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: inspections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) =>
                            _InspectionCard(inspection: inspections[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  const _InspectionCard({required this.inspection});

  final BuildingInspectionModel inspection;

  @override
  Widget build(BuildContext context) {
    final resultColor = _resultColor(inspection.overallResult);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push('/building/inspection/${inspection.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inspection.title ??
                          'Begehung #${inspection.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  if (inspection.overallResult != null)
                    _Chip(
                        label: inspection.overallResult!,
                        color: resultColor),
                ],
              ),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 13),
                const SizedBox(width: 4),
                Text(inspection.inspectionDate,
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              if (inspection.createdByName != null)
                Row(children: [
                  const Icon(Icons.person_outline, size: 13),
                  const SizedBox(width: 4),
                  Text(inspection.createdByName!,
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              const SizedBox(height: 4),
              _Chip(label: inspection.status, color: _statusColor(inspection.status)),
            ],
          ),
        ),
      ),
    );
  }

  Color _resultColor(String? result) {
    switch (result?.toLowerCase()) {
      case 'ok':
        return Colors.green;
      case 'not_ok':
      case 'nok':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'abgeschlossen':
        return Colors.green;
      case 'in_progress':
      case 'in bearbeitung':
        return Colors.blue;
      case 'open':
      case 'offen':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

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
