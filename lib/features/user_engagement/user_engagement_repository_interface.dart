import 'package:portugal_guide/features/user_engagement/user_engagement_model.dart';

/// Interface do Repository de User Engagement (Princípio de Inversão de Dependência - SOLID)
/// Define o contrato para operações de engajamento com a API
/// 
/// Documentação: FLUTTER_ENGAGEMENT_API_INTEGRATION_GUIDE.md
/// Base URL: /api/v1/engagements
abstract class UserEngagementRepositoryInterface {
  /// ✅ PRINCIPAL: Cria um novo registro de engajamento
  /// Usado quando o usuário clica em um conteúdo
  /// 
  /// POST /api/v1/engagements
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final engagement = UserEngagementModel(
  ///   userId: currentUserId,
  ///   contentId: videoId,
  ///   engagementType: UserEngagementType.clickToView,
  ///   deviceType: 'mobile',
  ///   platform: Platform.isAndroid ? 'Android' : 'iOS',
  ///   source: 'home',
  ///   engagedAt: DateTime.now(),
  /// );
  /// await createEngagement(engagement);
  /// ```
  Future<UserEngagementModel?> createEngagement(UserEngagementModel engagement);

  /// Atualiza um engajamento existente (ex: adicionar tempo de visualização)
  /// 
  /// PUT /api/v1/engagements/{id}
  Future<UserEngagementModel?> updateEngagement(String engagementId, Map<String, dynamic> updates);

  /// Busca engajamentos de um conteúdo específico
  /// 
  /// GET /api/v1/engagements/content/{contentId}
  Future<List<UserEngagementModel>> getContentEngagements(String contentId);

  /// Busca estatísticas de um conteúdo (total de likes, views, etc.)
  /// 
  /// GET /api/v1/engagements/content/{contentId}/stats
  Future<Map<String, dynamic>> getContentStats(String contentId);

  /// Busca engagements de um usuário (histórico completo)
  /// 
  /// GET /api/v1/engagements/user/{userId}
  Future<List<UserEngagementModel>> getUserEngagements(String userId);

  /// Busca engajamentos recentes de um usuário (útil para "Assistidos Recentemente")
  /// 
  /// GET /api/v1/engagements/user/{userId}/recent?days=7
  Future<List<UserEngagementModel>> getUserRecentEngagements(String userId, {int days = 7});

  /// Busca estatísticas do usuário (total de engagements, média de conclusão, etc.)
  /// 
  /// GET /api/v1/engagements/user/{userId}/stats
  Future<Map<String, dynamic>> getUserStats(String userId);

  /// Busca conteúdos mais interagidos pelo usuário (para recomendações)
  /// 
  /// GET /api/v1/engagements/user/{userId}/top-contents?limit=10
  Future<List<Map<String, dynamic>>> getUserTopContents(String userId, {int limit = 10});

  /// Busca um engajamento específico por ID
  /// 
  /// GET /api/v1/engagements/{id}
  Future<UserEngagementModel?> getEngagementById(String engagementId);

  /// Deleta um engajamento (soft delete)
  /// 
  /// DELETE /api/v1/engagements/{id}
  Future<bool> deleteEngagement(String engagementId);
}
