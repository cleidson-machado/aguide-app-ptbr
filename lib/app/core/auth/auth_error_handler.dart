import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/core/auth/auth_exception.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';

/// Handler global para erros de autenticação
/// Centraliza a lógica de tratamento de erros HTTP relacionados a auth
class AuthErrorHandler {
  final AuthTokenManager _tokenManager;

  AuthErrorHandler(this._tokenManager);

  /// Processa exceptions da camada de dados e converte em exceptions amigáveis
  /// Retorna uma exception adequada para exibição ao usuário
  Exception handleError(Object error, {String? context}) {
    if (kDebugMode) {
      debugPrint('🚨 [AuthErrorHandler] Tratando erro: ${error.runtimeType}');
      debugPrint('📍 [AuthErrorHandler] Contexto: ${context ?? "N/A"}');
    }

    // Erro de Dio (HTTP)
    if (error is DioException) {
      return _handleDioError(error);
    }

    // Já é uma AuthException customizada
    if (error is AuthException) {
      return error;
    }

    // Erro genérico (fallback)
    return AuthException(
      'Ocorreu um erro inesperado. Tente novamente.',
      technicalDetails: error.toString(),
    );
  }

  /// Trata erros específicos do Dio
  Exception _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final technicalDetails = error.toString();

    if (kDebugMode) {
      debugPrint('🔍 [AuthErrorHandler] DioException - Status: $statusCode');
      debugPrint('🔍 [AuthErrorHandler] Type: ${error.type}');
    }

    switch (error.type) {
      // Erros de conexão/timeout
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(technicalDetails: technicalDetails);

      // Erro de resposta da API
      case DioExceptionType.badResponse:
        return _handleBadResponse(statusCode, technicalDetails);

      // Cancelamento de requisição
      case DioExceptionType.cancel:
        return AuthException(
          'Operação cancelada.',
          technicalDetails: technicalDetails,
        );

      // Outros erros
      default:
        return NetworkException(technicalDetails: technicalDetails);
    }
  }

  /// Trata erros de resposta HTTP por status code
  Exception _handleBadResponse(int? statusCode, String technicalDetails) {
    switch (statusCode) {
      case 401:
        // Token expirado ou inválido - fazer logout automático
        _handleSessionExpired();
        return TokenExpiredException(technicalDetails: technicalDetails);

      case 403:
        return TokenInvalidException(technicalDetails: technicalDetails);

      case 400:
        return AuthException(
          'Requisição inválida. Verifique os dados e tente novamente.',
          statusCode: statusCode,
          technicalDetails: technicalDetails,
        );

      case 404:
        return AuthException(
          'Recurso não encontrado.',
          statusCode: statusCode,
          technicalDetails: technicalDetails,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(technicalDetails: technicalDetails);

      default:
        return AuthException(
          'Erro no servidor (código $statusCode). Tente novamente.',
          statusCode: statusCode,
          technicalDetails: technicalDetails,
        );
    }
  }

  /// Lógica centralizada para lidar com expiração de sessão
  /// - Limpa token local
  /// - Redireciona para tela de login
  void _handleSessionExpired() {
    if (kDebugMode) {
      debugPrint('⏰ [AuthErrorHandler] Sessão expirada - executando logout');
    }

    // Limpar token de forma assíncrona
    _tokenManager.clearAuth().then((_) {
      if (kDebugMode) {
        debugPrint('✅ [AuthErrorHandler] Token limpo com sucesso');
      }

      // Redirecionar para login
      // NOTA: Usar pushReplacementNamed para evitar voltar para tela autenticada
      Modular.to.navigate(AppRoutes.login);

      if (kDebugMode) {
        debugPrint('🔄 [AuthErrorHandler] Redirecionado para tela de login');
      }
    }).catchError((error) {
      if (kDebugMode) {
        debugPrint('❌ [AuthErrorHandler] Erro ao limpar token: $error');
      }
    });
  }

  /// Verifica se um erro é relacionado a autenticação (401/403)
  static bool isAuthError(Exception error) {
    return error is TokenExpiredException || error is TokenInvalidException;
  }

  /// Extrai mensagem amigável de qualquer exception
  static String getUserFriendlyMessage(Exception error) {
    if (error is AuthException) {
      return error.message;
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}
