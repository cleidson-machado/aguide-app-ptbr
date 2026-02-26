/// Exceções customizadas para autenticação
/// Evita expor stacktraces técnicos ao usuário final

// ignore_for_file: dangling_library_doc_comments

/// Exception genérica de autenticação
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? technicalDetails;

  AuthException(
    this.message, {
    this.statusCode,
    this.technicalDetails,
  });

  @override
  String toString() => message;

  /// Retorna mensagem técnica completa (apenas para logs)
  String toTechnicalString() {
    return 'AuthException: $message (Status: $statusCode)\n'
        'Technical Details: ${technicalDetails ?? "N/A"}';
  }
}

/// Exception específica para token expirado (401)
class TokenExpiredException extends AuthException {
  TokenExpiredException({String? technicalDetails})
      : super(
          'Sua sessão expirou. Por favor, faça login novamente.',
          statusCode: 401,
          technicalDetails: technicalDetails,
        );
}

/// Exception para token inválido (403 ou outros erros de autorização)
class TokenInvalidException extends AuthException {
  TokenInvalidException({String? technicalDetails})
      : super(
          'Erro de autenticação. Por favor, faça login novamente.',
          statusCode: 403,
          technicalDetails: technicalDetails,
        );
}

/// Exception para erro de conexão/rede
class NetworkException extends AuthException {
  NetworkException({String? technicalDetails})
      : super(
          'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          statusCode: null,
          technicalDetails: technicalDetails,
        );
}

/// Exception para erros de servidor (5xx)
class ServerException extends AuthException {
  ServerException({String? technicalDetails})
      : super(
          'O servidor está temporariamente indisponível. Tente novamente em alguns minutos.',
          statusCode: 500,
          technicalDetails: technicalDetails,
        );
}
