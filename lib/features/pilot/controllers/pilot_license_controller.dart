import 'package:flutter/foundation.dart';

import '../models/pilot_license_form_request.dart';
import '../models/pilot_license_model.dart';
import '../services/pilot_license_service.dart';

class PilotLicenseController extends ChangeNotifier {
  PilotLicenseController(this.service);

  final PilotLicenseService service;

  List<PilotLicenseModel> licenses = <PilotLicenseModel>[];

  bool isLoading = false;
  bool isSaving = false;
  bool isDeleting = false;
  bool isOpeningDocument = false;

  String? openingDocumentKey;
  String? errorMessage;

  Future<void> loadLicenses() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      licenses = await service.getMyLicenses();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<PilotLicenseModel?> loadLicense(int id) async {
    errorMessage = null;

    try {
      return await service.getLicense(id);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createLicense(
      PilotLicenseFormRequest request,
      ) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await service.createLicense(request);
      await _reloadAfterMutation();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateLicense(
      int id,
      PilotLicenseFormRequest request,
      ) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await service.updateLicense(id, request);
      await _reloadAfterMutation();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLicense(int id) async {
    if (isDeleting) return false;

    isDeleting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await service.deleteLicense(id);
      licenses.removeWhere((item) => item.id == id);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
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
    notifyListeners();

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
      notifyListeners();
    }
  }

  Future<void> _reloadAfterMutation() async {
    try {
      licenses = await service.getMyLicenses();
    } catch (_) {
      // Mutation succeeded. A later screen refresh can re-fetch the list.
    }
  }
}
