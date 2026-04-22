import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import 'models/building_model.dart';

final buildingRepositoryProvider = Provider<BuildingRepository>((ref) {
  return BuildingRepository(
    tokenStorage: ref.watch(tokenStorageProvider),
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class BuildingRepository {
  BuildingRepository({
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

  BuildingModel _rowToBuilding(BuildingsTableData row) => BuildingModel(
        id: row.id,
        name: row.name,
        address: row.address,
        description: row.description,
        enabled: row.enabled,
        projectId: row.projectId,
      );

  BuildingInspectionModel _rowToInspection(BuildingInspectionsTableData row) =>
      BuildingInspectionModel(
        id: row.id,
        buildingId: row.buildingId,
        buildingName: row.buildingName,
        title: row.title,
        inspectionDate: row.inspectionDate,
        status: row.status,
        overallResult: row.overallResult,
        createdByName: row.createdByName,
        weather: row.weather,
        attendees: row.attendees,
        generalNotes: row.generalNotes,
      );

  Stream<List<BuildingModel>> getBuildings(int? projectId) async* {
    final local = projectId != null
        ? await _db.buildingDao.getBuildingsByProject(projectId)
        : await _db.buildingDao.getAllBuildings();
    if (local.isNotEmpty) {
      yield local.map(_rowToBuilding).toList();
    }

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get(
          'building_list',
          queryParams: projectId != null ? {'project_id': projectId} : null,
        );
        final list = (data['buildings'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        await _db.buildingDao.upsertAllBuildings(list
            .map((b) => BuildingsTableCompanion.insert(
                  id: Value(b['id'] as int),
                  name: b['name']?.toString() ?? '',
                  address: Value(b['address']?.toString()),
                  description: Value(b['description']?.toString()),
                  enabled: Value(b['enabled'] as bool? ?? true),
                  projectId: Value(b['project_id'] as int?),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = projectId != null
            ? await _db.buildingDao.getBuildingsByProject(projectId)
            : await _db.buildingDao.getAllBuildings();
        yield updated.map(_rowToBuilding).toList();
      } on NetworkException {
        // Use local
      } catch (_) {}
    }
  }

  Stream<List<BuildingInspectionModel>> getInspections({
    int? buildingId,
    String? status,
    int? year,
    int limit = 50,
    int offset = 0,
  }) async* {
    final local = buildingId != null
        ? await _db.buildingDao.getInspectionsByBuilding(buildingId)
        : await _db.buildingDao.getAllInspections();
    if (local.isNotEmpty) {
      yield local.map(_rowToInspection).toList();
    }

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final params = <String, dynamic>{'limit': limit, 'offset': offset};
        if (buildingId != null) params['building_id'] = buildingId;
        if (status != null) params['status'] = status;
        if (year != null) params['year'] = year;

        final data =
            await client.get('building_inspections', queryParams: params);
        final list = (data['inspections'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        await _db.buildingDao.upsertAllInspections(list
            .map((i) => BuildingInspectionsTableCompanion.insert(
                  id: Value(i['id'] as int),
                  buildingId: i['building_id'] as int,
                  buildingName: Value(i['building_name']?.toString()),
                  title: Value(i['title']?.toString()),
                  inspectionDate: i['inspection_date']?.toString() ?? '',
                  status: i['status']?.toString() ?? '',
                  overallResult: Value(i['overall_result']?.toString()),
                  createdByName: Value(i['created_by_name']?.toString()),
                  weather: Value(i['weather']?.toString()),
                  attendees: Value(i['attendees']?.toString()),
                  generalNotes: Value(i['general_notes']?.toString()),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = buildingId != null
            ? await _db.buildingDao.getInspectionsByBuilding(buildingId)
            : await _db.buildingDao.getAllInspections();
        yield updated.map(_rowToInspection).toList();
      } on NetworkException {
        // Use local
      } catch (_) {}
    }
  }

  Stream<BuildingInspectionModel?> getInspectionDetail(int id) async* {
    final local = await _db.buildingDao.getInspectionById(id);
    if (local != null) yield _rowToInspection(local);

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get('building_inspection_detail',
            queryParams: {'id': id});
        final detail = data['inspection'] as Map<String, dynamic>? ?? data;
        final model = BuildingInspectionModel.fromJson(detail);

        await _db.buildingDao.upsertInspection(
          BuildingInspectionsTableCompanion.insert(
            id: Value(model.id),
            buildingId: model.buildingId,
            buildingName: Value(model.buildingName),
            title: Value(model.title),
            inspectionDate: model.inspectionDate,
            status: model.status,
            overallResult: Value(model.overallResult),
            createdByName: Value(model.createdByName),
            weather: Value(model.weather),
            attendees: Value(model.attendees),
            generalNotes: Value(model.generalNotes),
            syncedAt: Value(DateTime.now()),
          ),
        );
        yield model;
      } on NetworkException {
        // Use local
      } catch (_) {}
    }
  }
}
