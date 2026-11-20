import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/features/company/services/company_collection_service.dart';
import 'package:tototl_app/features/company/services/stripe_checkout_url.dart';

void main() {
  group('Scoped payment-attempt status decoding', () {
    test('reads a direct attempt status', () {
      expect(CompanyCollectionService.collectionAttemptStatus(
        {'id': 2, 'status': 'pending'}), 'pending');
    });

    test('reads nested payment status from collect response', () {
      expect(CompanyCollectionService.collectionAttemptStatus({
        'attempt': {'id': 2, 'payment': {'status': 'funded'}},
      }), 'funded');
    });

    test('unknown does not become a failed or paid attempt', () {
      expect(CompanyCollectionService.collectionAttemptStatus(
        {'reference': 'cs_test_123'}), isNull);
      expect(isProviderPaymentConfirmedStatus(null), isFalse);
      expect(isProviderPaymentConfirmedStatus('pending'), isFalse);
    });

    test('only the full trusted Checkout URL can be recovered', () {
      const url = 'https://checkout.stripe.com/c/pay/cs_test_456';
      expect(ContractFundingSnapshot.extractCheckoutUri({
        'payment': {'client_action': {'type': 'redirect', 'token': url}},
      })?.toString(), url);
      expect(ContractFundingSnapshot.extractCheckoutUri({
        'payment': {'client_action': {'session_id': 'cs_test_456'}},
      }), isNull);
    });

    test('an accepted contract remains unfunded even if provider was paid', () {
      final snapshot = ContractFundingSnapshot.fromResponse({
        'success': true,
        'data': {'status': 'accepted', 'payment': {'status': 'paid'}},
      });
      expect(snapshot.isFunded, isFalse);
      expect(isProviderPaymentConfirmedStatus(snapshot.paymentStatus), isTrue);
    });
  });
}
