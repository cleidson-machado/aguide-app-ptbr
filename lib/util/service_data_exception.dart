// Custom exception class for handling service data errors
class ServiceDataException implements Exception {
  final String message;
  final Exception? cause;

  // Constructor with message only
  ServiceDataException(this.message) : cause = null;

  // Constructor with message and cause
  ServiceDataException.withCause(this.message, this.cause);

  // Named constructor for handler
  ServiceDataException.handler(this.message) : cause = null;

  @override
  String toString() {
    if (cause != null) {
      return 'ServiceDataException: $message, caused by: $cause';
    }
    return 'ServiceDataException: $message';
  }
}
