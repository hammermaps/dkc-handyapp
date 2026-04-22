import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ──────────────────────────── Tables ────────────────────────────

class NeasTable extends Table {
  @override
  String get tableName => 'neas';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get installationDate => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get projectId => integer().nullable()();
  TextColumn get lastInspectionDate => text().nullable()();
  TextColumn get lastInspectionResult => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class NeaInspectionsTable extends Table {
  @override
  String get tableName => 'nea_inspections';

  IntColumn get id => integer()();
  IntColumn get neaSystemId => integer()();
  TextColumn get systemName => text().nullable()();
  TextColumn get inspectionType => text().nullable()();
  TextColumn get inspectionDate => text()();
  TextColumn get inspectorName => text().nullable()();
  TextColumn get status => text()();
  TextColumn get overallResult => text().nullable()();
  RealColumn get runtimeHours => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get checklistData => text().nullable()(); // JSON blob
  TextColumn get defectNotes => text().nullable()();
  TextColumn get photos => text().nullable()(); // JSON array
  TextColumn get createdAt => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MangelmeldungenTable extends Table {
  @override
  String get tableName => 'mangelmeldungen';

  TextColumn get uid => text()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get betreff => text().nullable()();
  TextColumn get meldungMassage => text().nullable()();
  TextColumn get street => text().nullable()();
  TextColumn get whg => text().nullable()();
  TextColumn get melder => text().nullable()();
  TextColumn get tel => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get datetime => text().nullable()();
  TextColumn get dringlichkeit => text().nullable()();
  TextColumn get nachunternehmer => text().nullable()();
  TextColumn get zugeh => text().nullable()();
  BoolColumn get scanned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class BuildingsTable extends Table {
  @override
  String get tableName => 'buildings';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get projectId => integer().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BuildingInspectionsTable extends Table {
  @override
  String get tableName => 'building_inspections';

  IntColumn get id => integer()();
  IntColumn get buildingId => integer()();
  TextColumn get buildingName => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get inspectionDate => text()();
  TextColumn get status => text()();
  TextColumn get overallResult => text().nullable()();
  TextColumn get createdByName => text().nullable()();
  TextColumn get weather => text().nullable()();
  TextColumn get attendees => text().nullable()();
  TextColumn get generalNotes => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class KlimaDevicesTable extends Table {
  @override
  String get tableName => 'klima_devices';

  IntColumn get address => integer()();
  TextColumn get name => text()();
  IntColumn get groupId => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  TextColumn get operatingMode => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {address};
}

class KeysTable extends Table {
  @override
  String get tableName => 'keys_inventory';

  IntColumn get id => integer()();
  TextColumn get number => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get typeId => integer().nullable()();
  IntColumn get cabinetId => integer().nullable()();
  IntColumn get totalCount => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class KeysIssuedTable extends Table {
  @override
  String get tableName => 'keys_issued';

  IntColumn get id => integer()();
  IntColumn get keyId => integer()();
  TextColumn get keyNumber => text().nullable()();
  TextColumn get keyName => text().nullable()();
  TextColumn get recipientName => text()();
  TextColumn get issuedAt => text()();
  TextColumn get issuedBy => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DashboardCacheTable extends Table {
  @override
  String get tableName => 'dashboard_cache';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().nullable()();
  TextColumn get data => text()(); // JSON blob
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

class UserPermissionsTable extends Table {
  @override
  String get tableName => 'user_permissions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get permissionKey => text()();
  BoolColumn get hasPermission => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

class ProjectsTable extends Table {
  @override
  String get tableName => 'projects';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ──────────────────────────── DAOs ────────────────────────────

@DriftAccessor(tables: [NeasTable, NeaInspectionsTable])
class NeaDao extends DatabaseAccessor<AppDatabase> with _$NeaDaoMixin {
  NeaDao(super.db);

  Future<List<NeasTableData>> getAllNeas() => select(neasTable).get();

  Future<List<NeasTableData>> getNeasByProject(int projectId) =>
      (select(neasTable)..where((t) => t.projectId.equals(projectId))).get();

  Future<void> upsertNea(NeasTableCompanion entry) =>
      into(neasTable).insertOnConflictUpdate(entry);

  Future<void> upsertAllNeas(List<NeasTableCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(neasTable, entries));

  Future<List<NeaInspectionsTableData>> getAllInspections() =>
      select(neaInspectionsTable).get();

  Future<List<NeaInspectionsTableData>> getInspectionsBySystem(int systemId) =>
      (select(neaInspectionsTable)
            ..where((t) => t.neaSystemId.equals(systemId)))
          .get();

  Future<NeaInspectionsTableData?> getInspectionById(int id) =>
      (select(neaInspectionsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertInspection(NeaInspectionsTableCompanion entry) =>
      into(neaInspectionsTable).insertOnConflictUpdate(entry);

  Future<void> upsertAllInspections(
          List<NeaInspectionsTableCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(neaInspectionsTable, entries));
}

@DriftAccessor(tables: [MangelmeldungenTable])
class MmDao extends DatabaseAccessor<AppDatabase> with _$MmDaoMixin {
  MmDao(super.db);

  Future<List<MangelmeldungenTableData>> getAll() =>
      select(mangelmeldungenTable).get();

  Future<List<MangelmeldungenTableData>> getByStatus(int status) =>
      (select(mangelmeldungenTable)
            ..where((t) => t.status.equals(status)))
          .get();

  Future<MangelmeldungenTableData?> getByUid(String uid) =>
      (select(mangelmeldungenTable)..where((t) => t.uid.equals(uid)))
          .getSingleOrNull();

  Future<void> upsert(MangelmeldungenTableCompanion entry) =>
      into(mangelmeldungenTable).insertOnConflictUpdate(entry);

  Future<void> upsertAll(List<MangelmeldungenTableCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(mangelmeldungenTable, entries));
}

@DriftAccessor(tables: [BuildingsTable, BuildingInspectionsTable])
class BuildingDao extends DatabaseAccessor<AppDatabase>
    with _$BuildingDaoMixin {
  BuildingDao(super.db);

  Future<List<BuildingsTableData>> getAllBuildings() =>
      select(buildingsTable).get();

  Future<List<BuildingsTableData>> getBuildingsByProject(int projectId) =>
      (select(buildingsTable)
            ..where((t) => t.projectId.equals(projectId)))
          .get();

  Future<void> upsertBuilding(BuildingsTableCompanion entry) =>
      into(buildingsTable).insertOnConflictUpdate(entry);

  Future<void> upsertAllBuildings(List<BuildingsTableCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(buildingsTable, entries));

  Future<List<BuildingInspectionsTableData>> getAllInspections() =>
      select(buildingInspectionsTable).get();

  Future<List<BuildingInspectionsTableData>> getInspectionsByBuilding(
          int buildingId) =>
      (select(buildingInspectionsTable)
            ..where((t) => t.buildingId.equals(buildingId)))
          .get();

  Future<BuildingInspectionsTableData?> getInspectionById(int id) =>
      (select(buildingInspectionsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertInspection(BuildingInspectionsTableCompanion entry) =>
      into(buildingInspectionsTable).insertOnConflictUpdate(entry);

  Future<void> upsertAllInspections(
          List<BuildingInspectionsTableCompanion> entries) =>
      batch(
          (b) => b.insertAllOnConflictUpdate(buildingInspectionsTable, entries));
}

@DriftAccessor(tables: [KlimaDevicesTable])
class KlimaDao extends DatabaseAccessor<AppDatabase> with _$KlimaDaoMixin {
  KlimaDao(super.db);

  Future<List<KlimaDevicesTableData>> getAll() =>
      select(klimaDevicesTable).get();

  Future<void> upsertDevice(KlimaDevicesTableCompanion entry) =>
      into(klimaDevicesTable).insertOnConflictUpdate(entry);

  Future<void> upsertAll(List<KlimaDevicesTableCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(klimaDevicesTable, entries));
}

@DriftAccessor(tables: [KeysTable, KeysIssuedTable])
class KeysDao extends DatabaseAccessor<AppDatabase> with _$KeysDaoMixin {
  KeysDao(super.db);

  Future<List<KeysTableData>> getAllKeys() => select(keysTable).get();

  Future<void> upsertKey(KeysTableCompanion entry) =>
      into(keysTable).insertOnConflictUpdate(entry);

  Future<void> upsertAllKeys(List<KeysTableCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(keysTable, entries));

  Future<List<KeysIssuedTableData>> getAllIssued() =>
      select(keysIssuedTable).get();

  Future<void> upsertIssued(KeysIssuedTableCompanion entry) =>
      into(keysIssuedTable).insertOnConflictUpdate(entry);

  Future<void> upsertAllIssued(List<KeysIssuedTableCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(keysIssuedTable, entries));
}

@DriftAccessor(tables: [DashboardCacheTable])
class DashboardDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardDaoMixin {
  DashboardDao(super.db);

  Future<DashboardCacheTableData?> getCacheForProject(int? projectId) =>
      (select(dashboardCacheTable)
            ..where((t) => projectId == null
                ? t.projectId.isNull()
                : t.projectId.equals(projectId))
            ..orderBy([(t) => OrderingTerm.desc(t.syncedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsertCache(DashboardCacheTableCompanion entry) =>
      into(dashboardCacheTable).insertOnConflictUpdate(entry);
}

@DriftAccessor(tables: [UserPermissionsTable])
class PermissionsDao extends DatabaseAccessor<AppDatabase>
    with _$PermissionsDaoMixin {
  PermissionsDao(super.db);

  Future<List<UserPermissionsTableData>> getAll() =>
      select(userPermissionsTable).get();

  Future<bool?> getPermission(String key) async {
    final row = await (select(userPermissionsTable)
          ..where((t) => t.permissionKey.equals(key)))
        .getSingleOrNull();
    return row?.hasPermission;
  }

  Future<void> upsertPermission(UserPermissionsTableCompanion entry) =>
      into(userPermissionsTable).insertOnConflictUpdate(entry);

  Future<void> replaceAll(List<UserPermissionsTableCompanion> entries) async {
    await delete(userPermissionsTable).go();
    await batch((b) => b.insertAll(userPermissionsTable, entries));
  }
}

@DriftAccessor(tables: [ProjectsTable])
class ProjectsDao extends DatabaseAccessor<AppDatabase>
    with _$ProjectsDaoMixin {
  ProjectsDao(super.db);

  Future<List<ProjectsTableData>> getAll() => select(projectsTable).get();

  Future<ProjectsTableData?> getById(int id) =>
      (select(projectsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertProject(ProjectsTableCompanion entry) =>
      into(projectsTable).insertOnConflictUpdate(entry);

  Future<void> upsertAll(List<ProjectsTableCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(projectsTable, entries));
}

// ──────────────────────────── Database ────────────────────────────

@DriftDatabase(
  tables: [
    NeasTable,
    NeaInspectionsTable,
    MangelmeldungenTable,
    BuildingsTable,
    BuildingInspectionsTable,
    KlimaDevicesTable,
    KeysTable,
    KeysIssuedTable,
    DashboardCacheTable,
    UserPermissionsTable,
    ProjectsTable,
  ],
  daos: [
    NeaDao,
    MmDao,
    BuildingDao,
    KlimaDao,
    KeysDao,
    DashboardDao,
    PermissionsDao,
    ProjectsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dkc_handyapp');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          await m.createAll();
        },
      );
}
