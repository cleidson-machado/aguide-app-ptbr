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

  // ═══════════════════════════════════════════════════════════════════════════
  // 🆕 PHASE B: VALIDAÇÕES DE TELEMETRIA ENRIQUECIDA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida totalContentViews (deve ser >= 0)
  /// 
  /// Throws: [ValidationException] se valor negativo
  static void validateContentViews(int? totalContentViews) {
    if (totalContentViews == null) return; // Campo opcional
    
    if (totalContentViews < 0) {
      throw ValidationException(
        'totalContentViews não pode ser negativo (recebido: $totalContentViews)',
      );
    }
  }

  /// Valida uniqueContentViews (deve ser >= 0 e <= totalContentViews)
  /// 
  /// Regra de negócio: uniqueContentViews nunca pode exceder totalContentViews
  /// 
  /// Throws: [ValidationException] se inválido
  static void validateUniqueContentViews({
    int? uniqueContentViews,
    int? totalContentViews,
  }) {
    if (uniqueContentViews == null) return; // Campo opcional
    
    if (uniqueContentViews < 0) {
      throw ValidationException(
        'uniqueContentViews não pode ser negativo (recebido: $uniqueContentViews)',
      );
    }

    // Se totalContentViews for fornecido, uniqueContentViews não pode excedê-lo
    if (totalContentViews != null && uniqueContentViews > totalContentViews) {
      throw ValidationException(
        'uniqueContentViews ($uniqueContentViews) não pode exceder '
        'totalContentViews ($totalContentViews)',
      );
    }
  }

  /// Valida avgDailyUsageMinutes (deve estar entre 0 e 1440 - 24 horas)
  /// 
  /// Throws: [ValidationException] se fora do intervalo [0, 1440]
  static void validateDailyUsageMinutes(int? avgDailyUsageMinutes) {
    if (avgDailyUsageMinutes == null) return; // Campo opcional

    const maxMinutesPerDay = 1440; // 24 horas

    if (avgDailyUsageMinutes < 0) {
      throw ValidationException(
        'avgDailyUsageMinutes não pode ser negativo '
        '(recebido: $avgDailyUsageMinutes)',
      );
    }

    if (avgDailyUsageMinutes > maxMinutesPerDay) {
      throw ValidationException(
        'avgDailyUsageMinutes não pode exceder $maxMinutesPerDay minutos/dia '
        '(recebido: $avgDailyUsageMinutes)',
      );
    }
  }

  /// Valida favoriteCategory (máximo 100 caracteres)
  /// 
  /// Throws: [ValidationException] se muito longo ou vazio
  static void validateFavoriteCategory(String? favoriteCategory) {
    if (favoriteCategory == null) return; // Campo opcional

    const maxLength = 100;

    if (favoriteCategory.isEmpty) {
      throw ValidationException(
        'favoriteCategory não pode ser string vazia',
      );
    }

    if (favoriteCategory.length > maxLength) {
      throw ValidationException(
        'favoriteCategory excede limite de $maxLength caracteres '
        '(recebido: ${favoriteCategory.length} chars)',
      );
    }
  }

  /// Valida profileCompletionPercentage (deve estar entre 0 e 100)
  /// 
  /// Throws: [ValidationException] se fora do intervalo [0, 100]
  static void validateProfileCompletionPercentage(
    int? profileCompletionPercentage,
  ) {
    if (profileCompletionPercentage == null) return; // Campo opcional

    if (profileCompletionPercentage < 0 || profileCompletionPercentage > 100) {
      throw ValidationException(
        'profileCompletionPercentage deve estar entre 0 e 100 '
        '(recebido: $profileCompletionPercentage)',
      );
    }
  }

  /// Validação completa de todos os campos de telemetria Phase B
  /// 
  /// Exemplo de uso no Service:
  /// ```dart
  /// UserTrackingValidator.validateTelemetryFields(
  ///   totalContentViews: model.totalContentViews,
  ///   uniqueContentViews: model.uniqueContentViews,
  ///   avgDailyUsageMinutes: model.avgDailyUsageMinutes,
  ///   favoriteCategory: model.favoriteCategory,
  ///   profileCompletionPercentage: model.profileCompletionPercentage,
  /// );
  /// ```
  static void validateTelemetryFields({
    int? totalContentViews,
    int? uniqueContentViews,
    int? avgDailyUsageMinutes,
    String? favoriteCategory,
    int? profileCompletionPercentage,
  }) {
    validateContentViews(totalContentViews);
    validateUniqueContentViews(
      uniqueContentViews: uniqueContentViews,
      totalContentViews: totalContentViews,
    );
    validateDailyUsageMinutes(avgDailyUsageMinutes);
    validateFavoriteCategory(favoriteCategory);
    validateProfileCompletionPercentage(profileCompletionPercentage);
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
