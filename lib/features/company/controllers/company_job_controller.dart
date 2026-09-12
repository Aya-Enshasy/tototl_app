import '../screens/operations/company_applicant_list_item.dart';
import '../models/company_create_job_request.dart';
import '../models/company_job_application_model.dart';
import '../models/company_job_posting_model.dart';
import '../models/company_update_job_request.dart';
import '../services/company_job_service.dart';

class CompanyJobController {
  final CompanyJobService service;

  CompanyJobController(this.service);

  bool isCreating = false;
  bool isPublishing = false;
  bool isClosing = false;
  bool isCancelling = false;
  bool isLoadingJobs = false;
  bool isLoadingDetail = false;
  bool isLoadingApplicants = false;
  bool isLoadingCompanyApplicants = false;
  bool isLoadingApplicantPilotProfile = false;
  bool isLoadingApplicantCredentials = false;
  bool isLoadingApplicantDrones = false;
  bool isDownloadingApplicantDocument = false;
  bool isUpdating = false;
  bool isDeleting = false;
  bool isAcceptingApplicant = false;
  bool isRejectingApplicant = false;
  int? actingApplicationId;

  String? errorMessage;
  String? applicantsErrorMessage;
  String? companyApplicantsErrorMessage;
  String? applicantPilotProfileErrorMessage;
  String? applicantCredentialsErrorMessage;
  String? applicantDronesErrorMessage;
  String? applicantDocumentErrorMessage;

  List<CompanyJobPostingModel> jobs = const [];
  CompanyJobPostingModel? selectedJob;
  List<CompanyJobApplicationModel> applicants = const [];
  List<CompanyApplicantListItem> companyApplicants = const [];

  CompanyApplicantPilotModel? applicantPilotProfile;
  List<CompanyPilotCredentialModel> applicantCredentials = const [];
  List<CompanyApplicantDroneModel> applicantDrones = const [];
  CompanyApplicantDroneModel? committedApplicantDrone;

  Future<bool> loadMyJobs() async {
    if (isLoadingJobs) return false;

    isLoadingJobs = true;
    errorMessage = null;

    try {
      jobs = await service.getMyJobs();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoadingJobs = false;
    }
  }


  Future<bool> loadCompanyApplicants({
    String? status,
    int perPage = 50,
  }) async {
    if (isLoadingCompanyApplicants) return false;

    isLoadingCompanyApplicants = true;
    companyApplicantsErrorMessage = null;

    try {
      companyApplicants = await service.getCompanyApplicants(
        status: status,
        perPage: perPage,
      );
      return true;
    } catch (e) {
      companyApplicantsErrorMessage = e.toString();
      return false;
    } finally {
      isLoadingCompanyApplicants = false;
    }
  }

  Future<bool> loadJobDetails(int jobId) async {
    if (isLoadingDetail) return false;

    isLoadingDetail = true;
    errorMessage = null;

    try {
      selectedJob = await service.getJobDetails(jobId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoadingDetail = false;
    }
  }

  Future<bool> loadApplicants(int jobId) async {
    if (isLoadingApplicants) return false;

    isLoadingApplicants = true;
    applicantsErrorMessage = null;

    try {
      applicants = await service.getApplicants(jobId);
      return true;
    } catch (e) {
      applicants = const [];
      applicantsErrorMessage = e.toString();
      return false;
    } finally {
      isLoadingApplicants = false;
    }
  }


  Future<bool> loadApplicantPilotProfile(
      int pilotProfileId,
      ) async {
    if (isLoadingApplicantPilotProfile) return false;

    isLoadingApplicantPilotProfile = true;
    applicantPilotProfileErrorMessage = null;

    try {
      applicantPilotProfile =
      await service.getCompanyPilotProfile(pilotProfileId);
      return true;
    } catch (e) {
      applicantPilotProfileErrorMessage = e.toString();
      return false;
    } finally {
      isLoadingApplicantPilotProfile = false;
    }
  }

  Future<bool> loadApplicantCredentials(
      int pilotProfileId,
      ) async {
    if (isLoadingApplicantCredentials) return false;

    isLoadingApplicantCredentials = true;
    applicantCredentialsErrorMessage = null;

    try {
      applicantCredentials =
      await service.getCompanyPilotCredentials(pilotProfileId);
      return true;
    } catch (e) {
      applicantCredentialsErrorMessage = e.toString();
      return false;
    } finally {
      isLoadingApplicantCredentials = false;
    }
  }

  Future<bool> loadApplicantDrones({
    required int pilotProfileId,
    required int committedDroneId,
  }) async {
    if (isLoadingApplicantDrones) return false;

    isLoadingApplicantDrones = true;
    applicantDronesErrorMessage = null;

    try {
      final loaded =
      await service.getCompanyPilotDrones(pilotProfileId);
      applicantDrones = loaded;

      CompanyApplicantDroneModel? committed;
      for (final drone in loaded) {
        if (drone.id == committedDroneId) {
          committed = drone;
          break;
        }
      }

      committedApplicantDrone = committed;
      return true;
    } catch (e) {
      applicantDronesErrorMessage = e.toString();
      return false;
    } finally {
      isLoadingApplicantDrones = false;
    }
  }

  Future<String?> downloadApplicantDocument({
    required CompanyPilotMediaModel document,
  }) async {
    if (isDownloadingApplicantDocument) return null;

    isDownloadingApplicantDocument = true;
    applicantDocumentErrorMessage = null;

    try {
      return await service.downloadCompanyPilotDocument(
        mediaId: document.id,
        downloadUrl: document.bestDownloadUrl,
        fileName: document.fileName,
        mimeType: document.mimeType,
      );
    } catch (e) {
      applicantDocumentErrorMessage = e.toString();
      return null;
    } finally {
      isDownloadingApplicantDocument = false;
    }
  }

  Future<CompanyJobApplicationModel?> acceptApplicant({
    required int jobId,
    required CompanyJobApplicationModel application,
  }) async {
    if (isAcceptingApplicant || isRejectingApplicant) {
      return null;
    }

    isAcceptingApplicant = true;
    actingApplicationId = application.id;
    applicantsErrorMessage = null;

    try {
      final updated = await service.acceptApplicant(
        jobId: jobId,
        applicationId: application.id,
      );

      final enriched = updated.copyWith(
        pilotProfile: application.pilotProfile,
        drone: application.drone,
      );

      _replaceApplicant(enriched);

      return enriched;
    } catch (e) {
      applicantsErrorMessage = e.toString();
      return null;
    } finally {
      isAcceptingApplicant = false;
      actingApplicationId = null;
    }
  }

  Future<CompanyJobApplicationModel?> rejectApplicant({
    required int jobId,
    required CompanyJobApplicationModel application,
    String? reason,
  }) async {
    if (isAcceptingApplicant || isRejectingApplicant) {
      return null;
    }

    isRejectingApplicant = true;
    actingApplicationId = application.id;
    applicantsErrorMessage = null;

    try {
      final updated = await service.rejectApplicant(
        jobId: jobId,
        applicationId: application.id,
        reason: reason,
      );

      final enriched = updated.copyWith(
        pilotProfile: application.pilotProfile,
        drone: application.drone,
      );

      _replaceApplicant(enriched);

      return enriched;
    } catch (e) {
      applicantsErrorMessage = e.toString();
      return null;
    } finally {
      isRejectingApplicant = false;
      actingApplicationId = null;
    }
  }

  void _replaceApplicant(
      CompanyJobApplicationModel updated,
      ) {
    final mutable = List<CompanyJobApplicationModel>.from(
      applicants,
    );

    final index = mutable.indexWhere(
          (item) => item.id == updated.id,
    );

    if (index == -1) {
      mutable.insert(0, updated);
    } else {
      mutable[index] = updated;
    }

    applicants = mutable;
  }

  Future<CompanyJobPostingModel?> createJob(
      CompanyCreateJobRequest request,
      ) async {
    if (isCreating) return null;

    isCreating = true;
    errorMessage = null;

    try {
      return await service.createJob(request);
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isCreating = false;
    }
  }

  Future<CompanyJobPostingModel?> updateJob(
      int jobId,
      CompanyUpdateJobRequest request,
      ) async {
    if (isUpdating) return null;

    isUpdating = true;
    errorMessage = null;

    try {
      final updated = await service.updateJob(jobId, request);
      selectedJob = updated;
      return updated;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isUpdating = false;
    }
  }

  Future<bool> deleteJob(int jobId) async {
    if (isDeleting) return false;

    isDeleting = true;
    errorMessage = null;

    try {
      await service.deleteJob(jobId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isDeleting = false;
    }
  }

  Future<CompanyJobPostingModel?> publishJob(int jobId) async {
    if (isPublishing) return null;

    isPublishing = true;
    errorMessage = null;

    try {
      final published = await service.publishJob(jobId);
      selectedJob = published;
      return published;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isPublishing = false;
    }
  }


  Future<CompanyJobPostingModel?> closeJob(int jobId) async {
    if (isClosing || isCancelling) return null;

    isClosing = true;
    errorMessage = null;

    try {
      final closed = await service.closeJob(jobId);
      selectedJob = closed;
      return closed;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isClosing = false;
    }
  }

  Future<CompanyJobPostingModel?> cancelJob(
      int jobId, {
        String? reason,
      }) async {
    if (isCancelling || isClosing) return null;

    isCancelling = true;
    errorMessage = null;

    try {
      final cancelled = await service.cancelJob(
        jobId,
        reason: reason,
      );
      selectedJob = cancelled;
      return cancelled;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isCancelling = false;
    }
  }
}
