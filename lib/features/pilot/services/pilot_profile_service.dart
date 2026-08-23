import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

import '../models/pilot_profile_model.dart';
import '../models/pilot_profile_update_model.dart';
import '../models/profile_document_model.dart';

class PilotProfileService {
  final ApiClient apiClient;

  PilotProfileService(this.apiClient);

  Future<PilotProfileModel> getMyProfile() async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.pilotProfile,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseResponseBody(response.data);

      if (body['success'] != true) {
        throw PilotProfileException(
          _messageFromBody(
            body,
            fallback: 'Unable to load pilot profile.',
          ),
        );
      }

      final data = body['data'];
      if (data is! Map) {
        throw const PilotProfileException(
          'Pilot profile data is missing.',
        );
      }

      return PilotProfileModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw PilotProfileException(_dioErrorMessage(e));
    }
  }

  Future<PilotProfileModel> updateMyProfile(
      PilotProfileUpdateRequest request,
      ) async {
    final token = await _getToken();

    try {
      final response = await apiClient.patch(
        ApiEndpoints.pilotProfile,
        data: request.toJson(),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseResponseBody(response.data);

      if (body['success'] != true) {
        throw PilotProfileException(
          _messageFromBody(
            body,
            fallback: 'Unable to update pilot profile.',
          ),
        );
      }

      final data = body['data'];
      if (data is! Map) {
        throw const PilotProfileException(
          'Updated profile data is missing.',
        );
      }

      return PilotProfileModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw PilotProfileException(_dioErrorMessage(e));
    }
  }

  Future<ProfileDocumentModel> uploadProfilePhoto({
    required String filePath,
  }) async {
    final token = await _getToken();
    final file = File(filePath);

    if (!await file.exists()) {
      throw const PilotProfileException(
        'Selected image was not found.',
      );
    }

    const maxBytes = 10 * 1024 * 1024;
    final fileSize = await file.length();

    if (fileSize > maxBytes) {
      throw const PilotProfileException(
        'Profile photo must be smaller than 10 MB.',
      );
    }

    final fileName = file.uri.pathSegments.isEmpty
        ? 'profile_photo.jpg'
        : file.uri.pathSegments.last;

    try {
      final formData = FormData.fromMap({
        'collection': 'profile_photo',
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await apiClient.post(
        ApiEndpoints.profileDocuments,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseResponseBody(response.data);

      if (body['success'] != true) {
        throw PilotProfileException(
          _messageFromBody(
            body,
            fallback: 'Unable to upload profile photo.',
          ),
        );
      }

      final data = body['data'];
      if (data is! Map) {
        throw const PilotProfileException(
          'Uploaded photo data is missing.',
        );
      }

      final document = ProfileDocumentModel.fromJson(
        Map<String, dynamic>.from(data),
      );

      if (document.url.trim().isEmpty) {
        throw const PilotProfileException(
          'Profile photo URL is missing.',
        );
      }

      return document;
    } on DioException catch (e) {
      throw PilotProfileException(_dioErrorMessage(e));
    }
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const PilotProfileException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  Map<String, dynamic> _parseResponseBody(dynamic raw) {
    if (raw is! Map) {
      throw const PilotProfileException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(raw);
  }

  String _messageFromBody(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    final message = body['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  String _dioErrorMessage(DioException error) {
    final raw = error.response?.data;

    if (raw is Map) {
      final body = Map<String, dynamic>.from(raw);
      final errors = body['errors'];

      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }

          if (value != null) {
            return value.toString();
          }
        }
      }

      final message = body['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timed out. Please try again.';
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return 'Server response timed out. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }

    return 'Something went wrong. Please try again.';
  }
}

class PilotProfileException implements Exception {
  final String message;

  const PilotProfileException(this.message);

  @override
  String toString() => message;
}
