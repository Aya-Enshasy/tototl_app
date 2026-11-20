import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/core/network/request_error_message.dart';

void main() {
  for (final status in [500, 502, 503, 504]) {
    test('HTTP $status does not leak technical exception in UI', () {
      final request = RequestOptions(path: '/v1/contracts');
      final error = DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: status,
          data: '<html>gateway failed</html>'),
        type: DioExceptionType.badResponse,
      );
      final message = RequestErrorMessage.from(error);
      expect(message, contains('server'));
      expect(message, isNot(contains('DioException')));
      expect(message, isNot(contains('<html>')));
    });
  }
}
