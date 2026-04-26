// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/user_choice/user_choice_repository_interface.dart';

/// Decisão de roteamento para botão "RELAÇÕES"
enum RelationRouteDecision {
  /// Usuário NÃO possui user-choice → redirecionar para welcome/onboarding
  welcome,

  /// Usuário JÁ possui user-choice → redirecionar para connections network
  connections,
}

/// Guard/Controller para lógica de navegação condicional do botão "RELAÇÕES"
/// 
/// 🎯 Responsabilidade:
/// - Verificar se usuário logado possui registro de user-choice no backend
/// - Retornar decisão de rota: welcome (onboarding) ou connections (network)
/// 
/// 📍 Localização no projeto:
/// - Domain: lib/features/user_choice/
/// - Usado por: HomeContentTabScreen (botão "RELAÇÕES" index 1)
/// 
/// 🏗️ Arquitetura:
/// - Usa UserChoiceRepository.getUserActiveProfile(userId)
/// - Injeta via GetIt (singleton durante sessão)
/// - Cacheia resultado durante sessão para evitar chamadas repetidas
/// 
/// 🔄 Comportamento:
/// - Primeira chamada: consulta backend via repository
/// - Chamadas subsequentes: retorna cache
/// - Erro de rede: fallback para welcome (onboarding seguro)
/// 
/// 🚨 Tratamento de Erros:
/// - Network failure → welcome (assume novo usuário)
/// - 404 Not Found → welcome (registro não existe)
/// - 200 OK com null → welcome (perfil deletado ou inválido)
/// - 200 OK com data → connections (perfil ativo encontrado)
/// 
/// 📚 Documentação Arquitetural:
/// - x_temp_files/DESIGN_RELATIONS_TAB_ROUTING.md
class UserChoiceNavigationGuard {
  final UserChoiceRepositoryInterface _repository;
  final AuthTokenManager _tokenManager;

  /// Cache de decisão durante sessão (evita múltiplas chamadas HTTP)
  RelationRouteDecision? _cachedDecision;

  UserChoiceNavigationGuard({
    required UserChoiceRepositoryInterface repository,
    required AuthTokenManager tokenManager,
  })  : _repository = repository,
        _tokenManager = tokenManager;

  /// Verifica se usuário possui user-choice e retorna decisão de rota
  /// 
  /// Fluxo:
  /// 1. Verifica cache (retorna imediatamente se disponível)
  /// 2. Obtém userId do token JWT
  /// 3. Consulta backend via repository.getUserActiveProfile(userId)
  /// 4. Processa resposta e cacheia decisão
  /// 
  /// Retorna:
  /// - [RelationRouteDecision.welcome] → Navegar para main_relation_welcome_screen
  /// - [RelationRouteDecision.connections] → Navegar para connections_network_screen
  Future<RelationRouteDecision> checkRouteDecision() async {
    // ✅ Retornar cache se disponível (evita chamadas repetidas)
    if (_cachedDecision != null) {
      if (kDebugMode) {
        print('🔄 [UserChoiceNavigationGuard] Usando decisão em cache: $_cachedDecision');
      }
      return _cachedDecision!;
    }

    try {
      // 1. Obter userId do token JWT
      final userId = _tokenManager.getUserId();
      
      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ [UserChoiceNavigationGuard] userId é null → redirect to welcome');
        }
        _cachedDecision = RelationRouteDecision.welcome;
        return _cachedDecision!;
      }

      if (kDebugMode) {
        print('📍 [UserChoiceNavigationGuard] Verificando user-choice para userId: $userId');
      }

      // 2. Consultar backend via repository
      final userChoice = await _repository.getUserActiveProfile(userId);

      // 3. Processar resposta e determinar rota
      if (userChoice != null) {
        // ✅ Perfil ativo encontrado → connections network
        if (kDebugMode) {
          print('✅ [UserChoiceNavigationGuard] user-choice encontrado (${userChoice.profileType}) → connections');
        }
        _cachedDecision = RelationRouteDecision.connections;
      } else {
        // ❌ Perfil não existe ou deletado → onboarding
        if (kDebugMode) {
          print('❌ [UserChoiceNavigationGuard] user-choice NÃO encontrado → welcome/onboarding');
        }
        _cachedDecision = RelationRouteDecision.welcome;
      }

      return _cachedDecision!;
    } catch (e) {
      // 🚨 Erro de rede ou outro → fallback para onboarding (UX segura)
      if (kDebugMode) {
        print('🚨 [UserChoiceNavigationGuard] Erro ao verificar user-choice: $e');
        print('   Fallback: redirect to welcome (onboarding)');
      }
      _cachedDecision = RelationRouteDecision.welcome;
      return _cachedDecision!;
    }
  }

  /// Limpa cache de decisão (útil após logout ou criação de user-choice)
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// // Após usuário completar wizard de onboarding
  /// final guard = injector<UserChoiceNavigationGuard>();
  /// guard.clearCache();
  /// ```
  void clearCache() {
    if (kDebugMode) {
      print('🗑️ [UserChoiceNavigationGuard] Cache limpo');
    }
    _cachedDecision = null;
  }

  /// Força rota de destino (útil para testes ou feature flags)
  /// 
  /// ⚠️ ATENÇÃO: Use apenas em cenários de desenvolvimento/teste
  void forceDecision(RelationRouteDecision decision) {
    if (kDebugMode) {
      print('🎯 [UserChoiceNavigationGuard] Decisão forçada: $decision');
    }
    _cachedDecision = decision;
  }
}
