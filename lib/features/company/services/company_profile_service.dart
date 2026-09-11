import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

import '../models/company_profile_model.dart';
import '../models/company_profile_update_model.dart';

class CompanyProfileService {
  final ApiClient apiClient;

  CompanyProfileService(this.apiClient);

  Future<CompanyProfileModel> getMyProfile() async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.companyProfile,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(response.data);
      if (body['success'] != true) {
        throw CompanyProfileException(
          _messageFromBody(
            body,
            fallback: 'Unable to load company profile.',
          ),
        );
      }

      final rawData = body['data'];
      if (rawData is! Map) {
        throw const CompanyProfileException(
          'Company profile data is missing.',
        );
      }

      return CompanyProfileModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } on DioException catch (e) {
      throw CompanyProfileException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load company profile.',
        ),
      );
    }
  }

  Future<CompanyProfileModel> updateMyProfile(
      CompanyProfileUpdateRequest request,
      ) async {
    final token = await _getToken();

    try {
      final response = await apiClient.patch(
        ApiEndpoints.companyProfile,
        data: request.toJson(),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(response.data);
      if (body['success'] != true) {
        throw CompanyProfileException(
          _messageFromBody(
            body,
            fallback: 'Unable to update company profile.',
          ),
        );
      }

      final rawData = body['data'];
      if (rawData is! Map) {
        throw const CompanyProfileException(
          'Updated company profile data is missing.',
        );
      }

      return CompanyProfileModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } on DioException catch (e) {
      throw CompanyProfileException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to update company profile.',
        ),
      );
    }
  }

  Future<String> uploadProfilePhoto({
    required String filePath,
  }) async {
    final token = await _getToken();
    final file = File(filePath);

    if (!await file.exists()) {
      throw const CompanyProfileException('Selected image was not found.');
    }

    const maxBytes = 10 * 1024 * 1024;
    if (await file.length() > maxBytes) {
      throw const CompanyProfileException(
        'Company photo must be smaller than 10 MB.',
      );
    }

    final fileName = file.uri.pathSegments.isEmpty
        ? 'company_profile_photo.jpg'
        : file.uri.pathSegments.last;

    try {
      final formData = FormData.fromMap({
        // Same generic profile-photo collection used by the Pilot flow.
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

      final body = _parseBody(response.data);
      if (body['success'] != true) {
        throw CompanyProfileException(
          _messageFromBody(
            body,
            fallback: 'Unable to upload company photo.',
          ),
        );
      }

      final rawData = body['data'];
      if (rawData is! Map) {
        throw const CompanyProfileException(
          'Uploaded photo data is missing.',
        );
      }

      final data = Map<String, dynamic>.from(rawData);
      final url = data['url']?.toString().trim() ?? '';

      if (url.isEmpty) {
        throw const CompanyProfileException(
          'Profile photo URL is missing.',
        );
      }

      return url;
    } on DioException catch (e) {
      throw CompanyProfileException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to upload company photo.',
        ),
      );
    }
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const CompanyProfileException('Authentication token not found.');
    }
    return token.trim();
  }

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) {
      throw const CompanyProfileException('Invalid server response.');
    }
    return Map<String, dynamic>.from(raw);
  }

  String _messageFromBody(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    final errors = body['errors'];

    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();
          if (first.isNotEmpty) return first;
        }
        if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }
    }

    final message = body['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;
    return fallback;
  }

  String _dioErrorMessage(
      DioException error, {
        required String fallback,
      }) {
    final raw = error.response?.data;
    if (raw is Map) {
      return _messageFromBody(
        Map<String, dynamic>.from(raw),
        fallback: fallback,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timed out.';
    }
    if (error.type == DioExceptionType.receiveTimeout) {
      return 'Server response timed out.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return fallback;
  }
}

class CompanyProfileException implements Exception {
  final String message;
  const CompanyProfileException(this.message);

  @override
  String toString() => message;
}
