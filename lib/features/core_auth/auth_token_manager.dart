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
}
