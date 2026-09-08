import 'package:dio/dio.dart';

import 'api_endpoints.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  // ============================================================
  // GET
  // ============================================================

  Future<Response<dynamic>> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ============================================================
  // POST
  // ============================================================

  Future<Response<dynamic>> post(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.post<dynamic>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<Response<dynamic>> put(
      String endpoint, {
        dynamic data,
        Options? options,
      }) async {
    return await _dio.put<dynamic>(
      endpoint,
      data: data,
      options: options,
    );
  }

  // ============================================================
  // PATCH
  // ============================================================

  Future<Response<dynamic>> patch(
      String endpoint, {
        dynamic data,
        Options? options,
      }) async {
    return await _dio.patch<dynamic>(
      endpoint,
      data: data,
      options: options,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<Response<dynamic>> delete(
      String endpoint, {
        dynamic data,
        Options? options,
      }) async {
    return await _dio.delete<dynamic>(
      endpoint,
      data: data,
      options: options,
    );
  }
}