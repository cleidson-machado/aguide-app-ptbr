/// Model para histórico de adição de pontos (auditoria)
/// 
/// Representa um registro individual de adição de pontos ao ranking do usuário.
/// Usado pela API GET /user/{userId}/points-history
/// 
/// Referência: .local_knowledge/FRONTEND_INTEGRATION_USER_RANKING_SECURITY.md
class PointsHistoryModel {
  /// Data e hora da adição de pontos (ISO 8601)
  final DateTime date;

  /// Quantidade de pontos adicionados
  final int points;

  /// Motivo da adição de pontos
  /// 
  /// Valores possíveis:
  /// - `daily_login`: Login diário (+10 pontos)
  /// - `7day_bonus`: Bônus de 7 dias consecutivos (+50 pontos)
  /// - `30day_bonus`: Bônus de 30 dias consecutivos (+200 pontos)
  /// - `content_interaction`: Interação com conteúdo (+5 pontos)
  /// - `message_sent`: Mensagem enviada (+3 pontos)
  final String reason;

  /// Score total do usuário APÓS a adição (pode ser null)
  final int? totalScoreAfter;

  /// Endereço IP da requisição que adicionou os pontos
  final String ipAddress;

  const PointsHistoryModel({
    required this.date,
    required this.points,
    required this.reason,
    this.totalScoreAfter,
    required this.ipAddress,
  });

  /// Cria instância a partir de JSON da API
  /// 
  /// Exemplo de JSON:
  /// ```json
  /// {
  ///   "date": "2026-03-29T10:15:00",
  ///   "points": 50,
  ///   "reason": "7day_bonus",
  ///   "totalScoreAfter": null,
  ///   "ipAddress": "192.168.1.1"
  /// }
  /// ```
  factory PointsHistoryModel.fromJson(Map<String, dynamic> json) {
    return PointsHistoryModel(
      date: DateTime.parse(json['date'] as String),
      points: json['points'] as int,
      reason: json['reason'] as String,
      totalScoreAfter: json['totalScoreAfter'] as int?,
      ipAddress: json['ipAddress'] as String,
    );
  }

  /// Converte instância para JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'points': points,
      'reason': reason,
      'totalScoreAfter': totalScoreAfter,
      'ipAddress': ipAddress,
    };
  }

  /// Retorna descrição formatada do motivo (para UI)
  /// 
  /// Uso:
  /// ```dart
  /// final description = historyItem.getReasonDescription();
  /// // Retorna: "Bônus de 7 Dias 🔥"
  /// ```
  String getReasonDescription() {
    switch (reason) {
      case 'daily_login':
        return 'Login Diário ⭐';
      case '7day_bonus':
        return 'Bônus de 7 Dias 🔥';
      case '30day_bonus':
        return 'Bônus de 30 Dias 🏆';
      case 'content_interaction':
        return 'Interação com Conteúdo 📖';
      case 'message_sent':
        return 'Mensagem Enviada 💬';
      default:
        return reason; // Fallback para valores desconhecidos
    }
  }

  /// Retorna ícone baseado no motivo (para UI)
  String getReasonIcon() {
    switch (reason) {
      case 'daily_login':
        return '⭐';
      case '7day_bonus':
        return '🔥';
      case '30day_bonus':
        return '🏆';
      case 'content_interaction':
        return '📖';
      case 'message_sent':
        return '💬';
      default:
        return '📌';
    }
  }

  @override
  String toString() {
    return 'PointsHistoryModel('
        'date: ${date.toIso8601String()}, '
        'points: $points, '
        'reason: $reason, '
        'totalScoreAfter: $totalScoreAfter, '
        'ipAddress: $ipAddress'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PointsHistoryModel &&
        other.date == date &&
        other.points == points &&
        other.reason == reason &&
        other.totalScoreAfter == totalScoreAfter &&
        other.ipAddress == ipAddress;
  }

  @override
  int get hashCode {
    return date.hashCode ^
        points.hashCode ^
        reason.hashCode ^
        totalScoreAfter.hashCode ^
        ipAddress.hashCode;
  }
}
