/// Classe para validações client-side de User Tracking Data
/// 
/// Implementa defesa em profundidade: mesmo o backend devendo validar,
/// o Flutter adiciona validações locais para proteger contra bugs e
/// detectar problemas antes de enviar dados inválidos ao servidor.
/// 
/// Referência: x_temp_files/ANALISE_ACOES_FLUTTER_RESPOSTA_BACKEND.md
/// 
/// Validações implementadas:
/// - Timestamps não podem ser no futuro (com tolerância de 5min)
/// - Timestamps não podem ser muito antigos (> 1 dia no passado)
/// - Streak não pode aumentar mais de 1 por login
/// - Streak não pode ser negativo
/// - Limites máximos de pontos e streak
class UserTrackingValidator {
  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 CONSTANTES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Tolerância de timestamp no futuro (dessincronia de relógio)
  static const Duration timestampFutureTolerance = Duration(minutes: 5);
  
  /// Limite de quão antigo um timestamp pode ser
  static const Duration timestampPastLimit = Duration(days: 1);
  
  /// Score máximo permitido (evitar overflow e abuso)
  static const int maxTotalScore = 9999999;
  
  /// Streak máximo permitido (~27 anos de uso consecutivo)
  static const int maxConsecutiveDaysStreak = 9999;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛡️ VALIDAÇÕES DE TIMESTAMP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida se timestamp não está no futuro (além da tolerância)
  /// 
  /// Permite 5min de tolerância para dessincronia de relógio entre
  /// dispositivo e servidor.
  /// 
  /// Throws: [ValidationException] se timestamp for futuro demais
  static void validateTimestampNotFuture(
    DateTime timestamp,
    String fieldName,
  ) {
    final now = DateTime.now().toUtc();
    final maxAllowed = now.add(timestampFutureTolerance);

    if (timestamp.isAfter(maxAllowed)) {
      throw ValidationException(
        '$fieldName não pode ser no futuro '
        '(timestamp: ${timestamp.toIso8601String()}, '
        'máximo: ${maxAllowed.toIso8601String()})',
      );
    }
  }

  /// Valida se timestamp não é muito antigo (> 1 dia no passado)
  /// 
  /// Protege contra envio de dados desatualizados ou manipulados.
  /// 
  /// Throws: [ValidationException] se timestamp for muito antigo
  static void validateTimestampNotTooOld(
    DateTime timestamp,
    String fieldName,
  ) {
    final now = DateTime.now().toUtc();
    final minAllowed = now.subtract(timestampPastLimit);

    if (timestamp.isBefore(minAllowed)) {
      throw ValidationException(
        '$fieldName muito antigo '
        '(timestamp: ${timestamp.toIso8601String()}, '
        'mínimo: ${minAllowed.toIso8601String()})',
      );
    }
  }

  /// Valida timestamp completo (não futuro E não muito antigo)
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// UserTrackingValidator.validateTimestamp(
  ///   DateTime.now(),
  ///   'lastLoginAt'
  /// );
  /// ```
  static void validateTimestamp(DateTime timestamp, String fieldName) {
    validateTimestampNotFuture(timestamp, fieldName);
    validateTimestampNotTooOld(timestamp, fieldName);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛡️ VALIDAÇÕES DE STREAK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida que streak incrementou corretamente (máximo +1)
  /// 
  /// Streak só pode:
  /// - Aumentar em 1 (novo dia consecutivo)
  /// - Resetar para 1 (quebrou streak)
  /// - Manter o valor (mesmo dia)
  /// 
  /// Throws: [ValidationException] se incremento for inválido
  static void validateStreakIncrement({
    required int oldStreak,
    required int newStreak,
    required bool isSameDay,
  }) {
    // Mesmo dia → deve manter streak
    if (isSameDay && newStreak != oldStreak) {
      throw ValidationException(
        'Streak não deve mudar no mesmo dia '
        '(atual: $oldStreak, tentou enviar: $newStreak)',
      );
    }

    // Novo dia → só pode incrementar +1 ou resetar para 1
    if (!isSameDay) {
      final isIncrement = newStreak == oldStreak + 1;
      final isReset = newStreak == 1;

      if (!isIncrement && !isReset) {
        throw ValidationException(
          'Streak inválido: esperado ${oldStreak + 1} ou 1, '
          'recebido $newStreak',
        );
      }
    }
  }

  /// Valida limites mínimo e máximo de streak
  /// 
  /// Throws: [ValidationException] se fora dos limites
  static void validateStreakLimits(int streak) {
    if (streak < 1) {
      throw ValidationException(
        'Streak não pode ser negativo ou zero (recebido: $streak)',
      );
    }

    if (streak > maxConsecutiveDaysStreak) {
      throw ValidationException(
        'Streak excede limite máximo de $maxConsecutiveDaysStreak '
        '(recebido: $streak)',
      );
    }
  }

  /// Validação completa de streak
  static void validateStreak({
    required int oldStreak,
    required int newStreak,
    required bool isSameDay,
  }) {
    validateStreakLimits(newStreak);
    validateStreakIncrement(
      oldStreak: oldStreak,
      newStreak: newStreak,
      isSameDay: isSameDay,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛡️ VALIDAÇÕES DE PONTOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Limite mínimo de pontos por chamada de addPoints (conforme backend)
  static const int minPointsPerCall = 1;
  
  /// Limite máximo de pontos por chamada de addPoints (conforme backend)
  static const int maxPointsPerCall = 1000;

  /// Valida que pontos a adicionar estão dentro dos limites permitidos
  /// 
  /// Backend requer: 1 ≤ points ≤ 1000 por chamada
  /// 
  /// Throws: [ValidationException] se pontos fora do intervalo [1, 1000]
  static void validatePointsToAdd(int points) {
    if (points < minPointsPerCall) {
      throw ValidationException(
        'Pontos devem ser no mínimo $minPointsPerCall (recebido: $points)',
      );
    }
    
    if (points > maxPointsPerCall) {
      throw ValidationException(
        'Pontos não podem exceder $maxPointsPerCall por chamada (recebido: $points)',
      );
    }
  }

  /// Valida que score total não excede limite máximo
  /// 
  /// Throws: [ValidationException] se exceder limite
  static void validateTotalScore(int totalScore) {
    if (totalScore < 0) {
      throw ValidationException(
        'Score não pode ser negativo (recebido: $totalScore)',
      );
    }

    if (totalScore > maxTotalScore) {
      throw ValidationException(
        'Score excede limite máximo de $maxTotalScore '
        '(recebido: $totalScore)',
      );
    }
  }

  /// Valida que adição de pontos não ultrapassa limite
  /// 
  /// Exemplo:
  /// ```dart
  /// UserTrackingValidator.validateScoreAfterAddition(
  ///   currentScore: 9999990,
  ///   pointsToAdd: 20,
  /// );
  /// ```
  static void validateScoreAfterAddition({
    required int currentScore,
    required int pointsToAdd,
  }) {
    validatePointsToAdd(pointsToAdd);

    final projectedScore = currentScore + pointsToAdd;
    
    if (projectedScore > maxTotalScore) {
      throw ValidationException(
        'Adicionar $pointsToAdd pontos ultrapassaria limite máximo '
        '(score atual: $currentScore, limite: $maxTotalScore)',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛡️ VALIDAÇÃO DE userId
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida que userId não está vazio ou inválido
  /// 
  /// Throws: [ValidationException] se userId inválido
  static void validateUserId(String userId) {
    if (userId.isEmpty) {
      throw ValidationException('userId não pode ser vazio');
    }

    // Validar formato UUID (básico)
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    if (!uuidPattern.hasMatch(userId)) {
      throw ValidationException(
        'userId deve ser um UUID válido (recebido: $userId)',
      );
    }
  }

  /// Valida que userId no tracking corresponde ao userId esperado
  /// 
  /// Proteção contra modificação de ranking de outros usuários
  /// (mesmo backend devendo validar).
  /// 
  /// Throws: [ValidationException] se userId divergir
  static void validateUserIdMatch({
    required String expectedUserId,
    required String trackingUserId,
  }) {
    validateUserId(expectedUserId);
    validateUserId(trackingUserId);

    if (expectedUserId != trackingUserId) {
      throw ValidationException(
        'userId não corresponde: esperado $expectedUserId, '
        'recebido $trackingUserId',
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🚨 EXCEÇÃO CUSTOMIZADA
// ═══════════════════════════════════════════════════════════════════════════

/// Exceção lançada por validações de User Tracking
/// 
/// Contém mensagem descritiva do erro para debug e logs.
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
