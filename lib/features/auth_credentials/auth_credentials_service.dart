import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/app/core/auth/auth_exception.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_model.dart';

/// Service responsável por fazer requisições de autenticação à API
class AuthCredentialsService {
  final http.Client client;
  
  // Usar variável de ambiente específica para autenticação
  static String get baseUrl => EnvKeyHelperConfig.apiBaseUrl;

  AuthCredentialsService(this.client);

  /// Realiza o login na API
  Future<AuthCredentialsLoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = AuthCredentialsLoginRequest(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('🔐 [AuthCredentialsService] Tentando login para: $email');
        debugPrint('📍 [AuthCredentialsService] URL: $baseUrl/auth/login');
      }

      final response = await client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (kDebugMode) {
        debugPrint('📥 [AuthCredentialsService] Status Code: ${response.statusCode}');
        final bodyPreview = response.body.length > 200 
            ? '${response.body.substring(0, 200)}...' 
            : response.body;
        debugPrint('📥 [AuthCredentialsService] Response Body: $bodyPreview');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ [AuthCredentialsService] JSON parseado com sucesso');
          debugPrint('🔑 [AuthCredentialsService] Token presente: ${jsonResponse.containsKey('token')}');
        }
        
        final loginResponse = AuthCredentialsLoginResponse.fromJson(jsonResponse);
        if (kDebugMode) {
          debugPrint('✅ [AuthCredentialsService] Model criado com sucesso');
        }
        
        return loginResponse;
      } else if (response.statusCode == 401) {
        throw AuthException(
          'Email ou senha inválidos',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 400) {
        throw AuthException(
          'Dados de login inválidos. Verifique email e senha',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode >= 500) {
        throw AuthException(
          'Erro no servidor. Tente novamente mais tarde',
          statusCode: response.statusCode,
        );
      } else {
        throw AuthException(
          'Erro ao fazer login: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Erro de conexão: $e');
    }
  }

  /// Realiza o logout (se houver endpoint específico)
  Future<void> logout(String token) async {
    try {
      // Implementar se houver endpoint de logout na API
      // Por enquanto, apenas limpar o token localmente
      await client.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignorar erros de logout, pois o token será limpo localmente de qualquer forma
    }
  }

  /// Valida o token (se houver endpoint de validação)
  Future<bool> validateToken(String token) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/auth/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
