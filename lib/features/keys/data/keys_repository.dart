import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import 'models/key_model.dart';

final keysRepositoryProvider = Provider<KeysRepository>((ref) {
  return KeysRepository(
    tokenStorage: ref.watch(tokenStorageProvider),
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class KeysRepository {
  KeysRepository({
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

  KeyItem _rowToKey(KeysTableData row) => KeyItem(
        id: row.id,
        number: row.number,
        name: row.name,
        description: row.description,
        typeId: row.typeId,
        cabinetId: row.cabinetId,
        totalCount: row.totalCount,
        enabled: row.enabled,
      );

  KeyIssued _rowToIssued(KeysIssuedTableData row) => KeyIssued(
        id: row.id,
        keyId: row.keyId,
        keyNumber: row.keyNumber,
        keyName: row.keyName,
        recipientName: row.recipientName,
        issuedAt: row.issuedAt,
        issuedBy: row.issuedBy,
        notes: row.notes,
      );

  Stream<List<KeyItem>> getInventory({
    String? status,
    int limit = 100,
    int offset = 0,
  }) async* {
    final local = await _db.keysDao.getAllKeys();
    if (local.isNotEmpty) {
      yield local.map(_rowToKey).toList();
    }

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final params = <String, dynamic>{'limit': limit, 'offset': offset};
        if (status != null) params['status'] = status;

        final data = await client.get('keys_inventory', queryParams: params);
        final list = (data['keys'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        await _db.keysDao.upsertAllKeys(list
            .map((k) => KeysTableCompanion.insert(
                  id: Value(k['id'] as int),
                  number: Value(k['number']?.toString()),
                  name: k['name']?.toString() ?? '',
                  description: Value(k['description']?.toString()),
                  typeId: Value(k['type_id'] as int?),
                  cabinetId: Value(k['cabinet_id'] as int?),
                  totalCount:
                      Value((k['total_count'] as num?)?.toInt() ?? 0),
                  enabled: Value(k['enabled'] as bool? ?? true),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = await _db.keysDao.getAllKeys();
        yield updated.map(_rowToKey).toList();
      } on NetworkException {
        // Use local
      } catch (_) {}
    }
  }

  Stream<List<KeyIssued>> getIssued({
    int limit = 100,
    int offset = 0,
  }) async* {
    final local = await _db.keysDao.getAllIssued();
    if (local.isNotEmpty) {
      yield local.map(_rowToIssued).toList();
    }

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get('keys_issued',
            queryParams: {'limit': limit, 'offset': offset});
        final list = (data['issued'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        await _db.keysDao.upsertAllIssued(list
            .map((i) => KeysIssuedTableCompanion.insert(
                  id: Value(i['id'] as int),
                  keyId: i['key_id'] as int,
                  keyNumber: Value(i['key_number']?.toString()),
                  keyName: Value(i['key_name']?.toString()),
                  recipientName: i['recipient_name']?.toString() ?? '',
                  issuedAt: i['issued_at']?.toString() ?? '',
                  issuedBy: Value(i['issued_by']?.toString()),
                  notes: Value(i['notes']?.toString()),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = await _db.keysDao.getAllIssued();
        yield updated.map(_rowToIssued).toList();
      } on NetworkException {
        // Use local
      } catch (_) {}
    }
  }
}
