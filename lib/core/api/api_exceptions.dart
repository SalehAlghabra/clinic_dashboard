class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException({required super.message});
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({required super.message, super.statusCode = 401});
}

class ValidationException extends ApiException {
  final Map<String, dynamic> errors;

  ValidationException({
    required super.message,
    required this.errors,
    super.statusCode = 422,
  });
}
