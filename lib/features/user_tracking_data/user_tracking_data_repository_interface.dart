import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_model.dart';

/// Interface do Repository de User Tracking Data (Princípio de Inversão de Dependência - SOLID)
/// Define o contrato para operações de rastreamento de comportamento do usuário
/// 
/// Documentação: .local_knowledge/FLUTTER_USER_TRACKING_MVP_GUIDE.md
/// Base URL: /api/v1/user-rankings
/// 
/// 🎯 Responsabilidade: Sistema de Ranking/Gamificação baseado em pontuação
/// ⚠️ Diferença de user_engagement: 
///    - user_engagement: rastreia eventos individuais (clicks, views, etc.)
///    - user_tracking_data: rastreia métricas agregadas (score, streak, dias ativos)
abstract class UserTrackingDataRepositoryInterface {
  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 CRUD BÁSICO
  // ═══════════════════════════════════════════════════════════════════════════

  /// ✅ Cria registro inicial de ranking para novo usuário
  /// 
  /// Endpoint: POST /api/v1/user-rankings
  /// 
  /// Quando usar: Primeira vez que usuário loga (após signup ou primeiro login)
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final tracking = UserTrackingDataModel(
  ///   userId: currentUserId,
  ///   lastLoginAt: DateTime.now(),
  ///   lastActivityAt: DateTime.now(),
  ///   totalActiveDays: 1,
  ///   consecutiveDaysStreak: 1,
  ///   totalScore: 1,
  /// );
  /// final result = await createUserTracking(tracking);
  /// ```
  /// 
  /// Erros esperados:
  /// - 409 Conflict: Usuário já tem ranking (usar updateUserTracking)
  /// - 400 Bad Request: Dados inválidos (verificar userId)
  /// - 401 Unauthorized: Token JWT inválido
  Future<UserTrackingDataModel?> createUserTracking(
      UserTrackingDataModel tracking);

  /// Atualiza ranking existente (timestamps, contadores)
  /// 
  /// Endpoint: PUT /api/v1/user-rankings/{id}
  /// 
  /// Quando usar: Login recorrente para atualizar lastLoginAt, totalActiveDays, streak
  /// 
  /// ⚠️ NOTA: Este endpoint NÃO incrementa totalScore (usar addPoints)
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final updated = existing.copyWith(
  ///   lastLoginAt: DateTime.now(),
  ///   totalActiveDays: existing.totalActiveDays + 1,
  ///   consecutiveDaysStreak: newStreak,
  /// );
  /// await updateUserTracking(rankingId, updated);
  /// ```
  Future<UserTrackingDataModel?> updateUserTracking(
      String id, UserTrackingDataModel tracking);

  /// Busca ranking de um usuário específico
  /// 
  /// Endpoint: GET /api/v1/user-rankings/user/{userId}
  /// 
  /// Quando usar: 
  /// - Verificar se usuário já tem ranking (antes de criar)
  /// - Carregar estatísticas para exibir em tela de perfil
  /// - Cache local de dados do ranking
  /// 
  /// Retorna null se usuário não tem ranking (404 Not Found)
  Future<UserTrackingDataModel?> getUserTrackingByUserId(String userId);

  /// Busca ranking por ID do registro
  /// 
  /// Endpoint: GET /api/v1/user-rankings/{id}
  /// 
  /// Quando usar: Após criar/atualizar, para obter estado completo
  Future<UserTrackingDataModel?> getUserTrackingById(String id);

  /// Deleta ranking (soft delete)
  /// 
  /// Endpoint: DELETE /api/v1/user-rankings/{id}
  /// 
  /// Quando usar: GDPR/LGPD - usuário solicita apagar dados de gamificação
  Future<bool> deleteUserTracking(String id);

  /// Restaura ranking deletado (soft delete)
  /// 
  /// Endpoint: PUT /api/v1/user-rankings/{id}/restore
  Future<UserTrackingDataModel?> restoreUserTracking(String id);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 OPERAÇÕES ESPECÍFICAS DE GAMIFICAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  /// ✅ PRINCIPAL: Adiciona pontos ao score do usuário
  /// 
  /// Endpoint: POST /api/v1/user-rankings/user/{userId}/add-points?points={valor}
  /// 
  /// **🆕 PHASE B: Aceita query param `reason` opcional para auditoria**
  /// Endpoint completo: POST /api/v1/user-rankings/user/{userId}/add-points?points={valor}&reason={snake_case}
  /// 
  /// Quando usar:
  /// - Login diário: +1 ponto (reason: "daily_login")
  /// - Primeira atividade do dia: +1 ponto (reason: "first_activity")
  /// - Completar streak de 7 dias: +5 pontos (bônus)
  /// - Wizard entry: +2 pontos (reason: "wizard_entry")
  /// - Profile 50%: +3 pontos (reason: "profile_50_percent")
  /// - Profile 100%: +10 pontos (reason: "profile_100_percent")
  /// 
  /// ⚠️ Backend atualiza automaticamente:
  /// - totalScore (incrementa)
  /// - scoreUpdatedAt (timestamp atual)
  /// - engagementLevel (recalcula baseado em novo score)
  /// - points_history (registra reason para auditoria se fornecido)
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// // Registrar login (sem reason - legado)
  /// final updated = await addPoints(userId, 1);
  /// print('Novo score: ${updated.totalScore}');
  /// print('Nível: ${updated.engagementLevel}');
  /// 
  /// // 🆕 PHASE B: Adicionar pontos COM reason (auditável)
  /// await addPoints(userId, 2, reason: 'wizard_entry');
  /// 
  /// // Bônus de streak
  /// if (streak == 7) {
  ///   await addPoints(userId, 5);
  /// }
  /// ```
  Future<UserTrackingDataModel?> addPoints(String userId, int points, {String? reason});

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏆 RANKING E LEADERBOARDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Busca top usuários ordenados por score (ranking global)
  /// 
  /// Endpoint: GET /api/v1/user-rankings/top?limit={n}
  /// 
  /// Quando usar: Exibir leaderboard/ranking na UI
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final top10 = await getTopUsersByScore(limit: 10);
  /// for (var rank in top10) {
  ///   print('${rank.userId}: ${rank.totalScore} pontos');
  /// }
  /// ```
  Future<List<UserTrackingDataModel>> getTopUsersByScore({int limit = 10});

  /// Busca usuários por nível de engajamento
  /// 
  /// Endpoint: GET /api/v1/user-rankings/engagement/{level}
  /// 
  /// Quando usar: Filtrar usuários por engajamento (analytics, segmentação)
  /// 
  /// @param level - LOW, MEDIUM, HIGH, VERY_HIGH
  Future<List<UserTrackingDataModel>> getUsersByEngagementLevel(String level);

  /// Busca todos os rankings (paginado)
  /// 
  /// Endpoint: GET /api/v1/user-rankings
  /// 
  /// Quando usar: Admin dashboard, analytics gerais
  /// 
  /// ⚠️ Pode retornar muitos dados - usar com cautela
  Future<List<UserTrackingDataModel>> getAllUserTrackings();

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔮 FUTUROS (NÃO IMPLEMENTADOS NO MVP)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Busca usuários por potencial de conversão (FUTURE - não no MVP)
  /// 
  /// Endpoint: GET /api/v1/user-rankings/conversion/{potential}
  /// 
  /// Campo `conversionPotential` ainda não rastreado no MVP
  /// Implementar em versões futuras quando adicionar:
  /// - totalContentViews, favoriteCategory, avgDailyUsageMinutes, etc.
  // Future<List<UserTrackingDataModel>> getUsersByConversionPotential(String potential);
}
