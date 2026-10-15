import 'package:freezed_annotation/freezed_annotation.dart';

part 'location.freezed.dart';
part 'location.g.dart';

@freezed
class WeatherLocation with _$WeatherLocation {
  const factory WeatherLocation({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    String? country,
    String? region,
    String? timezone,
    @Default(false) bool isFavourite,
  }) = _WeatherLocation;

  factory WeatherLocation.fromJson(Map<String, dynamic> json) =>
      _$WeatherLocationFromJson(json);
}
