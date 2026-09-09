import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
 import '../../../core/storage/user_session_storage.dart';
import '../models/drone_form_request.dart';
import '../models/drone_model.dart';

class DroneService {
  final ApiClient apiClient;

  DroneService(this.apiClient);

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _cacheVersion = 'v2';

  static final Map<int, List<DroneModel>> _memoryDrones =
  <int, List<DroneModel>>{};

  // ---------------------------------------------------------------------------
  // LOCAL CACHE
  // ---------------------------------------------------------------------------

  /// Returns null when no snapshot has been cached yet.
  /// An empty list means a valid cached snapshot exists with zero drones.
  Future<List<DroneModel>?> getCachedDrones() async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return null;

    final memory = _memoryDrones[userId];
    if (memory != null) {
      return List<DroneModel>.unmodifiable(memory);
    }

    final key = _cacheKey(userId);

    try {
      final raw = await _storage.read(key: key);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await _storage.delete(key: key);
        return null;
      }

      final drones = decoded
          .whereType<Map>()
          .map(
            (item) => DroneModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      _memoryDrones[userId] = List<DroneModel>.from(drones);
      return List<DroneModel>.unmodifiable(drones);
    } catch (_) {
      await _storage.delete(key: key);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // GET MY DRONES
  // ---------------------------------------------------------------------------

  Future<List<DroneModel>> getMyDrones() async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.drones,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to load your drones.',
      );

      final drones = _parseDroneList(body['data']);

      // Return fresh data immediately; persist the snapshot in the background.
      unawaited(_rememberList(drones));
      return drones;
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load your drones.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET ONE DRONE
  // ---------------------------------------------------------------------------

  Future<DroneModel> getDrone(int droneId) async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.drone(droneId),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to load this drone.',
      );

      final drone = _parseDrone(body['data']);
      unawaited(_rememberDrone(drone));
      return drone;
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load this drone.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  Future<DroneModel> createDrone(
      DroneFormRequest request,
      ) async {
    final token = await _getToken();

    try {
      final formData = await _buildFormData(request);

      final response = await apiClient.post(
        ApiEndpoints.drones,
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to add the drone.',
      );

      final drone = _parseDrone(body['data']);
      unawaited(_rememberDrone(drone));
      return drone;
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to add the drone.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  Future<DroneModel> updateDrone(
      int droneId,
      DroneFormRequest request,
      ) async {
    final token = await _getToken();

    try {
      final formData = await _buildFormData(request);

      final response = await apiClient.patch(
        ApiEndpoints.drone(droneId),
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to update the drone.',
      );

      final drone = _parseDrone(body['data']);
      unawaited(_rememberDrone(drone));
      return drone;
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to update the drone.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> deleteDrone(int droneId) async {
    final token = await _getToken();

    try {
      final response = await apiClient.delete(
        ApiEndpoints.drone(droneId),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(response.data);
      _ensureSuccess(
        body,
        fallback: 'Unable to remove the drone.',
      );

      unawaited(_forgetDrone(droneId));
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to remove the drone.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CACHE WRITE HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _rememberList(List<DroneModel> drones) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return;

    final copy = List<DroneModel>.from(drones);
    _memoryDrones[userId] = copy;

    unawaited(
      _storage.write(
        key: _cacheKey(userId),
        value: jsonEncode(
          copy.map((item) => item.toJson()).toList(),
        ),
      ),
    );
  }

  Future<void> _rememberDrone(DroneModel drone) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return;

    var list = _memoryDrones[userId];

    if (list == null) {
      final cached = await getCachedDrones();
      list = cached == null
          ? <DroneModel>[]
          : List<DroneModel>.from(cached);
      _memoryDrones[userId] = list;
    }

    final index = list.indexWhere((item) => item.id == drone.id);
    if (index == -1) {
      list.insert(0, drone);
    } else {
      list[index] = drone;
    }

    await _persistMemory(userId);
  }

  Future<void> _forgetDrone(int droneId) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return;

    var list = _memoryDrones[userId];

    if (list == null) {
      final cached = await getCachedDrones();
      if (cached == null) return;
      list = List<DroneModel>.from(cached);
      _memoryDrones[userId] = list;
    }

    list.removeWhere((item) => item.id == droneId);
    await _persistMemory(userId);
  }

  Future<void> _persistMemory(int userId) async {
    final list = _memoryDrones[userId];
    if (list == null) return;

    try {
      await _storage.write(
        key: _cacheKey(userId),
        value: jsonEncode(
          list.map((item) => item.toJson()).toList(),
        ),
      );
    } catch (_) {
      // Cache failure must never affect the actual API flow.
    }
  }

  String _cacheKey(int userId) =>
      'pilot_${userId}_drones_$_cacheVersion';

  // ---------------------------------------------------------------------------
  // FORM DATA
  // ---------------------------------------------------------------------------

  Future<FormData> _buildFormData(
      DroneFormRequest request,
      ) async {
    final formData = FormData();

    final values = request.toFields();

    for (final entry in values.entries) {
      if (entry.value == null) continue;

      formData.fields.add(
        MapEntry(
          entry.key,
          entry.value.toString(),
        ),
      );
    }

    // Laravel expects a real multipart array, not a comma-separated string.
    final cleanCapabilities = request.capabilities
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    for (var i = 0; i < cleanCapabilities.length; i++) {
      formData.fields.add(
        MapEntry(
          'capabilities[$i]',
          cleanCapabilities[i],
        ),
      );
    }

    final imagePath = request.imagePath?.trim() ?? '';

    if (imagePath.isNotEmpty) {
      final imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        throw const DroneException(
          'Selected drone image could not be found.',
        );
      }

      final size = await imageFile.length();
      const maxBytes = 10 * 1024 * 1024;

      if (size > maxBytes) {
        throw const DroneException(
          'Drone image must be 10 MB or smaller.',
        );
      }

      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imagePath,
            filename: imageFile.uri.pathSegments.isEmpty
                ? 'drone.jpg'
                : imageFile.uri.pathSegments.last,
          ),
        ),
      );
    }

    return formData;
  }

  // ---------------------------------------------------------------------------
  // PARSE
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) {
      throw const DroneException('Invalid server response.');
    }

    return Map<String, dynamic>.from(raw);
  }

  List<DroneModel> _parseDroneList(dynamic raw) {
    if (raw == null) return <DroneModel>[];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (item) => DroneModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();
    }

    // Defensive support for generated API responses that wrap lists in maps.
    if (raw is Map) {
      final result = <DroneModel>[];

      for (final value in raw.values) {
        if (value is Map) {
          result.add(
            DroneModel.fromJson(
              Map<String, dynamic>.from(value),
            ),
          );
        } else if (value is List) {
          for (final item in value) {
            if (item is Map) {
              result.add(
                DroneModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              );
            }
          }
        }
      }

      return result;
    }

    throw const DroneException('Drone list data is invalid.');
  }

  DroneModel _parseDrone(dynamic raw) {
    if (raw is Map) {
      return DroneModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          return DroneModel.fromJson(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    throw const DroneException('Drone data is missing.');
  }

  // ---------------------------------------------------------------------------
  // AUTH / ERRORS
  // ---------------------------------------------------------------------------

  void _ensureSuccess(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    if (body['success'] == true) return;

    throw DroneException(
      _messageFromBody(
        body,
        fallback: fallback,
      ),
    );
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const DroneException(
        'Authentication token not found.',
      );
    }

    return token.trim();
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

class DroneException implements Exception {
  final String message;

  const DroneException(this.message);

  @override
  String toString() => message;
}
