import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';

/// **Adapter Pattern** - Converte OwnershipContentModel para MainContentTopicModel
/// 
/// **Responsabilidade Única:** Isola a lógica de mapeamento de objetos.
/// 
/// **Justificativa dos Valores Padrão:**
/// - `type: 'VIDEO'` - Ownership sempre representa vídeos do YouTube
/// - `categoryId/categoryName: ''` - Ownership não fornece categorização
/// - `durationSeconds: 0, durationIso: 'PT0S'` - Duração não disponível no endpoint
/// - `definition: 'hd', caption: false` - Valores padrão seguros
/// - `viewCount/likeCount/commentCount: 0` - Métricas enriquecidas posteriormente
/// 
/// **Semantic Mapping:**
/// - `createdAt: verifiedAt` - Data de verificação representa quando o conteúdo foi "criado" no sistema
/// - `updatedAt: verifiedAt` - Sem histórico de atualizações, usa mesma data
class OwnershipContentAdapter {
  /// Converte OwnershipContentModel para MainContentTopicModel
  /// 
  /// **Não deve ser chamada diretamente pela UI** - Use este adapter via ViewModel.
  static MainContentTopicModel toMainContentModel(
    OwnershipContentModel ownershipContent,
  ) {
    return MainContentTopicModel(
      id: ownershipContent.contentId,
      title: ownershipContent.title,
      description: ownershipContent.description,
      videoUrl: ownershipContent.videoUrl,
      videoThumbnailUrl: ownershipContent.videoThumbnailUrl,
      publishedAt: ownershipContent.publishedAt,
      
      // Semantic mapping: verifiedAt representa quando o conteúdo entrou no sistema
      createdAt: ownershipContent.verifiedAt,
      updatedAt: ownershipContent.verifiedAt,
      
      // Canal information
      channelId: ownershipContent.channelId,
      channelOwnerLinkId: null, // Não fornecido por ownership
      channelName: ownershipContent.channelName,
      
      // Valores padrão para campos não fornecidos
      type: 'VIDEO',
      categoryId: '',
      categoryName: '',
      tags: null,
      durationSeconds: 0,
      durationIso: 'PT0S',
      definition: 'hd',
      caption: false,
      
      // Métricas zeradas (enriquecidas posteriormente via MainContentTopicViewModel)
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      
      // Idiomas não fornecidos
      defaultLanguage: null,
      defaultAudioLanguage: null,
      
      // Hash de validação
      validationHash: ownershipContent.validationHash,
    );
  }

  /// Converte lista de OwnershipContentModel para lista de MainContentTopicModel
  /// 
  /// **Uso:** Facilita conversão em batch para ViewModels que precisam de listas completas.
  static List<MainContentTopicModel> toMainContentModelList(
    List<OwnershipContentModel> ownershipContents,
  ) {
    return ownershipContents
        .map((content) => toMainContentModel(content))
        .toList();
  }
}
