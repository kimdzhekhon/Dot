// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ScanResult {
  int get score => throw _privateConstructorUsedError; // 0 to 100
  String get message => throw _privateConstructorUsedError;
  bool get isSafe => throw _privateConstructorUsedError;
  Map<String, dynamic>? get details => throw _privateConstructorUsedError;

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScanResultCopyWith<ScanResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScanResultCopyWith<$Res> {
  factory $ScanResultCopyWith(
    ScanResult value,
    $Res Function(ScanResult) then,
  ) = _$ScanResultCopyWithImpl<$Res, ScanResult>;
  @useResult
  $Res call({
    int score,
    String message,
    bool isSafe,
    Map<String, dynamic>? details,
  });
}

/// @nodoc
class _$ScanResultCopyWithImpl<$Res, $Val extends ScanResult>
    implements $ScanResultCopyWith<$Res> {
  _$ScanResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? message = null,
    Object? isSafe = null,
    Object? details = freezed,
  }) {
    return _then(
      _value.copyWith(
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            isSafe: null == isSafe
                ? _value.isSafe
                : isSafe // ignore: cast_nullable_to_non_nullable
                      as bool,
            details: freezed == details
                ? _value.details
                : details // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScanResultImplCopyWith<$Res>
    implements $ScanResultCopyWith<$Res> {
  factory _$$ScanResultImplCopyWith(
    _$ScanResultImpl value,
    $Res Function(_$ScanResultImpl) then,
  ) = __$$ScanResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int score,
    String message,
    bool isSafe,
    Map<String, dynamic>? details,
  });
}

/// @nodoc
class __$$ScanResultImplCopyWithImpl<$Res>
    extends _$ScanResultCopyWithImpl<$Res, _$ScanResultImpl>
    implements _$$ScanResultImplCopyWith<$Res> {
  __$$ScanResultImplCopyWithImpl(
    _$ScanResultImpl _value,
    $Res Function(_$ScanResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? message = null,
    Object? isSafe = null,
    Object? details = freezed,
  }) {
    return _then(
      _$ScanResultImpl(
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        isSafe: null == isSafe
            ? _value.isSafe
            : isSafe // ignore: cast_nullable_to_non_nullable
                  as bool,
        details: freezed == details
            ? _value._details
            : details // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc

class _$ScanResultImpl implements _ScanResult {
  const _$ScanResultImpl({
    required this.score,
    required this.message,
    required this.isSafe,
    final Map<String, dynamic>? details,
  }) : _details = details;

  @override
  final int score;
  // 0 to 100
  @override
  final String message;
  @override
  final bool isSafe;
  final Map<String, dynamic>? _details;
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ScanResult(score: $score, message: $message, isSafe: $isSafe, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScanResultImpl &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.isSafe, isSafe) || other.isSafe == isSafe) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    score,
    message,
    isSafe,
    const DeepCollectionEquality().hash(_details),
  );

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScanResultImplCopyWith<_$ScanResultImpl> get copyWith =>
      __$$ScanResultImplCopyWithImpl<_$ScanResultImpl>(this, _$identity);
}

abstract class _ScanResult implements ScanResult {
  const factory _ScanResult({
    required final int score,
    required final String message,
    required final bool isSafe,
    final Map<String, dynamic>? details,
  }) = _$ScanResultImpl;

  @override
  int get score; // 0 to 100
  @override
  String get message;
  @override
  bool get isSafe;
  @override
  Map<String, dynamic>? get details;

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScanResultImplCopyWith<_$ScanResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
