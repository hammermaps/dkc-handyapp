import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/database.dart';
import '../../../core/providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return DashboardRepository(
    tokenStorage: tokenStorage,
    db: db,
    connectivity: connectivity,
  );
});

/// Repository for dashboard data and project list. Implements offline-first pattern.
class DashboardRepository {
  DashboardRepository({
    required TokenStorage tokenStorage,
    required AppDatabase db,
    required ConnectivityService connectivity,
  })  : _tokenStorage = tokenStorage,
        _db = db,
        _connectivity = connectivity;

  final TokenStorage _tokenStorage;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  Future<ApiClient> _getClient() async {
    final url = await _tokenStorage.getServerUrl();
    final token = await _tokenStorage.getToken();
    if (url == null) throw const NetworkException(message: 'Server-URL fehlt');
    return ApiClient(baseUrl: url, tokenGetter: () => token);
  }

  /// Returns dashboard data as a JSON-decoded map.
  /// Loads from local DB first, then refreshes from API if online.
  Stream<Map<String, dynamic>> getDashboardData(int? projectId) async* {
    // 1. Yield cached data immediately (include syncedAt for the UI timestamp).
    final cached = await _db.dashboardDao.getCacheForProject(projectId);
    if (cached != null) {
      final map = jsonDecode(cached.data) as Map<String, dynamic>;
      map['_syncedAt'] = cached.syncedAt?.toIso8601String();
      yield map;
    }

    // 2. Fetch from API if online.
    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get(
          'dashboard_data',
          queryParams: projectId != null ? {'project_id': projectId} : null,
        );
        final now = DateTime.now();
        await _db.dashboardDao.upsertCache(
          DashboardCacheTableCompanion.insert(
            projectId: Value(projectId),
            data: jsonEncode(data),
            syncedAt: Value(now),
          ),
        );
        final map = Map<String, dynamic>.from(data as Map<String, dynamic>);
        map['_syncedAt'] = now.toIso8601String();
        yield map;
      } on NetworkException {
        // Already yielded cache
      } catch (_) {
        // Silently ignore API errors if we have cache
      }
    }
  }

  /// Returns list of projects. Offline-first.
  Stream<List<Map<String, dynamic>>> getProjectsList() async* {
    // 1. Yield from local DB first.
    final local = await _db.projectsDao.getAll();
    if (local.isNotEmpty) {
      yield local
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'description': p.description,
                'status': p.status,
                'created_at': p.createdAt,
              })
          .toList();
    }

    // 2. Refresh from API.
    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get('projects_list');
        final list = (data['projects'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        await _db.projectsDao.upsertAll(list
            .map((p) => ProjectsTableCompanion.insert(
                  id: Value(p['id'] as int),
                  name: p['name']?.toString() ?? '',
                  description: Value(p['description']?.toString()),
                  status: Value(p['status']?.toString()),
                  createdAt: Value(p['created_at']?.toString()),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = await _db.projectsDao.getAll();
        yield updated
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'description': p.description,
                  'status': p.status,
                  'created_at': p.createdAt,
                })
            .toList();
      } on NetworkException {
        // Already yielded local data
      } catch (_) {}
    }
  }
}
