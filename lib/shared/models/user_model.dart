import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String username,
    required String vname,
    required String nname,
    required String email,
    @JsonKey(name: 'is_admin') required bool isAdmin,
    @JsonKey(name: 'active_project_id') int? activeProjectId,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
