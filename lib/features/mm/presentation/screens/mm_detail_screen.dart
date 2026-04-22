import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/mm_repository.dart';
import '../../data/models/mm_model.dart';

final _mmDetailProvider =
    StreamProvider.autoDispose.family<MmDetail?, String>(
  (ref, uid) => ref.watch(mmRepositoryProvider).getDetail(uid),
);

class MmDetailScreen extends ConsumerWidget {
  const MmDetailScreen({required this.uid, super.key});

  final String uid;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_mmDetailProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: Text('MM $uid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_mmDetailProvider(uid)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppLoadingWidget(label: 'Lade Meldung…'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(_mmDetailProvider(uid)),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Meldung nicht gefunden'));
          }
          return _DetailBody(detail: detail);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final MmDetail detail;

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
    final statusLabel = _statusLabels[detail.status] ?? 'Status ${detail.status}';
    final statusColor = _statusColors[detail.status] ?? Colors.grey;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status header
        Card(
          color: statusColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
                const Spacer(),
                if (detail.dringlichkeit != null)
                  Column(
                    children: [
                      Text('Dringlichkeit',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        detail.dringlichkeit!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Subject
        if (detail.betreff != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Betreff',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          )),
                  const SizedBox(height: 4),
                  Text(detail.betreff!,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Details card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 16),
                _Row('UID', detail.uid),
                if (detail.street != null) _Row('Straße', detail.street!),
                if (detail.whg != null) _Row('Wohnung', detail.whg!),
                if (detail.datetime != null) _Row('Datum', detail.datetime!),
                if (detail.melder != null) _Row('Melder', detail.melder!),
                if (detail.tel != null) _Row('Telefon', detail.tel!),
                if (detail.email != null) _Row('E-Mail', detail.email!),
                if (detail.nachunternehmer != null)
                  _Row('Nachunternehmer', detail.nachunternehmer!),
                if (detail.zugeh != null) _Row('Zugehörigkeit', detail.zugeh!),
                _Row('Gescannt', detail.scanned ? 'Ja' : 'Nein'),
              ],
            ),
          ),
        ),

        // Message
        if (detail.meldungMassage != null &&
            detail.meldungMassage!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meldungstext',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(height: 16),
                  Text(detail.meldungMassage!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
