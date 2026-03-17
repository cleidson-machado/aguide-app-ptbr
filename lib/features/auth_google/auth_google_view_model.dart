import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_model.dart';
import 'package:portugal_guide/features/auth_google/auth_google_model.dart';
import 'package:portugal_guide/features/auth_google/auth_google_service.dart';

/// ViewModel responsável pela lógica de login com Google OAuth
class AuthGoogleViewModel extends ChangeNotifier {
  final AuthGoogleService _service;
  final AuthTokenManager _tokenManager;

  OAuthState _state = OAuthState.initial;
  String? _errorMessage;
  AuthCredentialsLoginResponse? _loginResponse;
  AuthGoogleUserData? _googleUserData;

  OAuthState get state => _state;
  String? get errorMessage => _errorMessage;
  AuthCredentialsLoginResponse? get loginResponse => _loginResponse;
  AuthGoogleUserData? get googleUserData => _googleUserData;
  bool get isLoading => _state == OAuthState.loading;
  bool get isAuthenticated => _tokenManager.isAuthenticated();

  AuthGoogleViewModel({
    required AuthGoogleService service,
    required AuthTokenManager tokenManager,
  })  : _service = service,
        _tokenManager = tokenManager;

  /// Login com Google (inclui escopos YouTube)
  Future<void> signInWithGoogle() async {
    if (kDebugMode) {
      print('🚀 [AuthGoogleViewModel] Iniciando login com Google...');
    }

    _state = OAuthState.loading;
    _errorMessage = null;
    _googleUserData = null;
    notifyListeners();

    try {
      // 1. Autenticar com Google e obter dados do usuário
      if (kDebugMode) {
        print('📱 [AuthGoogleViewModel] Passo 1: Autenticando com Google...');
      }
      final googleData = await _service.signInWithGoogle();
      _googleUserData = googleData;

      if (kDebugMode) {
        print('✅ [AuthGoogleViewModel] Usuário Google: ${googleData.email}');
        print('📋 [AuthGoogleViewModel] Escopos concedidos: ${googleData.scopes}');
      }

      // 2. Enviar dados OAuth para backend e obter JWT do app
      if (kDebugMode) {
        print('📱 [AuthGoogleViewModel] Passo 2: Autenticando com backend...');
      }
      final response = await _service.authenticateWithBackend(googleData);
      _loginResponse = response;

      if (kDebugMode) {
        print('✅ [AuthGoogleViewModel] Backend respondeu com token do app');
      }

      // 3. Salvar JWT localmente (token do app, não do Google)
      if (kDebugMode) {
        print('📱 [AuthGoogleViewModel] Passo 3: Salvando token localmente...');
      }
      final tokenSaved = await _tokenManager.saveToken(response.token);

      if (kDebugMode) {
        print('💾 [AuthGoogleViewModel] Token salvo: $tokenSaved');
      }

      // Salvar refresh token se disponível
      if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
        await _tokenManager.saveRefreshToken(response.refreshToken!);
        if (kDebugMode) {
          print('💾 [AuthGoogleViewModel] Refresh token salvo');
        }
      }

      // Salvar email do usuário
      final userEmail = response.user?.email ?? googleData.email;
      await _tokenManager.saveUserEmail(userEmail);

      // Salvar nome do usuário se disponível
      final userName = response.user?.name ?? googleData.displayName;
      if (userName != null && userName.isNotEmpty) {
        await _tokenManager.saveUserName(userName);
        if (kDebugMode) {
          print('👤 [AuthGoogleViewModel] Nome salvo: $userName');
        }
      }

      if (kDebugMode) {
        print('✅ [AuthGoogleViewModel] Login com Google realizado com sucesso!');
        final userName = response.user?.name ?? googleData.displayName ?? '';
        print('👤 [AuthGoogleViewModel] Usuário: $userName');
        print('📧 [AuthGoogleViewModel] Email: $userEmail');
      }

      _state = OAuthState.success;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _state = OAuthState.error;
      _googleUserData = null;
      _loginResponse = null;

      // Mensagens de erro amigáveis
      if (e.toString().contains('cancelado')) {
        _errorMessage = 'Login cancelado';
        _state = OAuthState.cancelled;
      } else if (e.toString().contains('network') || e.toString().contains('conexão')) {
        _errorMessage = 'Erro de conexão. Verifique sua internet';
      } else if (e.toString().contains('401') || e.toString().contains('Credenciais')) {
        _errorMessage = 'Falha na autenticação. Tente novamente';
      } else if (e.toString().contains('servidor') || e.toString().contains('500')) {
        _errorMessage = 'Erro no servidor. Tente novamente mais tarde';
      } else {
        _errorMessage = 'Erro ao fazer login com Google';
      }

      if (kDebugMode) {
        print('❌ [AuthGoogleViewModel] Erro no login: $e');
        print('💬 [AuthGoogleViewModel] Mensagem para usuário: $_errorMessage');
      }

      notifyListeners();
    }
  }

  /// Logout (limpa tokens do app e do Google)
  Future<void> signOut() async {
    if (kDebugMode) {
      print('🚪 [AuthGoogleViewModel] Fazendo logout...');
    }

    try {
      // Logout do Google
      await _service.signOut();

      // Limpar tokens do app
      await _tokenManager.clearAuth();

      _state = OAuthState.initial;
      _errorMessage = null;
      _loginResponse = null;
      _googleUserData = null;

      if (kDebugMode) {
        print('✅ [AuthGoogleViewModel] Logout realizado com sucesso');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthGoogleViewModel] Erro ao fazer logout: $e');
      }
      // Mesmo com erro, limpar estado local
      _state = OAuthState.initial;
      _errorMessage = null;
      _loginResponse = null;
      _googleUserData = null;
      notifyListeners();
    }
  }

  /// Desconecta completamente a conta Google (revoga acesso)
  Future<void> disconnect() async {
    if (kDebugMode) {
      print('🔌 [AuthGoogleViewModel] Desconectando conta Google...');
    }

    try {
      await _service.disconnect();
      await _tokenManager.clearAuth();

      _state = OAuthState.initial;
      _errorMessage = null;
      _loginResponse = null;
      _googleUserData = null;

      if (kDebugMode) {
        print('✅ [AuthGoogleViewModel] Desconexão realizada com sucesso');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthGoogleViewModel] Erro ao desconectar: $e');
      }
      // Mesmo com erro, limpar estado local
      _state = OAuthState.initial;
      notifyListeners();
    }
  }

  /// Limpa mensagem de erro
  void clearError() {
    _errorMessage = null;
    if (_state == OAuthState.error || _state == OAuthState.cancelled) {
      _state = OAuthState.initial;
    }
    notifyListeners();
  }

  /// Verifica se usuário está logado no Google
  bool get isSignedInWithGoogle => _service.isSignedIn;

  @override
  void dispose() {
    if (kDebugMode) {
      print('🗑️ [AuthGoogleViewModel] Disposing...');
    }
    super.dispose();
  }
}
