/// **Utility Class** - Formatação de métricas de engajamento de conteúdo.
/// 
/// **Responsabilidade Única:** Transformar números brutos em strings legíveis.
/// 
/// **Exemplos:**
/// - 1.234.567 → "1.2M"
/// - 45.678 → "45.7K"
/// - 999 → "999"
/// 
/// **Nota:** Esta classe é stateless e todas as operações são puras (sem side effects).
class ContentMetricsFormatter {
  // Private constructor - forçar uso via métodos estáticos
  ContentMetricsFormatter._();

  /// Formata número para exibição compacta (K = mil, M = milhão)
  /// 
  /// **Regras:**
  /// - >= 1.000.000 → "X.XM" (1 casa decimal)
  /// - >= 1.000 → "X.XK" (1 casa decimal)
  /// - < 1.000 → valor inteiro sem formatação
  /// 
  /// **Performance:** O(1) - operação aritmética simples.
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// Formata métricas de engajamento para exibição em cards
  /// 
  /// **Uso:** Quando precisa formatar múltiplas métricas de uma vez.
  /// 
  /// **Retorna:** Map com chaves 'views', 'likes', 'comments'.
  static Map<String, String> formatEngagementMetrics({
    required int viewCount,
    required int likeCount,
    required int commentCount,
  }) {
    return {
      'views': formatNumber(viewCount),
      'likes': formatNumber(likeCount),
      'comments': formatNumber(commentCount),
    };
  }

  /// Formata número com separador de milhares (ex: 1.234.567 → "1,234,567")
  /// 
  /// **Uso:** Para exibições detalhadas onde precisão numérica é importante.
  static String formatWithThousandsSeparator(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
