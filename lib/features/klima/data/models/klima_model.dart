import 'package:freezed_annotation/freezed_annotation.dart';

part 'klima_model.freezed.dart';
part 'klima_model.g.dart';

@freezed
class KlimaDevice with _$KlimaDevice {
  const factory KlimaDevice({
    required int address,
    required String name,
    @JsonKey(name: 'group_id') int? groupId,
    @Default(true) bool enabled,
    @Default(0) int sort,
    @JsonKey(name: 'operating_mode') String? operatingMode,
    // Live status fields (from klima_status endpoint)
    double? temperature,
    double? setTemperature,
    String? mode,
    bool? power,
  }) = _KlimaDevice;

  factory KlimaDevice.fromJson(Map<String, dynamic> json) =>
      _$KlimaDeviceFromJson(json);
}
