import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/features/company/services/stripe_checkout_url.dart';

void main() {
  test('accepts only hosted Stripe Checkout with session path', () {
    expect(isTrustedStripeCheckoutUri(Uri.parse(
      'https://checkout.stripe.com/c/pay/cs_test_ABC#exampleFragment')),
      isTrue,
    );
    for (final invalid in [
      'http://checkout.stripe.com/c/pay/cs_test_ABC',
      'https://checkout.stripe.com.evil.example/c/pay/cs_test_ABC',
      'https://evil.example/c/pay/cs_test_ABC',
      'https://checkout.stripe.com/@evil.example',
      'https://checkout.stripe.com/pay/cs_test_ABC',
    ]) {
      expect(isTrustedStripeCheckoutUri(Uri.tryParse(invalid)), isFalse,
          reason: invalid);
    }
  });

  test('recognizes actual TOTOTL return page without treating it as paid', () {
    expect(isTototlPaymentReturnUri(Uri.parse(
      'https://tototl.abdullahdheir.dev/payments/return?session_id=cs_test_ABC')),
      isTrue,
    );
    expect(isTototlPaymentReturnUri(Uri.parse(
      'https://tototl.abdullahdheir.dev.evil.example/payments/return')),
      isFalse,
    );
    expect(isProviderPaymentConfirmedStatus('pending'), isFalse);
    expect(isProviderPaymentConfirmedStatus('paid'), isTrue);
  });
}
