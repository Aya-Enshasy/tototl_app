import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/review_model.dart';

class ReviewService {
  final ApiClient apiClient;

  ReviewService(this.apiClient);

  // ===========================================================================
  // PILOT REVIEWS
  // ===========================================================================

  Future<ReviewListModel> getPilotReviews(
      int pilotProfileId, {
        int page = 1,
        int perPage = 15,
      }) async {
    if (pilotProfileId <= 0) {
      throw const ReviewException(
        'Invalid pilot profile.',
      );
    }

    return _getReviews(
      endpoint: ApiEndpoints.pilotReviews(
        pilotProfileId,
      ),
      page: page,
      perPage: perPage,
      fallback:
      'Unable to load pilot reviews.',
    );
  }

  // ===========================================================================
  // COMPANY REVIEWS
  // ===========================================================================

  Future<ReviewListModel> getCompanyReviews(
      int companyProfileId, {
        int page = 1,
        int perPage = 15,
      }) async {
    if (companyProfileId <= 0) {
      throw const ReviewException(
        'Invalid company profile.',
      );
    }

    return _getReviews(
      endpoint: ApiEndpoints.companyReviews(
        companyProfileId,
      ),
      page: page,
      perPage: perPage,
      fallback:
      'Unable to load company reviews.',
    );
  }

  // ===========================================================================
  // PRIVATE LOAD
  // ===========================================================================

  Future<ReviewListModel> _getReviews({
    required String endpoint,
    required int page,
    required int perPage,
    required String fallback,
  }) async {
    final token =
    await _getToken();

    final safePage =
    page < 1 ? 1 : page;

    final safePerPage =
    perPage.clamp(1, 50).toInt();

    final query =
    <String>[
      'page=$safePage',
      'per_page=$safePerPage',
    ].join('&');

    try {
      final response =
      await apiClient.get(
        '$endpoint?$query',
        options:
        _authOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback: fallback,
      );

      final rawData =
      body['data'];

      if (rawData is! Map) {
        throw ReviewException(
          '$fallback Reviews data is missing.',
        );
      }

      return ReviewListModel.fromJson(
        Map<String, dynamic>.from(
          rawData,
        ),
      );
    } on DioException catch (e) {
      throw ReviewException(
        _dioErrorMessage(
          e,
          fallback: fallback,
        ),
      );
    }
  }

  // ===========================================================================
  // AUTH
  // ===========================================================================

  Future<String> _getToken() async {
    final token =
    await TokenStorage
        .getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw const ReviewException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  Options _authOptions(
      String token,
      ) {
    return Options(
      headers: {
        'Accept':
        'application/json',
        'Authorization':
        'Bearer $token',
      },
    );
  }

  // ===========================================================================
  // RESPONSE PARSING
  // ===========================================================================

  Map<String, dynamic> _parseBody(
      dynamic raw,
      ) {
    if (raw is! Map) {
      throw const ReviewException(
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

    throw ReviewException(
      _messageFromBody(
        body,
        fallback: fallback,
      ),
    );
  }

  String _messageFromBody(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    final errors =
    body['errors'];

    if (errors is Map) {
      for (final value
      in errors.values) {
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

          if (text.isNotEmpty) {
            return text;
          }
        }
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
    final status = error.response?.statusCode;
    if (status == 503 || status == 502 || status == 504 || status == 500) {
      return 'The review service is temporarily unavailable. Please try again.';
    }
    if (status == 429) return 'Too many requests. Please try again shortly.';
    final raw =
        error.response?.data;

    if (raw is Map) {
      return _messageFromBody(
        Map<String, dynamic>.from(
          raw,
        ),
        fallback: fallback,
      );
    }

    if (error.type ==
        DioExceptionType
            .connectionTimeout) {
      return 'Connection timed out. Please try again.';
    }

    if (error.type ==
        DioExceptionType
            .receiveTimeout) {
      return 'Server response timed out. Please try again.';
    }

    if (error.type ==
        DioExceptionType
            .connectionError) {
      return 'No internet connection.';
    }

    return fallback;
  }
}

class ReviewException
    implements Exception {
  final String message;

  const ReviewException(
      this.message,
      );

  @override
  String toString() =>
      message;
}