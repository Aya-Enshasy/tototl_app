import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/features/company/services/company_collection_service.dart';

void main() {
  Map<String, dynamic> response({
    String contractStatus = 'accepted',
    String paymentStatus = 'pending',
    String? token = 'https://checkout.stripe.com/c/pay/cs_test_demo',
  }) => {
        'success': true,
        'data': {
          'id': 14,
          'status': contractStatus,
          'payment': {
            'id': 3,
            'status': paymentStatus,
            'client_action': {
              'type': 'redirect',
              'token': token,
              'session_id': 'cs_test_example',
            },
          },
        },
      };

  test('Fund response exposes a Stripe checkout but not successful funding', () {
    final snapshot = ContractFundingSnapshot.fromResponse(response());
    expect(snapshot.paymentId, 3);
    expect(snapshot.paymentStatus, 'pending');
    expect(snapshot.isFunded, isFalse);
    expect(snapshot.hasPendingPayment, isTrue);
    expect(snapshot.checkoutUri?.host, 'checkout.stripe.com');
    expect(snapshot.isTestSession, isTrue);
  });

  test('Stripe URL must never be accepted from an untrusted host', () {
    final snapshot = ContractFundingSnapshot.fromResponse(
      response(token: 'https://untrusted.invalid/stripe-checkout'),
    );
    expect(snapshot.checkoutUri, isNull);
    expect(snapshot.hasPendingPayment, isTrue);
  });

  test('Only authoritative server progression marks a contract funded', () {
    expect(ContractFundingSnapshot.fromResponse(
      response(contractStatus: 'accepted', paymentStatus: 'pending'),
    ).isFunded, isFalse);
    expect(ContractFundingSnapshot.fromResponse(
      response(contractStatus: 'active', paymentStatus: 'funded'),
    ).isFunded, isTrue);
  });

  test('Existing pending payment in a GET contract blocks another charge', () {
    final snapshot = ContractFundingSnapshot.fromResponse({
      'success': true,
      'data': {
        'status': 'accepted',
        'payments': [
          {'id': 3, 'status': 'pending'},
        ],
      },
    });
    expect(snapshot.hasPendingPayment, isTrue);
    expect(snapshot.paymentId, 3);
    expect(snapshot.checkoutUri, isNull);
  });
}
