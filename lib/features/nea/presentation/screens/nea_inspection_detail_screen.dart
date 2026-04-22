import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/nea_inspection_model.dart';
import '../../data/nea_repository.dart';

final _inspectionDetailProvider =
    StreamProvider.autoDispose.family<NeaInspectionModel?, int>(
  (ref, id) => ref.watch(neaRepositoryProvider).getInspectionDetail(id),
);

class NeaInspectionDetailScreen extends ConsumerWidget {
  const NeaInspectionDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_inspectionDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prüfungsdetails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_inspectionDetailProvider(id)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppLoadingWidget(label: 'Lade Prüfung…'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(_inspectionDetailProvider(id)),
        ),
        data: (inspection) {
          if (inspection == null) {
            return const Center(child: Text('Prüfung nicht gefunden'));
          }
          return _InspectionDetailBody(inspection: inspection);
        },
      ),
    );
  }
}

class _InspectionDetailBody extends StatelessWidget {
  const _InspectionDetailBody({required this.inspection});

  final NeaInspectionModel inspection;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Allgemeine Informationen',
          children: [
            _DetailRow('System', inspection.systemName ?? '#${inspection.neaSystemId}'),
            _DetailRow('Datum', inspection.inspectionDate),
            if (inspection.inspectionType != null)
              _DetailRow('Typ', inspection.inspectionType!),
            if (inspection.inspectorName != null)
              _DetailRow('Prüfer', inspection.inspectorName!),
            _DetailRow('Status', inspection.status),
            if (inspection.overallResult != null)
              _DetailRow(
                'Gesamtergebnis',
                inspection.overallResult!,
                valueColor: _resultColor(inspection.overallResult),
              ),
            if (inspection.runtimeHours != null)
              _DetailRow('Betriebsstunden', '${inspection.runtimeHours} h'),
          ],
        ),
        if (inspection.notes != null && inspection.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Notizen',
            children: [
              Text(inspection.notes!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
        if (inspection.defectNotes != null &&
            inspection.defectNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Mängelnotizen',
            children: [
              Text(
                inspection.defectNotes!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
        ],
        if (inspection.checklistData != null &&
            inspection.checklistData!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Checkliste',
            children: inspection.checklistData!.entries
                .map((entry) => _DetailRow(entry.key, entry.value.toString()))
                .toList(),
          ),
        ],
        if (inspection.photos != null && inspection.photos!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Fotos (${inspection.photos!.length})',
            children: inspection.photos!
                .map((photo) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_outlined, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(photo,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Color? _resultColor(String? result) {
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: valueColor != null ? FontWeight.w600 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
