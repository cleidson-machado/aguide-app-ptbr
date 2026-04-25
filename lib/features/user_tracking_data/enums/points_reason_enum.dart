/// Enum para motivos de adição de pontos no sistema de ranking
/// 
/// Backend usa estes valores para auditoria e histórico de pontuação
/// Valores são convertidos para snake_case ao enviar para API
/// 
/// Referência: .local_knowledge/add-user-tracking-phase-b/RESPONSE_FRONTEND_PHASE_B_IMPLEMENTATION.md
enum PointsReason {
  /// Login diário (+1 ponto)
  dailyLogin,
  
  /// Entrada no wizard de verificação (+2 pontos)
  wizardEntry,
  
  /// Conclusão do step 1 do wizard (+3 pontos)
  wizardStep1,
  
  /// Conclusão do step 2 do wizard (+2 pontos)
  wizardStep2,
  
  /// Conclusão do step 3 do wizard (+2 pontos)
  wizardStep3,
  
  /// Conclusão do step 4 do wizard (+3 pontos)
  wizardStep4,
  
  /// Conclusão do step 5 do wizard - submissão final (+4 pontos)
  wizardStep5,
  
  /// Perfil 50% completo (+3 pontos)
  profile50Percent,
  
  /// Perfil 100% completo (+10 pontos)
  profile100Percent,
  
  /// Visualização de conteúdo (+1 ponto)
  contentView,
  
  /// Milestone: 10 visualizações de conteúdo (+2 pontos) - Detectado automaticamente pelo backend
  contentViews10,
  
  /// Milestone: 50 visualizações de conteúdo (+10 pontos) - Detectado automaticamente pelo backend
  contentViews50,
  
  /// Milestone: 100 visualizações de conteúdo (+25 pontos) - Detectado automaticamente pelo backend
  contentViews100,
  
  /// Primeira mensagem enviada (+3 pontos) - Futuro
  firstMessageSent,
  
  /// Primeira conversa iniciada (+5 pontos) - Futuro
  firstConversation,
  
  /// Motivo não especificado (backward compatibility)
  unspecified;

  /// Converte enum para snake_case (formato API)
  /// 
  /// Exemplo:
  /// ```dart
  /// PointsReason.wizardEntry.toJson() → "wizard_entry"
  /// PointsReason.profile50Percent.toJson() → "profile_50_percent"
  /// ```
  String toJson() => _toSnakeCase(name);

  /// Converte camelCase para snake_case
  /// 
  /// Regex detecta letras maiúsculas e adiciona underscore antes delas
  static String _toSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceAllMapped(
          RegExp(r'[0-9]+'),
          (match) => '_${match.group(0)}',
        )
        .replaceAll('__', '_'); // Remove underscores duplicados
  }

  /// Converte string snake_case para enum
  /// 
  /// Retorna null se valor não reconhecido
  /// 
  /// Exemplo:
  /// ```dart
  /// PointsReason.fromString("wizard_entry") → PointsReason.wizardEntry
  /// PointsReason.fromString("invalid") → null
  /// ```
  static PointsReason? fromString(String? value) {
    if (value == null) return null;
    
    // Converter snake_case para camelCase
    final camelCase = value.split('_').indexed.map((entry) {
      final (index, word) = entry;
      if (index == 0) return word.toLowerCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
    
    try {
      return PointsReason.values.firstWhere(
        (e) => e.name == camelCase,
      );
    } catch (_) {
      return null; // Valor não reconhecido
    }
  }
}
