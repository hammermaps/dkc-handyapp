import 'package:freezed_annotation/freezed_annotation.dart';

part 'nea_system_model.freezed.dart';
part 'nea_system_model.g.dart';

@freezed
class NeaSystemModel with _$NeaSystemModel {
  const factory NeaSystemModel({
    required int id,
    required String name,
    String? description,
    String? location,
    String? manufacturer,
    String? model,
    @JsonKey(name: 'serial_number') String? serialNumber,
    @JsonKey(name: 'installation_date') String? installationDate,
    @Default(true) bool enabled,
    @JsonKey(name: 'project_id') int? projectId,
    @JsonKey(name: 'last_inspection_date') String? lastInspectionDate,
    @JsonKey(name: 'last_inspection_result') String? lastInspectionResult,
  }) = _NeaSystemModel;

  factory NeaSystemModel.fromJson(Map<String, dynamic> json) =>
      _$NeaSystemModelFromJson(json);
}
