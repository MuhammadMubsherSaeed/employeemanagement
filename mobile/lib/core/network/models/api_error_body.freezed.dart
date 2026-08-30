// Generated locally to match Freezed 2.x for ApiErrorBody.
part of 'api_error_body.dart';

mixin _$ApiErrorBody {
  String? get detail => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  $ApiErrorBodyCopyWith<ApiErrorBody> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $ApiErrorBodyCopyWith<$Res> {
  factory $ApiErrorBodyCopyWith(
    ApiErrorBody value,
    $Res Function(ApiErrorBody) then,
  ) = _$ApiErrorBodyCopyWithImpl<$Res, ApiErrorBody>;

  $Res call({String? detail, String? message});
}

class _$ApiErrorBodyCopyWithImpl<$Res, $Val extends ApiErrorBody>
    implements $ApiErrorBodyCopyWith<$Res> {
  _$ApiErrorBodyCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @override
  $Res call({
    Object? detail = freezed,
    Object? message = freezed,
  }) {
    return _then(
      _value.copyWith(
        detail: identical(detail, freezed) ? _value.detail : detail as String?,
        message:
            identical(message, freezed) ? _value.message : message as String?,
      ) as $Val,
    );
  }
}

abstract class _$$ApiErrorBodyImplCopyWith<$Res>
    implements $ApiErrorBodyCopyWith<$Res> {
  factory _$$ApiErrorBodyImplCopyWith(
    _$ApiErrorBodyImpl value,
    $Res Function(_$ApiErrorBodyImpl) then,
  ) = __$$ApiErrorBodyImplCopyWithImpl<$Res>;

  @override
  $Res call({String? detail, String? message});
}

class __$$ApiErrorBodyImplCopyWithImpl<$Res>
    extends _$ApiErrorBodyCopyWithImpl<$Res, _$ApiErrorBodyImpl>
    implements _$$ApiErrorBodyImplCopyWith<$Res> {
  __$$ApiErrorBodyImplCopyWithImpl(
    _$ApiErrorBodyImpl super._value,
    super._then,
  );

  @override
  $Res call({
    Object? detail = freezed,
    Object? message = freezed,
  }) {
    return _then(
      _$ApiErrorBodyImpl(
        detail: identical(detail, freezed) ? _value.detail : detail as String?,
        message:
            identical(message, freezed) ? _value.message : message as String?,
      ),
    );
  }
}

class _$ApiErrorBodyImpl implements _ApiErrorBody {
  const _$ApiErrorBodyImpl({this.detail, this.message});

  @override
  final String? detail;
  @override
  final String? message;

  @override
  String toString() => 'ApiErrorBody(detail: $detail, message: $message)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiErrorBodyImpl &&
            (identical(other.detail, detail) || other.detail == detail) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, detail, message);

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  _$$ApiErrorBodyImplCopyWith<_$ApiErrorBodyImpl> get copyWith =>
      __$$ApiErrorBodyImplCopyWithImpl<_$ApiErrorBodyImpl>(this, _$identity);
}

abstract class _ApiErrorBody implements ApiErrorBody {
  const factory _ApiErrorBody({String? detail, String? message}) =
      _$ApiErrorBodyImpl;

  @override
  String? get detail;
  @override
  String? get message;
}

Never get _privateConstructorUsedError =>
    throw UnsupportedError('ApiErrorBody was constructed incorrectly.');

T _$identity<T>(T value) => value;
