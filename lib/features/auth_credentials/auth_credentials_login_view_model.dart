import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/auth/auth_exception.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_model.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_service.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_service.dart';

/// Estados possíveis do login
enum LoginState {
  initial,
  loading,
  success,
  error,
}

/// ViewModel responsável pela lógica de login
class AuthCredentialsLoginViewModel extends ChangeNotifier {
  final AuthCredentialsService _service;
  final AuthTokenManager _tokenManager;

  LoginState _state = LoginState.initial;
  String? _errorMessage;
  AuthCredentialsLoginResponse? _loginResponse;

  LoginState get state => _state;
  String? get errorMessage => _errorMessage;
  AuthCredentialsLoginResponse? get loginResponse => _loginResponse;
  bool get isLoading => _state == LoginState.loading;
  bool get isAuthenticated => _tokenManager.isAuthenticated();

  AuthCredentialsLoginViewModel({
    required AuthCredentialsService service,
    required AuthTokenManager tokenManager,
  })  : _service = service,
        _tokenManager = tokenManager;

  /// Realiza o login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Validação básica
    if (email.isEmpty || password.isEmpty) {
      _state = LoginState.error;
      _errorMessage = 'Email e senha são obrigatórios';
      notifyListeners();
      return;
    }

    if (!_isValidEmail(email)) {
      _state = LoginState.error;
      _errorMessage = 'Email inválido';
      notifyListeners();
      return;
    }

    _state = LoginState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.login(
        email: email,
        password: password,
      );

      // Salvar token
      final tokenSaved = await _tokenManager.saveToken(response.token);
      
      if (kDebugMode) {
        print('💾 [AuthCredentialsLoginViewModel] Token salvo: $tokenSaved');
        print('🔍 [AuthCredentialsLoginViewModel] Verificando token salvo: ${_tokenManager.getToken()?.substring(0, 20)}...');
      }
      
      // Salvar refresh token se disponível
      if (response.refreshToken != null) {
        await _tokenManager.saveRefreshToken(response.refreshToken!);
      }

      // Salvar email do usuário
      if (response.user?.email != null) {
        await _tokenManager.saveUserEmail(response.user!.email!);
      }

      // Salvar nome do usuário se disponível
      if (response.user?.name != null && response.user!.name!.isNotEmpty) {
        await _tokenManager.saveUserName(response.user!.name!);
        if (kDebugMode) {
          print('👤 [AuthCredentialsLoginViewModel] Nome salvo: ${response.user!.name}');
        }
      }

      // ✅ TRACKING: Registrar login no sistema de ranking/gamificação
      // ⚠️ NÃO bloqueia o login - erros são logados mas não propagados
      if (response.user?.id != null) {
        try {
          final trackingService = injector<UserTrackingDataService>();
          await trackingService.trackLoginEvent(response.user!.id!);

          if (kDebugMode) {
            print('📊 [AuthCredentialsLoginViewModel] Login rastreado no sistema de ranking');
          }
        } catch (e) {
          // Apenas loga o erro - não impede o login
          if (kDebugMode) {
            print('⚠️  [AuthCredentialsLoginViewModel] Falha ao rastrear login: $e');
            print('   → Continuando login normalmente. Ranking será sincronizado depois.');
          }
        }
      }

      _loginResponse = response;
      _state = LoginState.success;
      _errorMessage = null;

      if (kDebugMode) {
        print('✅ [AuthCredentialsLoginViewModel] Login realizado com sucesso');
        print('📜 [AuthCredentialsLoginViewModel] Token: ${response.token.substring(0, 20)}...');
      }

      notifyListeners();
    } on AuthException catch (e) {
      _state = LoginState.error;
      _errorMessage = e.message;
      
      if (kDebugMode) {
        print('❌ [AuthCredentialsLoginViewModel] Erro de autenticação: ${e.message}');
      }

      notifyListeners();
    } catch (e) {
      _state = LoginState.error;
      _errorMessage = 'Erro inesperado: ${e.toString()}';
      
      if (kDebugMode) {
        print('❌ [AuthCredentialsLoginViewModel] Erro inesperado: $e');
      }

      notifyListeners();
    }
  }

  /// Realiza o logout
  Future<void> logout() async {
    final token = _tokenManager.getToken();
    
    if (token != null) {
      try {
        await _service.logout(token);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [AuthCredentialsLoginViewModel] Erro ao fazer logout no servidor: $e');
        }
      }
    }

    // Limpar dados locais
    await _tokenManager.clearAuth();
    
    _state = LoginState.initial;
    _errorMessage = null;
    _loginResponse = null;
    
    if (kDebugMode) {
      print('✅ [AuthCredentialsLoginViewModel] Logout realizado com sucesso');
    }

    notifyListeners();
  }

  /// Valida formato de email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Limpa mensagem de erro
  void clearError() {
    _errorMessage = null;
    if (_state == LoginState.error) {
      _state = LoginState.initial;
    }
    notifyListeners();
  }

  /// Retorna o token de autenticação
  String? getToken() {
    return _tokenManager.getToken();
  }

  /// Retorna o header de autorização para uso em requisições HTTP
  String? getAuthorizationHeader() {
    return _tokenManager.getAuthorizationHeader();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🗑️ [AuthCredentialsLoginViewModel] Dispose');
    }
    super.dispose();
  }
}
