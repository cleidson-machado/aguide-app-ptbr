import 'featured_content_models.dart';

/// Contrato de leitura de conteúdos para a seção "Temas em Destaque".
///
/// Todos os métodos lançam exceção em falha de rede/HTTP; a composição
/// (fallback, descarte) é decidida no ViewModel.
abstract class UserRelationFeaturedContentRepositoryInterface {
  /// GET /api/v1/contents?page=0&size={size}&sort=publishedAt&order=desc
  /// `size` é limitado a 100 no cliente.
  Future<List<FeaturedContentRecord>> getLatestContents({int size});

  /// GET /api/v1/engagements/user/{userId}/top-contents?limit={limit}
  Future<List<UserTopContent>> getUserTopContents({
    required String userId,
    int limit,
  });

  /// GET /api/v1/contents/{contentId}
  Future<FeaturedContentRecord> getContentById(String contentId);
}
