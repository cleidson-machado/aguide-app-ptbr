import 'package:portugal_guide/features/main_contents/topic/content_sort_option.dart';

/// Value Object que representa os critérios de ordenação para a API REST
/// Encapsula os parâmetros `sort` e `order` necessários para requisições
/// Segue padrão DDD: imutável e auto-validável
class ContentSortCriteria {
  /// Campo pelo qual ordenar (ex: 'title', 'publishedAt', 'createdAt')
  final String field;

  /// Direção da ordenação ('asc' ou 'desc')
  final String order;

  /// Opção de ordenação original que gerou estes critérios
  final ContentSortOption option;

  const ContentSortCriteria({
    required this.field,
    required this.order,
    required this.option,
  });

  /// Cria critérios a partir de uma opção de ordenação
  /// Este é o método principal de criação, mapeando domínio → infraestrutura
  factory ContentSortCriteria.fromOption(ContentSortOption option) {
    switch (option) {
      case ContentSortOption.titleAscending:
        return ContentSortCriteria(
          field: 'title',
          order: 'asc',
          option: option,
        );
      case ContentSortOption.titleDescending:
        return ContentSortCriteria(
          field: 'title',
          order: 'desc',
          option: option,
        );
      case ContentSortOption.newestPublished:
        return ContentSortCriteria(
          field: 'publishedAt',
          order: 'desc',
          option: option,
        );
      case ContentSortOption.oldestPublished:
        return ContentSortCriteria(
          field: 'publishedAt',
          order: 'asc',
          option: option,
        );
      case ContentSortOption.channelNameAscending:
        return ContentSortCriteria(
          field: 'channelName',
          order: 'asc',
          option: option,
        );
      case ContentSortOption.recentlyAdded:
        return ContentSortCriteria(
          field: 'createdAt',
          order: 'desc',
          option: option,
        );
    }
  }

  /// Converte para Map para uso em query parameters da API
  Map<String, String> toQueryParams() {
    return {
      'sort': field,
      'order': order,
    };
  }

  /// Retorna descrição amigável baseada na opção original
  String get displayName => option.displayName;

  /// Cria cópia com modificações (padrão copyWith)
  ContentSortCriteria copyWith({
    String? field,
    String? order,
    ContentSortOption? option,
  }) {
    return ContentSortCriteria(
      field: field ?? this.field,
      order: order ?? this.order,
      option: option ?? this.option,
    );
  }

  @override
  String toString() =>
      'ContentSortCriteria(field: $field, order: $order, option: ${option.debugDescription})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentSortCriteria &&
        other.field == field &&
        other.order == order &&
        other.option == option;
  }

  @override
  int get hashCode => Object.hash(field, order, option);
}
