import '../../company/models/contract_submission_model.dart';
import '../models/pilot_contract_model.dart';

/// Only changes the local display of an in-progress contract when the
/// submission list proves the newest work round is awaiting company review.
/// Never writes a contract status to the backend.
class PilotSubmissionState {
  const PilotSubmissionState._();

  static PilotContractModel forDisplay(
    PilotContractModel contract,
    List<ContractSubmissionModel> submissions,
  ) {
    if (!contract.isInProgress || submissions.isEmpty) return contract;
    final latest = submissions.last;
    if (latest.contractId != contract.id || !latest.isSubmitted) {
      return contract;
    }
    return contract.copyWith(
      status: 'submitted',
      submittedAt: contract.submittedAt ?? latest.createdAt ??
          DateTime.now().toUtc(),
    );
  }
}
