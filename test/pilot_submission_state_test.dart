import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/features/company/models/contract_submission_model.dart';
import 'package:tototl_app/features/pilot/models/pilot_contract_model.dart';
import 'package:tototl_app/features/pilot/services/pilot_submission_state.dart';

void main() {
  PilotContractModel contract(String status) => PilotContractModel.fromJson({
    'id': 20,
    'status': status,
    'amount': 55,
    'currency': 'USD',
  });
  ContractSubmissionModel submission(int contractId, String status) =>
      ContractSubmissionModel.fromJson({
        'id': 9,
        'contract_id': contractId,
        'status': status,
        'notes': 'Work completed',
        'files': [],
      });

  test('accepted upload makes stale in_progress display awaiting review', () {
    final displayed = PilotSubmissionState.forDisplay(
      contract('in_progress'), [submission(20, 'submitted')],
    );
    expect(displayed.isSubmitted, isTrue);
    expect(displayed.canSubmitWork, isFalse);
  });

  test('work from a different contract never changes this one', () {
    final displayed = PilotSubmissionState.forDisplay(
      contract('in_progress'), [submission(21, 'submitted')],
    );
    expect(displayed.isInProgress, isTrue);
  });

  test('revision requested re-enables revised submissions', () {
    final displayed = PilotSubmissionState.forDisplay(
      contract('in_progress'), [submission(20, 'revision_requested')],
    );
    expect(displayed.canSubmitWork, isTrue);
  });

  test('completed contract is never downgraded by old submissions', () {
    final displayed = PilotSubmissionState.forDisplay(
      contract('completed'), [submission(20, 'submitted')],
    );
    expect(displayed.isCompleted, isTrue);
  });
}
