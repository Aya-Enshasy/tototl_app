import '../../company/models/contract_submission_model.dart';
import '../models/pilot_contract_model.dart';
import '../models/pilot_contract_location_model.dart';
import '../services/pilot_contract_service.dart';

class PilotContractController {
  final PilotContractService service;

  PilotContractController(this.service);

  bool isLoadingList = false;
  bool isLoadingDetail = false;
  bool isAccepting = false;
  bool isRejecting = false;
  bool isLoadingLocation = false;
  bool isStartingWork = false;
  bool isLoadingSubmissions = false;
  bool isSubmittingWork = false;

  String? listErrorMessage;
  String? detailErrorMessage;
  String? actionErrorMessage;
  String? locationErrorMessage;
  String? submissionErrorMessage;

  List<PilotContractModel> contracts = const [];
  PilotContractModel? selectedContract;
  PilotContractLocationModel? location;
  List<ContractSubmissionModel> submissions = const [];

  Future<bool> loadContracts({
    String? status,
  }) async {
    if (isLoadingList) return false;

    isLoadingList = true;
    listErrorMessage = null;

    try {
      contracts = await service.getContracts(status: status);
      return true;
    } catch (e) {
      listErrorMessage = e.toString();
      return false;
    } finally {
      isLoadingList = false;
    }
  }

  Future<PilotContractModel?> loadContract(
    int contractId,
  ) async {
    if (isLoadingDetail) return null;

    isLoadingDetail = true;
    detailErrorMessage = null;

    try {
      selectedContract = await service.getContract(contractId);
      _replaceContract(selectedContract!);
      return selectedContract;
    } catch (e) {
      detailErrorMessage = e.toString();
      return null;
    } finally {
      isLoadingDetail = false;
    }
  }


  Future<PilotContractLocationModel?> loadLocation(int contractId) async {
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

  Future<PilotContractModel?> startWork(int contractId) async {
    if (isStartingWork || isAccepting || isRejecting) return null;
    isStartingWork = true;
    actionErrorMessage = null;
    try {
      final updated = await service.startWork(contractId);
      selectedContract = updated;
      _replaceContract(updated);
      return updated;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isStartingWork = false;
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

  Future<PilotSubmitWorkResult?> submitWork(
    int contractId, {
    String? notes,
    List<String> filePaths = const [],
  }) async {
    if (isSubmittingWork || isStartingWork || isAccepting || isRejecting) {
      return null;
    }
    isSubmittingWork = true;
    actionErrorMessage = null;
    try {
      final result = await service.submitWork(
        contractId,
        notes: notes,
        filePaths: filePaths,
      );
      selectedContract = result.contract;
      _replaceContract(result.contract);
      final list = List<ContractSubmissionModel>.from(submissions);
      final index = list.indexWhere((item) => item.id == result.submission.id);
      if (index == -1) {
        list.add(result.submission);
      } else {
        list[index] = result.submission;
      }
      submissions = List.unmodifiable(list);
      return result;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isSubmittingWork = false;
    }
  }

  Future<PilotContractModel?> acceptContract(
    int contractId,
  ) async {
    if (isAccepting || isRejecting) return null;

    isAccepting = true;
    actionErrorMessage = null;

    try {
      final updated = await service.acceptContract(contractId);
      selectedContract = updated;
      _replaceContract(updated);
      return updated;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isAccepting = false;
    }
  }

  Future<PilotContractModel?> rejectContract(
    int contractId, {
    String? reason,
  }) async {
    if (isAccepting || isRejecting) return null;

    isRejecting = true;
    actionErrorMessage = null;

    try {
      final updated = await service.rejectContract(
        contractId,
        reason: reason,
      );
      selectedContract = updated;
      _replaceContract(updated);
      return updated;
    } catch (e) {
      actionErrorMessage = e.toString();
      return null;
    } finally {
      isRejecting = false;
    }
  }

  void _replaceContract(PilotContractModel updated) {
    final mutable = List<PilotContractModel>.from(contracts);
    final index = mutable.indexWhere((item) => item.id == updated.id);

    if (index == -1) {
      mutable.insert(0, updated);
    } else {
      mutable[index] = updated;
    }

    contracts = mutable;
  }
}
