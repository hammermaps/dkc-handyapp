import 'package:freezed_annotation/freezed_annotation.dart';

part 'nea_inspection_model.freezed.dart';
part 'nea_inspection_model.g.dart';

@freezed
class NeaInspectionModel with _$NeaInspectionModel {
  const factory NeaInspectionModel({
    required int id,
    @JsonKey(name: 'nea_system_id') required int neaSystemId,
    @JsonKey(name: 'system_name') String? systemName,
    @JsonKey(name: 'inspection_type') String? inspectionType,
    @JsonKey(name: 'inspection_date') required String inspectionDate,
    @JsonKey(name: 'inspector_name') String? inspectorName,
    required String status,
    @JsonKey(name: 'overall_result') String? overallResult,
    @JsonKey(name: 'runtime_hours') double? runtimeHours,
    String? notes,
    @JsonKey(name: 'checklist_data') Map<String, dynamic>? checklistData,
    @JsonKey(name: 'defect_notes') String? defectNotes,
    List<String>? photos,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _NeaInspectionModel;

  factory NeaInspectionModel.fromJson(Map<String, dynamic> json) =>
      _$NeaInspectionModelFromJson(json);
}
