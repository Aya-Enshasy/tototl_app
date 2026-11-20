import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/user_session_storage.dart';

import '../models/pilot_license_form_request.dart';
import '../models/pilot_license_model.dart';
import '../services/pilot_license_service.dart';

class PilotLicenseController extends ChangeNotifier {
  PilotLicenseController(this.service);

  final PilotLicenseService service;
  static const FlutterSecureStorage _cache = FlutterSecureStorage();
  static const String _cachePrefix = 'tototl_pilot_licenses_v1_';
  static final Map<int, List<PilotLicenseModel>> _memoryByUser = {};
  static final Map<int, DateTime> _refreshedAtByUser = {};
  bool _disposed = false;
  int? _loadedForUserId;

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _restoreFromCache(int userId) async {
    final inMemory = _memoryByUser[userId];
    if (inMemory != null) {
      licenses = List<PilotLicenseModel>.of(inMemory);
      _notifyIfActive();
      return;
    }
    try {
      final raw = await _cache.read(key: '$_cachePrefix$userId');
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = decoded.whereType<Map>().map((item) =>
          PilotLicenseModel.fromJson(Map<String, dynamic>.from(item))).toList();
      _memoryByUser[userId] = loaded;
      licenses = List<PilotLicenseModel>.of(loaded);
      _notifyIfActive();
    } catch (_) { /* Corrupt or unavailable local snapshot: network still works. */ }
  }

  Future<void> _saveToCache(int userId) async {
    final snapshot = List<PilotLicenseModel>.of(licenses);
    _memoryByUser[userId] = snapshot;
    _refreshedAtByUser[userId] = DateTime.now();
    try {
      await _cache.write(key: '$_cachePrefix$userId',
          value: jsonEncode(snapshot.map((item) => item.toJson()).toList()));
    } catch (_) { /* Do not fail a successful network read because of storage. */ }
  }

  List<PilotLicenseModel> licenses = <PilotLicenseModel>[];

  bool isLoading = false;
  bool isSaving = false;
  bool isDeleting = false;
  bool isOpeningDocument = false;

  String? openingDocumentKey;
  String? errorMessage;

  Future<void> loadLicenses({bool force = false}) async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    _notifyIfActive();
    try {
      final userId = await UserSessionStorage.getUserId();
      if (_loadedForUserId != userId) {
        // Never keep a previous signed-in user's credentials visible.
        licenses = <PilotLicenseModel>[];
        _loadedForUserId = userId;
        _notifyIfActive();
      }
      if (userId != null) {
        if (licenses.isEmpty) await _restoreFromCache(userId);
        final last = _refreshedAtByUser[userId];
        // Reopening Profile and View All does not need another GET immediately.
        if (!force && last != null &&
            DateTime.now().difference(last) < const Duration(minutes: 2)) {
          return;
        }
      }
      licenses = await service.getMyLicenses();
      if (userId != null) await _saveToCache(userId);
    } catch (e) {
      if (licenses.isEmpty) {
        errorMessage = e.toString();
      } else if (kDebugMode) {
        debugPrint('[TOTOTL][LICENSES][STALE_SNAPSHOT] '
            'Showing the last verified list while refresh failed. '
            'errorType=${e.runtimeType}');
      }
    } finally {
      isLoading = false;
      _notifyIfActive();
    }
  }

  Future<PilotLicenseModel?> loadLicense(int id) async {
    errorMessage = null;

    try {
      return await service.getLicense(id);
    } catch (e) {
      errorMessage = e.toString();
      _notifyIfActive();
      return null;
    }
  }

  Future<bool> createLicense(
      PilotLicenseFormRequest request,
      ) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;
    _notifyIfActive();

    try {
      await service.createLicense(request);
      await _reloadAfterMutation();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      _notifyIfActive();
    }
  }

  Future<bool> updateLicense(
      int id,
      PilotLicenseFormRequest request,
      ) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;
    _notifyIfActive();

    try {
      await service.updateLicense(id, request);
      await _reloadAfterMutation();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      _notifyIfActive();
    }
  }

  Future<bool> deleteLicense(int id) async {
    if (isDeleting) return false;

    isDeleting = true;
    errorMessage = null;
    _notifyIfActive();

    try {
      await service.deleteLicense(id);
      licenses.removeWhere((item) => item.id == id);
      final userId = await UserSessionStorage.getUserId();
      if (userId != null) await _saveToCache(userId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isDeleting = false;
      _notifyIfActive();
    }
  }

  // ==========================================================================
  // PRIVATE DOCUMENT
  // ==========================================================================

  Future<String?> downloadDocument({
    required String documentKey,
    required int mediaId,
    required String downloadUrl,
    required String fileName,
    String mimeType = '',
  }) async {
    if (isOpeningDocument) return null;

    isOpeningDocument = true;
    openingDocumentKey = documentKey;
    errorMessage = null;
    _notifyIfActive();

    try {
      return await service.downloadPrivateDocument(
        mediaId: mediaId,
        downloadUrl: downloadUrl,
        fileName: fileName,
        mimeType: mimeType,
      );
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isOpeningDocument = false;
      openingDocumentKey = null;
      _notifyIfActive();
    }
  }

  Future<void> _reloadAfterMutation() async {
    try {
      licenses = await service.getMyLicenses();
      final userId = await UserSessionStorage.getUserId();
      if (userId != null) await _saveToCache(userId);
    } catch (_) {
      // The write was successful; keep the old snapshot until next refresh.
      final userId = await UserSessionStorage.getUserId();
      if (userId != null) _refreshedAtByUser.remove(userId);
    }
  }
}
