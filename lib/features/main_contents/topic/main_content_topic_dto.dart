// ignore_for_file: public_member_api_docs

import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';

/// DTO (Data Transfer Object) simplificado para a camada de Apresentação
/// Contém APENAS os campos essenciais usados pela View/UI
/// Segue o princípio de Segregação de Interface (SOLID - ISP)
/// 
/// Nomes dos atributos IGUAIS aos da API REST para evitar confusão
class MainContentTopicDto {
  final String id;
  final String title;
  final String channelName;
  final String description;
  final String videoThumbnailUrl;
  final String videoUrl;
  final String type;

  const MainContentTopicDto({
    required this.id,
    required this.title,
    required this.channelName,
    required this.description,
    required this.videoThumbnailUrl,
    required this.videoUrl,
    required this.type,
  });

  /// Cria DTO a partir do Model completo
  /// Responsabilidade Única (SOLID - SRP): Conversão de Model para DTO
  factory MainContentTopicDto.fromModel(MainContentTopicModel model) {
    return MainContentTopicDto(
      id: model.id,
      title: model.title,
      channelName: model.channelName,
      description: model.description,
      videoThumbnailUrl: model.videoThumbnailUrl,
      videoUrl: model.videoUrl,
      type: model.type,
    );
  }

  @override
  String toString() {
    return 'MainContentTopicDto(id: $id, title: $title, channelName: $channelName, type: $type)';
  }
}
