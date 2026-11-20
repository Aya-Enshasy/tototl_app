import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/core/network/api_client.dart';

void main() {
  test('Cloudflare HTML 429 is not parsed as a Laravel error code', () {
    final request = RequestOptions(path: '/jobs/19');
    final error = DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 429,
        data: '<!DOCTYPE html><title>Just a moment...</title>',
      ),
    );
    expect(ApiClient.errorCodeFromDio(error), isNull);
  });

  test('Structured Laravel subscription error code is retained', () {
    final request = RequestOptions(path: '/company/job-postings');
    final error = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 403,
        data: <String, dynamic>{
          'message': 'Plan limit reached',
          'errors': <String, dynamic>{
            'error_code': 'SUBSCRIPTION_LIMIT_REACHED',
          },
        },
      ),
    );
    expect(ApiClient.errorCodeFromDio(error), 'SUBSCRIPTION_LIMIT_REACHED');
  });
}
