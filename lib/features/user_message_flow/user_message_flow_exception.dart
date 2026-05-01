class UserMessageFlowException implements Exception {
  final String message;
  final int? statusCode;

  const UserMessageFlowException(this.message, {this.statusCode});

  bool get isBadRequest => statusCode == 400;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;
}
