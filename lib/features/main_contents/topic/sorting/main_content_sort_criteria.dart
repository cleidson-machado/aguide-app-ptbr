import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_option.dart';

/// Value Object que representa os critérios de ordenação para a API REST
/// Encapsula os parâmetros `sort` e `order` necessários para requisições
/// Segue padrão DDD: imutável e auto-validável
class MainContentSortCriteria {
  /// Campo pelo qual ordenar (ex: 'title', 'publishedAt', 'createdAt')
  final String field;

  /// Direção da ordenação ('asc' ou 'desc')
  final String order;

  /// Opção de ordenação original que gerou estes critérios
  final MainContentSortOption option;

  const MainContentSortCriteria({
    required this.field,
    required this.order,
    required this.option,
  });

  /// Cria critérios a partir de uma opção de ordenação
  /// Este é o método principal de criação, mapeando domínio → infraestrutura
  factory MainContentSortCriteria.fromOption(MainContentSortOption option) {
    switch (option) {
      case MainContentSortOption.titleAscending:
        return MainContentSortCriteria(
          field: 'title',
          order: 'asc',
          option: option,
        );
      case MainContentSortOption.titleDescending:
        return MainContentSortCriteria(
          field: 'title',
          order: 'desc',
          option: option,
        );
      case MainContentSortOption.newestPublished:
        return MainContentSortCriteria(
          field: 'publishedAt',
          order: 'desc',
          option: option,
        );
      case MainContentSortOption.oldestPublished:
        return MainContentSortCriteria(
          field: 'publishedAt',
          order: 'asc',
          option: option,
        );
      case MainContentSortOption.channelNameAscending:
        return MainContentSortCriteria(
          field: 'channelName',
          order: 'asc',
          option: option,
        );
      case MainContentSortOption.recentlyAdded:
        return MainContentSortCriteria(
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
  MainContentSortCriteria copyWith({
    String? field,
    String? order,
    MainContentSortOption? option,
  }) {
    return MainContentSortCriteria(
      field: field ?? this.field,
      order: order ?? this.order,
      option: option ?? this.option,
    );
  }

  @override
  String toString() =>
      'MainContentSortCriteria(field: $field, order: $order, option: ${option.debugDescription})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MainContentSortCriteria &&
        other.field == field &&
        other.order == order &&
        other.option == option;
  }

  @override
  int get hashCode => Object.hash(field, order, option);
}
