/// Domain-level failure types. Mapping from Dio/HTTP happens in data sources.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network request failed']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
