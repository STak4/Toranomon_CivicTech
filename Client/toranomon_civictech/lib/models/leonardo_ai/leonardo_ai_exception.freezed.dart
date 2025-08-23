// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leonardo_ai_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LeonardoAiException {

 String get message;
/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeonardoAiExceptionCopyWith<LeonardoAiException> get copyWith => _$LeonardoAiExceptionCopyWithImpl<LeonardoAiException>(this as LeonardoAiException, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeonardoAiException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LeonardoAiException(message: $message)';
}


}

/// @nodoc
abstract mixin class $LeonardoAiExceptionCopyWith<$Res>  {
  factory $LeonardoAiExceptionCopyWith(LeonardoAiException value, $Res Function(LeonardoAiException) _then) = _$LeonardoAiExceptionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$LeonardoAiExceptionCopyWithImpl<$Res>
    implements $LeonardoAiExceptionCopyWith<$Res> {
  _$LeonardoAiExceptionCopyWithImpl(this._self, this._then);

  final LeonardoAiException _self;
  final $Res Function(LeonardoAiException) _then;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc


class NetworkError implements LeonardoAiException {
  const NetworkError(this.message);
  

@override final  String message;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkErrorCopyWith<NetworkError> get copyWith => _$NetworkErrorCopyWithImpl<NetworkError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LeonardoAiException.networkError(message: $message)';
}


}

/// @nodoc
abstract mixin class $NetworkErrorCopyWith<$Res> implements $LeonardoAiExceptionCopyWith<$Res> {
  factory $NetworkErrorCopyWith(NetworkError value, $Res Function(NetworkError) _then) = _$NetworkErrorCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class _$NetworkErrorCopyWithImpl<$Res>
    implements $NetworkErrorCopyWith<$Res> {
  _$NetworkErrorCopyWithImpl(this._self, this._then);

  final NetworkError _self;
  final $Res Function(NetworkError) _then;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(NetworkError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApiError implements LeonardoAiException {
  const ApiError(this.statusCode, this.message);
  

 final  int statusCode;
@override final  String message;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiErrorCopyWith<ApiError> get copyWith => _$ApiErrorCopyWithImpl<ApiError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,message);

@override
String toString() {
  return 'LeonardoAiException.apiError(statusCode: $statusCode, message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiErrorCopyWith<$Res> implements $LeonardoAiExceptionCopyWith<$Res> {
  factory $ApiErrorCopyWith(ApiError value, $Res Function(ApiError) _then) = _$ApiErrorCopyWithImpl;
@override @useResult
$Res call({
 int statusCode, String message
});




}
/// @nodoc
class _$ApiErrorCopyWithImpl<$Res>
    implements $ApiErrorCopyWith<$Res> {
  _$ApiErrorCopyWithImpl(this._self, this._then);

  final ApiError _self;
  final $Res Function(ApiError) _then;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? statusCode = null,Object? message = null,}) {
  return _then(ApiError(
null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthenticationError implements LeonardoAiException {
  const AuthenticationError(this.message);
  

@override final  String message;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticationErrorCopyWith<AuthenticationError> get copyWith => _$AuthenticationErrorCopyWithImpl<AuthenticationError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticationError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LeonardoAiException.authenticationError(message: $message)';
}


}

/// @nodoc
abstract mixin class $AuthenticationErrorCopyWith<$Res> implements $LeonardoAiExceptionCopyWith<$Res> {
  factory $AuthenticationErrorCopyWith(AuthenticationError value, $Res Function(AuthenticationError) _then) = _$AuthenticationErrorCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AuthenticationErrorCopyWithImpl<$Res>
    implements $AuthenticationErrorCopyWith<$Res> {
  _$AuthenticationErrorCopyWithImpl(this._self, this._then);

  final AuthenticationError _self;
  final $Res Function(AuthenticationError) _then;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AuthenticationError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RateLimitError implements LeonardoAiException {
  const RateLimitError(this.message, this.retryAfter);
  

@override final  String message;
 final  DateTime retryAfter;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RateLimitErrorCopyWith<RateLimitError> get copyWith => _$RateLimitErrorCopyWithImpl<RateLimitError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RateLimitError&&(identical(other.message, message) || other.message == message)&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter));
}


@override
int get hashCode => Object.hash(runtimeType,message,retryAfter);

@override
String toString() {
  return 'LeonardoAiException.rateLimitError(message: $message, retryAfter: $retryAfter)';
}


}

/// @nodoc
abstract mixin class $RateLimitErrorCopyWith<$Res> implements $LeonardoAiExceptionCopyWith<$Res> {
  factory $RateLimitErrorCopyWith(RateLimitError value, $Res Function(RateLimitError) _then) = _$RateLimitErrorCopyWithImpl;
@override @useResult
$Res call({
 String message, DateTime retryAfter
});




}
/// @nodoc
class _$RateLimitErrorCopyWithImpl<$Res>
    implements $RateLimitErrorCopyWith<$Res> {
  _$RateLimitErrorCopyWithImpl(this._self, this._then);

  final RateLimitError _self;
  final $Res Function(RateLimitError) _then;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? retryAfter = null,}) {
  return _then(RateLimitError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,null == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class ValidationError implements LeonardoAiException {
  const ValidationError(this.message);
  

@override final  String message;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationErrorCopyWith<ValidationError> get copyWith => _$ValidationErrorCopyWithImpl<ValidationError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LeonardoAiException.validationError(message: $message)';
}


}

/// @nodoc
abstract mixin class $ValidationErrorCopyWith<$Res> implements $LeonardoAiExceptionCopyWith<$Res> {
  factory $ValidationErrorCopyWith(ValidationError value, $Res Function(ValidationError) _then) = _$ValidationErrorCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ValidationErrorCopyWithImpl<$Res>
    implements $ValidationErrorCopyWith<$Res> {
  _$ValidationErrorCopyWithImpl(this._self, this._then);

  final ValidationError _self;
  final $Res Function(ValidationError) _then;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ValidationError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UnknownError implements LeonardoAiException {
  const UnknownError(this.message);
  

@override final  String message;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownErrorCopyWith<UnknownError> get copyWith => _$UnknownErrorCopyWithImpl<UnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LeonardoAiException.unknownError(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnknownErrorCopyWith<$Res> implements $LeonardoAiExceptionCopyWith<$Res> {
  factory $UnknownErrorCopyWith(UnknownError value, $Res Function(UnknownError) _then) = _$UnknownErrorCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class _$UnknownErrorCopyWithImpl<$Res>
    implements $UnknownErrorCopyWith<$Res> {
  _$UnknownErrorCopyWithImpl(this._self, this._then);

  final UnknownError _self;
  final $Res Function(UnknownError) _then;

/// Create a copy of LeonardoAiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(UnknownError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
