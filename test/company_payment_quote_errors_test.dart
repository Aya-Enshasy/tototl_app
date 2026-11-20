import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/features/company/services/company_collection_service.dart';

void main() {
  DioException errorFor(
    int status,
    Map<String, dynamic> body, {
    Map<String, List<String>>? headers,
  }) {
    final request = RequestOptions(path: '/v1/company/contracts/12/quote');
    return DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: status,
        data: body,
        headers: Headers.fromMap(headers ?? {}),
      ),
      type: DioExceptionType.badResponse,
    );
  }

  test('422 preserves the real server reason instead of assuming expiry', () {
    final result = CompanyPaymentApiException.fromDio(
      errorFor(422, {
        'message': 'Contract is not eligible for a quote.',
        'error_code': 'CONTRACT_NOT_ELIGIBLE',
      }),
      operation: 'quote',
    );
    expect(result.statusCode, 422);
    expect(result.message, 'Contract is not eligible for a quote.');
    expect(result.errorCode, 'CONTRACT_NOT_ELIGIBLE');
  });

  test('429 exposes bounded Retry-After without echoing request body', () {
    final result = CompanyPaymentApiException.fromDio(
      errorFor(429, {'message': 'Too many requests.'},
          headers: {'retry-after': ['300'], 'cf-ray': ['request-123']}),
      operation: 'quote',
    );
    expect(result.statusCode, 429);
    expect(result.retryAfterSeconds, 120);
    expect(result.requestId, 'request-123');
  });

  test('pending attempt 422 is recognized, not mislabeled an expired quote', () {
    final result = CompanyPaymentApiException.fromDio(
      errorFor(422, {
        'message': 'Attempt #2 is still pending on this contract. Resolve it before starting another.',
      }),
      operation: 'fund',
    );
    expect(result.isPendingAttemptConflict, isTrue);
    expect(result.pendingAttemptId, 2);
    expect(result.statusCode, 422);
  });

  test('fund response opens only a trusted Stripe redirect and remains pending', () {
    final snapshot = ContractFundingSnapshot.fromResponse({
      'data': {
        'status': 'accepted',
        'payment': {
          'id': 14,
          'status': 'pending',
          'client_action': {
            'type': 'redirect',
            'token': 'https://checkout.stripe.com/c/pay/cs_test_sample',
            'session_id': 'cs_test_sample',
          },
        },
      },
    });
    expect(snapshot.hasPendingPayment, isTrue);
    expect(snapshot.isFunded, isFalse);
    expect(snapshot.paymentId, 14);
    expect(snapshot.checkoutUri?.host, 'checkout.stripe.com');
    expect(snapshot.isTestSession, isTrue);
  });

  test('fund response rejects unrelated websites as checkout targets', () {
    final snapshot = ContractFundingSnapshot.fromResponse({
      'data': {
        'status': 'accepted',
        'payment': {
          'id': 15,
          'status': 'pending',
          'client_action': {
            'type': 'redirect',
            'token': 'https://fake-checkout.example.com/payment',
          },
        },
      },
    });
    expect(snapshot.checkoutUri, isNull);
  });

  test('HTML error pages do not leak into payment UI', () {
    final result = CompanyPaymentApiException.fromDio(
      errorFor(503, {'message': '<html>service unavailable</html>'}),
      operation: 'quote',
    );
    expect(result.message, isNot(contains('<html>')));
  });
}
