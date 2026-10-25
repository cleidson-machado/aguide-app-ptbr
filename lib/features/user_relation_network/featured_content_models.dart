/// DTOs tolerantes para a seção "Temas em Destaque".
///
/// NOTE: `MainContentTopicModel.fromMap` (main_contents) faz casts não-nulos
/// em campos que a API pode enviar `null` (ex.: `publishedAt`). Estes DTOs
/// leem só o que a grid usa, sem alterar a feature core.
library;

String _readString(Object? value) => value is String ? value.trim() : '';

int _readInt(Object? value) => value is num ? value.toInt() : 0;

/// Item de `content_record` (GET /contents e GET /contents/{id}).
class FeaturedContentRecord {
  final String id;
  final String title;
  final String videoThumbnailUrl;
  final String channelName;
  final String categoryId;
  final String categoryName;
  final int viewCount;

  const FeaturedContentRecord({
    required this.id,
    required this.title,
    required this.videoThumbnailUrl,
    required this.channelName,
    required this.categoryId,
    required this.categoryName,
    required this.viewCount,
  });

  factory FeaturedContentRecord.fromJson(Map<String, dynamic> json) {
    return FeaturedContentRecord(
      id: _readString(json['id']),
      title: _readString(json['title']),
      videoThumbnailUrl: _readString(json['videoThumbnailUrl']),
      channelName: _readString(json['channelName']),
      categoryId: _readString(json['categoryId']),
      categoryName: _readString(json['categoryName']),
      viewCount: _readInt(json['viewCount']),
    );
  }
}

/// Item de `topContents` (GET /engagements/user/{userId}/top-contents).
/// A API não envia categoria: ela é resolvida via `content_record`.
class UserTopContent {
  final String contentId;
  final String contentTitle;
  final String thumbnailUrl;
  final int totalInteractions;

  const UserTopContent({
    required this.contentId,
    required this.contentTitle,
    required this.thumbnailUrl,
    required this.totalInteractions,
  });

  factory UserTopContent.fromJson(Map<String, dynamic> json) {
    return UserTopContent(
      contentId: _readString(json['contentId']),
      contentTitle: _readString(json['contentTitle']),
      thumbnailUrl: _readString(json['thumbnailUrl']),
      totalInteractions: _readInt(json['totalInteractions']),
    );
  }
}
