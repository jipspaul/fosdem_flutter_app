class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  ServerException({
    this.message = 'Server error occurred',
    this.statusCode,
  });
  
  @override
  String toString() => 'ServerException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException({this.message = 'Network connection failed'});
  
  @override
  String toString() => 'NetworkException: $message';
}

class DatabaseException implements Exception {
  final String message;
  
  DatabaseException({this.message = 'Database error occurred'});
  
  @override
  String toString() => 'DatabaseException: $message';
}

class CacheException implements Exception {
  final String message;
  
  CacheException({this.message = 'Cache error occurred'});
  
  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;
  
  ValidationException({
    this.message = 'Validation error',
    this.errors,
  });
  
  @override
  String toString() => 'ValidationException: $message${errors != null ? ' - $errors' : ''}';
}

class NotFoundException implements Exception {
  final String message;
  
  NotFoundException({this.message = 'Resource not found'});
  
  @override
  String toString() => 'NotFoundException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  
  UnauthorizedException({this.message = 'Unauthorized access'});
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ParseException implements Exception {
  final String message;
  
  ParseException({this.message = 'Failed to parse data'});
  
  @override
  String toString() => 'ParseException: $message';
}
