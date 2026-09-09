import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/pilot_license_form_request.dart';
import '../models/pilot_license_model.dart';

class PilotLicenseService {
  PilotLicenseService(this.apiClient);

  final ApiClient apiClient;

  // ===========================================================================
  // GET /pilot-licenses
  // ===========================================================================

  Future<List<PilotLicenseModel>> getMyLicenses() async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.pilotLicenses,
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
        fallback: 'Unable to load your licenses.',
      );

      return _parseLicenseList(body['data']);
    } on DioException catch (e) {
      throw PilotLicenseException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load your licenses.',
        ),
      );
    }
  }

  // ===========================================================================
  // GET /pilot-licenses/{id}
  // ===========================================================================

  Future<PilotLicenseModel> getLicense(int id) async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.pilotLicense(id),
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
        fallback: 'Unable to load this license.',
      );

      return _parseSingleLicense(body['data']);
    } on DioException catch (e) {
      throw PilotLicenseException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load this license.',
        ),
      );
    }
  }

  // ===========================================================================
  // POST /pilot-licenses
  // multipart/form-data
  // ===========================================================================

  Future<void> createLicense(
      PilotLicenseFormRequest request,
      ) async {
    final token = await _getToken();

    final primaryPath =
        request.licenseDocumentPath?.trim() ?? '';

    if (primaryPath.isEmpty) {
      throw const PilotLicenseException(
        'License document is required.',
      );
    }

    try {
      final formData = await _buildFormData(
        request,
        requirePrimaryDocument: true,
      );

      final response = await apiClient.post(
        ApiEndpoints.pilotLicenses,
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
        fallback: 'Unable to add the license.',
      );
    } on DioException catch (e) {
      throw PilotLicenseException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to add the license.',
        ),
      );
    }
  }

  // ===========================================================================
  // PATCH /pilot-licenses/{id}
  // multipart/form-data
  // ===========================================================================

  Future<void> updateLicense(
      int id,
      PilotLicenseFormRequest request,
      ) async {
    final token = await _getToken();

    try {
      final formData = await _buildFormData(
        request,
        requirePrimaryDocument: false,
      );

      final response = await apiClient.patch(
        ApiEndpoints.pilotLicense(id),
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
        fallback: 'Unable to update the license.',
      );
    } on DioException catch (e) {
      throw PilotLicenseException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to update the license.',
        ),
      );
    }
  }

  // ===========================================================================
  // DELETE /pilot-licenses/{id}
  // ===========================================================================

  Future<void> deleteLicense(int id) async {
    final token = await _getToken();

    try {
      final response = await apiClient.delete(
        ApiEndpoints.pilotLicense(id),
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
        fallback: 'Unable to delete the license.',
      );
    } on DioException catch (e) {
      throw PilotLicenseException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to delete the license.',
        ),
      );
    }
  }

  // ===========================================================================
  // PRIVATE MEDIA DOWNLOAD
  // GET /media/{id}/download
  //
  // The backend protects this endpoint with Bearer auth. We therefore download
  // the bytes ourselves, save them to the device temp directory, then let the
  // UI open the local file with the native viewer.
  // ===========================================================================

  Future<String> downloadPrivateDocument({
    required int mediaId,
    required String downloadUrl,
    required String fileName,
    String mimeType = '',
  }) async {
    final token = await _getToken();

    final cleanUrl = downloadUrl.trim();
    final endpoint = cleanUrl.isNotEmpty
        ? cleanUrl
        : (mediaId > 0 ? '/media/$mediaId/download' : '');

    if (endpoint.isEmpty) {
      throw const PilotLicenseException(
        'Document download link is missing.',
      );
    }

    try {
      // Use a dedicated Dio request here because download_url is an absolute
      // URL returned by the API. The token is sent only in the Authorization
      // header; it is never appended to the URL.
      final response = await Dio().get<dynamic>(
        endpoint,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: {
            'Accept': '*/*',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final bytes = _asBytes(response.data);

      if (bytes.isEmpty) {
        throw const PilotLicenseException(
          'The downloaded document is empty.',
        );
      }

      final directory = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}tototl_private_media',
      );

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final resolvedName = _resolveFileName(
        fileName: fileName,
        mimeType: mimeType,
        mediaId: mediaId,
      );

      final localFile = File(
        '${directory.path}${Platform.pathSeparator}${mediaId > 0 ? '${mediaId}_' : ''}$resolvedName',
      );

      await localFile.writeAsBytes(
        bytes,
        flush: true,
      );

      return localFile.path;
    } on PilotLicenseException {
      rethrow;
    } on DioException catch (e) {
      throw PilotLicenseException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to open this document.',
        ),
      );
    } on FileSystemException {
      throw const PilotLicenseException(
        'Unable to prepare this document on the device.',
      );
    } catch (_) {
      throw const PilotLicenseException(
        'Unable to open this document.',
      );
    }
  }

  Uint8List _asBytes(dynamic raw) {
    if (raw is Uint8List) {
      return raw;
    }

    if (raw is List<int>) {
      return Uint8List.fromList(raw);
    }

    if (raw is List) {
      try {
        return Uint8List.fromList(
          raw.map((value) => value as int).toList(),
        );
      } catch (_) {
        return Uint8List(0);
      }
    }

    return Uint8List(0);
  }

  String _resolveFileName({
    required String fileName,
    required String mimeType,
    required int mediaId,
  }) {
    var name = fileName.trim();

    if (name.isEmpty) {
      name = mediaId > 0 ? 'document_$mediaId' : 'document';
    }

    name = name.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (!name.contains('.')) {
      final extension = _extensionFromMime(mimeType);
      if (extension.isNotEmpty) {
        name = '$name.$extension';
      }
    }

    return name;
  }

  String _extensionFromMime(String mimeType) {
    switch (mimeType.trim().toLowerCase()) {
      case 'application/pdf':
        return 'pdf';
      case 'image/png':
        return 'png';
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/webp':
        return 'webp';
      default:
        return '';
    }
  }

  // ===========================================================================
  // FORM DATA
  // ===========================================================================

  Future<FormData> _buildFormData(
      PilotLicenseFormRequest request, {
        required bool requirePrimaryDocument,
      }) async {
    final formData = FormData();

    for (final entry in request.toFields().entries) {
      formData.fields.add(
        MapEntry(
          entry.key,
          entry.value.toString(),
        ),
      );
    }

    final primaryPath =
        request.licenseDocumentPath?.trim() ?? '';

    if (primaryPath.isNotEmpty) {
      formData.files.add(
        MapEntry(
          'license_document',
          await _multipartFile(
            primaryPath,
            label: 'License document',
          ),
        ),
      );
    } else if (requirePrimaryDocument) {
      throw const PilotLicenseException(
        'License document is required.',
      );
    }

    final secondaryPath =
        request.permitOrInsuranceDocumentPath?.trim() ?? '';

    if (secondaryPath.isNotEmpty) {
      formData.files.add(
        MapEntry(
          'permit_or_insurance_document',
          await _multipartFile(
            secondaryPath,
            label: 'Permit or insurance document',
          ),
        ),
      );
    }

    return formData;
  }

  Future<MultipartFile> _multipartFile(
      String path, {
        required String label,
      }) async {
    final file = File(path);

    if (!await file.exists()) {
      throw PilotLicenseException(
        '$label could not be found.',
      );
    }

    final bytes = await file.length();
    const maxBytes = 10 * 1024 * 1024;

    if (bytes > maxBytes) {
      throw PilotLicenseException(
        '$label must be 10 MB or smaller.',
      );
    }

    final fileName = file.uri.pathSegments.isEmpty
        ? 'document'
        : file.uri.pathSegments.last;

    return MultipartFile.fromFile(
      path,
      filename: fileName,
    );
  }

  // ===========================================================================
  // RESPONSE PARSING
  // ===========================================================================

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) {
      throw const PilotLicenseException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(raw);
  }

  List<PilotLicenseModel> _parseLicenseList(dynamic raw) {
    final result = <PilotLicenseModel>[];

    void add(dynamic item) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);

        if (_looksLikeLicense(map)) {
          final license = PilotLicenseModel.fromJson(map);
          if (license.id > 0 ||
              license.licenseType.isNotEmpty ||
              license.licenseNumber.isNotEmpty) {
            result.add(license);
          }
          return;
        }

        final nestedData = map['data'];
        if (nestedData != null) {
          add(nestedData);
        }

        for (final value in map.values) {
          if (value is List || value is Map) {
            add(value);
          }
        }
      } else if (item is List) {
        for (final value in item) {
          add(value);
        }
      }
    }

    add(raw);

    final unique = <String, PilotLicenseModel>{};
    for (final license in result) {
      final key = license.id > 0
          ? 'id:${license.id}'
          : '${license.licenseType}|${license.licenseNumber}|${license.issuingAuthority}';
      unique[key] = license;
    }

    return unique.values.toList();
  }

  PilotLicenseModel _parseSingleLicense(dynamic raw) {
    final list = _parseLicenseList(raw);

    if (list.isNotEmpty) {
      return list.first;
    }

    throw const PilotLicenseException(
      'License data is missing.',
    );
  }

  bool _looksLikeLicense(Map<String, dynamic> map) {
    return map.containsKey('license_type') ||
        map.containsKey('licenseType') ||
        map.containsKey('license_number') ||
        map.containsKey('licenseNumber');
  }

  void _ensureSuccess(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    if (body['success'] == true) return;

    throw PilotLicenseException(
      _messageFromBody(
        body,
        fallback: fallback,
      ),
    );
  }

  // ===========================================================================
  // AUTH
  // ===========================================================================

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const PilotLicenseException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  // ===========================================================================
  // ERRORS
  // ===========================================================================

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

class PilotLicenseException implements Exception {
  const PilotLicenseException(this.message);

  final String message;

  @override
  String toString() => message;
}

