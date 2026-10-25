import 'package:portugal_guide/features/user/user_details_model.dart';
import 'user_ranking_summary_model.dart';

/// Sugestão exibida na seção "Sugestões": ranking (`/user-rankings/top`)
/// enriquecido com a identidade de `/users/{id}/details`.
class RelationSuggestionData {
  final String userId;
  final String fullName;

  /// Posição 1-based no leaderboard (a API não envia `rankPosition`).
  final int rankPosition;
  final int totalScore;
  final String engagementLevel;

  const RelationSuggestionData({
    required this.userId,
    required this.fullName,
    required this.rankPosition,
    required this.totalScore,
    required this.engagementLevel,
  });

  factory RelationSuggestionData.fromRankingAndDetails({
    required UserRankingSummaryModel ranking,
    required UserDetailsModel details,
    required int rankPosition,
  }) {
    final String composedName = '${details.name} ${details.surname}'.trim();
    return RelationSuggestionData(
      userId: ranking.userId,
      fullName: details.fullName.trim().isNotEmpty ? details.fullName.trim() : composedName,
      rankPosition: rankPosition,
      totalScore: ranking.totalScore,
      engagementLevel: ranking.engagementLevel,
    );
  }

  String get initial => fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
}
