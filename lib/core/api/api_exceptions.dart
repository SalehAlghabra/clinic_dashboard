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

/// Extracts a human-readable error message from any exception thrown by the API client.
/// Prioritises the server's specific validation messages before falling back to
/// the generic exception message.
String parseErrorMessage(Object e) {
  if (e is ValidationException) {
    if (e.errors.isNotEmpty) {
      // Return the first validation error field message
      final firstField = e.errors.values.first;
      if (firstField is List && firstField.isNotEmpty) {
        return firstField.first.toString();
      }
      return firstField.toString();
    }
    return e.message;
  }
  if (e is ApiException) {
    return e.message;
  }
  // Strip the Dart exception class prefix for cleaner display
  final raw = e.toString();
  if (raw.startsWith('ApiException: ')) return raw.substring(14);
  return raw;
}
