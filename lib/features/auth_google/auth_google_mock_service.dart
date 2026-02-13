import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/auth_google/auth_google_model.dart';

/// Mock Service para autenticação Google (desenvolvimento sem credenciais reais)
/// 
/// ⚠️ USO: Apenas para desenvolvimento/testes locais
/// ⚠️ NÃO usar em produção
/// ⚠️ Desabilitar quando tiver Client IDs reais do Google Cloud Console
class AuthGoogleMockService {
  static const bool _enableMock = true; // 🔴 Alterar para false quando tiver IDs reais

  /// Simula autenticação com Google (retorna dados fake)
  Future<AuthGoogleUserData> signInWithGoogle() async {
    if (!_enableMock) {
      throw Exception('Mock desabilitado. Configure Client IDs reais no Google Cloud Console.');
    }

    if (kDebugMode) {
      print('🎭 [AuthGoogleMockService] MOCK ATIVADO - Simulando login Google...');
    }

    // Simular delay de rede (500ms)
    await Future.delayed(const Duration(milliseconds: 500));

    // Dados fake de um usuário Google
    final mockUserData = AuthGoogleUserData(
      id: 'mock_google_user_123456789',
      email: 'mockuser@gmail.com',
      displayName: 'Mock User Dev',
      photoUrl: 'https://i.pravatar.cc/150?img=12', // Avatar fake
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      idToken: 'mock_id_token_${DateTime.now().millisecondsSinceEpoch}',
      scopes: [
        'email',
        'profile',
        'https://www.googleapis.com/auth/youtube.readonly',
        'https://www.googleapis.com/auth/youtube.force-ssl',
      ],
    );

    if (kDebugMode) {
      print('✅ [AuthGoogleMockService] MOCK login bem-sucedido');
      print('👤 [AuthGoogleMockService] Usuário: ${mockUserData.displayName}');
      print('📧 [AuthGoogleMockService] Email: ${mockUserData.email}');
    }

    return mockUserData;
  }

  /// Simula logout do Google
  Future<void> signOut() async {
    if (!_enableMock) return;

    if (kDebugMode) {
      print('🚪 [AuthGoogleMockService] MOCK Logout');
    }

    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Simula desconexão da conta Google
  Future<void> disconnect() async {
    if (!_enableMock) return;

    if (kDebugMode) {
      print('🔌 [AuthGoogleMockService] MOCK Disconnect');
    }

    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Verifica se mock está habilitado
  static bool get isMockEnabled => _enableMock;

  /// Verifica se "usuário" está logado (sempre false no mock)
  bool get isSignedIn => false;
}
