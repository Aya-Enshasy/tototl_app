import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/company_document_model.dart';

class CompanyDocumentService {
  CompanyDocumentService(this.apiClient);

  final ApiClient apiClient;

  static const int maxFileBytes = 10 * 1024 * 1024;

  Future<CompanyDocumentModel> uploadCompanyDocument({
    required String filePath,
  }) async {
    final token = await _getToken();
    final file = File(filePath);

    if (!await file.exists()) {
      throw const CompanyDocumentException(
        'Selected company document was not found.',
      );
    }

    final bytes = await file.length();
    if (bytes > maxFileBytes) {
      throw const CompanyDocumentException(
        'Company document must be 10 MB or smaller.',
      );
    }

    final fileName = file.uri.pathSegments.isEmpty
        ? 'company_document'
        : file.uri.pathSegments.last;

    try {
      final response = await apiClient.post(
        ApiEndpoints.profileDocuments,
        data: FormData.fromMap({
          'collection': 'company_documents',
          'file': await MultipartFile.fromFile(
            filePath,
            filename: fileName,
          ),
        }),
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
        fallback: 'Unable to upload company document.',
      );

      final rawData = body['data'];
      if (rawData is! Map) {
        throw const CompanyDocumentException(
          'Uploaded document data is missing.',
        );
      }

      final document = CompanyDocumentModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );

      if (document.id <= 0) {
        throw const CompanyDocumentException(
          'Uploaded document ID is missing.',
        );
      }

      return document;
    } on DioException catch (e) {
      throw CompanyDocumentException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to upload company document.',
        ),
      );
    }
  }

  Future<void> deleteCompanyDocument(int mediaId) async {
    if (mediaId <= 0) {
      throw const CompanyDocumentException(
        'Company document ID is invalid.',
      );
    }

    final token = await _getToken();

    try {
      final response = await apiClient.delete(
        '${ApiEndpoints.profileDocuments}/$mediaId',
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
        fallback: 'Unable to delete company document.',
      );
    } on DioException catch (e) {
      throw CompanyDocumentException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to delete company document.',
        ),
      );
    }
  }

  Future<String> downloadPrivateDocument({
    required int mediaId,
    required String downloadUrl,
    required String fileName,
    String mimeType = '',
  }) async {
    if (mediaId <= 0 && downloadUrl.trim().isEmpty) {
      throw const CompanyDocumentException(
        'Document download link is missing.',
      );
    }

    final token = await _getToken();
    final cleanUrl = downloadUrl.trim();
    final endpoint = cleanUrl.isNotEmpty
        ? cleanUrl
        : '${ApiEndpoints.baseUrl}/media/$mediaId/download';

    try {
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
        throw const CompanyDocumentException(
          'The downloaded document is empty.',
        );
      }

      final directory = Directory(
        '${Directory.systemTemp.path}'
            '${Platform.pathSeparator}tototl_company_documents',
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
        '${directory.path}${Platform.pathSeparator}'
            '${mediaId > 0 ? '${mediaId}_' : ''}$resolvedName',
      );

      await localFile.writeAsBytes(
        bytes,
        flush: true,
      );

      return localFile.path;
    } on CompanyDocumentException {
      rethrow;
    } on DioException catch (e) {
      throw CompanyDocumentException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to open this company document.',
        ),
      );
    } on FileSystemException {
      throw const CompanyDocumentException(
        'Unable to prepare this document on the device.',
      );
    } catch (_) {
      throw const CompanyDocumentException(
        'Unable to open this company document.',
      );
    }
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const CompanyDocumentException(
        'Authentication token not found.',
      );
    }
    return token.trim();
  }

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) {
      throw const CompanyDocumentException(
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
    throw CompanyDocumentException(
      _messageFromBody(body, fallback: fallback),
    );
  }

  String _messageFromBody(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    final message = body['message']?.toString().trim() ?? '';
    if (message.isNotEmpty) return message;

    final errors = body['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }

    return fallback;
  }

  String _dioErrorMessage(
      DioException e, {
        required String fallback,
      }) {
    final data = e.response?.data;

    if (data is Map) {
      final body = Map<String, dynamic>.from(data);
      return _messageFromBody(body, fallback: fallback);
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Unable to connect to the server. Please try again.';
    }

    return fallback;
  }

  Uint8List _asBytes(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);

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
      name = mediaId > 0 ? 'company_document_$mediaId' : 'company_document';
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
}

class CompanyDocumentException implements Exception {
  const CompanyDocumentException(this.message);

  final String message;

  @override
  String toString() => message;
}
