import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/core/network/api_endpoints.dart';
import 'package:tototl_app/features/company/models/company_contract_model.dart';
import 'package:tototl_app/features/company/services/company_collection_service.dart';

void main() {
  test('Latest API identity and collection endpoints remain stable', () {
    expect(ApiEndpoints.legalIdentity, '/legal-identity');
    expect(ApiEndpoints.adminPendingLegalIdentities, '/admin/legal-identities/pending');
    expect(ApiEndpoints.quoteCompanyContract(12), '/company/contracts/12/quote');
    expect(ApiEndpoints.collectCompanyContract(12), '/company/contracts/12/collect');
    expect(ApiEndpoints.collectionStatus(12, 45), '/company/contracts/12/collect/45');
  });

  test('Stripe redirect endpoint is the backend fund route', () {
    expect(ApiEndpoints.fundCompanyContract(12),
        '/company/contracts/12/fund');
  });

  test('Payment required only once the pilot has accepted', () {
    CompanyContractModel parse(String status) => CompanyContractModel.fromJson({
      'id': 12,
      'job_posting_id': 15,
      'job_application_id': 15,
      'company_profile_id': 5,
      'pilot_profile_id': 7,
      'amount': '100.00',
      'currency': 'USD',
      'payment_type': 'fixed',
      'status': status,
      'payments': [],
    });
    expect(parse('pending').canFund, isFalse);
    expect(parse('accepted').canFund, isTrue);
    expect(parse('active').canFund, isFalse);
    expect(parse('in_progress').canFund, isFalse);
  });
}
