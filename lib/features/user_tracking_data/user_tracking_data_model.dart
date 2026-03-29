/// Model para rastreamento de comportamento do usuário (User Behavior Tracking MVP)
/// Usado para sistema de ranking/gamificação baseado em pontuação de engajamento
/// 
/// Documentação da API: .local_knowledge/FLUTTER_USER_TRACKING_MVP_GUIDE.md
/// Endpoints: /api/v1/user-rankings
/// 
/// ⚠️ IMPORTANTE: Este é o MVP - apenas campos básicos de rastreamento
/// Campos futuros (não implementados): totalContentViews, favoriteCategory, etc.
class UserTrackingDataModel {
  /// ID do registro de ranking (UUID gerado pelo backend)
  /// Opcional na criação (POST), obrigatório em atualizações (PUT)
  final String? id;

  /// ID do usuário autenticado (UUID)
  /// Chave estrangeira para tabela de usuários
  final String userId;

  /// Pontuação total acumulada do usuário
  /// Incrementa a cada ação significativa (login, completar streak, etc.)
  final int totalScore;

  /// Data/hora do último login no app (ISO 8601 com timezone UTC)
  /// Exemplo: "2026-03-29T10:30:00Z"
  final DateTime lastLoginAt;

  /// Data/hora da última atividade no app (navegação, interação, etc.)
  /// Atualizado periodicamente durante uso ativo
  final DateTime lastActivityAt;

  /// Total de dias distintos que o usuário usou o app
  /// Incrementa apenas 1x por dia (não duplica se logar múltiplas vezes)
  final int totalActiveDays;

  /// Dias consecutivos de uso até hoje (streak)
  /// Reseta para 1 se quebrar sequência (gap > 1 dia)
  /// Exemplo: login dia 1, 2, 3 → streak = 3 | pula dia 4 → streak volta para 1
  final int consecutiveDaysStreak;

  /// Nível de engajamento calculado automaticamente pela API
  /// Valores: LOW, MEDIUM, HIGH, VERY_HIGH
  /// ⚠️ NÃO calcular no Flutter - backend retorna valor calculado
  final String engagementLevel;

  /// Data/hora da última atualização de score (ISO 8601 UTC)
  /// Atualizado automaticamente pelo backend ao chamar /add-points
  final DateTime? scoreUpdatedAt;

  /// Data/hora de criação do registro (retornado pela API)
  final DateTime? createdAt;

  /// Data/hora da última atualização do registro (retornado pela API)
  final DateTime? updatedAt;

  const UserTrackingDataModel({
    this.id,
    required this.userId,
    this.totalScore = 0,
    required this.lastLoginAt,
    required this.lastActivityAt,
    this.totalActiveDays = 1,
    this.consecutiveDaysStreak = 1,
    this.engagementLevel = 'LOW',
    this.scoreUpdatedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Converte JSON da API para Model
  /// 
  /// Exemplo de JSON da API:
  /// ```json
  /// {
  ///   "id": "7c9e6679-7425-40de-944b-e07fc1f9a6b0",
  ///   "userId": "550e8400-e29b-41d4-a716-446655440000",
  ///   "totalScore": 125,
  ///   "lastLoginAt": "2026-03-29T10:30:00Z",
  ///   "lastActivityAt": "2026-03-29T10:45:00Z",
  ///   "totalActiveDays": 12,
  ///   "consecutiveDaysStreak": 5,
  ///   "engagementLevel": "MEDIUM",
  ///   "scoreUpdatedAt": "2026-03-29T10:45:00Z",
  ///   "createdAt": "2026-03-20T08:00:00Z",
  ///   "updatedAt": "2026-03-29T10:45:00Z"
  /// }
  /// ```
  factory UserTrackingDataModel.fromJson(Map<String, dynamic> json) {
    return UserTrackingDataModel(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      totalScore: json['totalScore'] as int? ?? 0,
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      totalActiveDays: json['totalActiveDays'] as int? ?? 1,
      consecutiveDaysStreak: json['consecutiveDaysStreak'] as int? ?? 1,
      engagementLevel: json['engagementLevel'] as String? ?? 'LOW',
      scoreUpdatedAt: json['scoreUpdatedAt'] != null
          ? DateTime.parse(json['scoreUpdatedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converte Model para JSON para enviar à API
  /// 
  /// Usado em:
  /// - POST /api/v1/user-rankings (criar ranking inicial)
  /// - PUT /api/v1/user-rankings/{id} (atualizar timestamps/contadores)
  /// 
  /// Campos opcionais são incluídos apenas se não-null
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'totalScore': totalScore,
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'totalActiveDays': totalActiveDays,
      'consecutiveDaysStreak': consecutiveDaysStreak,
      'engagementLevel': engagementLevel,
      if (scoreUpdatedAt != null)
        'scoreUpdatedAt': scoreUpdatedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Cria uma cópia com campos modificados
  /// 
  /// Útil para:
  /// - Atualizar lastActivityAt sem recriar objeto inteiro
  /// - Incrementar totalActiveDays localmente antes de enviar para API
  UserTrackingDataModel copyWith({
    String? id,
    String? userId,
    int? totalScore,
    DateTime? lastLoginAt,
    DateTime? lastActivityAt,
    int? totalActiveDays,
    int? consecutiveDaysStreak,
    String? engagementLevel,
    DateTime? scoreUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserTrackingDataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalScore: totalScore ?? this.totalScore,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      consecutiveDaysStreak:
          consecutiveDaysStreak ?? this.consecutiveDaysStreak,
      engagementLevel: engagementLevel ?? this.engagementLevel,
      scoreUpdatedAt: scoreUpdatedAt ?? this.scoreUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Representação em String para debug
  @override
  String toString() {
    return 'UserTrackingDataModel('
        'id: $id, '
        'userId: $userId, '
        'totalScore: $totalScore, '
        'engagementLevel: $engagementLevel, '
        'streak: $consecutiveDaysStreak, '
        'activeDays: $totalActiveDays'
        ')';
  }

  /// Comparação de igualdade (útil para testes)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserTrackingDataModel &&
        other.id == id &&
        other.userId == userId &&
        other.totalScore == totalScore &&
        other.lastLoginAt == lastLoginAt &&
        other.lastActivityAt == lastActivityAt &&
        other.totalActiveDays == totalActiveDays &&
        other.consecutiveDaysStreak == consecutiveDaysStreak &&
        other.engagementLevel == engagementLevel;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      totalScore,
      lastLoginAt,
      lastActivityAt,
      totalActiveDays,
      consecutiveDaysStreak,
      engagementLevel,
    );
  }
}

/// Enum para níveis de engajamento (referência visual)
/// ⚠️ NÃO usar para cálculos - backend retorna String
/// Calculado automaticamente pela API conforme:
/// - VERY_HIGH: totalScore >= 1000 OU consecutiveDaysStreak >= 30
/// - HIGH: totalScore >= 500 OU consecutiveDaysStreak >= 14
/// - MEDIUM: totalScore >= 100 OU streak >= 7
/// - LOW: demais casos
enum UserEngagementLevel {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH'),
  veryHigh('VERY_HIGH');

  final String value;
  const UserEngagementLevel(this.value);

  /// Emoji visual para UI
  String get emoji {
    switch (this) {
      case UserEngagementLevel.low:
        return '🌱';
      case UserEngagementLevel.medium:
        return '🌿';
      case UserEngagementLevel.high:
        return '🌳';
      case UserEngagementLevel.veryHigh:
        return '🏆';
    }
  }

  /// Nome traduzível (usar com i18n)
  String get displayName {
    switch (this) {
      case UserEngagementLevel.low:
        return 'Iniciante';
      case UserEngagementLevel.medium:
        return 'Ativo';
      case UserEngagementLevel.high:
        return 'Engajado';
      case UserEngagementLevel.veryHigh:
        return 'Campeão';
    }
  }

  /// Converte string da API para enum
  static UserEngagementLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'VERY_HIGH':
        return UserEngagementLevel.veryHigh;
      case 'HIGH':
        return UserEngagementLevel.high;
      case 'MEDIUM':
        return UserEngagementLevel.medium;
      case 'LOW':
      default:
        return UserEngagementLevel.low;
    }
  }
}
