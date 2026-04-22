import 'package:freezed_annotation/freezed_annotation.dart';

part 'key_model.freezed.dart';
part 'key_model.g.dart';

@freezed
class KeyItem with _$KeyItem {
  const factory KeyItem({
    required int id,
    String? number,
    required String name,
    String? description,
    @JsonKey(name: 'type_id') int? typeId,
    @JsonKey(name: 'cabinet_id') int? cabinetId,
    @JsonKey(name: 'total_count') @Default(0) int totalCount,
    @Default(true) bool enabled,
  }) = _KeyItem;

  factory KeyItem.fromJson(Map<String, dynamic> json) =>
      _$KeyItemFromJson(json);
}

@freezed
class KeyIssued with _$KeyIssued {
  const factory KeyIssued({
    required int id,
    @JsonKey(name: 'key_id') required int keyId,
    @JsonKey(name: 'key_number') String? keyNumber,
    @JsonKey(name: 'key_name') String? keyName,
    @JsonKey(name: 'recipient_name') required String recipientName,
    @JsonKey(name: 'issued_at') required String issuedAt,
    @JsonKey(name: 'issued_by') String? issuedBy,
    String? notes,
  }) = _KeyIssued;

  factory KeyIssued.fromJson(Map<String, dynamic> json) =>
      _$KeyIssuedFromJson(json);
}
