import 'package:http/http.dart' as http;
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/core_auth/auth_token_manager.dart';

/// Cliente HTTP que adiciona automaticamente o token de autenticação
/// nos headers de todas as requisições
class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final AuthTokenManager _tokenManager;

  AuthenticatedHttpClient({
    http.Client? inner,
    AuthTokenManager? tokenManager,
  })  : _inner = inner ?? http.Client(),
        _tokenManager = tokenManager ?? injector<AuthTokenManager>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Adicionar token de autenticação se disponível
    final authHeader = _tokenManager.getAuthorizationHeader();
    if (authHeader != null) {
      request.headers['Authorization'] = authHeader;
    }

    // Garantir que Content-Type seja JSON se não especificado
    if (!request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Helper para criar facilmente um cliente HTTP autenticado
class HttpClientHelper {
  /// Cria um cliente HTTP que adiciona automaticamente o token de autenticação
  static http.Client createAuthenticatedClient() {
    return AuthenticatedHttpClient();
  }

  /// Cria um cliente HTTP padrão sem autenticação automática
  static http.Client createClient() {
    return http.Client();
  }
}
