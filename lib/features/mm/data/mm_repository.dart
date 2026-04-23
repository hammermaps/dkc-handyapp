import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import 'models/mm_model.dart';

final mmRepositoryProvider = Provider<MmRepository>((ref) {
  return MmRepository(
    tokenStorage: ref.watch(tokenStorageProvider),
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class MmRepository {
  MmRepository({
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

  MmListItem _rowToListItem(MangelmeldungenTableData row) => MmListItem(
        uid: row.uid,
        status: row.status,
        betreff: row.betreff,
        street: row.street,
        whg: row.whg,
        melder: row.melder,
        datetime: row.datetime,
        dringlichkeit: row.dringlichkeit,
      );

  MmDetail _rowToDetail(MangelmeldungenTableData row) => MmDetail(
        uid: row.uid,
        status: row.status,
        betreff: row.betreff,
        meldungMassage: row.meldungMassage,
        street: row.street,
        whg: row.whg,
        melder: row.melder,
        tel: row.tel,
        email: row.email,
        datetime: row.datetime,
        dringlichkeit: row.dringlichkeit,
        nachunternehmer: row.nachunternehmer,
        zugeh: row.zugeh,
        scanned: row.scanned,
      );

  Stream<List<MmListItem>> getList({
    int? status,
    String? street,
    int limit = 50,
    int offset = 0,
  }) async* {
    // 1. Yield from local DB
    final localRows = status != null
        ? await _db.mmDao.getByStatus(status)
        : await _db.mmDao.getAll();
    if (localRows.isNotEmpty) {
      yield localRows.map(_rowToListItem).toList();
    }

    // 2. Fetch from API
    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final params = <String, dynamic>{'limit': limit, 'offset': offset};
        if (status != null) params['status'] = status;
        if (street != null && street.isNotEmpty) params['street'] = street;

        final data = await client.get('mm_list', queryParams: params);
        final list = (data['meldungen'] as List<dynamic>? ??
                data['items'] as List<dynamic>? ??
                [])
            .cast<Map<String, dynamic>>();

        await _db.mmDao.upsertAll(list
            .map((m) => MangelmeldungenTableCompanion.insert(
                  uid: m['uid']?.toString() ?? '',
                  status: Value((m['status'] as num?)?.toInt() ?? 0),
                  betreff: Value(m['betreff']?.toString()),
                  meldungMassage: Value(m['meldung_massage']?.toString()),
                  street: Value(m['street']?.toString()),
                  whg: Value(m['whg']?.toString()),
                  melder: Value(m['melder']?.toString()),
                  tel: Value(m['tel']?.toString()),
                  email: Value(m['email']?.toString()),
                  datetime: Value(m['datetime']?.toString()),
                  dringlichkeit: Value(m['dringlichkeit']?.toString()),
                  nachunternehmer: Value(m['nachunternehmer']?.toString()),
                  zugeh: Value(m['zugeh']?.toString()),
                  scanned: Value(m['scanned'] as bool? ?? false),
                  syncedAt: Value(DateTime.now()),
                ))
            .toList());

        final updated = status != null
            ? await _db.mmDao.getByStatus(status)
            : await _db.mmDao.getAll();
        yield updated.map(_rowToListItem).toList();
      } on NetworkException {
        // Already yielded local data
      } catch (_) {}
    }
  }

  Stream<MmDetail?> getDetail(String uid) async* {
    final local = await _db.mmDao.getByUid(uid);
    if (local != null) yield _rowToDetail(local);

    if (await _connectivity.checkConnectivity()) {
      try {
        final client = await _getClient();
        final data = await client.get('mm_detail', queryParams: {'uid': uid});
        final detail = data['meldung'] as Map<String, dynamic>? ?? data;
        final model = MmDetail.fromJson(detail);

        await _db.mmDao.upsert(MangelmeldungenTableCompanion.insert(
          uid: model.uid,
          status: Value(model.status),
          betreff: Value(model.betreff),
          meldungMassage: Value(model.meldungMassage),
          street: Value(model.street),
          whg: Value(model.whg),
          melder: Value(model.melder),
          tel: Value(model.tel),
          email: Value(model.email),
          datetime: Value(model.datetime),
          dringlichkeit: Value(model.dringlichkeit),
          nachunternehmer: Value(model.nachunternehmer),
          zugeh: Value(model.zugeh),
          scanned: Value(model.scanned),
          syncedAt: Value(DateTime.now()),
        ));
        yield model;
      } on NetworkException {
        // Already yielded local data
      } catch (_) {}
    }
  }
}
