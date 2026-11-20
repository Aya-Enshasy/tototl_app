import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/features/company/services/company_collection_service.dart';
import 'package:tototl_app/features/company/services/stripe_checkout_url.dart';

void main() {
  Map<String, dynamic> row(int id, int contractId, String status) => {
        'id': id,
        'contract_id': contractId,
        'status': status,
      };

  group('Safe company payment reconciliation', () {
    test('uses exact payment ID and contract ID when both match', () {
      final status = CompanyCollectionService.resolveCompanyPaymentStatus(
        [row(5, 20, 'failed'), row(9, 20, 'funded')],
        contractId: 20,
        paymentId: 9,
      );
      expect(status, 'funded');
    });

    test('different attempt ID is reconciled only for unique contract payment', () {
      // Provider attempt #9 and company payment row #7 may differ.
      final status = CompanyCollectionService.resolveCompanyPaymentStatus(
        [row(7, 20, 'funded'), row(9, 21, 'failed')],
        contractId: 20,
        paymentId: 9,
      );
      expect(status, 'funded');
    });

    test('multiple contract payments without matching ID stay ambiguous', () {
      final status = CompanyCollectionService.resolveCompanyPaymentStatus(
        [row(5, 20, 'failed'), row(7, 20, 'pending')],
        contractId: 20,
        paymentId: 9,
      );
      expect(status, isNull);
    });

    test('a payment from another contract can never confirm this contract', () {
      expect(
        CompanyCollectionService.resolveCompanyPaymentStatus(
          [row(9, 21, 'funded')],
          contractId: 20,
          paymentId: 9,
        ),
        isNull,
      );
    });

    test('no row / an invalid status is unknown, not failed', () {
      expect(
        CompanyCollectionService.resolveCompanyPaymentStatus(
          [], contractId: 20, paymentId: 9,
        ),
        isNull,
      );
      expect(
        CompanyCollectionService.resolveCompanyPaymentStatus(
          [{'id': 9, 'contract_id': 20, 'status': ''}],
          contractId: 20,
          paymentId: 9,
        ),
        isNull,
      );
    });
  });

  test('a provider return URL is only a status-check signal', () {
    final returnUri = Uri.parse(
      'https://tototl.abdullahdheir.dev/payments/return?session_id=cs_test_demo',
    );
    expect(isTototlPaymentReturnUri(returnUri), isTrue);
    expect(isProviderPaymentConfirmedStatus('pending'), isFalse);
    final contract = ContractFundingSnapshot.fromResponse({
      'success': true,
      'data': {'status': 'accepted', 'payment': {'status': 'pending'}},
    });
    expect(contract.isFunded, isFalse);
  });
}
