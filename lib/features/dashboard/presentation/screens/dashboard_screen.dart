import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart' show selectedProjectIdProvider;
import '../../../../shared/widgets/last_synced_text.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/dashboard_repository.dart';

final _projectsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getProjectsList();
});

final _dashboardDataProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  final projectId = ref.watch(selectedProjectIdProvider);
  return repo.getDashboardData(projectId);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final permissions = ref.watch(userPermissionsProvider);
    final projectsAsync = ref.watch(_projectsProvider);
    final dashboardAsync = ref.watch(_dashboardDataProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DKC HandyApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.token_outlined),
            onPressed: () => context.push('/tokens'),
            tooltip: 'Tokens verwalten',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context, ref),
            tooltip: 'Abmelden',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: projectsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (projects) => _ProjectDropdown(
              projects: projects,
              selectedId: selectedProjectId,
              onChanged: (id) =>
                  ref.read(selectedProjectIdProvider.notifier).state = id,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_dashboardDataProvider);
                ref.invalidate(_projectsProvider);
              },
              child: dashboardAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Fehler beim Laden: $e'),
                ),
                data: (data) => _DashboardBody(
                  data: data,
                  permissions: permissions.valueOrNull,
                  user: user,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text('Möchten Sie sich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _ProjectDropdown extends StatelessWidget {
  const _ProjectDropdown({
    required this.projects,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> projects;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButton<int?>(
        value: selectedId,
        isExpanded: true,
        hint: const Text('Projekt wählen'),
        underline: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Alle Projekte'),
          ),
          ...projects.map(
            (p) => DropdownMenuItem<int?>(
              value: p['id'] as int?,
              child: Text(p['name']?.toString() ?? ''),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.permissions,
    required this.user,
  });

  final Map<String, dynamic> data;
  final dynamic permissions;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    // Read the actual sync time stored in the data map by the repository.
    final syncedAtRaw = data['_syncedAt'] as String?;
    final syncedAt =
        syncedAtRaw != null ? DateTime.tryParse(syncedAtRaw) : null;
    final modules = <_ModuleInfo>[
      _ModuleInfo(
        title: 'Mängelmeldungen',
        subtitle: _countLabel(data['mm_pending'], 'ausstehend'),
        icon: Icons.report_problem_outlined,
        color: Colors.orange,
        route: '/mm',
        visible: permissions?.canViewMm ?? true,
      ),
      _ModuleInfo(
        title: 'Netzersatzanlagen',
        subtitle: _countLabel(data['nea_total'], 'Systeme'),
        icon: Icons.electrical_services_outlined,
        color: Colors.blue,
        route: '/nea',
        visible: permissions?.canViewNea ?? true,
      ),
      _ModuleInfo(
        title: 'Gebäudebegehungen',
        subtitle: _countLabel(data['building_open'], 'offen'),
        icon: Icons.business_outlined,
        color: Colors.green,
        route: '/building',
        visible: permissions?.canViewBuilding ?? true,
      ),
      _ModuleInfo(
        title: 'Schlüsselverwaltung',
        subtitle: _countLabel(data['keys_issued'], 'ausgegeben'),
        icon: Icons.key_outlined,
        color: Colors.purple,
        route: '/keys',
        visible: permissions?.canViewKeys ?? true,
      ),
      _ModuleInfo(
        title: 'Klimaanlage',
        subtitle: 'Geräte verwalten',
        icon: Icons.ac_unit_outlined,
        color: Colors.cyan,
        route: '/klima',
        visible: permissions?.canViewKlima ?? true,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null) ...[
          Text(
            'Willkommen, ${user.vname} ${user.nname}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (syncedAt != null) ...[
            const SizedBox(height: 4),
            LastSyncedText(syncedAt: syncedAt),
          ],
          const SizedBox(height: 16),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: modules.where((m) => m.visible).length,
          itemBuilder: (context, index) {
            final visible = modules.where((m) => m.visible).toList();
            return _ModuleTile(info: visible[index]);
          },
        ),
      ],
    );
  }

  String _countLabel(dynamic count, String suffix) {
    if (count == null) return suffix;
    return '$count $suffix';
  }
}

class _ModuleInfo {
  const _ModuleInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.visible,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final bool visible;
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.info});

  final _ModuleInfo info;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(info.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icon, color: info.color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                info.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                info.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
