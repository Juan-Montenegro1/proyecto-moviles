/// Custom failures for handling errors
abstract class Failure {
  final String message;
  
  Failure({required this.message});
}

class NetworkFailure extends Failure {
  NetworkFailure({required String message}) : super(message: message);
}

class DatabaseFailure extends Failure {
  DatabaseFailure({required String message}) : super(message: message);
}

class UnknownFailure extends Failure {
  UnknownFailure({required String message}) : super(message: message);
}
