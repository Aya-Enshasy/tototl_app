import '../models/company_contract_model.dart';
import '../models/company_contract_location_model.dart';
import '../models/contract_submission_model.dart';
import '../services/company_contract_service.dart';

class CompanyContractController {
  final CompanyContractService service;
  CompanyContractController(this.service);

  bool isLoading = false;
  bool isLoadingDetail = false;
  bool isFunding = false;
  bool isCheckingExistingContract = false;
  bool isLoadingLocation = false;
  bool isSavingLocation = false;
  bool isLoadingSubmissions = false;
  bool isReviewingSubmission = false;
  bool isCancelling = false;
  bool isTerminating = false;
  String? errorMessage;
  String? actionErrorMessage;
  String? existingContractErrorMessage;
  String? locationErrorMessage;
  String? submissionErrorMessage;
  List<CompanyContractModel> contracts = const [];
  CompanyContractModel? selectedContract;
  CompanyContractModel? applicationContract;
  CompanyContractLocationModel? location;
  List<ContractSubmissionModel> submissions = const [];

  Future<bool> loadContracts({String? status}) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    try {
      contracts = await service.getContracts(status: status);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> loadContract(int id) async {
    if (isLoadingDetail) return false;
    isLoadingDetail = true;
    errorMessage = null;
    try {
      selectedContract = await service.getContract(id);
      _upsert(selectedContract!);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoadingDetail = false;
    }
  }


  /// Checks the server for an already-existing contract before Create Contract.
  ///
  /// It first matches the exact application. If the backend already has another
  /// non-terminal contract for the same job, that contract is returned as a
  /// fallback because the backend does not allow a second active contract.
  Future<CompanyContractModel?> loadExistingContract({
    required int applicationId,
    required int jobId,
  }) async {
    if (isCheckingExistingContract) return applicationContract;

    isCheckingExistingContract = true;
    existingContractErrorMessage = null;

    try {
      final contract = await service.findExistingContract(
        applicationId: applicationId,
        jobId: jobId,
      );
      applicationContract = contract;

      if (contract != null) {
        selectedContract = contract;
        _upsert(contract);
      }

      return contract;
    } catch (e) {
      existingContractErrorMessage = e.toString();
      return null;
    } finally {
      isCheckingExistingContract = false;
    }
  }

  void clearApplicationContract() {
    applicationContract = null;
    existingContractErrorMessage = null;
  }


  Future<CompanyContractLocationModel?> loadLocation(int contractId) async {
    if (isLoadingLocation) return location;
    isLoadingLocation = true;
    locationErrorMessage = null;
    try {
      location = await service.getContractLocation(contractId);
      return location;
    } catch (e) {
      locationErrorMessage = e.toString();
      return null;
    } finally {
      isLoadingLocation = false;
    }
  }

  Future<CompanyContractLocationModel?> saveLocation(
    int contractId,
    CompanyContractLocationRequest request,
  ) async {
    if (isSavingLocation) return null;
    isSavingLocation = true;
    locationErrorMessage = null;
    try {
      final saved = await service.saveContractLocation(contractId, request);
      location = saved;
      return saved;
    } catch (e) {
      locationErrorMessage = e.toString();
      return null;
    } finally {
      isSavingLocation = false;
    }
  }

  Future<List<ContractSubmissionModel>> loadSubmissions(int contractId) async {
    if (isLoadingSubmissions) return submissions;
    isLoadingSubmissions = true;
    submissionErrorMessage = null;
    try {
      submissions = await service.getSubmissions(contractId);
      return submissions;
    } catch (e) {
      submissionErrorMessage = e.toString();
      return submissions;
    } finally {
      isLoadingSubmissions = false;
    }
  }

  Future<CompanySubmissionReviewResult?> approveSubmission(
    int contractId,
    int submissionId, {
    String? reviewNotes,
  }) async {
    if (isReviewingSubmission || isFunding) return null;
    isReviewingSubmission = true;
    actionErrorMessage = null;
    try {
      final result = await service.approveSubmission(
        contractId,
        submissionId,
        reviewNotes: reviewNotes,
      );
      selectedContract = result.contract;
      _upsert(result.contract);
      _upsertSubmission(result.submission);
      return result;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isReviewingSubmission = false;
    }
  }

  Future<CompanySubmissionReviewResult?> requestRevision(
    int contractId,
    int submissionId, {
    required String reviewNotes,
  }) async {
    if (isReviewingSubmission || isFunding) return null;
    isReviewingSubmission = true;
    actionErrorMessage = null;
    try {
      final result = await service.requestRevision(
        contractId,
        submissionId,
        reviewNotes: reviewNotes,
      );
      selectedContract = result.contract;
      _upsert(result.contract);
      _upsertSubmission(result.submission);
      return result;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isReviewingSubmission = false;
    }
  }

  void _upsertSubmission(ContractSubmissionModel submission) {
    final list = List<ContractSubmissionModel>.from(submissions);
    final index = list.indexWhere((item) => item.id == submission.id);
    if (index == -1) {
      list.add(submission);
    } else {
      list[index] = submission;
    }
    submissions = List.unmodifiable(list);
  }


  Future<CompanyContractModel?> cancelContract(
    int contractId, {
    String? reason,
  }) async {
    if (isCancelling || isTerminating || isFunding || isReviewingSubmission) {
      return null;
    }
    isCancelling = true;
    actionErrorMessage = null;
    try {
      final updated = await service.cancelContract(
        contractId,
        reason: reason,
      );
      selectedContract = updated;
      _upsert(updated);
      return updated;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isCancelling = false;
    }
  }

  Future<CompanyContractModel?> terminateContract(
    int contractId, {
    required String reason,
  }) async {
    if (isTerminating || isCancelling || isFunding || isReviewingSubmission) {
      return null;
    }
    isTerminating = true;
    actionErrorMessage = null;
    try {
      final updated = await service.terminateContract(
        contractId,
        reason: reason,
      );
      selectedContract = updated;
      _upsert(updated);
      return updated;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isTerminating = false;
    }
  }

  Future<CompanyContractModel?> fundContract(int id) async {
    if (isFunding) return null;
    isFunding = true;
    actionErrorMessage = null;
    try {
      final updated = await service.fundContract(id);
      selectedContract = updated;
      _upsert(updated);
      return updated;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isFunding = false;
    }
  }

  void seed(CompanyContractModel contract) {
    selectedContract = contract;
    _upsert(contract);
  }

  void _upsert(CompanyContractModel contract) {
    final list = List<CompanyContractModel>.from(contracts);
    final index = list.indexWhere((item) => item.id == contract.id);
    if (index == -1) {
      list.insert(0, contract);
    } else {
      list[index] = contract;
    }
    contracts = List.unmodifiable(list);
  }
}
