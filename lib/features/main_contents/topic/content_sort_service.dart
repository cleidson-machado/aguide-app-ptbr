import 'dart:math';

import 'package:portugal_guide/features/main_contents/topic/content_sort_criteria.dart';
import 'package:portugal_guide/features/main_contents/topic/content_sort_option.dart';

/// Serviço responsável por lógica relacionada à ordenação de conteúdos
/// Segue SRP: única responsabilidade de gerenciar estratégias de ordenação
class ContentSortService {
  final Random _random;

  ContentSortService({Random? random}) : _random = random ?? Random();

  /// Seleciona uma opção de ordenação aleatória
  /// Útil para variar a apresentação de conteúdos
  ContentSortOption getRandomOption() {
    const options = ContentSortOption.values;
    return options[_random.nextInt(options.length)];
  }

  /// Converte opção de ordenação em critérios para a API
  ContentSortCriteria toCriteria(ContentSortOption option) {
    return ContentSortCriteria.fromOption(option);
  }

  /// Converte opção aleatória diretamente em critérios
  ContentSortCriteria getRandomCriteria() {
    final option = getRandomOption();
    return ContentSortCriteria.fromOption(option);
  }

  /// Retorna todas as opções disponíveis
  List<ContentSortOption> getAllOptions() {
    return ContentSortOption.values;
  }

  /// Retorna todas as opções com suas descrições (útil para UI de filtros)
  Map<ContentSortOption, String> getOptionsWithDisplayNames() {
    return {
      for (var option in ContentSortOption.values)
        option: option.displayName,
    };
  }
}
