import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/token_storage.dart';

import '../../../core/storage/user_session_storage.dart';
import '../models/pilot_application_model.dart';

class PilotApplicationDetailsResult {
  final PilotApplicationModel application;
  final ApplicationCompanyChatTarget? companyChatTarget;
  final ApplicationPilotIdentity? pilotIdentity;

  const PilotApplicationDetailsResult({
    required this.application,
    this.companyChatTarget,
    this.pilotIdentity,
  });
}

class ApplicationPilotIdentity {
  final int id;
  final int? userId;
  final String name;
  final String photoUrl;
  final int? experienceYears;
  final String country;
  final String state;
  final String city;

  const ApplicationPilotIdentity({
    required this.id,
    this.userId,
    this.name = '',
    this.photoUrl = '',
    this.experienceYears,
    this.country = '',
    this.state = '',
    this.city = '',
  });

  String get displayName => name.trim().isEmpty ? 'Pilot #$id' : name.trim();

  String get locationLabel {
    final parts = <String>[];
    final seen = <String>{};

    void add(String value) {
      final clean = value.trim();
      if (clean.isEmpty) return;
      final key = clean.toLowerCase();
      if (seen.add(key)) parts.add(clean);
    }

    add(city);
    add(state);
    add(country);
    return parts.join(', ');
  }

  String get experienceLabel {
    final years = experienceYears;
    if (years == null) return '';
    if (years <= 0) return 'New pilot';
    if (years == 1) return '1 year experience';
    return '$years years experience';
  }
}

class ApplicationCompanyChatTarget {
  final int userId;
  final String name;
  final String photoUrl;

  const ApplicationCompanyChatTarget({
    required this.userId,
    required this.name,
    this.photoUrl = '',
  });
}

class PilotApplicationService {
  final ApiClient apiClient;

  PilotApplicationService(this.apiClient);

  static const String _applicationsPath = '/applications';
  static const String _cacheVersion = 'v2';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final Map<int, List<PilotApplicationModel>> _memoryLists =
  <int, List<PilotApplicationModel>>{};

  static final Map<int, Map<int, PilotApplicationModel>> _memoryDetails =
  <int, Map<int, PilotApplicationModel>>{};

  // ---------------------------------------------------------------------------
  // APPLY
  // ---------------------------------------------------------------------------

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

    try {
      final response = await apiClient.post(
        endpoint,
        data: payload,
        options: _jsonAuthOptions(token),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to submit your application.',
      );

      final rawApplication = _applicationMap(body['data']);
      final application = _parseApplication(
        body['data'],
        fallback: 'Submitted application data is missing.',
      );

      unawaited(
        _rememberNetworkApplication(
          application,
          rawApplication,
        ),
      );

      return application;
    } on DioException catch (e) {
      throw PilotApplicationException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to submit your application.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL CACHE - APPLICATION LIST
  // ---------------------------------------------------------------------------

  /// Returns null when no cache has ever been stored for this user.
  /// An empty list means a valid cached snapshot exists and contains no items.
  Future<List<PilotApplicationModel>?> getCachedApplications() async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return null;

    final memory = _memoryLists[userId];
    if (memory != null) {
      return List<PilotApplicationModel>.unmodifiable(memory);
    }

    final key = _listCacheKey(userId);

    try {
      final raw = await _storage.read(key: key);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await _storage.delete(key: key);
        return null;
      }

      final applications = decoded
          .whereType<Map>()
          .map(
            (item) => PilotApplicationModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      _sortNewestFirst(applications);
      _rememberList(userId, applications);

      return List<PilotApplicationModel>.unmodifiable(applications);
    } catch (_) {
      await _storage.delete(key: key);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL CACHE - ONE APPLICATION
  // ---------------------------------------------------------------------------

  Future<PilotApplicationModel?> getCachedApplication(
      int applicationId,
      ) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return null;

    final memoryDetail = _memoryDetails[userId]?[applicationId];
    if (memoryDetail != null) return memoryDetail;

    final memoryList = _memoryLists[userId];
    if (memoryList != null) {
      for (final item in memoryList) {
        if (item.id == applicationId) {
          _rememberDetail(userId, item);
          return item;
        }
      }
    }

    final key = _detailCacheKey(userId, applicationId);

    try {
      final raw = await _storage.read(key: key);

      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final application = PilotApplicationModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          _rememberDetail(userId, application);
          return application;
        }
      }
    } catch (_) {
      await _storage.delete(key: key);
    }

    final list = await getCachedApplications();
    if (list == null) return null;

    for (final item in list) {
      if (item.id == applicationId) {
        _rememberDetail(userId, item);
        return item;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // GET MY APPLICATIONS - NETWORK
  // ---------------------------------------------------------------------------

  Future<List<PilotApplicationModel>> getMyApplications() async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        _applicationsPath,
        options: _authOptions(token),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to load your applications.',
      );

      final applications = _parseApplicationList(body['data']);
      _sortNewestFirst(applications);

      final rawMaps = _extractApplicationMaps(body['data']);

      // Do not make the UI wait for disk I/O after the network response has
      // already succeeded. Cache work continues in the background.
      unawaited(
        _rememberNetworkList(
          applications,
          rawMaps,
        ),
      );

      return applications;
    } on DioException catch (e) {
      throw PilotApplicationException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load your applications.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET APPLICATION DETAIL - NETWORK
  // ---------------------------------------------------------------------------

  Future<PilotApplicationDetailsResult> getApplicationDetailsResult(
      int applicationId,
      ) async {
    final token = await _getToken();
    final endpoint = '$_applicationsPath/$applicationId';

    try {
      final response = await apiClient.get(
        endpoint,
        options: _authOptions(token),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to load this application.',
      );

      final rawApplication = _applicationMap(body['data']);
      final application = _parseApplication(
        body['data'],
        fallback: 'Application details are missing.',
      );

      final chatTarget = _extractCompanyChatTargetFromApplication(
        rawApplication,
      );
      final pilotIdentity = _extractPilotIdentity(rawApplication);

      unawaited(
        _rememberNetworkApplication(
          application,
          rawApplication,
        ),
      );

      return PilotApplicationDetailsResult(
        application: application,
        companyChatTarget: chatTarget,
        pilotIdentity: pilotIdentity,
      );
    } on DioException catch (e) {
      throw PilotApplicationException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load this application.',
        ),
      );
    }
  }

  Future<PilotApplicationModel> getApplicationDetails(
      int applicationId,
      ) async {
    final result = await getApplicationDetailsResult(applicationId);
    return result.application;
  }

  /// Tries the published-job response only when the accepted application
  /// response did not include a company user identity. We never use
  /// company_profile_id as a Firebase user id because those are different
  /// identifiers in the API model.
  Future<ApplicationCompanyChatTarget?> resolveCompanyChatTargetFromJob(
      int jobPostingId,
      ) async {
    if (jobPostingId <= 0) return null;

    final token = await _getToken();

    try {
      final response = await apiClient.get(
        '/jobs/$jobPostingId',
        options: _authOptions(token),
      );

      final body = _parseBody(response.data);
      if (body['success'] != true) return null;

      final raw = body['data'];
      if (raw is! Map) return null;

      return _extractCompanyChatTargetFromJob(
        Map<String, dynamic>.from(raw),
      );
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // WITHDRAW
  // ---------------------------------------------------------------------------

  Future<PilotApplicationModel> withdrawApplication(
      int applicationId,
      ) async {
    final token = await _getToken();
    final endpoint = '$_applicationsPath/$applicationId/withdraw';

    try {
      final response = await apiClient.post(
        endpoint,
        options: _authOptions(token),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to withdraw this application.',
      );

      final rawApplication = _applicationMap(body['data']);
      final application = _parseApplication(
        body['data'],
        fallback: 'Withdrawn application data is missing.',
      );

      unawaited(
        _rememberNetworkApplication(
          application,
          rawApplication,
        ),
      );

      return application;
    } on DioException catch (e) {
      throw PilotApplicationException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to withdraw this application.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CACHE HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _rememberNetworkList(
      List<PilotApplicationModel> applications,
      List<Map<String, dynamic>> rawMaps,
      ) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return;

    _rememberList(userId, applications);

    try {
      await _persistApplicationList(userId, rawMaps);
    } catch (_) {
      // Cache failure must never affect the real API flow.
    }
  }

  Future<void> _rememberNetworkApplication(
      PilotApplicationModel application,
      Map<String, dynamic>? rawApplication,
      ) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return;

    _rememberDetail(userId, application);
    _upsertMemoryList(userId, application);

    if (rawApplication == null) return;

    await Future.wait<void>([
      _storage.write(
        key: _detailCacheKey(userId, application.id),
        value: jsonEncode(rawApplication),
      ),
      _upsertPersistentListRaw(
        userId,
        rawApplication,
      ),
    ]);
  }

  void _rememberList(
      int userId,
      List<PilotApplicationModel> values,
      ) {
    final copy = List<PilotApplicationModel>.from(values);
    _sortNewestFirst(copy);
    _memoryLists[userId] = copy;

    final details = _memoryDetails.putIfAbsent(
      userId,
          () => <int, PilotApplicationModel>{},
    );

    for (final item in copy) {
      details[item.id] = item;
    }
  }

  void _rememberDetail(
      int userId,
      PilotApplicationModel application,
      ) {
    final details = _memoryDetails.putIfAbsent(
      userId,
          () => <int, PilotApplicationModel>{},
    );
    details[application.id] = application;
  }

  void _upsertMemoryList(
      int userId,
      PilotApplicationModel application,
      ) {
    final list = _memoryLists[userId];
    if (list == null) return;

    final index = list.indexWhere((item) => item.id == application.id);
    if (index == -1) {
      list.insert(0, application);
    } else {
      list[index] = application;
    }

    _sortNewestFirst(list);
  }

  Future<void> _persistApplicationList(
      int userId,
      List<Map<String, dynamic>> rawMaps,
      ) async {
    await _storage.write(
      key: _listCacheKey(userId),
      value: jsonEncode(rawMaps),
    );
  }

  Future<void> _upsertPersistentListRaw(
      int userId,
      Map<String, dynamic> rawApplication,
      ) async {
    final key = _listCacheKey(userId);

    try {
      final existingRaw = await _storage.read(key: key);
      final existing = <Map<String, dynamic>>[];

      if (existingRaw != null && existingRaw.trim().isNotEmpty) {
        final decoded = jsonDecode(existingRaw);
        if (decoded is List) {
          existing.addAll(
            decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item)),
          );
        }
      }

      final id = _asInt(rawApplication['id']);
      final index = id == null
          ? -1
          : existing.indexWhere(
            (item) => _asInt(item['id']) == id,
      );

      if (index == -1) {
        existing.insert(0, rawApplication);
      } else {
        existing[index] = rawApplication;
      }

      await _storage.write(
        key: key,
        value: jsonEncode(existing),
      );
    } catch (_) {
      // Cache failure must never affect the real API flow.
    }
  }

  String _listCacheKey(int userId) =>
      'pilot_${userId}_applications_$_cacheVersion';

  String _detailCacheKey(int userId, int applicationId) =>
      'pilot_${userId}_application_${applicationId}_$_cacheVersion';

  // ---------------------------------------------------------------------------
  // PARSING
  // ---------------------------------------------------------------------------

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
      return PilotApplicationModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }
    throw PilotApplicationException(fallback);
  }

  List<PilotApplicationModel> _parseApplicationList(dynamic raw) {
    return _extractApplicationMaps(raw)
        .map(PilotApplicationModel.fromJson)
        .toList();
  }

  List<Map<String, dynamic>> _extractApplicationMaps(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final nested = map['data'];

      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    if (raw == null) return <Map<String, dynamic>>[];

    throw const PilotApplicationException(
      'Application list data is invalid.',
    );
  }

  Map<String, dynamic>? _applicationMap(dynamic raw) {
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  ApplicationPilotIdentity? _extractPilotIdentity(
      Map<String, dynamic>? application,
      ) {
    if (application == null) return null;

    final pilot = _mapOf(application['pilot_profile']) ??
        _mapOf(application['pilotProfile']) ??
        _mapOf(application['pilot']);
    if (pilot == null) return null;

    final id = _asInt(pilot['id']) ?? _asInt(application['pilot_profile_id']);
    if (id == null || id <= 0) return null;

    final photoMedia = _mapOf(pilot['profile_photo']) ??
        _mapOf(pilot['photo']);

    return ApplicationPilotIdentity(
      id: id,
      userId: _asInt(pilot['user_id']),
      name: _firstNonEmpty([
        pilot['name'],
        pilot['full_name'],
        pilot['username'],
      ]),
      photoUrl: pilot['profile_photo'] is String
          ? pilot['profile_photo'].toString().trim()
          : _firstNonEmpty([
        pilot['profile_photo_url'],
        pilot['photo_url'],
        photoMedia?['original_url'],
        photoMedia?['url'],
      ]),
      experienceYears: _asInt(
        pilot['experience_years'] ?? pilot['years_experience'],
      ),
      country: _firstNonEmpty([
        pilot['current_country'],
        pilot['country'],
      ]),
      state: _firstNonEmpty([
        pilot['current_state'],
        pilot['state'],
      ]),
      city: _firstNonEmpty([
        pilot['current_city'],
        pilot['city'],
      ]),
    );
  }

  ApplicationCompanyChatTarget? _extractCompanyChatTargetFromApplication(
      Map<String, dynamic>? application,
      ) {
    if (application == null) return null;

    final directUserId = _asInt(application['company_user_id']);
    if (directUserId != null && directUserId > 0) {
      return ApplicationCompanyChatTarget(
        userId: directUserId,
        name: _firstNonEmpty([
          application['company_name'],
          application['company_label'],
          'Company',
        ]),
        photoUrl: _firstNonEmpty([
          application['company_photo_url'],
          application['company_logo_url'],
        ]),
      );
    }

    final directCompanyUser =
        _mapOf(application['company_user']) ?? _mapOf(application['companyUser']);
    final directCompanyUserId = _asInt(directCompanyUser?['id']);
    if (directCompanyUserId != null && directCompanyUserId > 0) {
      return ApplicationCompanyChatTarget(
        userId: directCompanyUserId,
        name: _firstNonEmpty([
          directCompanyUser?['name'],
          directCompanyUser?['username'],
          application['company_name'],
          'Company',
        ]),
        photoUrl: _firstNonEmpty([
          directCompanyUser?['profile_photo_url'],
          application['company_photo_url'],
        ]),
      );
    }

    for (final key in const [
      'company',
      'company_profile',
      'companyProfile',
    ]) {
      final candidate = _mapOf(application[key]);
      final target = _extractCompanyTarget(candidate);
      if (target != null) return target;
    }

    for (final key in const [
      'job',
      'job_posting',
      'jobPosting',
    ]) {
      final job = _mapOf(application[key]);
      final target = _extractCompanyChatTargetFromJob(job);
      if (target != null) return target;
    }

    return null;
  }

  ApplicationCompanyChatTarget? _extractCompanyChatTargetFromJob(
      Map<String, dynamic>? job,
      ) {
    if (job == null) return null;

    final directUserId = _asInt(job['company_user_id']);
    if (directUserId != null && directUserId > 0) {
      return ApplicationCompanyChatTarget(
        userId: directUserId,
        name: _firstNonEmpty([
          job['company_name'],
          job['company_label'],
          'Company',
        ]),
        photoUrl: _firstNonEmpty([
          job['company_photo_url'],
          job['company_logo_url'],
        ]),
      );
    }

    final directCompanyUser =
        _mapOf(job['company_user']) ?? _mapOf(job['companyUser']);
    final directCompanyUserId = _asInt(directCompanyUser?['id']);
    if (directCompanyUserId != null && directCompanyUserId > 0) {
      return ApplicationCompanyChatTarget(
        userId: directCompanyUserId,
        name: _firstNonEmpty([
          directCompanyUser?['name'],
          directCompanyUser?['username'],
          job['company_name'],
          'Company',
        ]),
        photoUrl: _firstNonEmpty([
          directCompanyUser?['profile_photo_url'],
          job['company_photo_url'],
        ]),
      );
    }

    for (final key in const [
      'company',
      'company_profile',
      'companyProfile',
    ]) {
      final target = _extractCompanyTarget(_mapOf(job[key]));
      if (target != null) return target;
    }

    return null;
  }

  ApplicationCompanyChatTarget? _extractCompanyTarget(
      Map<String, dynamic>? company,
      ) {
    if (company == null) return null;

    final user = _mapOf(company['user']);
    final userId = _asInt(company['user_id']) ?? _asInt(user?['id']);

    if (userId == null || userId <= 0) return null;

    final media = _mapOf(company['profile_photo']) ??
        _mapOf(company['logo']) ??
        _mapOf(company['photo']);

    return ApplicationCompanyChatTarget(
      userId: userId,
      name: _firstNonEmpty([
        company['company_name'],
        company['display_name'],
        company['name'],
        user?['name'],
        user?['username'],
        'Company',
      ]),
      photoUrl: _firstNonEmpty([
        company['profile_photo_url'],
        company['logo_url'],
        company['photo_url'],
        media?['original_url'],
        media?['url'],
        user?['profile_photo_url'],
      ]),
    );
  }

  Map<String, dynamic>? _mapOf(dynamic raw) {
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  String _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  void _sortNewestFirst(List<PilotApplicationModel> applications) {
    applications.sort((a, b) {
      final aDate =
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  // ---------------------------------------------------------------------------
  // RESPONSE / AUTH
  // ---------------------------------------------------------------------------

  void _ensureSuccess(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    if (body['success'] == true) return;
    throw PilotApplicationException(
      _messageFromBody(body, fallback: fallback),
    );
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const PilotApplicationException(
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

class PilotApplicationException implements Exception {
  final String message;

  const PilotApplicationException(this.message);

  @override
  String toString() => message;
}
