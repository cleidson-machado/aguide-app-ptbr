import 'dart:math';

/// Estratégias de ordenação disponíveis para listagem de contents
/// Baseadas nos parâmetros `sort` e `order` da API REST
enum ContentSortStrategy {
  /// Ordena por título crescente (A-Z)
  titleAsc,

  /// Ordena por título decrescente (Z-A)
  titleDesc,

  /// Ordena por data de publicação (mais recentes primeiro)
  publishedAtDesc,

  /// Ordena por data de publicação (mais antigos primeiro)
  publishedAtAsc,

  /// Ordena por nome do canal crescente (A-Z)
  channelNameAsc,

  /// Ordena por data de criação no sistema (mais recentes primeiro)
  createdAtDesc,
}

/// Configuração de ordenação contendo campo e direção
class ContentSortConfig {
  final String sortField;
  final String sortOrder;
  final ContentSortStrategy strategy;

  ContentSortConfig({
    required this.sortField,
    required this.sortOrder,
    required this.strategy,
  });

  /// Cria configuração a partir de uma estratégia
  factory ContentSortConfig.fromStrategy(ContentSortStrategy strategy) {
    switch (strategy) {
      case ContentSortStrategy.titleAsc:
        return ContentSortConfig(
          sortField: 'title',
          sortOrder: 'asc',
          strategy: strategy,
        );
      case ContentSortStrategy.titleDesc:
        return ContentSortConfig(
          sortField: 'title',
          sortOrder: 'desc',
          strategy: strategy,
        );
      case ContentSortStrategy.publishedAtDesc:
        return ContentSortConfig(
          sortField: 'publishedAt',
          sortOrder: 'desc',
          strategy: strategy,
        );
      case ContentSortStrategy.publishedAtAsc:
        return ContentSortConfig(
          sortField: 'publishedAt',
          sortOrder: 'asc',
          strategy: strategy,
        );
      case ContentSortStrategy.channelNameAsc:
        return ContentSortConfig(
          sortField: 'channelName',
          sortOrder: 'asc',
          strategy: strategy,
        );
      case ContentSortStrategy.createdAtDesc:
        return ContentSortConfig(
          sortField: 'createdAt',
          sortOrder: 'desc',
          strategy: strategy,
        );
    }
  }

  /// Seleciona uma estratégia aleatória
  static ContentSortStrategy randomStrategy() {
    final random = Random();
    const strategies = ContentSortStrategy.values;
    return strategies[random.nextInt(strategies.length)];
  }

  /// Retorna descrição amigável da estratégia (para debug/logs)
  String get description {
    switch (strategy) {
      case ContentSortStrategy.titleAsc:
        return 'Filtro - Título A-Z';
      case ContentSortStrategy.titleDesc:
        return 'Filtro - Título Z-A';
      case ContentSortStrategy.publishedAtDesc:
        return 'Filtro - Mais Recentes';
      case ContentSortStrategy.publishedAtAsc:
        return 'Filtro - Mais Antigos';
      case ContentSortStrategy.channelNameAsc:
        return 'Filtro - Canal A-Z';
      case ContentSortStrategy.createdAtDesc:
        return 'Filtro - Adicionados Recentemente';
    }
  }

  @override
  String toString() =>
      'ContentSortConfig(field: $sortField, order: $sortOrder, strategy: $description)';
}
