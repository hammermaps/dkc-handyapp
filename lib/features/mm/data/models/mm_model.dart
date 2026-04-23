import 'package:freezed_annotation/freezed_annotation.dart';

part 'mm_model.freezed.dart';
part 'mm_model.g.dart';

@freezed
class MmListItem with _$MmListItem {
  const factory MmListItem({
    required String uid,
    @Default(0) int status,
    String? betreff,
    String? street,
    String? whg,
    String? melder,
    String? datetime,
    String? dringlichkeit,
  }) = _MmListItem;

  factory MmListItem.fromJson(Map<String, dynamic> json) =>
      _$MmListItemFromJson(json);
}

@freezed
class MmDetail with _$MmDetail {
  const factory MmDetail({
    required String uid,
    @Default(0) int status,
    String? betreff,
    @JsonKey(name: 'meldung_massage') String? meldungMassage,
    String? street,
    String? whg,
    String? melder,
    String? tel,
    String? email,
    String? datetime,
    String? dringlichkeit,
    String? nachunternehmer,
    String? zugeh,
    @Default(false) bool scanned,
  }) = _MmDetail;

  factory MmDetail.fromJson(Map<String, dynamic> json) =>
      _$MmDetailFromJson(json);
}
