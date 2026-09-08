import 'package:dio/dio.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/token_storage.dart';

import '../models/pilot_job_filters.dart';
import '../models/pilot_job_model.dart';

class PilotJobService {
  final ApiClient apiClient;

  PilotJobService(this.apiClient);

  static const String _jobsPath = '/jobs';

  Future<PilotJobsPage> browseJobs({
    required PilotJobFilters filters,
    int page = 1,
    int perPage = 15,
  }) async {
    final token = await _getToken();

    final endpoint = _buildBrowseEndpoint(
      filters: filters,
      page: page,
      perPage: perPage,
    );

    print('================ PILOT JOBS REQUEST ================');
    print('PILOT JOBS URL: $endpoint');

    try {
      final response = await apiClient.get(
        endpoint,
        options: _authOptions(token),
      );

      print('PILOT JOBS STATUS: ${response.statusCode}');
      print('PILOT JOBS RAW RESPONSE: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to load available jobs.',
      );

      final result = _parseBrowseResponse(body);

      print('PILOT JOBS PARSED COUNT: ${result.jobs.length}');
      print(
        'PILOT JOBS META: page=${result.currentPage}, '
        'last=${result.lastPage}, total=${result.total}',
      );
      print('================ PILOT JOBS SUCCESS ================');

      return result;
    } on DioException catch (e, stack) {
      print('================ PILOT JOBS DIO ERROR ================');
      print('TYPE: ${e.type}');
      print('MESSAGE: ${e.message}');
      print('STATUS: ${e.response?.statusCode}');
      print('RESPONSE: ${e.response?.data}');
      print('URI: ${e.requestOptions.uri}');
      print('STACK: $stack');

      throw PilotJobException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load available jobs.',
        ),
      );
    } catch (e, stack) {
      print('================ PILOT JOBS GENERAL ERROR ================');
      print('ERROR: $e');
      print('STACK: $stack');
      rethrow;
    }
  }

  Future<PilotJobModel> getJobDetails(int jobId) async {
    final token = await _getToken();
    final endpoint = '$_jobsPath/$jobId';

    print('================ PILOT JOB DETAIL REQUEST ================');
    print('PILOT JOB DETAIL URL: $endpoint');

    try {
      final response = await apiClient.get(
        endpoint,
        options: _authOptions(token),
      );

      print('PILOT JOB DETAIL STATUS: ${response.statusCode}');
      print('PILOT JOB DETAIL RAW RESPONSE: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to load job details.',
      );

      final rawData = body['data'];

      if (rawData is! Map) {
        throw const PilotJobException('Job details data is missing.');
      }

      final job = PilotJobModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );

      print(
        'PILOT JOB DETAIL PARSED: '
        'id=${job.id}, title=${job.title}, '
        'company=${job.company?.displayName}, '
        'hasApplied=${job.application?.hasApplied}',
      );
      print('================ PILOT JOB DETAIL SUCCESS ================');

      return job;
    } on DioException catch (e, stack) {
      print('================ PILOT JOB DETAIL DIO ERROR ================');
      print('TYPE: ${e.type}');
      print('MESSAGE: ${e.message}');
      print('STATUS: ${e.response?.statusCode}');
      print('RESPONSE: ${e.response?.data}');
      print('URI: ${e.requestOptions.uri}');
      print('STACK: $stack');

      throw PilotJobException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load job details.',
        ),
      );
    } catch (e, stack) {
      print('================ PILOT JOB DETAIL GENERAL ERROR ================');
      print('ERROR: $e');
      print('STACK: $stack');
      rethrow;
    }
  }

  PilotJobsPage _parseBrowseResponse(Map<String, dynamic> body) {
    final rootData = body['data'];

    // Actual backend response tested by the user:
    // data: [ ...jobs... ], meta: { ...pagination... }
    if (rootData is List) {
      final jobs = _parseJobList(rootData);
      final rawMeta = body['meta'];
      final meta = rawMeta is Map
          ? Map<String, dynamic>.from(rawMeta)
          : const <String, dynamic>{};

      return PilotJobsPage(
        jobs: jobs,
        currentPage: _asInt(meta['current_page']) ?? 1,
        perPage: _asInt(meta['per_page']) ?? 15,
        total: _asInt(meta['total']) ?? jobs.length,
        lastPage: _asInt(meta['last_page']) ?? 1,
      );
    }

    // Defensive fallback for Laravel nested paginator responses.
    if (rootData is Map) {
      final paginator = Map<String, dynamic>.from(rootData);
      final rawJobs = paginator['data'];

      if (rawJobs is! List) {
        throw const PilotJobException('Available jobs data is missing.');
      }

      final jobs = _parseJobList(rawJobs);

      return PilotJobsPage(
        jobs: jobs,
        currentPage: _asInt(paginator['current_page']) ?? 1,
        perPage: _asInt(paginator['per_page']) ?? 15,
        total: _asInt(paginator['total']) ?? jobs.length,
        lastPage: _asInt(paginator['last_page']) ?? 1,
      );
    }

    throw const PilotJobException('Available jobs data is missing.');
  }

  List<PilotJobModel> _parseJobList(List<dynamic> raw) {
    final jobs = <PilotJobModel>[];

    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];

      if (item is! Map) {
        print('PILOT JOB SKIPPED INDEX $i: item is not an object');
        continue;
      }

      try {
        final job = PilotJobModel.fromJson(
          Map<String, dynamic>.from(item),
        );

        if (job.id > 0) {
          jobs.add(job);
          print(
            'PILOT JOB PARSED: '
            'id=${job.id}, title=${job.title}, status=${job.status}',
          );
        }
      } catch (e, stack) {
        print('PILOT JOB PARSE ERROR INDEX $i: $e');
        print('PILOT JOB PARSE STACK: $stack');
        rethrow;
      }
    }

    return jobs;
  }

  String _buildBrowseEndpoint({
    required PilotJobFilters filters,
    required int page,
    required int perPage,
  }) {
    final params = <MapEntry<String, String>>[];

    void add(String key, Object? value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      params.add(MapEntry(key, text));
    }

    add('search', filters.search);
    add('country', filters.country);
    add('state', filters.state);
    add('city', filters.city);
    add('region', filters.region);
    add('category', filters.category);

    if (filters.dateFrom != null) {
      final value = filters.dateFrom!;
      add(
        'date_from',
        DateTime.utc(value.year, value.month, value.day).toIso8601String(),
      );
    }

    if (filters.dateTo != null) {
      final value = filters.dateTo!;
      add(
        'date_to',
        DateTime.utc(
          value.year,
          value.month,
          value.day,
          23,
          59,
          59,
        ).toIso8601String(),
      );
    }

    add('payment_min', filters.paymentMin);
    add('payment_max', filters.paymentMax);

    for (final capability in filters.capabilities) {
      add('capabilities[]', capability);
    }

    add('sort', filters.sort);
    add('per_page', perPage.clamp(1, 50));
    add('page', page < 1 ? 1 : page);

    final query = params
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}='
              '${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    return query.isEmpty ? _jobsPath : '$_jobsPath?$query';
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const PilotJobException('Authentication token not found.');
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

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) {
      throw const PilotJobException('Invalid server response.');
    }

    return Map<String, dynamic>.from(raw);
  }

  void _ensureSuccess(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    if (body['success'] == true) return;

    throw PilotJobException(
      _messageFromBody(body, fallback: fallback),
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
          final text = value.first.toString().trim();
          if (text.isNotEmpty) return text;
        }

        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }

    final message = body['message']?.toString().trim() ?? '';
    return message.isEmpty ? fallback : message;
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

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class PilotJobException implements Exception {
  final String message;

  const PilotJobException(this.message);

  @override
  String toString() => message;
}
