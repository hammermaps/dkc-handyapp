import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../data/nea_repository.dart';

final _neaDashboardProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>, int?>(
  (ref, projectId) =>
      ref.watch(neaRepositoryProvider).getDashboard(projectId),
);

class NeaDashboardScreen extends ConsumerWidget {
  const NeaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(_neaDashboardProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEA – Netzersatzanlagen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_neaDashboardProvider),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: dashAsync.when(
              loading: () => const AppLoadingWidget(label: 'Lade Dashboard…'),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(_neaDashboardProvider),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(_neaDashboardProvider),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StatCard(
                      title: 'Gesamt',
                      value: '${data['total_systems'] ?? data['total'] ?? 0}',
                      icon: Icons.electrical_services_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Fällige Prüfungen',
                      value: '${data['due_count'] ?? data['due'] ?? 0}',
                      icon: Icons.warning_amber_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Zuletzt geprüft',
                      value: data['last_inspection_date']?.toString() ?? '–',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.push('/nea/systems'),
                            icon: const Icon(Icons.list_alt_outlined),
                            label: const Text('Alle Systeme'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/nea/inspections'),
                            icon: const Icon(Icons.history_outlined),
                            label: const Text('Prüfungen'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
