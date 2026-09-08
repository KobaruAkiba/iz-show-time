import '../../l10n/l10n.dart';

/// Custom error types for API responses
enum ApiErrorType {
  rateLimit,
  notFound,
  unauthorized,
  invalidResponse,
  networkError,
  timeout,
}

/// Typed failure from the HTTP client / TMDB service for presentation handling.
class ApiException implements Exception {
  const ApiException(this.type, this.message);

  final ApiErrorType type;
  final String message;

  bool get isConnectionIssue =>
      type == ApiErrorType.networkError || type == ApiErrorType.timeout;

  @override
  String toString() => 'ApiException($type): $message';
}

/// Localized user-facing copy for [ApiErrorType].
String apiErrorMessage(ApiErrorType type, [AppLocalizations? l10n]) {
  final loc = l10n ?? AppL10n.current;
  switch (type) {
    case ApiErrorType.timeout:
      return loc.errorTimeout;
    case ApiErrorType.networkError:
      return loc.errorNoConnection;
    case ApiErrorType.rateLimit:
      return loc.errorTooManyRequests;
    case ApiErrorType.notFound:
      return loc.errorResourceNotFound;
    case ApiErrorType.unauthorized:
      return loc.errorAccessDenied;
    case ApiErrorType.invalidResponse:
      return loc.errorInvalidResponse;
  }
}
