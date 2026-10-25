import 'featured_content_models.dart';
import 'featured_theme_data.dart';

/// Compõe a grid "Temas em Destaque" sem endpoint dedicado no backend.
///
/// 1. Conteúdos personalizados (top-contents do usuário), na ordem do ranking.
/// 2. Completa com o catálogo agrupado por categoria; o representante de cada
///    categoria é o item de maior `viewCount` (empate: o mais recente).
/// Cada categoria aparece uma única vez.
class FeaturedThemesComposer {
  const FeaturedThemesComposer();

  List<FeaturedThemeData> compose({
    required List<UserTopContent> personalized,
    required Map<String, FeaturedContentRecord> recordsById,
    required List<FeaturedContentRecord> catalog,
    required int maxThemes,
  }) {
    final Map<String, FeaturedThemeData> themesByKey = {};

    for (final UserTopContent top in personalized) {
      if (themesByKey.length >= maxThemes) break;
      final FeaturedContentRecord? record = recordsById[top.contentId];
      if (record == null) continue;
      final FeaturedThemeData? theme = FeaturedThemeData.fromRecord(
        record,
        source: FeaturedThemeSource.personalized,
        imageUrlOverride: top.thumbnailUrl,
      );
      if (theme != null) themesByKey.putIfAbsent(theme.key, () => theme);
    }

    for (final FeaturedContentRecord record in _representativesByCategory(
      catalog,
    )) {
      if (themesByKey.length >= maxThemes) break;
      final FeaturedThemeData? theme = FeaturedThemeData.fromRecord(
        record,
        source: FeaturedThemeSource.catalog,
      );
      if (theme != null) themesByKey.putIfAbsent(theme.key, () => theme);
    }

    return themesByKey.values.toList();
  }

  /// Mantém a ordem de primeira aparição da categoria no catálogo.
  List<FeaturedContentRecord> _representativesByCategory(
    List<FeaturedContentRecord> catalog,
  ) {
    final Map<String, FeaturedContentRecord> representatives = {};
    for (final FeaturedContentRecord record in catalog) {
      if (record.id.isEmpty) continue;
      final String key = FeaturedThemeData.themeKeyOf(record);
      final FeaturedContentRecord? current = representatives[key];
      if (current == null || record.viewCount > current.viewCount) {
        representatives[key] = record;
      }
    }
    return representatives.values.toList();
  }
}
