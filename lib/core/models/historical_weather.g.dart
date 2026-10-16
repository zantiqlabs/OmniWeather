// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'historical_weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HistoricalDayImpl _$$HistoricalDayImplFromJson(Map<String, dynamic> json) =>
    _$HistoricalDayImpl(
      date: DateTime.parse(json['date'] as String),
      weatherCode: (json['weatherCode'] as num).toInt(),
      tempMax: (json['tempMax'] as num).toDouble(),
      tempMin: (json['tempMin'] as num).toDouble(),
      tempMean: (json['tempMean'] as num).toDouble(),
      apparentTempMax: (json['apparentTempMax'] as num).toDouble(),
      apparentTempMin: (json['apparentTempMin'] as num).toDouble(),
      precipitationSum: (json['precipitationSum'] as num).toDouble(),
      rainSum: (json['rainSum'] as num).toDouble(),
      snowfallSum: (json['snowfallSum'] as num).toDouble(),
      precipitationHours: (json['precipitationHours'] as num).toDouble(),
      windSpeedMax: (json['windSpeedMax'] as num).toDouble(),
      windGustsMax: (json['windGustsMax'] as num).toDouble(),
      windDirectionDominant: (json['windDirectionDominant'] as num).toDouble(),
    );

Map<String, dynamic> _$$HistoricalDayImplToJson(_$HistoricalDayImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'weatherCode': instance.weatherCode,
      'tempMax': instance.tempMax,
      'tempMin': instance.tempMin,
      'tempMean': instance.tempMean,
      'apparentTempMax': instance.apparentTempMax,
      'apparentTempMin': instance.apparentTempMin,
      'precipitationSum': instance.precipitationSum,
      'rainSum': instance.rainSum,
      'snowfallSum': instance.snowfallSum,
      'precipitationHours': instance.precipitationHours,
      'windSpeedMax': instance.windSpeedMax,
      'windGustsMax': instance.windGustsMax,
      'windDirectionDominant': instance.windDirectionDominant,
    };

_$HistoricalDataImpl _$$HistoricalDataImplFromJson(Map<String, dynamic> json) =>
    _$HistoricalDataImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      days: (json['days'] as List<dynamic>)
          .map((e) => HistoricalDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );

Map<String, dynamic> _$$HistoricalDataImplToJson(
        _$HistoricalDataImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timezone': instance.timezone,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'days': instance.days,
      'fetchedAt': instance.fetchedAt.toIso8601String(),
    };

_$MonthlyClimatologyImpl _$$MonthlyClimatologyImplFromJson(
        Map<String, dynamic> json) =>
    _$MonthlyClimatologyImpl(
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      avgTempMax: (json['avgTempMax'] as num).toDouble(),
      avgTempMin: (json['avgTempMin'] as num).toDouble(),
      avgTempMean: (json['avgTempMean'] as num).toDouble(),
      totalPrecipitation: (json['totalPrecipitation'] as num).toDouble(),
      maxPrecipitationDay: (json['maxPrecipitationDay'] as num).toDouble(),
      rainyDays: (json['rainyDays'] as num).toInt(),
      snowyDays: (json['snowyDays'] as num).toInt(),
      avgWindSpeed: (json['avgWindSpeed'] as num).toDouble(),
    );

Map<String, dynamic> _$$MonthlyClimatologyImplToJson(
        _$MonthlyClimatologyImpl instance) =>
    <String, dynamic>{
      'month': instance.month,
      'year': instance.year,
      'avgTempMax': instance.avgTempMax,
      'avgTempMin': instance.avgTempMin,
      'avgTempMean': instance.avgTempMean,
      'totalPrecipitation': instance.totalPrecipitation,
      'maxPrecipitationDay': instance.maxPrecipitationDay,
      'rainyDays': instance.rainyDays,
      'snowyDays': instance.snowyDays,
      'avgWindSpeed': instance.avgWindSpeed,
    };
