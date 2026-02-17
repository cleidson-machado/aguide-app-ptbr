import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_model.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_service.dart';
import 'package:portugal_guide/features/auth_google/auth_google_model.dart';
import 'package:portugal_guide/features/auth_google/auth_google_mock_service.dart';

/// Exceção customizada para erros de OAuth Google
class GoogleOAuthException implements Exception {
  final String message;
  final int? statusCode;

  GoogleOAuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Service responsável pela autenticação com Google OAuth 2.0
class AuthGoogleService {
  final GoogleSignIn _googleSignIn;
  final http.Client _httpClient;
  final AuthGoogleMockService _mockService = AuthGoogleMockService();

  // Escopos do Google (incluindo YouTube API)
  static const List<String> _scopes = [
    'email',
    'profile',
    // YouTube API Scopes
    'https://www.googleapis.com/auth/youtube.readonly', // Ler dados do YouTube
    'https://www.googleapis.com/auth/youtube.force-ssl', // Acesso completo via HTTPS
    // Adicionar mais escopos conforme necessidade:
    // 'https://www.googleapis.com/auth/youtube.upload',       // Upload de vídeos
    // 'https://www.googleapis.com/auth/youtube',              // Gerenciar conta
    // 'https://www.googleapis.com/auth/youtube.channel-memberships.creator', // Membros do canal
  ];

  // Usar variável de ambiente para autenticação
  static String get baseUrl => EnvKeyHelperConfig.mocApi3Auth;

  AuthGoogleService(this._googleSignIn, this._httpClient);

  /// Factory para criar instância com configuração padrão
  factory AuthGoogleService.defaultInstance() {
    final googleSignIn = GoogleSignIn(
      scopes: _scopes,
      // Client IDs são configurados automaticamente via:
      // - Android: google-services.json OU hardcoded abaixo
      // - iOS: Info.plist + Reversed Client ID
      // - Web: index.html meta tag
    );

    return AuthGoogleService(googleSignIn, http.Client());
  }

  /// Autentica usuário com Google e solicita escopos YouTube
  Future<AuthGoogleUserData> signInWithGoogle() async {
    // 🎭 MOCK: Usar autenticação fake se habilitado
    if (AuthGoogleMockService.isMockEnabled) {
      if (kDebugMode) {
        print('🎭 [AuthGoogleService] MODO MOCK ATIVADO - Usando dados fake');
      }
      return await _mockService.signInWithGoogle();
    }

    try {
      if (kDebugMode) {
        print('🔐 [AuthGoogleService] Iniciando Google Sign-In...');
        print('📜 [AuthGoogleService] Escopos solicitados: $_scopes');
      }

      // 1. Verifica se já está logado (silent sign-in)
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      // 2. Se não está logado, mostra fluxo de autenticação
      account ??= await _googleSignIn.signIn();

      // 3. Usuário cancelou o login
      if (account == null) {
        if (kDebugMode) {
          print('❌ [AuthGoogleService] Login cancelado pelo usuário');
        }
        throw GoogleOAuthException('Login cancelado pelo usuário');
      }

      if (kDebugMode) {
        print('✅ [AuthGoogleService] Usuário autenticado: ${account.email}');
      }

      // 4. Obter tokens OAuth
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.accessToken == null || auth.accessToken!.isEmpty) {
        throw GoogleOAuthException('Falha ao obter access token do Google');
      }

      if (kDebugMode) {
        print('🔑 [AuthGoogleService] Access Token obtido: ${auth.accessToken?.substring(0, 20)}...');
        print('🔑 [AuthGoogleService] ID Token obtido: ${auth.idToken?.substring(0, 20) ?? 'null'}...');
      }

      // 5. Retornar dados do usuário
      return AuthGoogleUserData(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: auth.accessToken,
        idToken: auth.idToken,
        scopes: [], // grantedScopes não disponível nesta versão
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthGoogleService] Erro ao fazer login com Google: $e');
      }

      if (e is GoogleOAuthException) {
        rethrow;
      }

      throw GoogleOAuthException('Erro ao autenticar com Google: $e');
    }
  }

  /// Envia dados OAuth para backend e obtém JWT do app
  Future<AuthCredentialsLoginResponse> authenticateWithBackend(
    AuthGoogleUserData googleData,
  ) async {
    try {
      final request = AuthGoogleOAuthRequest(
        email: googleData.email,
        name: googleData.firstName.isNotEmpty ? googleData.firstName : googleData.email.split('@').first,
        surname: googleData.surname,
        oauthProvider: 'GOOGLE',
        oauthId: googleData.id,
        accessToken: googleData.accessToken!,
        idToken: googleData.idToken,
      );

      if (kDebugMode) {
        print('🌐 [AuthGoogleService] Autenticando com backend...');
        print('📍 [AuthGoogleService] URL: $baseUrl/auth/oauth/google');
        print('📤 [AuthGoogleService] Request: ${request.toString()}');
      }

      // POST para endpoint de OAuth do backend
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/auth/oauth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (kDebugMode) {
        print('📥 [AuthGoogleService] Status Code: ${response.statusCode}');
        final bodyPreview = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        print('📥 [AuthGoogleService] Response: $bodyPreview');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final loginResponse = AuthCredentialsLoginResponse.fromJson(jsonResponse);

        if (kDebugMode) {
          print('✅ [AuthGoogleService] Autenticação com backend bem-sucedida');
          print('🔑 [AuthGoogleService] App Token: ${loginResponse.token.substring(0, 20)}...');
        }

        return loginResponse;
      } else if (response.statusCode == 401) {
        throw AuthException(
          'Credenciais OAuth inválidas',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorJson = jsonDecode(response.body);
        final errorMessage = errorJson['message'] ?? 'Dados OAuth inválidos';
        throw AuthException(
          errorMessage,
          statusCode: response.statusCode,
        );
      } else if (response.statusCode >= 500) {
        throw AuthException(
          'Erro no servidor. Tente novamente mais tarde',
          statusCode: response.statusCode,
        );
      } else {
        throw AuthException(
          'Erro ao autenticar com backend: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthGoogleService] Erro ao autenticar com backend: $e');
      }
      throw AuthException('Erro de conexão com servidor: $e');
    }
  }

  /// Logout do Google
  Future<void> signOut() async {
    // 🎭 MOCK: Usar logout fake se habilitado
    if (AuthGoogleMockService.isMockEnabled) {
      return await _mockService.signOut();
    }

    try {
      if (kDebugMode) {
        print('🚪 [AuthGoogleService] Fazendo logout do Google...');
      }

      await _googleSignIn.signOut();

      if (kDebugMode) {
        print('✅ [AuthGoogleService] Logout realizado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthGoogleService] Erro ao fazer logout (ignorando): $e');
      }
      // Ignorar erros de logout, pois o token será limpo localmente de qualquer forma
    }
  }

  /// Desconecta completamente a conta Google (revoga acesso)
  Future<void> disconnect() async {
    // 🎭 MOCK: Usar disconnect fake se habilitado
    if (AuthGoogleMockService.isMockEnabled) {
      return await _mockService.disconnect();
    }

    try {
      if (kDebugMode) {
        print('🔌 [AuthGoogleService] Desconectando conta Google...');
      }

      await _googleSignIn.disconnect();

      if (kDebugMode) {
        print('✅ [AuthGoogleService] Desconexão realizada com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthGoogleService] Erro ao desconectar (ignorando): $e');
      }
    }
  }

  /// Verifica se usuário está logado no Google
  bool get isSignedIn {
    if (AuthGoogleMockService.isMockEnabled) {
      return _mockService.isSignedIn;
    }
    return _googleSignIn.currentUser != null;
  }

  /// Obtém usuário atual (se logado)
  GoogleSignInAccount? get currentUser {
    if (AuthGoogleMockService.isMockEnabled) {
      return null; // Mock não tem usuário real
    }
    return _googleSignIn.currentUser;
  }

  /// Verifica se está em modo mock
  static bool get isMockMode => AuthGoogleMockService.isMockEnabled;
}
