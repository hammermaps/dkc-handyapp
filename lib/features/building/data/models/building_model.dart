import 'package:freezed_annotation/freezed_annotation.dart';

part 'building_model.freezed.dart';
part 'building_model.g.dart';

@freezed
class BuildingModel with _$BuildingModel {
  const factory BuildingModel({
    required int id,
    required String name,
    String? address,
    String? description,
    @Default(true) bool enabled,
    @JsonKey(name: 'project_id') int? projectId,
  }) = _BuildingModel;

  factory BuildingModel.fromJson(Map<String, dynamic> json) =>
      _$BuildingModelFromJson(json);
}

@freezed
class BuildingInspectionModel with _$BuildingInspectionModel {
  const factory BuildingInspectionModel({
    required int id,
    @JsonKey(name: 'building_id') required int buildingId,
    @JsonKey(name: 'building_name') String? buildingName,
    String? title,
    @JsonKey(name: 'inspection_date') required String inspectionDate,
    required String status,
    @JsonKey(name: 'overall_result') String? overallResult,
    @JsonKey(name: 'created_by_name') String? createdByName,
    String? weather,
    String? attendees,
    @JsonKey(name: 'general_notes') String? generalNotes,
    @JsonKey(name: 'checkpoint_results') List<Map<String, dynamic>>? checkpointResults,
  }) = _BuildingInspectionModel;

  factory BuildingInspectionModel.fromJson(Map<String, dynamic> json) =>
      _$BuildingInspectionModelFromJson(json);
}
