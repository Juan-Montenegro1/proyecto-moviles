/// Custom exceptions for the application
class AppException implements Exception {
  final String message;
  
  AppException({required this.message});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({required String message}) : super(message: message);
}

class DatabaseException extends AppException {
  DatabaseException({required String message}) : super(message: message);
}
