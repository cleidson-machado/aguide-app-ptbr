import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Classe responsável por gerenciar o armazenamento e recuperação do token de autenticação
class AuthTokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userEmailKey = 'auth_user_email';

  final SharedPreferences _prefs;

  AuthTokenManager(this._prefs);

  /// Salva o token de autenticação
  Future<bool> saveToken(String token) async {
    return await _prefs.setString(_tokenKey, token);
  }

  /// Recupera o token de autenticação
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  /// Salva o refresh token (opcional)
  Future<bool> saveRefreshToken(String refreshToken) async {
    return await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Recupera o refresh token
  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  /// Salva o email do usuário logado
  Future<bool> saveUserEmail(String email) async {
    return await _prefs.setString(_userEmailKey, email);
  }

  /// Recupera o email do usuário logado
  String? getUserEmail() {
    return _prefs.getString(_userEmailKey);
  }

  /// Verifica se o usuário está autenticado
  bool isAuthenticated() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpa todos os dados de autenticação (logout)
  Future<bool> clearAuth() async {
    final tokenRemoved = await _prefs.remove(_tokenKey);
    final refreshTokenRemoved = await _prefs.remove(_refreshTokenKey);
    final emailRemoved = await _prefs.remove(_userEmailKey);
    return tokenRemoved && refreshTokenRemoved && emailRemoved;
  }

  /// Retorna o token formatado para uso em headers HTTP
  String? getAuthorizationHeader() {
    final token = getToken();
    if (token != null && token.isNotEmpty) {
      return 'Bearer $token';
    }
    return null;
  }

  /// Decodifica o JWT e retorna o payload como Map
  /// Retorna null se o token for inválido ou não existir
  Map<String, dynamic>? decodeToken() {
    try {
      final token = getToken();
      if (token == null || token.isEmpty) return null;

      // JWT formato: {header}.{payload}.{signature}
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decodificar payload (parte central do JWT)
      final payload = parts[1];
      
      // Normalizar base64 (adicionar padding se necessário)
      var normalizedPayload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }

      // Decodificar de base64 e converter para Map
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final Map<String, dynamic> decodedPayload = jsonDecode(decodedString);

      return decodedPayload;
    } catch (e) {
      // Se houver erro ao decodificar, retornar null
      return null;
    }
  }

  /// Extrai o userId do token JWT
  /// Retorna null se o token não existir ou não contiver userId
  String? getUserId() {
    final payload = decodeToken();
    if (payload == null) return null;

    // Tentar diferentes chaves comuns para userId
    // (pode variar dependendo da implementação do backend)
    return payload['userId'] as String? ??
           payload['user_id'] as String? ??
           payload['id'] as String? ??
           payload['sub'] as String?; // 'sub' é padrão JWT para subject (user identifier)
  }
}
