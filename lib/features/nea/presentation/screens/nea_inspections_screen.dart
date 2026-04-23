import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../data/models/nea_inspection_model.dart';
import '../../data/nea_repository.dart';

class NeaInspectionFilters {
  const NeaInspectionFilters({
    this.systemId,
    this.year,
    this.status,
  });

  final int? systemId;
  final int? year;
  final String? status;
}

final _filtersProvider =
    StateProvider.autoDispose((ref) => const NeaInspectionFilters());

final _inspectionsProvider =
    StreamProvider.autoDispose<List<NeaInspectionModel>>((ref) {
  final filters = ref.watch(_filtersProvider);
  return ref.watch(neaRepositoryProvider).getInspections(
        systemId: filters.systemId,
        year: filters.year,
        status: filters.status,
      );
});

class NeaInspectionsScreen extends ConsumerStatefulWidget {
  const NeaInspectionsScreen({this.systemId, this.systemName, super.key});

  final int? systemId;
  final String? systemName;

  @override
  ConsumerState<NeaInspectionsScreen> createState() =>
      _NeaInspectionsScreenState();
}

class _NeaInspectionsScreenState extends ConsumerState<NeaInspectionsScreen> {
  @override
  void initState() {
    super.initState();
    // Seed the filter with the system ID passed via the route so the
    // repository query is scoped correctly from the first load.
    if (widget.systemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(_filtersProvider.notifier).state =
              NeaInspectionFilters(systemId: widget.systemId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspectionsAsync = ref.watch(_inspectionsProvider);
    final filters = ref.watch(_filtersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.systemName != null
            ? 'Prüfungen: ${widget.systemName}'
            : 'NEA Prüfungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_inspectionsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, filters),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          if (filters.year != null || filters.status != null)
            _ActiveFiltersRow(filters: filters, ref: ref),
          Expanded(
            child: inspectionsAsync.when(
              loading: () => const AppLoadingWidget(label: 'Lade Prüfungen…'),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(_inspectionsProvider),
              ),
              data: (inspections) {
                if (inspections.isEmpty) {
                  return const Center(
                      child: Text('Keine Prüfungen gefunden'));
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(_inspectionsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: inspections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _InspectionCard(inspection: inspections[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, NeaInspectionFilters current) {
    final currentYear = DateTime.now().year;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _FilterSheet(
        current: current,
        currentYear: currentYear,
        onApply: (filters) {
          ref.read(_filtersProvider.notifier).state = filters;
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({required this.filters, required this.ref});

  final NeaInspectionFilters filters;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (filters.year != null)
            Chip(
              label: Text('${filters.year}'),
              onDeleted: () => ref.read(_filtersProvider.notifier).state =
                  NeaInspectionFilters(status: filters.status),
            ),
          if (filters.status != null)
            Chip(
              label: Text(filters.status!),
              onDeleted: () => ref.read(_filtersProvider.notifier).state =
                  NeaInspectionFilters(year: filters.year),
            ),
        ],
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  const _InspectionCard({required this.inspection});

  final NeaInspectionModel inspection;

  @override
  Widget build(BuildContext context) {
    final resultColor = _resultColor(inspection.overallResult);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/nea/inspection/${inspection.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inspection.systemName ?? 'System #${inspection.neaSystemId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (inspection.overallResult != null)
                    _StatusChip(
                        label: inspection.overallResult!, color: resultColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Datum: ${inspection.inspectionDate}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (inspection.inspectorName != null)
                Text(
                  'Prüfer: ${inspection.inspectorName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (inspection.inspectionType != null)
                Text(
                  'Typ: ${inspection.inspectionType}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

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

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.current,
    required this.currentYear,
    required this.onApply,
  });

  final NeaInspectionFilters current;
  final int currentYear;
  final ValueChanged<NeaInspectionFilters> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int? _year;
  late String? _status;

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
    _status = widget.current.status;
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
        5, (i) => widget.currentYear - i);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filter', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            decoration: const InputDecoration(labelText: 'Jahr'),
            value: _year,
            items: [
              const DropdownMenuItem(value: null, child: Text('Alle Jahre')),
              ...years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
            ],
            onChanged: (v) => setState(() => _year = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            decoration: const InputDecoration(labelText: 'Status'),
            value: _status,
            items: const [
              DropdownMenuItem(value: null, child: Text('Alle Status')),
              DropdownMenuItem(value: 'passed', child: Text('Bestanden')),
              DropdownMenuItem(value: 'failed', child: Text('Nicht bestanden')),
              DropdownMenuItem(value: 'pending', child: Text('Ausstehend')),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _year = null;
                      _status = null;
                    });
                    widget.onApply(const NeaInspectionFilters());
                  },
                  child: const Text('Zurücksetzen'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onApply(NeaInspectionFilters(
                    year: _year,
                    status: _status,
                  )),
                  child: const Text('Anwenden'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
