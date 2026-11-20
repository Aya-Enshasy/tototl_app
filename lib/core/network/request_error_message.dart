import 'package:dio/dio.dart';

/// Human-readable error without implementation details, HTML, tokens or URLs.
/// The full request diagnostics are printed by ApiClient in debug builds.
class RequestErrorMessage {
  const RequestErrorMessage._();

  static String from(Object error, {String fallback = 'Please try again.'}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) return 'Your session has expired. Please sign in again.';
      if (status == 403) return 'You do not have access to this action.';
      if (status == 404) return 'The requested item could not be found.';
      if (status == 429) return 'Too many requests. Please try again shortly.';
      if (status == 500 || status == 502 || status == 503 || status == 504) {
        return 'The server is temporarily unavailable. Please try again.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The server took too long to respond. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Could not reach the server. Check your connection and try again.';
      }
      final body = error.response?.data;
      if (body is Map) {
        final raw = body['message'];
        if (raw is String && raw.trim().isNotEmpty &&
            raw.length < 180 && !raw.toLowerCase().contains('<html')) {
          return raw.trim();
        }
      }
      return fallback;
    }
    final raw = error.toString().replaceFirst('Bad state: ', '').trim();
    if (raw.startsWith('DioException') || raw.startsWith('Instance of ') ||
        raw.startsWith('<!') || raw.length > 200) return fallback;
    return raw.isEmpty ? fallback : raw;
  }
}
