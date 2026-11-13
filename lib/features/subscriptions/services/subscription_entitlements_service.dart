import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/subscription_entitlements_model.dart';

class SubscriptionEntitlementsService {
  final ApiClient apiClient;

  SubscriptionEntitlementsService(
      this.apiClient,
      );

  static const String _endpoint =
      '/subscription/entitlements';

  Future<SubscriptionEntitlementsModel> getEntitlements() async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        _endpoint,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load subscription entitlements.',
      );

      final rawData = body['data'];

      if (rawData is! Map) {
        throw const SubscriptionEntitlementsException(
          'Subscription entitlements data is missing.',
        );
      }

      return SubscriptionEntitlementsModel.fromJson(
        Map<String, dynamic>.from(
          rawData,
        ),
      );
    } on DioException catch (e) {
      throw SubscriptionEntitlementsException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load subscription entitlements.',
        ),
        code: _errorCodeFromDio(
          e,
        ),
      );
    }
  }

  // ===========================================================================
  // TOKEN
  // ===========================================================================

  Future<String> _getToken() async {
    final token =
    await TokenStorage.getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw const SubscriptionEntitlementsException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  // ===========================================================================
  // RESPONSE
  // ===========================================================================

  Map<String, dynamic> _parseBody(
      dynamic raw,
      ) {
    if (raw is! Map) {
      throw const SubscriptionEntitlementsException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(
      raw,
    );
  }

  void _ensureSuccess(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    if (body['success'] == true) {
      return;
    }

    throw SubscriptionEntitlementsException(
      _messageFromBody(
        body,
        fallback:
        fallback,
      ),
      code: _errorCodeFromBody(
        body,
      ),
    );
  }

  // ===========================================================================
  // ERROR CODE
  // ===========================================================================

  String? _errorCodeFromBody(
      Map<String, dynamic> body,
      ) {
    final direct =
    body['error_code']
        ?.toString()
        .trim();

    if (direct != null &&
        direct.isNotEmpty) {
      return direct;
    }

    final errors =
    body['errors'];

    if (errors is Map) {
      final map =
      Map<String, dynamic>.from(
        errors,
      );

      for (final key in const [
        'error_code',
        'code',
      ]) {
        final raw =
        map[key];

        if (raw is List &&
            raw.isNotEmpty) {
          final value =
          raw.first
              .toString()
              .trim();

          if (value.isNotEmpty) {
            return value;
          }
        }

        final value =
        raw
            ?.toString()
            .trim();

        if (value != null &&
            value.isNotEmpty &&
            value.toLowerCase() !=
                'null') {
          return value;
        }
      }
    }

    return null;
  }

  String? _errorCodeFromDio(
      DioException error,
      ) {
    final raw =
        error.response?.data;

    if (raw is Map) {
      return _errorCodeFromBody(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    }

    return null;
  }

  // ===========================================================================
  // ERROR MESSAGE
  // ===========================================================================

  String _messageFromBody(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    final errors =
    body['errors'];

    if (errors is Map) {
      for (final entry
      in errors.entries) {
        final key =
        entry.key
            .toString()
            .trim()
            .toLowerCase();

        if (key == 'error_code' ||
            key == 'code') {
          continue;
        }

        final value =
            entry.value;

        if (value is List &&
            value.isNotEmpty) {
          final first =
          value.first
              .toString()
              .trim();

          if (first.isNotEmpty) {
            return first;
          }
        }

        if (value != null) {
          final text =
          value
              .toString()
              .trim();

          if (text.isNotEmpty &&
              text.toLowerCase() !=
                  'null') {
            return text;
          }
        }
      }
    }

    if (errors is List &&
        errors.isNotEmpty) {
      final first =
      errors.first
          .toString()
          .trim();

      if (first.isNotEmpty) {
        return first;
      }
    }

    final message =
    body['message']
        ?.toString()
        .trim();

    if (message != null &&
        message.isNotEmpty) {
      return message;
    }

    return fallback;
  }

  String _dioErrorMessage(
      DioException error, {
        required String fallback,
      }) {
    final raw =
        error.response?.data;

    if (raw is Map) {
      return _messageFromBody(
        Map<String, dynamic>.from(
          raw,
        ),
        fallback:
        fallback,
      );
    }

    if (error.response?.statusCode ==
        429) {
      final retryAfter =
      _retryAfterSeconds(
        error,
      );

      if (retryAfter != null) {
        return 'Too many requests. Please try again in $retryAfter seconds.';
      }

      return 'Too many requests. Please try again shortly.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';

      case DioExceptionType.connectionError:
        return 'No internet connection.';

      case DioExceptionType.badCertificate:
        return 'Unable to establish a secure connection.';

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return fallback;
    }
  }

  int? _retryAfterSeconds(
      DioException error,
      ) {
    final headers =
        error.response?.headers;

    if (headers == null) {
      return null;
    }

    final value =
    headers.value(
      'retry-after',
    );

    if (value == null ||
        value.trim().isEmpty) {
      return null;
    }

    return int.tryParse(
      value.trim(),
    );
  }
}

class SubscriptionEntitlementsException
    implements Exception {
  final String message;
  final String? code;

  const SubscriptionEntitlementsException(
      this.message, {
        this.code,
      });

  bool get isLimitReached =>
      code ==
          'SUBSCRIPTION_LIMIT_REACHED';

  bool get isFeatureUnavailable =>
      code ==
          'SUBSCRIPTION_FEATURE_UNAVAILABLE';

  bool get isAccountNotVerified =>
      code ==
          'ACCOUNT_NOT_VERIFIED';

  bool get isInvalidStatusTransition =>
      code ==
          'INVALID_STATUS_TRANSITION';

  bool get requiresUpgrade =>
      isLimitReached ||
          isFeatureUnavailable;

  @override
  String toString() =>
      message;
}