// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lightning.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LightningStrike _$LightningStrikeFromJson(Map<String, dynamic> json) {
  return _LightningStrike.fromJson(json);
}

/// @nodoc
mixin _$LightningStrike {
  String get id => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  LightningType get type => throw _privateConstructorUsedError;
  double get peakCurrent => throw _privateConstructorUsedError; // kA
  int get strokeCount => throw _privateConstructorUsedError;
  double? get distanceKm => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LightningStrikeCopyWith<LightningStrike> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LightningStrikeCopyWith<$Res> {
  factory $LightningStrikeCopyWith(
          LightningStrike value, $Res Function(LightningStrike) then) =
      _$LightningStrikeCopyWithImpl<$Res, LightningStrike>;
  @useResult
  $Res call(
      {String id,
      DateTime timestamp,
      double latitude,
      double longitude,
      LightningType type,
      double peakCurrent,
      int strokeCount,
      double? distanceKm});
}

/// @nodoc
class _$LightningStrikeCopyWithImpl<$Res, $Val extends LightningStrike>
    implements $LightningStrikeCopyWith<$Res> {
  _$LightningStrikeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? type = null,
    Object? peakCurrent = null,
    Object? strokeCount = null,
    Object? distanceKm = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as LightningType,
      peakCurrent: null == peakCurrent
          ? _value.peakCurrent
          : peakCurrent // ignore: cast_nullable_to_non_nullable
              as double,
      strokeCount: null == strokeCount
          ? _value.strokeCount
          : strokeCount // ignore: cast_nullable_to_non_nullable
              as int,
      distanceKm: freezed == distanceKm
          ? _value.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LightningStrikeImplCopyWith<$Res>
    implements $LightningStrikeCopyWith<$Res> {
  factory _$$LightningStrikeImplCopyWith(_$LightningStrikeImpl value,
          $Res Function(_$LightningStrikeImpl) then) =
      __$$LightningStrikeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime timestamp,
      double latitude,
      double longitude,
      LightningType type,
      double peakCurrent,
      int strokeCount,
      double? distanceKm});
}

/// @nodoc
class __$$LightningStrikeImplCopyWithImpl<$Res>
    extends _$LightningStrikeCopyWithImpl<$Res, _$LightningStrikeImpl>
    implements _$$LightningStrikeImplCopyWith<$Res> {
  __$$LightningStrikeImplCopyWithImpl(
      _$LightningStrikeImpl _value, $Res Function(_$LightningStrikeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? type = null,
    Object? peakCurrent = null,
    Object? strokeCount = null,
    Object? distanceKm = freezed,
  }) {
    return _then(_$LightningStrikeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as LightningType,
      peakCurrent: null == peakCurrent
          ? _value.peakCurrent
          : peakCurrent // ignore: cast_nullable_to_non_nullable
              as double,
      strokeCount: null == strokeCount
          ? _value.strokeCount
          : strokeCount // ignore: cast_nullable_to_non_nullable
              as int,
      distanceKm: freezed == distanceKm
          ? _value.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LightningStrikeImpl implements _LightningStrike {
  const _$LightningStrikeImpl(
      {required this.id,
      required this.timestamp,
      required this.latitude,
      required this.longitude,
      required this.type,
      required this.peakCurrent,
      required this.strokeCount,
      this.distanceKm});

  factory _$LightningStrikeImpl.fromJson(Map<String, dynamic> json) =>
      _$$LightningStrikeImplFromJson(json);

  @override
  final String id;
  @override
  final DateTime timestamp;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final LightningType type;
  @override
  final double peakCurrent;
// kA
  @override
  final int strokeCount;
  @override
  final double? distanceKm;

  @override
  String toString() {
    return 'LightningStrike(id: $id, timestamp: $timestamp, latitude: $latitude, longitude: $longitude, type: $type, peakCurrent: $peakCurrent, strokeCount: $strokeCount, distanceKm: $distanceKm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LightningStrikeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.peakCurrent, peakCurrent) ||
                other.peakCurrent == peakCurrent) &&
            (identical(other.strokeCount, strokeCount) ||
                other.strokeCount == strokeCount) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, timestamp, latitude,
      longitude, type, peakCurrent, strokeCount, distanceKm);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LightningStrikeImplCopyWith<_$LightningStrikeImpl> get copyWith =>
      __$$LightningStrikeImplCopyWithImpl<_$LightningStrikeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LightningStrikeImplToJson(
      this,
    );
  }
}

abstract class _LightningStrike implements LightningStrike {
  const factory _LightningStrike(
      {required final String id,
      required final DateTime timestamp,
      required final double latitude,
      required final double longitude,
      required final LightningType type,
      required final double peakCurrent,
      required final int strokeCount,
      final double? distanceKm}) = _$LightningStrikeImpl;

  factory _LightningStrike.fromJson(Map<String, dynamic> json) =
      _$LightningStrikeImpl.fromJson;

  @override
  String get id;
  @override
  DateTime get timestamp;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  LightningType get type;
  @override
  double get peakCurrent;
  @override // kA
  int get strokeCount;
  @override
  double? get distanceKm;
  @override
  @JsonKey(ignore: true)
  _$$LightningStrikeImplCopyWith<_$LightningStrikeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LightningData _$LightningDataFromJson(Map<String, dynamic> json) {
  return _LightningData.fromJson(json);
}

/// @nodoc
mixin _$LightningData {
  List<LightningStrike> get strikes => throw _privateConstructorUsedError;
  DateTime get fetchedAt => throw _privateConstructorUsedError;
  double get queryLatitude => throw _privateConstructorUsedError;
  double get queryLongitude => throw _privateConstructorUsedError;
  double get queryRadiusKm => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LightningDataCopyWith<LightningData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LightningDataCopyWith<$Res> {
  factory $LightningDataCopyWith(
          LightningData value, $Res Function(LightningData) then) =
      _$LightningDataCopyWithImpl<$Res, LightningData>;
  @useResult
  $Res call(
      {List<LightningStrike> strikes,
      DateTime fetchedAt,
      double queryLatitude,
      double queryLongitude,
      double queryRadiusKm});
}

/// @nodoc
class _$LightningDataCopyWithImpl<$Res, $Val extends LightningData>
    implements $LightningDataCopyWith<$Res> {
  _$LightningDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strikes = null,
    Object? fetchedAt = null,
    Object? queryLatitude = null,
    Object? queryLongitude = null,
    Object? queryRadiusKm = null,
  }) {
    return _then(_value.copyWith(
      strikes: null == strikes
          ? _value.strikes
          : strikes // ignore: cast_nullable_to_non_nullable
              as List<LightningStrike>,
      fetchedAt: null == fetchedAt
          ? _value.fetchedAt
          : fetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      queryLatitude: null == queryLatitude
          ? _value.queryLatitude
          : queryLatitude // ignore: cast_nullable_to_non_nullable
              as double,
      queryLongitude: null == queryLongitude
          ? _value.queryLongitude
          : queryLongitude // ignore: cast_nullable_to_non_nullable
              as double,
      queryRadiusKm: null == queryRadiusKm
          ? _value.queryRadiusKm
          : queryRadiusKm // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LightningDataImplCopyWith<$Res>
    implements $LightningDataCopyWith<$Res> {
  factory _$$LightningDataImplCopyWith(
          _$LightningDataImpl value, $Res Function(_$LightningDataImpl) then) =
      __$$LightningDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<LightningStrike> strikes,
      DateTime fetchedAt,
      double queryLatitude,
      double queryLongitude,
      double queryRadiusKm});
}

/// @nodoc
class __$$LightningDataImplCopyWithImpl<$Res>
    extends _$LightningDataCopyWithImpl<$Res, _$LightningDataImpl>
    implements _$$LightningDataImplCopyWith<$Res> {
  __$$LightningDataImplCopyWithImpl(
      _$LightningDataImpl _value, $Res Function(_$LightningDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strikes = null,
    Object? fetchedAt = null,
    Object? queryLatitude = null,
    Object? queryLongitude = null,
    Object? queryRadiusKm = null,
  }) {
    return _then(_$LightningDataImpl(
      strikes: null == strikes
          ? _value._strikes
          : strikes // ignore: cast_nullable_to_non_nullable
              as List<LightningStrike>,
      fetchedAt: null == fetchedAt
          ? _value.fetchedAt
          : fetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      queryLatitude: null == queryLatitude
          ? _value.queryLatitude
          : queryLatitude // ignore: cast_nullable_to_non_nullable
              as double,
      queryLongitude: null == queryLongitude
          ? _value.queryLongitude
          : queryLongitude // ignore: cast_nullable_to_non_nullable
              as double,
      queryRadiusKm: null == queryRadiusKm
          ? _value.queryRadiusKm
          : queryRadiusKm // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LightningDataImpl implements _LightningData {
  const _$LightningDataImpl(
      {required final List<LightningStrike> strikes,
      required this.fetchedAt,
      required this.queryLatitude,
      required this.queryLongitude,
      required this.queryRadiusKm})
      : _strikes = strikes;

  factory _$LightningDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$LightningDataImplFromJson(json);

  final List<LightningStrike> _strikes;
  @override
  List<LightningStrike> get strikes {
    if (_strikes is EqualUnmodifiableListView) return _strikes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_strikes);
  }

  @override
  final DateTime fetchedAt;
  @override
  final double queryLatitude;
  @override
  final double queryLongitude;
  @override
  final double queryRadiusKm;

  @override
  String toString() {
    return 'LightningData(strikes: $strikes, fetchedAt: $fetchedAt, queryLatitude: $queryLatitude, queryLongitude: $queryLongitude, queryRadiusKm: $queryRadiusKm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LightningDataImpl &&
            const DeepCollectionEquality().equals(other._strikes, _strikes) &&
            (identical(other.fetchedAt, fetchedAt) ||
                other.fetchedAt == fetchedAt) &&
            (identical(other.queryLatitude, queryLatitude) ||
                other.queryLatitude == queryLatitude) &&
            (identical(other.queryLongitude, queryLongitude) ||
                other.queryLongitude == queryLongitude) &&
            (identical(other.queryRadiusKm, queryRadiusKm) ||
                other.queryRadiusKm == queryRadiusKm));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_strikes),
      fetchedAt,
      queryLatitude,
      queryLongitude,
      queryRadiusKm);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LightningDataImplCopyWith<_$LightningDataImpl> get copyWith =>
      __$$LightningDataImplCopyWithImpl<_$LightningDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LightningDataImplToJson(
      this,
    );
  }
}

abstract class _LightningData implements LightningData {
  const factory _LightningData(
      {required final List<LightningStrike> strikes,
      required final DateTime fetchedAt,
      required final double queryLatitude,
      required final double queryLongitude,
      required final double queryRadiusKm}) = _$LightningDataImpl;

  factory _LightningData.fromJson(Map<String, dynamic> json) =
      _$LightningDataImpl.fromJson;

  @override
  List<LightningStrike> get strikes;
  @override
  DateTime get fetchedAt;
  @override
  double get queryLatitude;
  @override
  double get queryLongitude;
  @override
  double get queryRadiusKm;
  @override
  @JsonKey(ignore: true)
  _$$LightningDataImplCopyWith<_$LightningDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
