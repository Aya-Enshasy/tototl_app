import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

import '../models/company_create_job_request.dart';
import '../models/company_job_application_model.dart';
import '../models/company_job_posting_model.dart';
import '../models/company_update_job_request.dart';

class CompanyJobService {
  final ApiClient apiClient;

  CompanyJobService(this.apiClient);

  String get _jobsBase => ApiEndpoints.companyJobPostings;

  // ==========================================================================
  // MY JOBS
  // GET /company/job-postings
  // ==========================================================================

  Future<List<CompanyJobPostingModel>> getMyJobs() async {
    print('================ MY JOBS START ================');

    try {
      final token = await _getToken();

      print('MY JOBS TOKEN EXISTS: ${token.isNotEmpty}');
      print('MY JOBS ENDPOINT: $_jobsBase');

      final allJobs = <CompanyJobPostingModel>[];

      int page = 1;
      int lastPage = 1;

      do {
        final endpoint =
            '$_jobsBase?per_page=15&page=$page';

        print('MY JOBS REQUEST: $endpoint');

        final response = await apiClient.get(
          endpoint,
          options: _authOptions(token),
        );

        print(
          'MY JOBS STATUS CODE: ${response.statusCode}',
        );

        print(
          'MY JOBS RAW RESPONSE: ${response.data}',
        );

        final body = _parseBody(
          response.data,
        );

        print(
          'MY JOBS SUCCESS VALUE: ${body['success']}',
        );

        _ensureSuccess(
          body,
          fallback:
          'Unable to load company jobs.',
        );

        final rawData = body['data'];

        print(
          'MY JOBS DATA TYPE: ${rawData.runtimeType}',
        );

        if (rawData is! List) {
          print(
            'MY JOBS ERROR: data is NOT List',
          );

          throw const CompanyJobException(
            'Company jobs data is missing.',
          );
        }

        print(
          'MY JOBS ITEMS COUNT: ${rawData.length}',
        );

        for (var i = 0;
        i < rawData.length;
        i++) {
          final item = rawData[i];

          print(
            'PARSING JOB INDEX $i: $item',
          );

          if (item is Map) {
            try {
              final job =
              CompanyJobPostingModel.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              );

              print(
                'PARSED JOB OK: id=${job.id}, title=${job.title}, status=${job.status}',
              );

              allJobs.add(job);
            } catch (e, stack) {
              print(
                'JOB PARSE ERROR INDEX $i: $e',
              );

              print(
                'JOB PARSE STACK: $stack',
              );

              rethrow;
            }
          }
        }

        final rawMeta = body['meta'];

        print(
          'MY JOBS META: $rawMeta',
        );

        if (rawMeta is Map) {
          final meta =
          Map<String, dynamic>.from(
            rawMeta,
          );

          lastPage =
              _asInt(
                meta['last_page'],
              ) ??
                  page;
        } else {
          lastPage = page;
        }

        print(
          'MY JOBS PAGE $page / $lastPage',
        );

        page++;
      } while (page <= lastPage);

      print(
        'MY JOBS FINAL COUNT: ${allJobs.length}',
      );

      print(
        '================ MY JOBS SUCCESS ================',
      );

      return allJobs;
    } on DioException catch (e, stack) {
      print(
        '================ MY JOBS DIO ERROR ================',
      );

      print(
        'DIO TYPE: ${e.type}',
      );

      print(
        'DIO MESSAGE: ${e.message}',
      );

      print(
        'DIO STATUS: ${e.response?.statusCode}',
      );

      print(
        'DIO RESPONSE: ${e.response?.data}',
      );

      print(
        'DIO URI: ${e.requestOptions.uri}',
      );

      print(
        'DIO STACK: $stack',
      );

      throw CompanyJobException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load company jobs.',
        ),
      );
    } catch (e, stack) {
      print(
        '================ MY JOBS GENERAL ERROR ================',
      );

      print(
        'ERROR: $e',
      );

      print(
        'STACK: $stack',
      );

      rethrow;
    }
  }

  // ==========================================================================
  // JOB DETAIL
  // GET /company/job-postings/{id}
  // ==========================================================================

  Future<CompanyJobPostingModel> getJobDetails(int jobId) async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        '$_jobsBase/$jobId',
        options: _authOptions(token),
      );

      print('JOB DETAIL RESPONSE [$jobId]: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to load job details.',
      );

      final rawData = body['data'];

      if (rawData is! Map) {
        throw const CompanyJobException(
          'Job details data is missing.',
        );
      }

      return CompanyJobPostingModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } on DioException catch (e) {
      throw CompanyJobException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load job details.',
        ),
      );
    }
  }

  // ==========================================================================
  // APPLICANTS FOR ONE JOB
  // GET /company/job-postings/{id}/applicants
  // ==========================================================================

  Future<List<CompanyJobApplicationModel>> getApplicants(
    int jobId,
  ) async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        '$_jobsBase/$jobId/applicants',
        options: _authOptions(token),
      );

      print('JOB APPLICANTS RESPONSE [$jobId]: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to load job applicants.',
      );

      final rawData = body['data'];

      if (rawData is! List) {
        throw const CompanyJobException(
          'Applicants data is missing.',
        );
      }

      return rawData
          .whereType<Map>()
          .map(
            (item) => CompanyJobApplicationModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw CompanyJobException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load job applicants.',
        ),
      );
    }
  }

  // ==========================================================================
  // CREATE DRAFT
  // POST /company/job-postings
  // ==========================================================================

  Future<CompanyJobPostingModel> createJob(
    CompanyCreateJobRequest request,
  ) async {
    final token = await _getToken();

    try {
      final formData = FormData();

      void addField(String key, dynamic value) {
        if (value == null) return;

        final text = value.toString().trim();
        if (text.isEmpty) return;

        formData.fields.add(MapEntry(key, text));
      }

      addField('title', request.title);
      addField('description', request.description);
      addField('country', request.country);

      addField('service_category', request.serviceCategory);
      addField('state', request.state);
      addField('city', request.city);
      addField('region', request.region);

      addField(
        'start_date',
        request.startDate.toUtc().toIso8601String(),
      );
      addField(
        'end_date',
        request.endDate.toUtc().toIso8601String(),
      );

      addField('payment_type', request.paymentType);
      addField('payment_min', request.paymentMin);
      addField('payment_max', request.paymentMax);

      for (var i = 0; i < request.requiredCapabilities.length; i++) {
        addField(
          'required_capabilities[$i]',
          request.requiredCapabilities[i],
        );
      }

      addField('required_experience', request.requiredExperience);

      for (var i = 0; i < request.requiredCertifications.length; i++) {
        addField(
          'required_certifications[$i]',
          request.requiredCertifications[i],
        );
      }

      addField('drone_size', request.droneSize);

      addField(
        'training_safety_required',
        request.trainingSafetyRequired ? '1' : '0',
      );
      addField(
        'nda_required',
        request.ndaRequired ? '1' : '0',
      );

      addField('requirements_notes', request.requirementsNotes);

      if (request.attachmentPaths.length > 10) {
        throw const CompanyJobException(
          'You can upload up to 10 attachments.',
        );
      }

      for (var i = 0; i < request.attachmentPaths.length; i++) {
        final path = request.attachmentPaths[i];
        final file = File(path);

        if (!await file.exists()) {
          throw CompanyJobException(
            'Attachment not found: $path',
          );
        }

        const maxBytes = 10 * 1024 * 1024;
        final size = await file.length();

        if (size > maxBytes) {
          throw const CompanyJobException(
            'Each attachment must be smaller than 10 MB.',
          );
        }

        final fileName = file.uri.pathSegments.isEmpty
            ? 'attachment_$i'
            : file.uri.pathSegments.last;

        formData.files.add(
          MapEntry(
            'attachments[$i]',
            await MultipartFile.fromFile(
              path,
              filename: fileName,
            ),
          ),
        );
      }

      final response = await apiClient.post(
        _jobsBase,
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('CREATE JOB RESPONSE: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to create job posting.',
      );

      final rawData = body['data'];

      if (rawData is! Map) {
        throw const CompanyJobException(
          'Created job data is missing.',
        );
      }

      return CompanyJobPostingModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } on DioException catch (e) {
      throw CompanyJobException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to create job posting.',
        ),
      );
    }
  }

  // ==========================================================================
  // UPDATE DRAFT
  // PATCH /company/job-postings/{id}
  // ==========================================================================

  Future<CompanyJobPostingModel> updateJob(
    int jobId,
    CompanyUpdateJobRequest request,
  ) async {
    final token = await _getToken();

    try {
      final formData = FormData();

      void addRequired(String key, dynamic value) {
        formData.fields.add(
          MapEntry(key, value.toString().trim()),
        );
      }

      void addNullable(String key, String? value) {
        // Empty strings are intentionally sent for nullable text fields.
        // Laravel's normal ConvertEmptyStringsToNull middleware converts them
        // to null, allowing a company to clear an optional value.
        formData.fields.add(
          MapEntry(key, value?.trim() ?? ''),
        );
      }

      addRequired('title', request.title);
      addNullable('service_category', request.serviceCategory);
      addRequired('description', request.description);
      addRequired('country', request.country);
      addNullable('state', request.state);
      addNullable('city', request.city);
      addNullable('region', request.region);

      addRequired(
        'start_date',
        request.startDate.toUtc().toIso8601String(),
      );
      addRequired(
        'end_date',
        request.endDate.toUtc().toIso8601String(),
      );

      addRequired('payment_type', request.paymentType);

      if (request.paymentType == 'negotiable') {
        addNullable('payment_min', null);
        addNullable('payment_max', null);
      } else {
        addRequired('payment_min', request.paymentMin ?? 0);

        if (request.paymentMax == null) {
          addNullable('payment_max', null);
        } else {
          addRequired('payment_max', request.paymentMax!);
        }
      }

      for (var i = 0; i < request.requiredCapabilities.length; i++) {
        addRequired(
          'required_capabilities[$i]',
          request.requiredCapabilities[i],
        );
      }

      addNullable(
        'required_experience',
        request.requiredExperience,
      );

      for (var i = 0; i < request.requiredCertifications.length; i++) {
        addRequired(
          'required_certifications[$i]',
          request.requiredCertifications[i],
        );
      }

      addNullable('drone_size', request.droneSize);

      addRequired(
        'training_safety_required',
        request.trainingSafetyRequired ? '1' : '0',
      );
      addRequired(
        'nda_required',
        request.ndaRequired ? '1' : '0',
      );

      addNullable(
        'requirements_notes',
        request.requirementsNotes,
      );

      final response = await apiClient.patch(
        '$_jobsBase/$jobId',
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('UPDATE JOB RESPONSE [$jobId]: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to update job posting.',
      );

      final rawData = body['data'];

      if (rawData is! Map) {
        throw const CompanyJobException(
          'Updated job data is missing.',
        );
      }

      return CompanyJobPostingModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } on DioException catch (e) {
      throw CompanyJobException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to update job posting.',
        ),
      );
    }
  }

  // ==========================================================================
  // DELETE DRAFT
  // DELETE /company/job-postings/{id}
  // ==========================================================================

  Future<void> deleteJob(int jobId) async {
    final token = await _getToken();

    try {
      final response = await apiClient.delete(
        '$_jobsBase/$jobId',
        options: _authOptions(token),
      );

      print('DELETE JOB RESPONSE [$jobId]: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to delete job posting.',
      );
    } on DioException catch (e) {
      throw CompanyJobException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to delete job posting.',
        ),
      );
    }
  }

  // ==========================================================================
  // PUBLISH DRAFT
  // POST /company/job-postings/{id}/publish
  // ==========================================================================

  Future<CompanyJobPostingModel> publishJob(int jobId) async {
    final token = await _getToken();

    try {
      final response = await apiClient.post(
        '$_jobsBase/$jobId/publish',
        options: _authOptions(token),
      );

      print('PUBLISH JOB RESPONSE [$jobId]: ${response.data}');

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to publish job posting.',
      );

      final rawData = body['data'];

      if (rawData is! Map) {
        throw const CompanyJobException(
          'Published job data is missing.',
        );
      }

      return CompanyJobPostingModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } on DioException catch (e) {
      throw CompanyJobException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to publish job posting.',
        ),
      );
    }
  }

  // ==========================================================================
  // TOKEN / HELPERS
  // ==========================================================================

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const CompanyJobException(
        'Authentication token not found.',
      );
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

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) {
      throw const CompanyJobException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(raw);
  }

  void _ensureSuccess(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    if (body['success'] == true) return;

    throw CompanyJobException(
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
    final errors = body['errors'];

    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();

          if (first.isNotEmpty) {
            return first;
          }
        }

        if (value != null) {
          final text = value.toString().trim();

          if (text.isNotEmpty) {
            return text;
          }
        }
      }
    }

    final message = body['message']?.toString().trim();

    if (message != null && message.isNotEmpty) {
      return message;
    }

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
}

class CompanyJobException implements Exception {
  final String message;

  const CompanyJobException(this.message);

  @override
  String toString() => message;
}
