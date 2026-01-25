import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException({required this.message, this.statusCode});

  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: "Connection timed out. Please try again.");
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String msg = "Server error occurred.";
        if (statusCode == 401) msg = "Unauthorized access.";
        if (statusCode == 403) msg = "Access denied.";
        if (statusCode == 404) msg = "Resource not found.";
        // Custom backend error message if available
        if (data is Map && data['error'] != null) {
          msg = data['error'].toString();
        }
        return NetworkException(message: msg, statusCode: statusCode);
      case DioExceptionType.cancel:
        return NetworkException(message: "Request cancelled.");
      case DioExceptionType.unknown:
        if (error.message?.contains("SocketException") ?? false) {
          return NetworkException(message: "No internet connection.");
        }
        return NetworkException(message: "Unexpected error occurred.");
      default:
        return NetworkException(message: "Something went wrong. Please check your connection.");
    }
  }

  @override
  String toString() => message;
}
