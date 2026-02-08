/// Opções de ordenação disponíveis para conteúdos
/// Representa as escolhas do usuário no domínio da aplicação
/// Segue Linguagem Ubíqua: termos compreensíveis por stakeholders
enum MainContentSortOption {
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
extension MainContentSortOptionExtension on MainContentSortOption {
  /// Retorna descrição amigável para exibição na UI
  String get displayName {
    switch (this) {
      case MainContentSortOption.titleAscending:
        return 'Título A-Z';
      case MainContentSortOption.titleDescending:
        return 'Título Z-A';
      case MainContentSortOption.newestPublished:
        return 'Mais Recentes';
      case MainContentSortOption.oldestPublished:
        return 'Mais Antigos';
      case MainContentSortOption.channelNameAscending:
        return 'Canal A-Z';
      case MainContentSortOption.recentlyAdded:
        return 'Adicionados Recentemente';
    }
  }

  /// Retorna descrição detalhada para logs e debugging
  String get debugDescription {
    switch (this) {
      case MainContentSortOption.titleAscending:
        return 'Filtro - Título A-Z';
      case MainContentSortOption.titleDescending:
        return 'Filtro - Título Z-A';
      case MainContentSortOption.newestPublished:
        return 'Filtro - Mais Recentes';
      case MainContentSortOption.oldestPublished:
        return 'Filtro - Mais Antigos';
      case MainContentSortOption.channelNameAscending:
        return 'Filtro - Canal A-Z';
      case MainContentSortOption.recentlyAdded:
        return 'Filtro - Adicionados Recentemente';
    }
  }
}
