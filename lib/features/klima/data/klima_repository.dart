import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import 'models/klima_model.dart';

final klimaRepositoryProvider = Provider<KlimaRepository>((ref) {
  return KlimaRepository(
    tokenStorage: ref.watch(tokenStorageProvider),
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class KlimaRepository {
  KlimaRepository({
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

  KlimaDevice _rowToDevice(KlimaDevicesTableData row) => KlimaDevice(
        address: row.address,
        name: row.name,
        groupId: row.groupId,
        enabled: row.enabled,
        sort: row.sort,
        operatingMode: row.operatingMode,
      );

  Stream<List<KlimaDevice>> getDevices() async* {
    final local = await _db.klimaDao.getAll();
    if (local.isNotEmpty) {
      yield local.map(_rowToDevice).toList();
    }

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get('klima_devices');
        final list = (data['devices'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        await _db.klimaDao.upsertAll(list
            .map((d) => KlimaDevicesTableCompanion.insert(
                  address: Value(d['address'] as int),
                  name: d['name']?.toString() ?? '',
                  groupId: Value(d['group_id'] as int?),
                  enabled: Value(d['enabled'] as bool? ?? true),
                  sort: Value((d['sort'] as num?)?.toInt() ?? 0),
                  operatingMode: Value(d['operating_mode']?.toString()),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = await _db.klimaDao.getAll();
        yield updated.map(_rowToDevice).toList();
      } on NetworkException {
        // Use local
      } catch (_) {}
    }
  }

  /// Returns live status for all devices or a specific address.
  /// This requires active RMI hardware connection.
  Future<List<Map<String, dynamic>>> getStatus(int? address) async {
    final client = await _getClient();
    final params = address != null ? {'address': address} : null;
    final data = await client.get('klima_status', queryParams: params);
    final list = data['status'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
