import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/features/company/services/company_collection_service.dart';

void main() {
  const url = 'https://checkout.stripe.com/c/pay/cs_test_auto_resume';

  test('fund response opens Stripe when client_action belongs to payment', () {
    final snapshot = ContractFundingSnapshot.fromResponse({
      'success': true,
      'data': {
        'id': 12,
        'status': 'accepted',
        'payment': {
          'id': 2,
          'status': 'pending',
          'client_action': {'type': 'redirect', 'token': url},
        },
      },
    });
    expect(snapshot.checkoutUri?.toString(), url);
    expect(snapshot.hasPendingPayment, true);
    expect(snapshot.isFunded, false);
  });

  test('a different envelope can still contain a valid redirect', () {
    final snapshot = ContractFundingSnapshot.fromResponse({
      'success': true,
      'data': {
        'status': 'accepted',
        'payment': {'id': 2, 'status': 'pending'},
        'client_action': {'type': 'redirect', 'token': url},
      },
    });
    expect(snapshot.checkoutUri?.toString(), url);
  });

  test('only one scoped company payment can provide a fallback URL', () {
    final rows = <Map<String, dynamic>>[
      {
        'id': 2,
        'contract_id': 12,
        'status': 'pending',
        'client_action': {'token': url},
      },
      {
        'id': 9,
        'contract_id': 20,
        'status': 'pending',
        'client_action': {'token': 'https://checkout.stripe.com/c/pay/cs_test_other'},
      },
    ];
    expect(CompanyCollectionService.resolveCompanyCheckoutUri(
      rows, contractId: 12, paymentId: 2)?.toString(), url);
    expect(CompanyCollectionService.resolveCompanyCheckoutUri(
      rows, contractId: 11, paymentId: 2), isNull);
  });

  test('paid or ambiguous payment cannot be reopened', () {
    final rows = <Map<String, dynamic>>[
      {'id': 1, 'contract_id': 12, 'status': 'pending', 'checkout_url': url},
      {'id': 2, 'contract_id': 12, 'status': 'paid', 'checkout_url': url},
    ];
    expect(CompanyCollectionService.resolveCompanyCheckoutUri(
      rows, contractId: 12), isNull);
    expect(CompanyCollectionService.resolveCompanyCheckoutUri(
      rows, contractId: 12, paymentId: 2), isNull);
  });

  test('untrusted host or session-id-only cannot open checkout', () {
    expect(ContractFundingSnapshot.extractCheckoutUri({
      'client_action': {'token': 'https://evil.example/c/pay/cs_test_bad'},
    }), isNull);
    expect(ContractFundingSnapshot.extractCheckoutUri({
      'client_action': {'session_id': 'cs_test_only_id'},
    }), isNull);
  });
}
