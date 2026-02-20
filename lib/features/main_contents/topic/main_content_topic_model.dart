// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:portugal_guide/app/core/base/base_model.dart';

/// Model da camada de domínio - Entidade completa
/// Contém TODOS os atributos retornados pela API REST
/// Representa a entidade de domínio completa do sistema
class MainContentTopicModel implements BaseModel {
  @override
  final String id;

  // Informações básicas do conteúdo
  final String title;
  final String description;
  
  // URLs de mídia
  final String videoUrl;
  final String videoThumbnailUrl;
  
  // Metadados temporais
  final String publishedAt; // ISO 8601 format
  final String createdAt;
  final String updatedAt;
  
  // Informações do canal
  final String? channelId;
  final String? channelOwnerLinkId;
  final String channelName;
  
  // Tipo e categoria
  final String type; // VIDEO, ARTICLE, etc.
  final String categoryId;
  final String categoryName;
  final String? tags; // Pode ser null em alguns itens
  
  // Informações de vídeo
  final int durationSeconds;
  final String durationIso; // ISO 8601 duration (PT10M4S)
  final String definition; // "hd", "sd"
  final bool caption;
  
  // Métricas de engajamento
  final int viewCount;
  final int likeCount;
  final int commentCount;
  
  // Configurações de idioma
  final String? defaultLanguage;
  final String? defaultAudioLanguage;
  
  // Hash de validação (pode conter strings longas até 512 caracteres)
  final String? validationHash;

  MainContentTopicModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.videoThumbnailUrl,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.channelId,
    this.channelOwnerLinkId,
    required this.channelName,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    this.tags,
    required this.durationSeconds,
    required this.durationIso,
    required this.definition,
    required this.caption,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    this.defaultLanguage,
    this.defaultAudioLanguage,
    this.validationHash,
  });

  MainContentTopicModel copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? videoThumbnailUrl,
    String? publishedAt,
    String? createdAt,
    String? updatedAt,
    String? channelId,
    String? channelOwnerLinkId,
    String? channelName,
    String? type,
    String? categoryId,
    String? categoryName,
    String? tags,
    int? durationSeconds,
    String? durationIso,
    String? definition,
    bool? caption,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    String? defaultLanguage,
    String? defaultAudioLanguage,
    String? validationHash,
  }) {
    return MainContentTopicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      channelId: channelId ?? this.channelId,
      channelOwnerLinkId: channelOwnerLinkId ?? this.channelOwnerLinkId,
      channelName: channelName ?? this.channelName,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      tags: tags ?? this.tags,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationIso: durationIso ?? this.durationIso,
      definition: definition ?? this.definition,
      caption: caption ?? this.caption,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      defaultAudioLanguage: defaultAudioLanguage ?? this.defaultAudioLanguage,
      validationHash: validationHash ?? this.validationHash,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'videoThumbnailUrl': videoThumbnailUrl,
      'publishedAt': publishedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'channelId': channelId,
      'channelOwnerLinkId': channelOwnerLinkId,
      'channelName': channelName,
      'type': type,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'tags': tags,
      'durationSeconds': durationSeconds,
      'durationIso': durationIso,
      'definition': definition,
      'caption': caption,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'defaultLanguage': defaultLanguage,
      'defaultAudioLanguage': defaultAudioLanguage,
      'validationHash': validationHash,
    };
  }

  /// Deserializa JSON da API REST
  factory MainContentTopicModel.fromMap(Map<String, dynamic> map) {
    return MainContentTopicModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      videoUrl: map['videoUrl'] as String,
      videoThumbnailUrl: map['videoThumbnailUrl'] as String,
      publishedAt: map['publishedAt'] as String,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      channelId: map['channelId'] as String?,
      channelOwnerLinkId: map['channelOwnerLinkId'] as String?,
      channelName: map['channelName'] as String,
      type: map['type'] as String,
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String,
      tags: map['tags'] as String?,
      durationSeconds: map['durationSeconds'] as int,
      durationIso: map['durationIso'] as String,
      definition: map['definition'] as String,
      caption: map['caption'] as bool,
      viewCount: map['viewCount'] as int,
      likeCount: map['likeCount'] as int,
      commentCount: map['commentCount'] as int,
      defaultLanguage: map['defaultLanguage'] as String?,
      defaultAudioLanguage: map['defaultAudioLanguage'] as String?,
      validationHash: map['validationHash'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory MainContentTopicModel.fromJson(String source) =>
      MainContentTopicModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'MainContentTopicModel(id: $id, title: $title, channelName: $channelName, type: $type, viewCount: $viewCount)';
  }

  @override
  bool operator ==(covariant MainContentTopicModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.description == description &&
        other.videoUrl == videoUrl &&
        other.videoThumbnailUrl == videoThumbnailUrl &&
        other.channelName == channelName &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        videoUrl.hashCode ^
        videoThumbnailUrl.hashCode ^
        channelName.hashCode ^
        type.hashCode;
  }
}
