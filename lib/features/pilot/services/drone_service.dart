import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';

import '../models/drone_form_request.dart';
import '../models/drone_model.dart';

// ============================================================================
// DRONE SERVICE
// ============================================================================

class DroneService {
  final ApiClient apiClient;

  DroneService(
      this.apiClient,
      );

  // ==========================================================================
  // GET MY DRONES
  // GET /drones
  // ==========================================================================

  Future<List<DroneModel>>
  getMyDrones() async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.get(
        ApiEndpoints.drones,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body =
      _parseBody(response.data);

      _ensureSuccess(
        body,
        fallback:
        'Unable to load your drones.',
      );

      return _parseDroneList(
        body['data'],
      );
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load your drones.',
        ),
      );
    }
  }

  // ==========================================================================
  // GET DRONE
  // GET /drones/:id
  // ==========================================================================

  Future<DroneModel>
  getDrone(
      int droneId,
      ) async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.get(
        ApiEndpoints.drone(
          droneId,
        ),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body =
      _parseBody(response.data);

      _ensureSuccess(
        body,
        fallback:
        'Unable to load this drone.',
      );

      return _parseDrone(
        body['data'],
      );
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load this drone.',
        ),
      );
    }
  }

  // ==========================================================================
  // CREATE DRONE
  // POST /drones
  // multipart/form-data
  // ==========================================================================

  Future<DroneModel>
  createDrone(
      DroneFormRequest request,
      ) async {
    final token =
    await _getToken();

    try {
      final formData =
      await _buildFormData(
        request,
      );

      final response =
      await apiClient.post(
        ApiEndpoints.drones,
        data: formData,
        options: Options(
          contentType:
          Headers.multipartFormDataContentType,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body =
      _parseBody(response.data);

      _ensureSuccess(
        body,
        fallback:
        'Unable to add the drone.',
      );

      return _parseDrone(
        body['data'],
      );
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to add the drone.',
        ),
      );
    }
  }

  // ==========================================================================
  // UPDATE DRONE
  // PATCH /drones/:id
  // multipart/form-data
  // ==========================================================================

  Future<DroneModel>
  updateDrone(
      int droneId,
      DroneFormRequest request,
      ) async {
    final token =
    await _getToken();

    try {
      final formData =
      await _buildFormData(
        request,
      );

      final response =
      await apiClient.patch(
        ApiEndpoints.drone(
          droneId,
        ),
        data: formData,
        options: Options(
          contentType:
          Headers.multipartFormDataContentType,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body =
      _parseBody(response.data);

      _ensureSuccess(
        body,
        fallback:
        'Unable to update the drone.',
      );

      return _parseDrone(
        body['data'],
      );
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to update the drone.',
        ),
      );
    }
  }

  // ==========================================================================
  // DELETE DRONE
  // DELETE /drones/:id
  // ==========================================================================

  Future<void>
  deleteDrone(
      int droneId,
      ) async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.delete(
        ApiEndpoints.drone(
          droneId,
        ),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body =
      _parseBody(response.data);

      _ensureSuccess(
        body,
        fallback:
        'Unable to remove the drone.',
      );
    } on DioException catch (e) {
      throw DroneException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to remove the drone.',
        ),
      );
    }
  }

  // ==========================================================================
  // FORM DATA
  // ==========================================================================

  Future<FormData>
  _buildFormData(
      DroneFormRequest request,
      ) async {
    final formData =
    FormData();

    // ========================================================================
    // NORMAL FIELDS
    // ========================================================================

    final values =
    request.toFields();

    for (final entry
    in values.entries) {
      if (entry.value == null) {
        continue;
      }

      formData.fields.add(
        MapEntry(
          entry.key,
          entry.value.toString(),
        ),
      );
    }

    // ========================================================================
    // CAPABILITIES ARRAY
    //
    // IMPORTANT:
    // Do NOT send:
    // capabilities = "thermal,zoom,speaker"
    //
    // Laravel validation expects a real array.
    // These multipart keys become:
    // capabilities[0] = thermal
    // capabilities[1] = zoom
    // capabilities[2] = speaker
    // ========================================================================

    final cleanCapabilities =
    request.capabilities
        .map(
          (item) =>
          item.trim(),
    )
        .where(
          (item) =>
      item.isNotEmpty,
    )
        .toList();

    for (var i = 0;
    i < cleanCapabilities.length;
    i++) {
      formData.fields.add(
        MapEntry(
          'capabilities[$i]',
          cleanCapabilities[i],
        ),
      );
    }

    // ========================================================================
    // IMAGE
    // ========================================================================

    final imagePath =
        request.imagePath?.trim() ?? '';

    if (imagePath.isNotEmpty) {
      final imageFile =
      File(
        imagePath,
      );

      if (!await imageFile.exists()) {
        throw const DroneException(
          'Selected drone image could not be found.',
        );
      }

      final size =
      await imageFile.length();

      const maxBytes =
          10 * 1024 * 1024;

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
            filename:
            imageFile.uri.pathSegments.isEmpty
                ? 'drone.jpg'
                : imageFile.uri.pathSegments.last,
          ),
        ),
      );
    }

    return formData;
  }

  // ==========================================================================
  // PARSE
  // ==========================================================================

  Map<String, dynamic>
  _parseBody(
      dynamic raw,
      ) {
    if (raw is! Map) {
      throw const DroneException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(
      raw,
    );
  }

  List<DroneModel>
  _parseDroneList(
      dynamic raw,
      ) {
    if (raw == null) {
      return <DroneModel>[];
    }

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (item) => DroneModel.fromJson(
          Map<String, dynamic>.from(
            item,
          ),
        ),
      )
          .toList();
    }

    // Defensive support for generated API docs that may
    // describe data as an object containing list values.
    if (raw is Map) {
      final result =
      <DroneModel>[];

      for (final value in raw.values) {
        if (value is Map) {
          result.add(
            DroneModel.fromJson(
              Map<String, dynamic>.from(
                value,
              ),
            ),
          );
        } else if (value is List) {
          for (final item in value) {
            if (item is Map) {
              result.add(
                DroneModel.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              );
            }
          }
        }
      }

      return result;
    }

    throw const DroneException(
      'Drone list data is invalid.',
    );
  }

  DroneModel
  _parseDrone(
      dynamic raw,
      ) {
    if (raw is Map) {
      return DroneModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    }

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          return DroneModel.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }
    }

    throw const DroneException(
      'Drone data is missing.',
    );
  }

  void _ensureSuccess(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    if (body['success'] == true) {
      return;
    }

    throw DroneException(
      _messageFromBody(
        body,
        fallback: fallback,
      ),
    );
  }

  // ==========================================================================
  // TOKEN
  // ==========================================================================

  Future<String>
  _getToken() async {
    final token =
    await TokenStorage
        .getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw const DroneException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  // ==========================================================================
  // ERRORS
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
        fallback:
        fallback,
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

// ============================================================================
// EXCEPTION
// ============================================================================

class DroneException
    implements Exception {
  final String message;

  const DroneException(
      this.message,
      );

  @override
  String toString() =>
      message;
}