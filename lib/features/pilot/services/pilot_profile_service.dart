import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

import '../models/pilot_profile_model.dart';

class PilotProfileService {
  final ApiClient apiClient;

  PilotProfileService(
      this.apiClient,
      );

  // ============================================================
  // GET MY PILOT PROFILE
  // AUTHENTICATED REQUEST
  // ============================================================

  Future<PilotProfileModel> getMyProfile() async {
    print('===== PROFILE API CALLED =====');

    final token =
    await TokenStorage.getAccessToken();

    print(
      'TOKEN EXISTS: ${token != null && token.trim().isNotEmpty}',
    );

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Authentication token not found.',
      );
    }

    try {
      final response =
      await apiClient.get(
        ApiEndpoints.pilotProfile,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization':
            'Bearer ${token.trim()}',
          },
        ),
      );

      print('===== PROFILE API RESPONSE =====');
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');

      final raw = response.data;

      if (raw is! Map) {
        throw const FormatException(
          'Invalid pilot profile response.',
        );
      }

      final body =
      Map<String, dynamic>.from(raw);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ??
              'Unable to load pilot profile.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw const FormatException(
          'Pilot profile data is missing.',
        );
      }

      return PilotProfileModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      print('===== PROFILE API ERROR =====');
      print('URL SENT: ${e.requestOptions.uri}');
      print('STATUS: ${e.response?.statusCode}');
      print('RESPONSE: ${e.response?.data}');

      rethrow;
    }
  }
}