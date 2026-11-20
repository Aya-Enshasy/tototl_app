import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';

class ApiClient {
  // ===========================================================================
  // SINGLETON
  // ===========================================================================

  static final ApiClient _instance =
  ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;
  int _traceSerial = 0;

  // One request per resource/account while a GET is in flight. This is not
  // an HTTP cache: once completed, subsequent fetches can get fresh data.
  final Map<String, Future<Response<dynamic>>> _pendingGets = {};
  DateTime? _rateLimitedUntil;


  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 18),
        sendTimeout: const Duration(seconds: 18),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
            RequestOptions options,
            RequestInterceptorHandler handler,
            ) {
          if (options.method.toUpperCase() == 'GET') {
            options.headers.putIfAbsent(
              'Cache-Control',
                  () => 'no-cache',
            );

            options.headers.putIfAbsent(
              'Pragma',
                  () => 'no-cache',
            );
          }

          if (kDebugMode) {
            final id = ++_traceSerial;
            options.extra['tototl_trace_id'] = id;
            options.extra['tototl_trace_started'] =
                DateTime.now().millisecondsSinceEpoch;
            debugPrint('[TOTOTL][API][#$id][START] '
                '${options.method.toUpperCase()} ${options.uri.path}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            final request = response.requestOptions;
            final id = request.extra['tototl_trace_id'] ?? '-';
            final started = request.extra['tototl_trace_started'];
            final ms = started is int
                ? DateTime.now().millisecondsSinceEpoch - started
                : -1;
            debugPrint('[TOTOTL][API][#$id][OK] '
                '${request.method} ${request.uri.path} '
                'http=${response.statusCode} elapsedMs=$ms');
          }
          handler.next(response);
        },
        onError: (
            DioException error,
            ErrorInterceptorHandler handler,
            ) {
          if (kDebugMode) {
            final request = error.requestOptions;
            final id = request.extra['tototl_trace_id'] ?? '-';
            final started = request.extra['tototl_trace_started'];
            final ms = started is int
                ? DateTime.now().millisecondsSinceEpoch - started
                : -1;
            final requestId = error.response?.headers.value('x-request-id') ??
                error.response?.headers.value('cf-ray') ?? '-';
            debugPrint('[TOTOTL][API][#$id][FAIL] '
                '${request.method} ${request.uri.path} '
                'http=${error.response?.statusCode ?? '-'} '
                'type=${error.type.name} elapsedMs=$ms '
                'serverRequestId=$requestId');
            if (error.response?.statusCode == 422) {
              final raw = error.response?.data;
              if (raw is Map) {
                final validation = raw['errors'];
                final fields = validation is Map
                    ? validation.keys.map((e) => e.toString()).toList()
                    : const <String>[];
                debugPrint('[TOTOTL][API][#$id][VALIDATION] '
                    'fields=${fields.join(',')} '
                    'code=${ApiClient.errorCodeFromDio(error) ?? '-'}');
              }
            }
          }
          // Services receive the original structured DioException.
          handler.next(error);
        },
      ),
    );
  }

  // ===========================================================================
  // GET
  //
  // Retry transient transport errors once only. Never sleep on a 429 challenge.
  // ===========================================================================

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    final params = (queryParameters ?? const <String, dynamic>{}).entries
        .map((e) => '${e.key}=${e.value}').toList()..sort();
    // Authentication is part of the in-flight key. Never log the token.
    final auth = options?.headers?['Authorization']?.toString() ??
        options?.headers?['authorization']?.toString() ?? '';
    final key = '$path|${params.join('&')}|${auth.hashCode}';
    final existing = _pendingGets[key];
    if (existing != null) {
      if (kDebugMode) {
        debugPrint('[TOTOTL][API][COALESCED] GET ${Uri.parse(path).path}');
      }
      return existing;
    }

    final future = _getWithRetry(
      path, queryParameters: queryParameters, options: options,
    );
    _pendingGets[key] = future;
    void clear() {
      if (identical(_pendingGets[key], future)) _pendingGets.remove(key);
    }
    // Register both completion paths without creating an unobserved error.
    future.then((_) => clear(), onError: (Object _, StackTrace __) => clear());
    return future;
  }

  Future<Response<dynamic>> _getWithRetry(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final until = _rateLimitedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      if (kDebugMode) {
        debugPrint('[TOTOTL][API][RATE_LIMIT] GET ${Uri.parse(path).path} '
            'suppressed while server rate limit cools down');
      }
      final request = RequestOptions(path: path);
      throw DioException(
        requestOptions: request,
        response: Response<dynamic>(requestOptions: request, statusCode: 429,
            data: {'message': 'Too many requests. Please try again shortly.'}),
        type: DioExceptionType.badResponse,
      );
    }

    const maxAttempts = 2;
    DioException? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _dio.get<dynamic>(
          path, queryParameters: queryParameters, options: options,
        );
      } on DioException catch (error) {
        lastError = error;
        if (error.response?.statusCode == 429) {
          _rateLimitedUntil = DateTime.now().add(const Duration(seconds: 8));
        }
        if (!_shouldRetryGet(error) || attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(_retryDelayFor(error, failedAttempt: attempt));
      }
    }
    throw lastError ?? DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.unknown,
      error: 'Unknown network error.',
    );
  }

  // ===========================================================================
  // POST
  //
  // Mutation requests are NEVER auto-retried.
  // ===========================================================================

  Future<Response<dynamic>> post(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return _dio.post<dynamic>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ===========================================================================
  // PUT
  // ===========================================================================

  Future<Response<dynamic>> put(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return _dio.put<dynamic>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ===========================================================================
  // PATCH
  // ===========================================================================

  Future<Response<dynamic>> patch(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return _dio.patch<dynamic>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<Response<dynamic>> delete(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return _dio.delete<dynamic>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ===========================================================================
  // STRUCTURED API ERROR HELPERS
  // ===========================================================================

  static String? errorCodeFromDio(
      DioException error,
      ) {
    final raw = error.response?.data;

    if (raw is! Map) {
      return null;
    }

    final body =
    Map<String, dynamic>.from(raw);

    final direct =
    body['error_code']?.toString().trim();

    if (direct != null &&
        direct.isNotEmpty) {
      return direct;
    }

    final errors = body['errors'];

    if (errors is! Map) {
      return null;
    }

    final value =
        errors['error_code'] ??
            errors['code'];

    if (value is List &&
        value.isNotEmpty) {
      final text =
      value.first.toString().trim();

      return text.isEmpty
          ? null
          : text;
    }

    final text =
        value?.toString().trim() ??
            '';

    return text.isEmpty
        ? null
        : text;
  }

  static int? retryAfterSecondsFromDio(
      DioException error,
      ) {
    final value =
    error.response?.headers.value(
      'retry-after',
    );

    if (value == null) {
      return null;
    }

    final seconds =
    int.tryParse(
      value.trim(),
    );

    if (seconds == null ||
        seconds < 0) {
      return null;
    }

    return seconds;
  }

  // ===========================================================================
  // GET RETRY POLICY
  // ===========================================================================

  bool _shouldRetryGet(
      DioException error,
      ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;

      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return false;

      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;

      case DioExceptionType.transformTimeout:
        return true;
    }

    final statusCode =
        error.response?.statusCode;

    if (statusCode == null) {
      return error.type ==
          DioExceptionType.unknown;
    }

    // HTTP 503 may indicate maintenance / Cloudflare. Repeating it on
    // every paginated GET delayed screens by nearly a minute.
    return statusCode == 408 ||
        statusCode == 502 ||
        statusCode == 504;
  }

  Duration _retryDelayFor(
      DioException error, {
        required int failedAttempt,
      }) {
    return _retryDelay(
      failedAttempt,
    );
  }

  Duration _retryDelay(
      int failedAttempt,
      ) {
    switch (failedAttempt) {
      case 1:
        return const Duration(
          milliseconds: 450,
        );

      case 2:
        return const Duration(
          milliseconds: 800,
        );

      default:
        return const Duration(
          seconds: 2,
        );
    }
  }

  // ===========================================================================
  // OPTIONAL RAW DIO ACCESS
  // ===========================================================================

  Dio get dio => _dio;
}
