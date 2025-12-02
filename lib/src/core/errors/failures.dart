abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Please check your internet connection.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred.']);
}

class LocationNotFoundFailure extends Failure {
  const LocationNotFoundFailure([super.message = 'Location not found.']);
}

class ConfigSyncFailure extends Failure {
  const ConfigSyncFailure([super.message = 'Configuration sync failed.']);
}
