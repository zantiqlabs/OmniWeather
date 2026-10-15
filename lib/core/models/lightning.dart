import 'package:freezed_annotation/freezed_annotation.dart';

part 'lightning.freezed.dart';
part 'lightning.g.dart';

enum LightningType {
  cloudToGround, // CG
  cloudToCloud,  // CC
  unknown,
}

/// A single lightning strike as returned by the Xweather API.
@freezed
class LightningStrike with _$LightningStrike {
  const factory LightningStrike({
    required String id,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required LightningType type,
    required double peakCurrent,   // kA
    required int strokeCount,
    double? distanceKm,            // populated when using /closest endpoint
  }) = _LightningStrike;

  factory LightningStrike.fromJson(Map<String, dynamic> json) =>
      _$LightningStrikeFromJson(json);
}

/// The full response from an Xweather lightning query.
@freezed
class LightningData with _$LightningData {
  const factory LightningData({
    required List<LightningStrike> strikes,
    required DateTime fetchedAt,
    required double queryLatitude,
    required double queryLongitude,
    required double queryRadiusKm,
  }) = _LightningData;

  factory LightningData.fromJson(Map<String, dynamic> json) =>
      _$LightningDataFromJson(json);
}
