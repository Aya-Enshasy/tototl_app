import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
  }

  // GET
  Future<Response> get(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
      }) async {
    return await _dio.get(
      endpoint,
      queryParameters: queryParameters,
    );
  }

  // POST
  Future<Response> post(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
      }) async {
    return await _dio.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
    );
  }

  // PUT
  Future<Response> put(
      String endpoint, {
        dynamic data,
      }) async {
    return await _dio.put(
      endpoint,
      data: data,
    );
  }

  // PATCH
  Future<Response> patch(
      String endpoint, {
        dynamic data,
      }) async {
    return await _dio.patch(
      endpoint,
      data: data,
    );
  }

  // DELETE
  Future<Response> delete(
      String endpoint, {
        dynamic data,
      }) async {
    return await _dio.delete(
      endpoint,
      data: data,
    );
  }
}