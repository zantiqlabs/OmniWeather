// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HourlyForecastImpl _$$HourlyForecastImplFromJson(Map<String, dynamic> json) =>
    _$HourlyForecastImpl(
      time: DateTime.parse(json['time'] as String),
      temperature: (json['temperature'] as num).toDouble(),
      apparentTemperature: (json['apparentTemperature'] as num).toDouble(),
      relativeHumidity: (json['relativeHumidity'] as num).toDouble(),
      precipitationProbability:
          (json['precipitationProbability'] as num).toDouble(),
      precipitation: (json['precipitation'] as num).toDouble(),
      weatherCode: (json['weatherCode'] as num).toInt(),
      cloudCover: (json['cloudCover'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      windDirection: (json['windDirection'] as num).toDouble(),
      windGusts: (json['windGusts'] as num).toDouble(),
      visibility: (json['visibility'] as num).toDouble(),
      uvIndex: (json['uvIndex'] as num).toDouble(),
    );

Map<String, dynamic> _$$HourlyForecastImplToJson(
        _$HourlyForecastImpl instance) =>
    <String, dynamic>{
      'time': instance.time.toIso8601String(),
      'temperature': instance.temperature,
      'apparentTemperature': instance.apparentTemperature,
      'relativeHumidity': instance.relativeHumidity,
      'precipitationProbability': instance.precipitationProbability,
      'precipitation': instance.precipitation,
      'weatherCode': instance.weatherCode,
      'cloudCover': instance.cloudCover,
      'windSpeed': instance.windSpeed,
      'windDirection': instance.windDirection,
      'windGusts': instance.windGusts,
      'visibility': instance.visibility,
      'uvIndex': instance.uvIndex,
    };

_$DailyForecastImpl _$$DailyForecastImplFromJson(Map<String, dynamic> json) =>
    _$DailyForecastImpl(
      date: DateTime.parse(json['date'] as String),
      weatherCode: (json['weatherCode'] as num).toInt(),
      tempMax: (json['tempMax'] as num).toDouble(),
      tempMin: (json['tempMin'] as num).toDouble(),
      apparentTempMax: (json['apparentTempMax'] as num).toDouble(),
      apparentTempMin: (json['apparentTempMin'] as num).toDouble(),
      sunrise: DateTime.parse(json['sunrise'] as String),
      sunset: DateTime.parse(json['sunset'] as String),
      precipitationSum: (json['precipitationSum'] as num).toDouble(),
      rainSum: (json['rainSum'] as num).toDouble(),
      snowfallSum: (json['snowfallSum'] as num).toDouble(),
      precipitationHours: (json['precipitationHours'] as num).toDouble(),
      precipitationProbabilityMax:
          (json['precipitationProbabilityMax'] as num).toDouble(),
      windSpeedMax: (json['windSpeedMax'] as num).toDouble(),
      windGustsMax: (json['windGustsMax'] as num).toDouble(),
      windDirectionDominant: (json['windDirectionDominant'] as num).toDouble(),
      uvIndexMax: (json['uvIndexMax'] as num).toDouble(),
    );

Map<String, dynamic> _$$DailyForecastImplToJson(_$DailyForecastImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'weatherCode': instance.weatherCode,
      'tempMax': instance.tempMax,
      'tempMin': instance.tempMin,
      'apparentTempMax': instance.apparentTempMax,
      'apparentTempMin': instance.apparentTempMin,
      'sunrise': instance.sunrise.toIso8601String(),
      'sunset': instance.sunset.toIso8601String(),
      'precipitationSum': instance.precipitationSum,
      'rainSum': instance.rainSum,
      'snowfallSum': instance.snowfallSum,
      'precipitationHours': instance.precipitationHours,
      'precipitationProbabilityMax': instance.precipitationProbabilityMax,
      'windSpeedMax': instance.windSpeedMax,
      'windGustsMax': instance.windGustsMax,
      'windDirectionDominant': instance.windDirectionDominant,
      'uvIndexMax': instance.uvIndexMax,
    };

_$ForecastDataImpl _$$ForecastDataImplFromJson(Map<String, dynamic> json) =>
    _$ForecastDataImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      hourly: (json['hourly'] as List<dynamic>)
          .map((e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
          .toList(),
      daily: (json['daily'] as List<dynamic>)
          .map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
          .toList(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );

Map<String, dynamic> _$$ForecastDataImplToJson(_$ForecastDataImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timezone': instance.timezone,
      'hourly': instance.hourly,
      'daily': instance.daily,
      'fetchedAt': instance.fetchedAt.toIso8601String(),
    };
