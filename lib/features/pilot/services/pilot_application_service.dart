import 'package:dio/dio.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/token_storage.dart';

import '../models/pilot_application_model.dart';

class PilotApplicationService {
  final ApiClient apiClient;

  PilotApplicationService(this.apiClient);

  static const String _applicationsPath = '/applications';

  Future<PilotApplicationModel> applyToJob({
    required int jobId,
    required int droneId,
    String? coverMessage,
  }) async {
    final token = await _getToken();
    final endpoint = '/jobs/$jobId/apply';
    final cleanCover = coverMessage?.trim() ?? '';

    final payload = <String, dynamic>{
      'drone_id': droneId,
      if (cleanCover.isNotEmpty) 'cover_message': cleanCover,
    };

    print('================ APPLY TO JOB REQUEST ================');
    print('APPLY URL: $endpoint');
    print('APPLY JOB ID: $jobId');
    print('APPLY DRONE ID: $droneId');
    print('APPLY COVER LENGTH: ${cleanCover.length}');

    try {
      final response = await apiClient.post(
        endpoint,
        data: payload,
        options: _jsonAuthOptions(token),
      );

      print('APPLY STATUS: ${response.statusCode}');
      print('APPLY RAW RESPONSE: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to submit your application.');

      final application = _parseApplication(
        body['data'],
        fallback: 'Submitted application data is missing.',
      );

      print(
        'APPLY PARSED: id=${application.id}, status=${application.status}, '
        'job=${application.jobPostingId}, drone=${application.droneId}',
      );
      print('================ APPLY TO JOB SUCCESS ================');

      return application;
    } on DioException catch (e, stack) {
      _printDioError(title: 'APPLY TO JOB', error: e, stack: stack);
      throw PilotApplicationException(
        _dioErrorMessage(e, fallback: 'Unable to submit your application.'),
      );
    }
  }

  Future<List<PilotApplicationModel>> getMyApplications() async {
    final token = await _getToken();

    print('================ MY APPLICATIONS REQUEST ================');

    try {
      final response = await apiClient.get(
        _applicationsPath,
        options: _authOptions(token),
      );

      print('MY APPLICATIONS STATUS: ${response.statusCode}');
      print('MY APPLICATIONS RAW RESPONSE: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to load your applications.');

      final applications = _parseApplicationList(body['data']);
      applications.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      print('MY APPLICATIONS PARSED COUNT: ${applications.length}');
      print('================ MY APPLICATIONS SUCCESS ================');

      return applications;
    } on DioException catch (e, stack) {
      _printDioError(title: 'MY APPLICATIONS', error: e, stack: stack);
      throw PilotApplicationException(
        _dioErrorMessage(e, fallback: 'Unable to load your applications.'),
      );
    }
  }

  Future<PilotApplicationModel> getApplicationDetails(int applicationId) async {
    final token = await _getToken();
    final endpoint = '$_applicationsPath/$applicationId';

    print('================ APPLICATION DETAIL REQUEST ================');
    print('APPLICATION DETAIL URL: $endpoint');

    try {
      final response = await apiClient.get(
        endpoint,
        options: _authOptions(token),
      );

      print('APPLICATION DETAIL STATUS: ${response.statusCode}');
      print('APPLICATION DETAIL RAW RESPONSE: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to load this application.');

      final application = _parseApplication(
        body['data'],
        fallback: 'Application details are missing.',
      );

      print('APPLICATION DETAIL PARSED: id=${application.id}, status=${application.status}');
      print('================ APPLICATION DETAIL SUCCESS ================');

      return application;
    } on DioException catch (e, stack) {
      _printDioError(title: 'APPLICATION DETAIL', error: e, stack: stack);
      throw PilotApplicationException(
        _dioErrorMessage(e, fallback: 'Unable to load this application.'),
      );
    }
  }

  Future<PilotApplicationModel> withdrawApplication(int applicationId) async {
    final token = await _getToken();
    final endpoint = '$_applicationsPath/$applicationId/withdraw';

    print('================ WITHDRAW APPLICATION REQUEST ================');
    print('WITHDRAW URL: $endpoint');

    try {
      final response = await apiClient.post(
        endpoint,
        options: _authOptions(token),
      );

      print('WITHDRAW STATUS: ${response.statusCode}');
      print('WITHDRAW RAW RESPONSE: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to withdraw this application.');

      final application = _parseApplication(
        body['data'],
        fallback: 'Withdrawn application data is missing.',
      );

      print('WITHDRAW PARSED: id=${application.id}, status=${application.status}');
      print('================ WITHDRAW APPLICATION SUCCESS ================');

      return application;
    } on DioException catch (e, stack) {
      _printDioError(title: 'WITHDRAW APPLICATION', error: e, stack: stack);
      throw PilotApplicationException(
        _dioErrorMessage(e, fallback: 'Unable to withdraw this application.'),
      );
    }
  }

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) {
      throw const PilotApplicationException('Invalid server response.');
    }
    return Map<String, dynamic>.from(raw);
  }

  PilotApplicationModel _parseApplication(
    dynamic raw, {
    required String fallback,
  }) {
    if (raw is Map) {
      return PilotApplicationModel.fromJson(Map<String, dynamic>.from(raw));
    }
    throw PilotApplicationException(fallback);
  }

  List<PilotApplicationModel> _parseApplicationList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => PilotApplicationModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final nested = map['data'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => PilotApplicationModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    if (raw == null) return <PilotApplicationModel>[];

    throw const PilotApplicationException('Application list data is invalid.');
  }

  void _ensureSuccess(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    if (body['success'] == true) return;
    throw PilotApplicationException(_messageFromBody(body, fallback: fallback));
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const PilotApplicationException('Authentication token not found.');
    }
    return token.trim();
  }

  Options _authOptions(String token) {
    return Options(
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Options _jsonAuthOptions(String token) {
    return Options(
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
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
      return _messageFromBody(Map<String, dynamic>.from(raw), fallback: fallback);
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

    return fallback;
  }

  void _printDioError({
    required String title,
    required DioException error,
    required StackTrace stack,
  }) {
    print('================ $title DIO ERROR ================');
    print('TYPE: ${error.type}');
    print('MESSAGE: ${error.message}');
    print('STATUS: ${error.response?.statusCode}');
    print('RESPONSE: ${error.response?.data}');
    print('URI: ${error.requestOptions.uri}');
    print('STACK: $stack');
  }
}

class PilotApplicationException implements Exception {
  final String message;
  const PilotApplicationException(this.message);

  @override
  String toString() => message;
}
