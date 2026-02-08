/// Opções de ordenação disponíveis para conteúdos
/// Representa as escolhas do usuário no domínio da aplicação
/// Segue Linguagem Ubíqua: termos compreensíveis por stakeholders
enum ContentSortOption {
  /// Ordena por título em ordem alfabética crescente (A-Z)
  titleAscending,

  /// Ordena por título em ordem alfabética decrescente (Z-A)
  titleDescending,

  /// Ordena por data de publicação (mais recentes primeiro)
  newestPublished,

  /// Ordena por data de publicação (mais antigos primeiro)
  oldestPublished,

  /// Ordena por nome do canal em ordem alfabética (A-Z)
  channelNameAscending,

  /// Ordena por data de criação no sistema (mais recentes primeiro)
  recentlyAdded,
}

/// Extensão para fornecer descrições legíveis das opções de ordenação
extension ContentSortOptionExtension on ContentSortOption {
  /// Retorna descrição amigável para exibição na UI
  String get displayName {
    switch (this) {
      case ContentSortOption.titleAscending:
        return 'Título A-Z';
      case ContentSortOption.titleDescending:
        return 'Título Z-A';
      case ContentSortOption.newestPublished:
        return 'Mais Recentes';
      case ContentSortOption.oldestPublished:
        return 'Mais Antigos';
      case ContentSortOption.channelNameAscending:
        return 'Canal A-Z';
      case ContentSortOption.recentlyAdded:
        return 'Adicionados Recentemente';
    }
  }

  /// Retorna descrição detalhada para logs e debugging
  String get debugDescription {
    switch (this) {
      case ContentSortOption.titleAscending:
        return 'Filtro - Título A-Z';
      case ContentSortOption.titleDescending:
        return 'Filtro - Título Z-A';
      case ContentSortOption.newestPublished:
        return 'Filtro - Mais Recentes';
      case ContentSortOption.oldestPublished:
        return 'Filtro - Mais Antigos';
      case ContentSortOption.channelNameAscending:
        return 'Filtro - Canal A-Z';
      case ContentSortOption.recentlyAdded:
        return 'Filtro - Adicionados Recentemente';
    }
  }
}
