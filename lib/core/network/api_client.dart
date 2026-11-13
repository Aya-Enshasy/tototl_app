import 'dart:async';

import 'package:dio/dio.dart';

import 'api_endpoints.dart';

class ApiClient {
  // ===========================================================================
  // SINGLETON
  // ===========================================================================

  static final ApiClient _instance =
  ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 40),
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

          handler.next(options);
        },
        onError: (
            DioException error,
            ErrorInterceptorHandler handler,
            ) {
          // Keep the original DioException intact.
          // Feature services inspect status/error_code/Retry-After when needed.
          handler.next(error);
        },
      ),
    );
  }

  // ===========================================================================
  // GET
  //
  // Safe to retry. 429 respects the server Retry-After header.
  // ===========================================================================

  Future<Response<dynamic>> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    const maxAttempts = 3;

    DioException? lastError;

    for (
    var attempt = 1;
    attempt <= maxAttempts;
    attempt++
    ) {
      try {
        return await _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
          options: options,
        );
      } on DioException catch (error) {
        lastError = error;

        final shouldRetry =
        _shouldRetryGet(error);

        if (!shouldRetry ||
            attempt >= maxAttempts) {
          rethrow;
        }

        await Future<void>.delayed(
          _retryDelayFor(
            error,
            failedAttempt: attempt,
          ),
        );
      }
    }

    throw lastError ??
        DioException(
          requestOptions: RequestOptions(
            path: path,
          ),
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

    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  Duration _retryDelayFor(
      DioException error, {
        required int failedAttempt,
      }) {
    if (error.response?.statusCode ==
        429) {
      final retryAfter =
      retryAfterSecondsFromDio(
        error,
      );

      if (retryAfter != null) {
        return Duration(
          seconds: retryAfter,
        );
      }
    }

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
          milliseconds: 600,
        );

      case 2:
        return const Duration(
          milliseconds: 1400,
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
