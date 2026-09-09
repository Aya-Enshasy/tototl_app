import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

import '../../../core/storage/user_session_storage.dart';

import '../models/company_profile_model.dart';
import '../models/company_profile_update_model.dart';

// ============================================================================
// COMPANY PROFILE SERVICE
// ============================================================================

class CompanyProfileService {
  final ApiClient apiClient;

  CompanyProfileService(
      this.apiClient,
      );

  // ==========================================================================
  // GET MY COMPANY PROFILE
  //
  // IMPORTANT:
  // Read current account + profile from GET /me.
  // PATCH remains /company/profile.
  // ==========================================================================

  Future<CompanyProfileModel>
  getMyProfile() async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.get(
        ApiEndpoints.me,
        options: Options(
          headers: {
            'Accept':
            'application/json',
            'Authorization':
            'Bearer $token',
          },
        ),
      );

      final body =
      _parseBody(
        response.data,
      );

      if (body['success'] != true) {
        throw CompanyProfileException(
          _messageFromBody(
            body,
            fallback:
            'Unable to load company profile.',
          ),
        );
      }

      final rawData =
      body['data'];

      if (rawData is! Map) {
        throw const CompanyProfileException(
          'Account data is missing.',
        );
      }

      final meData =
      Map<String, dynamic>.from(
        rawData,
      );

      // ----------------------------------------------------------------------
      // USER
      // ----------------------------------------------------------------------

      final rawUser =
      meData['user'];

      if (rawUser is Map) {
        await UserSessionStorage
            .updateUser(
          Map<String, dynamic>.from(
            rawUser,
          ),
        );
      }

      // ----------------------------------------------------------------------
      // PROFILE
      // ----------------------------------------------------------------------

      final rawProfile =
      meData['profile'];

      if (rawProfile is! Map) {
        throw const CompanyProfileException(
          'Company profile data is missing.',
        );
      }

      final profileJson =
      Map<String, dynamic>.from(
        rawProfile,
      );

      await UserSessionStorage.mergeProfile(
        profileJson,
      );

      // profile_photo is a direct URL String or null.
      final profilePhotoUrl =
          profileJson['profile_photo']
              ?.toString()
              .trim() ??
              '';

      await UserSessionStorage
          .updateProfilePhotoUrl(
        profilePhotoUrl,
      );

      return CompanyProfileModel.fromJson(
        profileJson,
      );
    } on DioException catch (e) {
      throw CompanyProfileException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load company profile.',
        ),
      );
    }
  }

  // ==========================================================================
  // UPDATE MY COMPANY PROFILE
  // PATCH /company/profile
  // ==========================================================================

  Future<CompanyProfileModel>
  updateMyProfile(
      CompanyProfileUpdateRequest request,
      ) async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.patch(
        ApiEndpoints.companyProfile,
        data: request.toJson(),
        options: Options(
          headers: {
            'Accept':
            'application/json',
            'Content-Type':
            'application/json',
            'Authorization':
            'Bearer $token',
          },
        ),
      );

      final body =
      _parseBody(
        response.data,
      );

      if (body['success'] != true) {
        throw CompanyProfileException(
          _messageFromBody(
            body,
            fallback:
            'Unable to update company profile.',
          ),
        );
      }

      final rawData =
      body['data'];

      if (rawData is! Map) {
        throw const CompanyProfileException(
          'Updated company profile data is missing.',
        );
      }

      return CompanyProfileModel.fromJson(
        Map<String, dynamic>.from(
          rawData,
        ),
      );
    } on DioException catch (e) {
      throw CompanyProfileException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to update company profile.',
        ),
      );
    }
  }

  // ==========================================================================
  // TOKEN
  // ==========================================================================

  Future<String> _getToken() async {
    final token =
    await TokenStorage
        .getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw const CompanyProfileException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  // ==========================================================================
  // PARSE BODY
  // ==========================================================================

  Map<String, dynamic> _parseBody(
      dynamic raw,
      ) {
    if (raw is! Map) {
      throw const CompanyProfileException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(
      raw,
    );
  }

  // ==========================================================================
  // MESSAGE
  // ==========================================================================

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

  // ==========================================================================
  // DIO ERROR
  // ==========================================================================

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
        fallback: fallback,
      );
    }

    if (error.type ==
        DioExceptionType
            .connectionTimeout) {
      return 'Connection timed out.';
    }

    if (error.type ==
        DioExceptionType
            .receiveTimeout) {
      return 'Server response timed out.';
    }

    if (error.type ==
        DioExceptionType
            .connectionError) {
      return 'No internet connection.';
    }

    return fallback;
  }
}

// ============================================================================
// EXCEPTION
// ============================================================================

class CompanyProfileException
    implements Exception {
  final String message;

  const CompanyProfileException(
      this.message,
      );

  @override
  String toString() =>
      message;
}
