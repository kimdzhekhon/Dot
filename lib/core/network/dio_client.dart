import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dot/core/network/network_exception.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.addAll([
      // Logging Interceptor
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print("🚀 [REQ] ${options.method} ${options.path}");
            // Masking Sensitive Headers
            final headers = Map.of(options.headers);
            if (headers.containsKey('Authorization')) {
              headers['Authorization'] = 'Bearer ***';
            }
            if (headers.containsKey('x-api-key')) {
              headers['x-api-key'] = '***';
            }
            print("   Headers: $headers");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print("✅ [RES] ${response.statusCode} ${response.requestOptions.path}");
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print("❌ [ERR] ${e.message} ${e.requestOptions.path}");
          }
          return handler.next(e);
        },
      ),
      // Retry Logic (Simple)
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          if (_shouldRetry(e)) {
            try {
              // Retry once
              // Real implementation might need a more robust backoff strategy
              // For now, we manually retry via the repository pattern usually.
              // But here is a placeholder for interceptor-level retry.
              // Taking a conservative approach: just pass through.
              // Using a proper package like dio_smart_retry is better in prod.
            } catch (_) {}
          }
          return handler.next(e);
        },
      ),
    ]);
  }

  Dio get dio => _dio;

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.error.toString().contains("SocketException"));
  }

  // Wrapper methods for safety
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
