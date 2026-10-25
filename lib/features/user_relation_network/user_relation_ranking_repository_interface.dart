import 'user_ranking_summary_model.dart';

/// Contrato de leitura do leaderboard para a seção "Sugestões".
abstract class UserRelationRankingRepositoryInterface {
  /// GET /api/v1/user-rankings/top?limit={limit}
  ///
  /// Retorna a lista ordenada por `totalScore` DESC (ordem garantida pelo
  /// backend). Lança exceção em falha de rede/HTTP para a UI exibir erro.
  Future<List<UserRankingSummaryModel>> getTopRankings({int limit});
}
