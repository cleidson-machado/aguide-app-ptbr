/// Recorte read-only de `UserRankingResponse` (GET /api/v1/user-rankings/top)
/// usado pela seção "Sugestões" da tela de relações.
///
/// Mantém apenas os campos necessários e faz parsing tolerante: o contrato da
/// API permite `null` em timestamps, e `UserTrackingDataModel` (feature
/// user_tracking_data) exige `lastLoginAt`/`lastActivityAt` não nulos.
class UserRankingSummaryModel {
  final String id;
  final String userId;
  final int totalScore;
  final String engagementLevel;

  const UserRankingSummaryModel({
    required this.id,
    required this.userId,
    required this.totalScore,
    required this.engagementLevel,
  });

  factory UserRankingSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserRankingSummaryModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      engagementLevel: json['engagementLevel'] as String? ?? 'LOW',
    );
  }
}
