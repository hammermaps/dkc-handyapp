import 'package:freezed_annotation/freezed_annotation.dart';

part 'permissions_model.freezed.dart';
part 'permissions_model.g.dart';

@freezed
class PermissionsModel with _$PermissionsModel {
  const factory PermissionsModel({
    @JsonKey(name: 'can_view_mm') @Default(false) bool canViewMm,
    @JsonKey(name: 'can_edit_mm') @Default(false) bool canEditMm,
    @JsonKey(name: 'can_view_nea') @Default(false) bool canViewNea,
    @JsonKey(name: 'can_edit_nea') @Default(false) bool canEditNea,
    @JsonKey(name: 'can_view_building') @Default(false) bool canViewBuilding,
    @JsonKey(name: 'can_edit_building') @Default(false) bool canEditBuilding,
    @JsonKey(name: 'can_view_klima') @Default(false) bool canViewKlima,
    @JsonKey(name: 'can_edit_klima') @Default(false) bool canEditKlima,
    @JsonKey(name: 'can_view_keys') @Default(false) bool canViewKeys,
    @JsonKey(name: 'can_edit_keys') @Default(false) bool canEditKeys,
    @JsonKey(name: 'can_view_dashboard') @Default(false) bool canViewDashboard,
    @JsonKey(name: 'can_manage_users') @Default(false) bool canManageUsers,
    @JsonKey(name: 'can_manage_projects') @Default(false) bool canManageProjects,
  }) = _PermissionsModel;

  factory PermissionsModel.fromJson(Map<String, dynamic> json) =>
      _$PermissionsModelFromJson(json);
}
