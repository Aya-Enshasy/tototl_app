import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

/// Phase 4+ legal-identity API. API responses, not locally cached profile
/// verification badges, determine contract signing eligibility.
class LegalIdentityService {
  LegalIdentityService(this.api);
  final ApiClient api;

  Future<Options> _auth({bool multipart = false}) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Please sign in again to continue.');
    }
    return Options(
      contentType: multipart ? Headers.multipartFormDataContentType : Headers.jsonContentType,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${token.trim()}'},
    );
  }

  Map<String, dynamic> _unwrap(dynamic response) {
    if (response is! Map) throw const FormatException('Invalid server response.');
    final body = Map<String, dynamic>.from(response);
    if (body['success'] == false) {
      throw StateError(body['message']?.toString() ?? 'The request was rejected.');
    }
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Missing response data.');
  }

  Future<Map<String, dynamic>> getMine() async {
    final r = await api.get(ApiEndpoints.legalIdentity, options: await _auth());
    return _unwrap(r.data);
  }

  Future<Map<String, dynamic>> submit({
    required String legalName,
    required String entityKind,
    required String country,
    required String registrationScheme,
    required String registrationValue,
    String? legalForm,
    String? registeredAddress,
    List<PlatformFile> documents = const [],
  }) async {
    final code = country.trim().toUpperCase();
    if (legalName.trim().isEmpty || code.length != 2 ||
        registrationScheme.trim().isEmpty || registrationValue.trim().isEmpty) {
      throw ArgumentError('Please complete the legal identity and registration fields.');
    }
    if (documents.length > 5 || documents.any((file) => file.size > 10 * 1024 * 1024)) {
      throw ArgumentError('Attach at most five documents, each up to 10 MB.');
    }
    final fields = <String, dynamic>{
      'legal_name': legalName.trim(),
      'entity_kind': entityKind,
      'country': code,
      'registrations[0][scheme]': registrationScheme,
      'registrations[0][value]': registrationValue.trim(),
      if (legalForm?.trim().isNotEmpty == true) 'legal_form': legalForm!.trim(),
      if (registeredAddress?.trim().isNotEmpty == true)
        'registered_address': registeredAddress!.trim(),
    };
    for (var i = 0; i < documents.length; i++) {
      final f = documents[i];
      if (f.bytes != null) {
        fields['documents[$i]'] = MultipartFile.fromBytes(f.bytes!, filename: f.name);
      } else if (f.path != null) {
        fields['documents[$i]'] = await MultipartFile.fromFile(f.path!, filename: f.name);
      } else {
        throw ArgumentError('Cannot access ${f.name}. Please select it again.');
      }
    }
    final r = await api.post(ApiEndpoints.legalIdentity,
        data: FormData.fromMap(fields), options: await _auth(multipart: true));
    return _unwrap(r.data);
  }

  Future<List<Map<String, dynamic>>> pending() async {
    final r = await api.get(ApiEndpoints.adminPendingLegalIdentities,
        queryParameters: {'per_page': 50}, options: await _auth());
    final data = _unwrap(r.data);
    final raw = data['data'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getAdminIdentity(int id) async {
    final r = await api.get(ApiEndpoints.adminLegalIdentity(id), options: await _auth());
    return _unwrap(r.data);
  }

  Future<Map<String, dynamic>> verify(int id) async {
    final r = await api.post(ApiEndpoints.verifyAdminLegalIdentity(id), options: await _auth());
    return _unwrap(r.data);
  }

  Future<Map<String, dynamic>> reject(int id, String reason) async {
    if (reason.trim().length < 10 || reason.trim().length > 1000) {
      throw ArgumentError('The rejection reason must be 10–1000 characters.');
    }
    final r = await api.post(ApiEndpoints.rejectAdminLegalIdentity(id),
        data: {'reason': reason.trim()}, options: await _auth());
    return _unwrap(r.data);
  }
}
