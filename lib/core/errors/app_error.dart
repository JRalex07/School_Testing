/// Domain and operational error abstractions for MPS School Management System.
sealed class AppError {
  final String message;
  final String? code;
  final Object? cause;

  const AppError(this.message, {this.code, this.cause});
}

class NetworkError extends AppError {
  const NetworkError([
    super.message = 'Network connection error',
    String? code,
    Object? cause,
  ]) : super(code: code, cause: cause);
}

class AuthenticationError extends AppError {
  const AuthenticationError([
    super.message = 'Authentication failed',
    String? code,
    Object? cause,
  ]) : super(code: code, cause: cause);
}

class AuthorizationError extends AppError {
  const AuthorizationError([
    super.message = 'Access denied: Insufficient role permissions',
    String? code,
    Object? cause,
  ]) : super(code: code, cause: cause);
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError(
    super.message, {
    this.fieldErrors = const {},
    super.code,
    super.cause,
  });
}

class ServerError extends AppError {
  const ServerError([
    super.message = 'Server operation failed',
    String? code,
    Object? cause,
  ]) : super(code: code, cause: cause);
}

class NotFoundError extends AppError {
  const NotFoundError([
    super.message = 'Requested resource not found',
    String? code,
    Object? cause,
  ]) : super(code: code, cause: cause);
}
