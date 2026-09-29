/// Flutter 공식 아키텍처 가이드의 Result 패턴.
/// Kotlin 표준 Result 역할을 대신한다.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>._;
  const factory Result.error(Exception error) = Error<T>._;
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  final T value;
}

final class Error<T> extends Result<T> {
  const Error._(this.error);

  final Exception error;
}