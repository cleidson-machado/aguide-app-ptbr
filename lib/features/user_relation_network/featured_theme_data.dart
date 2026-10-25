import 'featured_content_models.dart';

/// Origem do tema exibido na grid.
enum FeaturedThemeSource { personalized, catalog }

/// Tema exibido em "Temas em Destaque": uma categoria representada por um
/// conteúdo (thumbnail) do catálogo ou do histórico do usuário.
class FeaturedThemeData {
  /// Chave de agrupamento (categoria) — única na grid.
  final String key;
  final String label;
  final String imageUrl;
  final String contentId;
  final FeaturedThemeSource source;

  const FeaturedThemeData({
    required this.key,
    required this.label,
    required this.imageUrl,
    required this.contentId,
    required this.source,
  });

  /// Monta o tema a partir de um conteúdo. Retorna `null` se o item não tem id.
  ///
  /// Sem categoria, o conteúdo vira um tema próprio rotulado pelo canal/título.
  static FeaturedThemeData? fromRecord(
    FeaturedContentRecord record, {
    required FeaturedThemeSource source,
    String? imageUrlOverride,
  }) {
    if (record.id.isEmpty) return null;

    final String key = themeKeyOf(record);
    final String label = [
      record.categoryName,
      record.channelName,
      record.title,
    ].firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final String override = imageUrlOverride?.trim() ?? '';

    return FeaturedThemeData(
      key: key,
      label: label,
      imageUrl: override.isNotEmpty ? override : record.videoThumbnailUrl,
      contentId: record.id,
      source: source,
    );
  }

  static String themeKeyOf(FeaturedContentRecord record) {
    if (record.categoryId.isNotEmpty) return 'category:${record.categoryId}';
    if (record.categoryName.isNotEmpty) {
      return 'category:${record.categoryName.toLowerCase()}';
    }
    return 'content:${record.id}';
  }
}
