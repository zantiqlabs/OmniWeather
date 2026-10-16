// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lightning.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LightningStrikeImpl _$$LightningStrikeImplFromJson(
        Map<String, dynamic> json) =>
    _$LightningStrikeImpl(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: $enumDecode(_$LightningTypeEnumMap, json['type']),
      peakCurrent: (json['peakCurrent'] as num).toDouble(),
      strokeCount: (json['strokeCount'] as num).toInt(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$LightningStrikeImplToJson(
        _$LightningStrikeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'type': _$LightningTypeEnumMap[instance.type]!,
      'peakCurrent': instance.peakCurrent,
      'strokeCount': instance.strokeCount,
      'distanceKm': instance.distanceKm,
    };

const _$LightningTypeEnumMap = {
  LightningType.cloudToGround: 'cloudToGround',
  LightningType.cloudToCloud: 'cloudToCloud',
  LightningType.unknown: 'unknown',
};

_$LightningDataImpl _$$LightningDataImplFromJson(Map<String, dynamic> json) =>
    _$LightningDataImpl(
      strikes: (json['strikes'] as List<dynamic>)
          .map((e) => LightningStrike.fromJson(e as Map<String, dynamic>))
          .toList(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      queryLatitude: (json['queryLatitude'] as num).toDouble(),
      queryLongitude: (json['queryLongitude'] as num).toDouble(),
      queryRadiusKm: (json['queryRadiusKm'] as num).toDouble(),
    );

Map<String, dynamic> _$$LightningDataImplToJson(_$LightningDataImpl instance) =>
    <String, dynamic>{
      'strikes': instance.strikes,
      'fetchedAt': instance.fetchedAt.toIso8601String(),
      'queryLatitude': instance.queryLatitude,
      'queryLongitude': instance.queryLongitude,
      'queryRadiusKm': instance.queryRadiusKm,
    };
