import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';

/// Interceptor global para requisições HTTP
/// Responsável por:
/// - Adicionar token de autenticação em todas as requisições
/// - Capturar erros 401 de forma centralizada
/// - Log detalhado em modo debug
class AuthHttpInterceptor extends Interceptor {
  final AuthTokenManager _tokenManager;
  final String? fallbackToken;

  AuthHttpInterceptor(
    this._tokenManager, {
    this.fallbackToken,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Obter token do usuário autenticado
    final userToken = _tokenManager.getToken();

    // Usar token do usuário ou fallback (dev token)
    final authToken = (userToken != null && userToken.isNotEmpty)
        ? userToken
        : fallbackToken;

    if (authToken != null && authToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $authToken';

      if (kDebugMode) {
        final tokenPreview = authToken.length > 20
            ? '${authToken.substring(0, 20)}...'
            : authToken;
        debugPrint('🔑 [AuthHttpInterceptor] Token adicionado: $tokenPreview');
        debugPrint(
          '📝 [AuthHttpInterceptor] Origem: ${userToken != null && userToken.isNotEmpty ? "USUÁRIO AUTENTICADO" : "DEV TOKEN (.env)"}',
        );
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [AuthHttpInterceptor] AVISO: Nenhum token disponível para requisição',
        );
      }
    }

    // Continuar com a requisição
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '✅ [AuthHttpInterceptor] Resposta ${response.statusCode} - ${response.requestOptions.path}',
      );
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    if (kDebugMode) {
      debugPrint(
        '❌ [AuthHttpInterceptor] Erro ${statusCode ?? "N/A"} - ${err.requestOptions.path}',
      );
      debugPrint('📍 [AuthHttpInterceptor] Tipo: ${err.type}');
    }

    // Log específico para erros de autenticação
    if (statusCode == 401) {
      if (kDebugMode) {
        debugPrint('🚨 [AuthHttpInterceptor] ERRO 401: Token expirado/inválido');
        debugPrint(
          '   URL: ${err.requestOptions.baseUrl}${err.requestOptions.path}',
        );
        debugPrint('   Mensagem: ${err.response?.data}');
      }
    }

    // Continuar com o erro (será tratado pelo ErrorHandler)
    return handler.next(err);
  }
}
