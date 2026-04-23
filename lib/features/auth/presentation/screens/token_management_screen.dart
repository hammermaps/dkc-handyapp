import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exception.dart';
import '../providers/auth_provider.dart';

final _tokensProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.getUserTokens();
  },
);

class TokenManagementScreen extends ConsumerWidget {
  const TokenManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync = ref.watch(_tokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Token-Verwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_tokensProvider),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: tokensAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : 'Fehler beim Laden der Tokens',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (tokens) => tokens.isEmpty
            ? const Center(child: Text('Keine Tokens gefunden'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tokens.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final token = tokens[index];
                  return _TokenCard(token: token);
                },
              ),
      ),
    );
  }
}

class _TokenCard extends ConsumerWidget {
  const _TokenCard({required this.token});

  final Map<String, dynamic> token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'de');

    String? _formatDate(dynamic raw) {
      if (raw == null) return null;
      try {
        return dateFormat.format(DateTime.parse(raw.toString()));
      } catch (_) {
        return raw.toString();
      }
    }

    final name = token['name']?.toString() ?? 'Unbekannt';
    final expiresAt = _formatDate(token['expires_at']);
    final lastUsedAt = _formatDate(token['last_used_at']);
    final lastIp = token['last_ip']?.toString();
    final tokenId = token['id'] as int?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.token_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (tokenId != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                    tooltip: 'Token löschen',
                    onPressed: () =>
                        _confirmDelete(context, ref, tokenId, name),
                  ),
              ],
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: 4),
              _InfoRow(icon: Icons.calendar_today_outlined,
                  label: 'Läuft ab: $expiresAt'),
            ],
            if (lastUsedAt != null) ...[
              const SizedBox(height: 4),
              _InfoRow(icon: Icons.access_time_outlined,
                  label: 'Zuletzt genutzt: $lastUsedAt'),
            ],
            if (lastIp != null) ...[
              const SizedBox(height: 4),
              _InfoRow(icon: Icons.computer_outlined, label: 'IP: $lastIp'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int tokenId,
    String tokenName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Token löschen?'),
        content: Text(
            'Möchten Sie den Token "$tokenName" wirklich löschen? '
            'Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteToken(tokenId);
      ref.invalidate(_tokensProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token gelöscht')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: ${e.message}')),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
