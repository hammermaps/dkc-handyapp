import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import 'models/nea_inspection_model.dart';
import 'models/nea_system_model.dart';

final neaRepositoryProvider = Provider<NeaRepository>((ref) {
  return NeaRepository(
    tokenStorage: ref.watch(tokenStorageProvider),
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class NeaRepository {
  NeaRepository({
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

  NeaSystemModel _rowToSystem(NeasTableData row) => NeaSystemModel(
        id: row.id,
        name: row.name,
        description: row.description,
        location: row.location,
        manufacturer: row.manufacturer,
        model: row.model,
        serialNumber: row.serialNumber,
        installationDate: row.installationDate,
        enabled: row.enabled,
        projectId: row.projectId,
        lastInspectionDate: row.lastInspectionDate,
        lastInspectionResult: row.lastInspectionResult,
      );

  NeaInspectionModel _rowToInspection(NeaInspectionsTableData row) =>
      NeaInspectionModel(
        id: row.id,
        neaSystemId: row.neaSystemId,
        systemName: row.systemName,
        inspectionType: row.inspectionType,
        inspectionDate: row.inspectionDate,
        inspectorName: row.inspectorName,
        status: row.status,
        overallResult: row.overallResult,
        runtimeHours: row.runtimeHours,
        notes: row.notes,
        checklistData: row.checklistData != null
            ? jsonDecode(row.checklistData!) as Map<String, dynamic>
            : null,
        defectNotes: row.defectNotes,
        photos: row.photos != null
            ? (jsonDecode(row.photos!) as List).cast<String>()
            : null,
        createdAt: row.createdAt,
      );

  /// Returns NEA systems. Offline-first.
  Stream<List<NeaSystemModel>> getSystems(int? projectId) async* {
    final localRows = projectId != null
        ? await _db.neaDao.getNeasByProject(projectId)
        : await _db.neaDao.getAllNeas();
    if (localRows.isNotEmpty) {
      yield localRows.map(_rowToSystem).toList();
    }

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get(
          'nea_systems',
          queryParams: projectId != null ? {'project_id': projectId} : null,
        );
        final list = (data['systems'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        await _db.neaDao.upsertAllNeas(list
            .map((s) => NeasTableCompanion.insert(
                  id: Value(s['id'] as int),
                  name: s['name']?.toString() ?? '',
                  description: Value(s['description']?.toString()),
                  location: Value(s['location']?.toString()),
                  manufacturer: Value(s['manufacturer']?.toString()),
                  model: Value(s['model']?.toString()),
                  serialNumber: Value(s['serial_number']?.toString()),
                  installationDate: Value(s['installation_date']?.toString()),
                  enabled: Value(s['enabled'] as bool? ?? true),
                  projectId: Value(s['project_id'] as int?),
                  lastInspectionDate:
                      Value(s['last_inspection_date']?.toString()),
                  lastInspectionResult:
                      Value(s['last_inspection_result']?.toString()),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = projectId != null
            ? await _db.neaDao.getNeasByProject(projectId)
            : await _db.neaDao.getAllNeas();
        yield updated.map(_rowToSystem).toList();
      } on NetworkException {
        // Use local data
      } catch (_) {}
    }
  }

  /// Returns NEA dashboard data (raw map). Offline-first via DashboardCache.
  Stream<Map<String, dynamic>> getDashboard(int? projectId) async* {
    final cached = await _db.dashboardDao.getCacheForProject(projectId);
    if (cached != null) {
      final full = jsonDecode(cached.data) as Map<String, dynamic>;
      yield full['nea'] as Map<String, dynamic>? ?? full;
    }

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get(
          'nea_dashboard',
          queryParams: projectId != null ? {'project_id': projectId} : null,
        );
        yield data as Map<String, dynamic>;
      } on NetworkException {
        // Use cached
      } catch (_) {}
    }
  }

  /// Returns inspections, with optional filters.
  Stream<List<NeaInspectionModel>> getInspections({
    int? systemId,
    int? year,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async* {
    final localRows = systemId != null
        ? await _db.neaDao.getInspectionsBySystem(systemId)
        : await _db.neaDao.getAllInspections();
    if (localRows.isNotEmpty) {
      yield localRows.map(_rowToInspection).toList();
    }

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final params = <String, dynamic>{
          'limit': limit,
          'offset': offset,
        };
        if (systemId != null) params['system_id'] = systemId;
        if (year != null) params['year'] = year;
        if (status != null) params['status'] = status;

        final data = await client.get('nea_inspections', queryParams: params);
        final list = (data['inspections'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        await _db.neaDao.upsertAllInspections(list
            .map((i) => NeaInspectionsTableCompanion.insert(
                  id: Value(i['id'] as int),
                  neaSystemId: i['nea_system_id'] as int,
                  systemName: Value(i['system_name']?.toString()),
                  inspectionType: Value(i['inspection_type']?.toString()),
                  inspectionDate: i['inspection_date']?.toString() ?? '',
                  status: i['status']?.toString() ?? '',
                  inspectorName: Value(i['inspector_name']?.toString()),
                  overallResult: Value(i['overall_result']?.toString()),
                  runtimeHours: Value(
                      (i['runtime_hours'] as num?)?.toDouble()),
                  notes: Value(i['notes']?.toString()),
                  checklistData: Value(i['checklist_data'] != null
                      ? jsonEncode(i['checklist_data'])
                      : null),
                  defectNotes: Value(i['defect_notes']?.toString()),
                  photos: Value(i['photos'] != null
                      ? jsonEncode(i['photos'])
                      : null),
                  createdAt: Value(i['created_at']?.toString()),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = systemId != null
            ? await _db.neaDao.getInspectionsBySystem(systemId)
            : await _db.neaDao.getAllInspections();
        yield updated.map(_rowToInspection).toList();
      } on NetworkException {
        // Already yielded local data
      } catch (_) {}
    }
  }

  /// Returns a single inspection detail. Offline-first.
  Stream<NeaInspectionModel?> getInspectionDetail(int id) async* {
    final local = await _db.neaDao.getInspectionById(id);
    if (local != null) yield _rowToInspection(local);

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get('nea_inspection_detail',
            queryParams: {'id': id});
        final detail = data['inspection'] as Map<String, dynamic>? ?? data;
        final model = NeaInspectionModel.fromJson(detail);

        await _db.neaDao.upsertInspection(NeaInspectionsTableCompanion.insert(
          id: Value(model.id),
          neaSystemId: model.neaSystemId,
          systemName: Value(model.systemName),
          inspectionType: Value(model.inspectionType),
          inspectionDate: model.inspectionDate,
          status: model.status,
          inspectorName: Value(model.inspectorName),
          overallResult: Value(model.overallResult),
          runtimeHours: Value(model.runtimeHours),
          notes: Value(model.notes),
          checklistData: Value(
              model.checklistData != null ? jsonEncode(model.checklistData) : null),
          defectNotes: Value(model.defectNotes),
          photos: Value(model.photos != null ? jsonEncode(model.photos) : null),
          createdAt: Value(model.createdAt),
          syncedAt: Value(DateTime.now()),
        ));
        yield model;
      } on NetworkException {
        // Use local
      } catch (_) {}
    }
  }
}
