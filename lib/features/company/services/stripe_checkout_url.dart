/// Stripe Checkout links are bearer capabilities. Only accept the hosted
/// checkout URL returned by the funding API or pasted by the same company.
/// Never log, put in analytics, or send them to arbitrary hosts.
bool isTrustedStripeCheckoutUri(Uri? uri) {
  if (uri == null || uri.scheme.toLowerCase() != 'https' ||
      uri.host.toLowerCase() != 'checkout.stripe.com' ||
      uri.userInfo.isNotEmpty) {
    return false;
  }
  final segments = uri.pathSegments;
  return segments.length >= 3 &&
      segments[0] == 'c' &&
      segments[1] == 'pay' &&
      segments[2].startsWith('cs_');
}

/// A redirect to the payment return page is only a signal to re-check the
/// backend. It is NOT evidence that funds were collected.
bool isTototlPaymentReturnUri(Uri? uri) {
  return uri != null &&
      uri.scheme.toLowerCase() == 'https' &&
      uri.host.toLowerCase() == 'tototl.abdullahdheir.dev' &&
      uri.path == '/payments/return';
}

bool isProviderPaymentConfirmedStatus(String? raw) {
  final status = raw?.trim().toLowerCase() ?? '';
  return const {
    'paid', 'succeeded', 'successful', 'completed', 'funded', 'held',
  }.contains(status);
}
