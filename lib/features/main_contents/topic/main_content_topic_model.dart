// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:portugal_guide/app/core/base/base_model.dart';

/// Model da camada de domínio usado pela UI/ViewModel
/// Mantém nomes adaptados para o contexto da aplicação Flutter
class MainContentTopicModel implements BaseModel {
  @override
  final String id;

  final String title;
  final String subtitle;
  final String description;
  final String contentImageUrl;
  final String contentUrl;
  final String contentType;

  MainContentTopicModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.contentImageUrl,
    required this.contentUrl,
    required this.contentType,
  });

  MainContentTopicModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? contentImageUrl,
    String? contentUrl,
    String? contentType,
  }) {
    return MainContentTopicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      contentImageUrl: contentImageUrl ?? this.contentImageUrl,
      contentUrl: contentUrl ?? this.contentUrl,
      contentType: contentType ?? this.contentType,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'contentImageUrl': contentImageUrl,
      'contentUrl': contentUrl,
      'contentType': contentType,
    };
  }

  factory MainContentTopicModel.fromMap(Map<String, dynamic> map) {
    return MainContentTopicModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle:
          map['channelName'] as String, // Mapeia channelName para subtitle
      description: map['description'] as String,
      contentImageUrl:
          map['videoThumbnailUrl']
              as String, // Mapeia videoThumbnailUrl para contentImageUrl
      contentUrl: map['videoUrl'] as String, // Mapeia videoUrl para contentUrl
      contentType: map['type'] as String, // Mapeia type para contentType
    );
  }

  String toJson() => json.encode(toMap());

  factory MainContentTopicModel.fromJson(String source) =>
      MainContentTopicModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'MainContentTopicModel(id: $id, title: $title, subtitle: $subtitle, description: $description, contentImageUrl: $contentImageUrl, contentUrl: $contentUrl, contentType: $contentType)';
  }

  @override
  bool operator ==(covariant MainContentTopicModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.description == description &&
        other.contentImageUrl == contentImageUrl &&
        other.contentUrl == contentUrl &&
        other.contentType == contentType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        subtitle.hashCode ^
        description.hashCode ^
        contentImageUrl.hashCode ^
        contentUrl.hashCode ^
        contentType.hashCode;
  }
}
