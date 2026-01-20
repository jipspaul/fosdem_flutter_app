import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class HttpClient {
  late final Dio _dio;

  HttpClient({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool enableLogging = true,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? 'https://fosdem.org',
        connectTimeout: connectTimeout ?? const Duration(seconds: 30),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json, application/xml, text/xml',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add logging interceptor
    if (enableLogging) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }

    // Add error handling interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Log error details
          print('HTTP Error: ${error.message}');
          if (error.response != null) {
            print('Status Code: ${error.response?.statusCode}');
            print('Response Data: ${error.response?.data}');
          }
          handler.next(error);
        },
        onRequest: (options, handler) {
          print('Request: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('Response: ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
      ),
    );

    // Add retry logic interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            try {
              final response = await _retry(error.requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  Dio get client => _dio;

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions, {
    int maxRetries = 3,
  }) async {
    int retries = 0;
    while (retries < maxRetries) {
      try {
        await Future.delayed(Duration(seconds: retries + 1));
        return await _dio.fetch(requestOptions);
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          rethrow;
        }
      }
    }
    throw Exception('Max retries reached');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
