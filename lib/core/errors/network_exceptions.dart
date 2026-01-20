import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const NetworkException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message';
}

class NoInternetException extends NetworkException {
  const NoInternetException({
    String message = 'No internet connection available',
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );

  String get recoveryMessage =>
      'Please check your internet connection and try again.';
}

class ServerException extends NetworkException {
  final int? statusCode;

  const ServerException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );

  String get recoveryMessage =>
      statusCode == 500
          ? 'Server error. Please try again later.'
          : statusCode == 503
              ? 'Service temporarily unavailable.'
              : 'Server error occurred. Please try again.';
}

class TimeoutException extends NetworkException {
  const TimeoutException({
    String message = 'Request timeout',
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );

  String get recoveryMessage =>
      'The request took too long. Please check your connection and try again.';
}

class ParseException extends NetworkException {
  const ParseException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );

  String get recoveryMessage =>
      'Failed to parse response data. The data format may be invalid.';
}

class NotFoundException extends NetworkException {
  const NotFoundException({
    String message = 'Resource not found',
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );

  String get recoveryMessage =>
      'The requested resource was not found. It may have been moved or deleted.';
}

class UnauthorizedException extends NetworkException {
  const UnauthorizedException({
    String message = 'Unauthorized access',
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );

  String get recoveryMessage =>
      'You are not authorized to access this resource.';
}

class NetworkExceptionHandler {
  static NetworkException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Request timeout: ${error.message}',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return NotFoundException(
            message: 'Resource not found',
            originalError: error,
          );
        } else if (statusCode == 401 || statusCode == 403) {
          return UnauthorizedException(
            message: 'Unauthorized access',
            originalError: error,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: 'Server error: $statusCode',
            statusCode: statusCode,
            originalError: error,
          );
        }
        return ServerException(
          message: 'Bad response: ${error.message}',
          statusCode: statusCode,
          originalError: error,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request was cancelled',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NoInternetException(
          message: 'Connection error: ${error.message}',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'SSL certificate error',
          originalError: error,
        );

      case DioExceptionType.unknown:
      default:
        return NetworkException(
          message: 'Unknown network error: ${error.message}',
          originalError: error,
        );
    }
  }

  static NetworkException handleError(dynamic error) {
    if (error is DioException) {
      return handleDioError(error);
    } else if (error is NetworkException) {
      return error;
    } else {
      return NetworkException(
        message: 'Unexpected error: $error',
        originalError: error,
      );
    }
  }
}
