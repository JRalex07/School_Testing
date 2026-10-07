import 'app_error.dart';

/// A strongly typed Result monad representing either success or failure.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  AppError? get errorOrNull => switch (this) {
        Success() => null,
        Failure(error: final e) => e,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      Failure(error: final e) => failure(e),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}
