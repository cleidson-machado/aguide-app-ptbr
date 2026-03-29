/// Model para rastreamento de engajamento do usuário com conteúdos
/// Usado para criar histórico de vídeos navegados, likes, bookmarks, etc.
/// 
/// Documentação da API: FLUTTER_ENGAGEMENT_API_INTEGRATION_GUIDE.md
/// Endpoint: POST /api/v1/engagements
class UserEngagementModel {
  final String? id; // Opcional na criação, retornado pela API
  final String userId;
  final String contentId;
  final String engagementType; // CLICK_TO_VIEW, VIEW, LIKE, SHARE, BOOKMARK, etc.
  final String engagementStatus; // ACTIVE, REMOVED, EXPIRED, FLAGGED
  final int? viewDurationSeconds;
  final int? completionPercentage;
  final int repeatCount;
  final String deviceType; // 'mobile', 'web', 'tablet'
  final String platform; // 'Android', 'iOS', 'Web'
  final String source; // 'home', 'search', 'recommendations', 'profile'
  final String? userIp;
  final String? userAgent;
  final String? metadata;
  final String? commentText;
  final int? rating;
  final DateTime engagedAt;
  final DateTime? endedAt;

  const UserEngagementModel({
    this.id,
    required this.userId,
    required this.contentId,
    required this.engagementType,
    this.engagementStatus = 'ACTIVE',
    this.viewDurationSeconds,
    this.completionPercentage,
    this.repeatCount = 1,
    required this.deviceType,
    required this.platform,
    required this.source,
    this.userIp,
    this.userAgent,
    this.metadata,
    this.commentText,
    this.rating,
    required this.engagedAt,
    this.endedAt,
  });

  /// Converte de JSON da API para Model
  factory UserEngagementModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementModel(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      contentId: json['contentId'] as String,
      engagementType: json['engagementType'] as String,
      engagementStatus: json['engagementStatus'] as String? ?? 'ACTIVE',
      viewDurationSeconds: json['viewDurationSeconds'] as int?,
      completionPercentage: json['completionPercentage'] as int?,
      repeatCount: json['repeatCount'] as int? ?? 1,
      deviceType: json['deviceType'] as String,
      platform: json['platform'] as String,
      source: json['source'] as String,
      userIp: json['userIp'] as String?,
      userAgent: json['userAgent'] as String?,
      metadata: json['metadata'] as String?,
      commentText: json['commentText'] as String?,
      rating: json['rating'] as int?,
      engagedAt: DateTime.parse(json['engagedAt'] as String),
      endedAt: json['endedAt'] != null 
          ? DateTime.parse(json['endedAt'] as String)
          : null,
    );
  }

  /// Converte Model para JSON para enviar à API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'contentId': contentId,
      'engagementType': engagementType,
      'engagementStatus': engagementStatus,
      if (viewDurationSeconds != null) 'viewDurationSeconds': viewDurationSeconds,
      if (completionPercentage != null) 'completionPercentage': completionPercentage,
      'repeatCount': repeatCount,
      'deviceType': deviceType,
      'platform': platform,
      'source': source,
      if (userIp != null) 'userIp': userIp,
      if (userAgent != null) 'userAgent': userAgent,
      if (metadata != null) 'metadata': metadata,
      if (commentText != null) 'commentText': commentText,
      if (rating != null) 'rating': rating,
      'engagedAt': engagedAt.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
    };
  }

  /// Cria uma cópia com campos modificados
  UserEngagementModel copyWith({
    String? id,
    String? userId,
    String? contentId,
    String? engagementType,
    String? engagementStatus,
    int? viewDurationSeconds,
    int? completionPercentage,
    int? repeatCount,
    String? deviceType,
    String? platform,
    String? source,
    String? userIp,
    String? userAgent,
    String? metadata,
    String? commentText,
    int? rating,
    DateTime? engagedAt,
    DateTime? endedAt,
  }) {
    return UserEngagementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      engagementType: engagementType ?? this.engagementType,
      engagementStatus: engagementStatus ?? this.engagementStatus,
      viewDurationSeconds: viewDurationSeconds ?? this.viewDurationSeconds,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      repeatCount: repeatCount ?? this.repeatCount,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      source: source ?? this.source,
      userIp: userIp ?? this.userIp,
      userAgent: userAgent ?? this.userAgent,
      metadata: metadata ?? this.metadata,
      commentText: commentText ?? this.commentText,
      rating: rating ?? this.rating,
      engagedAt: engagedAt ?? this.engagedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

/// Tipos de engajamento suportados pela API
class UserEngagementType {
  static const String clickToView = 'CLICK_TO_VIEW'; // ✅ Clicou no card/botão PLAY
  static const String view = 'VIEW'; // Iniciou visualização do vídeo
  static const String like = 'LIKE'; // Curtiu o conteúdo
  static const String dislike = 'DISLIKE'; // Não curtiu
  static const String share = 'SHARE'; // Compartilhou
  static const String bookmark = 'BOOKMARK'; // Salvou nos favoritos
  static const String comment = 'COMMENT'; // Comentou
  static const String complete = 'COMPLETE'; // Completou 100%
  static const String partialView = 'PARTIAL_VIEW'; // Assistiu parcialmente
}

/// Status do engajamento
class UserEngagementStatus {
  static const String active = 'ACTIVE'; // Ativo (padrão)
  static const String removed = 'REMOVED'; // Removido pelo usuário
  static const String expired = 'EXPIRED'; // Expirado
  static const String flagged = 'FLAGGED'; // Marcado para moderação
}
