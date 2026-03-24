/// Value Object: Metadados de Sessão
/// 
/// Representa informações imutáveis sobre a sessão do usuário.
/// Usado para telemetria e analytics na feature de User Engagement.
class UserEngagementSessionModel {
  final DateTime sessionStartedAt;
  final int sessionDurationSeconds;
  final int sessionDurationMinutes;
  final String? previousScreen;
  final int? screenViewCount;

  const UserEngagementSessionModel({
    required this.sessionStartedAt,
    required this.sessionDurationSeconds,
    required this.sessionDurationMinutes,
    this.previousScreen,
    this.screenViewCount,
  });

  /// Factory: Cria a partir de tempo de início da sessão
  factory UserEngagementSessionModel.fromSessionStart({
    required DateTime sessionStart,
    String? previousScreen,
    int? screenCount,
  }) {
    final now = DateTime.now();
    final sessionDuration = now.difference(sessionStart);

    return UserEngagementSessionModel(
      sessionStartedAt: sessionStart,
      sessionDurationSeconds: sessionDuration.inSeconds,
      sessionDurationMinutes: sessionDuration.inMinutes,
      previousScreen: previousScreen,
      screenViewCount: screenCount,
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementSessionModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementSessionModel(
      sessionStartedAt: json['sessionStartedAt'] != null
          ? DateTime.parse(json['sessionStartedAt'] as String)
          : DateTime.now(),
      sessionDurationSeconds: json['sessionDurationSeconds'] as int? ?? 0,
      sessionDurationMinutes: json['sessionDurationMinutes'] as int? ?? 0,
      previousScreen: json['previousScreen'] as String?,
      screenViewCount: json['screenViewCount'] as int?,
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionStartedAt': sessionStartedAt.toIso8601String(),
      'sessionDurationSeconds': sessionDurationSeconds,
      'sessionDurationMinutes': sessionDurationMinutes,
      if (previousScreen != null) 'previousScreen': previousScreen,
      if (screenViewCount != null) 'screenViewCount': screenViewCount,
    };
  }

  /// Cria cópia com modificações
  UserEngagementSessionModel copyWith({
    DateTime? sessionStartedAt,
    int? sessionDurationSeconds,
    int? sessionDurationMinutes,
    String? previousScreen,
    int? screenViewCount,
  }) {
    return UserEngagementSessionModel(
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      sessionDurationSeconds:
          sessionDurationSeconds ?? this.sessionDurationSeconds,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      previousScreen: previousScreen ?? this.previousScreen,
      screenViewCount: screenViewCount ?? this.screenViewCount,
    );
  }

  @override
  String toString() {
    return 'UserEngagementSessionModel(duration: ${sessionDurationMinutes}min, screens: $screenViewCount)';
  }
}
