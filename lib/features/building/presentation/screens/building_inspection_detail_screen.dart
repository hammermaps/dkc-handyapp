import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/building_repository.dart';
import '../../data/models/building_model.dart';

final _buildingInspectionDetailProvider =
    StreamProvider.autoDispose.family<BuildingInspectionModel?, int>(
  (ref, id) =>
      ref.watch(buildingRepositoryProvider).getInspectionDetail(id),
);

class BuildingInspectionDetailScreen extends ConsumerWidget {
  const BuildingInspectionDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(_buildingInspectionDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Begehungsdetails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(_buildingInspectionDetailProvider(id)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () =>
            const AppLoadingWidget(label: 'Lade Begehung…'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(_buildingInspectionDetailProvider(id)),
        ),
        data: (inspection) {
          if (inspection == null) {
            return const Center(child: Text('Begehung nicht gefunden'));
          }
          return _DetailBody(inspection: inspection);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.inspection});

  final BuildingInspectionModel inspection;

  @override
  Widget build(BuildContext context) {
    final resultColor = _resultColor(inspection.overallResult);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Allgemein',
          children: [
            _Row('Gebäude',
                inspection.buildingName ?? '#${inspection.buildingId}'),
            if (inspection.title != null)
              _Row('Titel', inspection.title!),
            _Row('Datum', inspection.inspectionDate),
            _Row('Status', inspection.status),
            if (inspection.overallResult != null)
              _Row('Gesamtergebnis', inspection.overallResult!,
                  valueColor: resultColor),
            if (inspection.createdByName != null)
              _Row('Erstellt von', inspection.createdByName!),
            if (inspection.weather != null)
              _Row('Wetter', inspection.weather!),
            if (inspection.attendees != null)
              _Row('Teilnehmer', inspection.attendees!),
          ],
        ),
        if (inspection.generalNotes != null &&
            inspection.generalNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Allgemeine Notizen',
            children: [
              Text(inspection.generalNotes!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
        if (inspection.checkpointResults != null &&
            inspection.checkpointResults!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Prüfpunkte',
            children: inspection.checkpointResults!
                .map((cp) => _CheckpointTile(checkpoint: cp))
                .toList(),
          ),
        ],
      ],
    );
  }

  Color? _resultColor(String? result) {
    switch (result?.toLowerCase()) {
      case 'ok':
        return Colors.green;
      case 'not_ok':
      case 'nok':
        return Colors.red;
      case 'na':
      case 'n/a':
        return Colors.grey;
      default:
        return null;
    }
  }
}

class _CheckpointTile extends StatelessWidget {
  const _CheckpointTile({required this.checkpoint});

  final Map<String, dynamic> checkpoint;

  @override
  Widget build(BuildContext context) {
    final name = checkpoint['name']?.toString() ?? checkpoint['title']?.toString() ?? '–';
    final result = checkpoint['result']?.toString();
    final notes = checkpoint['notes']?.toString();
    final color = _resultColor(result);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: color ?? Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (result != null)
                  Text(result,
                      style: TextStyle(
                          fontSize: 12, color: color ?? Colors.grey)),
                if (notes != null && notes.isNotEmpty)
                  Text(notes,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color? _resultColor(String? result) {
    switch (result?.toLowerCase()) {
      case 'ok':
        return Colors.green;
      case 'not_ok':
      case 'nok':
        return Colors.red;
      case 'na':
      case 'n/a':
        return Colors.grey;
      default:
        return null;
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.valueColor});

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
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                      fontWeight:
                          valueColor != null ? FontWeight.w600 : null,
                    )),
          ),
        ],
      ),
    );
  }
}
