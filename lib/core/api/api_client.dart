import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;
  final StorageService _storageService;

  ApiClient({
    required StorageService storageService,
    Dio? dio,
  })  : _storageService = storageService,
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = AppConfig.connectTimeout;
    _dio.options.receiveTimeout = AppConfig.receiveTimeout;
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final locale = await _storageService.getLocale();
        options.headers['Accept-Language'] = locale;
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        final exception = _handleDioError(error);
        return handler.next(DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: exception,
          message: exception.message,
        ));
      },
    ));
  }

  Dio get dio => _dio;

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(message: 'Connection error. Please check backend server.');
    }

    if (error.response == null) {
      return NetworkException(message: 'Unable to connect to server at ${AppConfig.baseUrl}');
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    
    String message = 'An error occurred';
    if (data is Map) {
      message = data['message'] ?? 'An error occurred';
    }

    switch (statusCode) {
      case 400:
        return ApiException(message: message, statusCode: statusCode, data: data);
      case 401:
        return UnauthorizedException(message: message, statusCode: statusCode);
      case 403:
        return ApiException(message: 'Access Denied.', statusCode: statusCode, data: data);
      case 404:
        return ApiException(message: 'Resource not found.', statusCode: statusCode, data: data);
      case 422:
        final errors = (data is Map) ? (data['errors'] ?? {}) : {};
        return ValidationException(message: message, errors: errors, statusCode: statusCode);
      case 500:
      default:
        return ApiException(message: 'Server error ($statusCode): $message', statusCode: statusCode, data: data);
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'HTTP Error');
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'HTTP Error');
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'HTTP Error');
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'HTTP Error');
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'HTTP Error');
    }
  }
}
