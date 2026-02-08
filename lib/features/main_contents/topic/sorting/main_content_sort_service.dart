import 'dart:math';

import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_criteria.dart';
import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_option.dart';

/// Serviço responsável por lógica relacionada à ordenação de conteúdos
/// Segue SRP: única responsabilidade de gerenciar estratégias de ordenação
class MainContentSortService {
  final Random _random;

  MainContentSortService({Random? random}) : _random = random ?? Random();

  /// Seleciona uma opção de ordenação aleatória
  /// Útil para variar a apresentação de conteúdos
  MainContentSortOption getRandomOption() {
    const options = MainContentSortOption.values;
    return options[_random.nextInt(options.length)];
  }

  /// Converte opção de ordenação em critérios para a API
  MainContentSortCriteria toCriteria(MainContentSortOption option) {
    return MainContentSortCriteria.fromOption(option);
  }

  /// Converte opção aleatória diretamente em critérios
  MainContentSortCriteria getRandomCriteria() {
    final option = getRandomOption();
    return MainContentSortCriteria.fromOption(option);
  }

  /// Retorna todas as opções disponíveis
  List<MainContentSortOption> getAllOptions() {
    return MainContentSortOption.values;
  }

  /// Retorna todas as opções com suas descrições (útil para UI de filtros)
  Map<MainContentSortOption, String> getOptionsWithDisplayNames() {
    return {
      for (var option in MainContentSortOption.values)
        option: option.displayName,
    };
  }
}
