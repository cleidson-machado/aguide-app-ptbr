/// Modelo para conteúdo verificado (ownership confirmado)
class OwnershipContentModel {
  final String contentId;
  final String title;
  final String description;
  final String videoUrl;
  final String videoThumbnailUrl;
  final String channelId;
  final String channelName;
  final String publishedAt;
  final String ownershipId;
  final String validationHash;
  final String verifiedAt;
  final bool verified;

  const OwnershipContentModel({
    required this.contentId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.videoThumbnailUrl,
    required this.channelId,
    required this.channelName,
    required this.publishedAt,
    required this.ownershipId,
    required this.validationHash,
    required this.verifiedAt,
    required this.verified,
  });

  factory OwnershipContentModel.fromJson(Map<String, dynamic> json) {
    return OwnershipContentModel(
      contentId: json['contentId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String,
      videoThumbnailUrl: json['videoThumbnailUrl'] as String,
      channelId: json['channelId'] as String,
      channelName: json['channelName'] as String,
      publishedAt: json['publishedAt'] as String,
      ownershipId: json['ownershipId'] as String,
      validationHash: json['validationHash'] as String,
      verifiedAt: json['verifiedAt'] as String,
      verified: json['verified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'videoThumbnailUrl': videoThumbnailUrl,
      'channelId': channelId,
      'channelName': channelName,
      'publishedAt': publishedAt,
      'ownershipId': ownershipId,
      'validationHash': validationHash,
      'verifiedAt': verifiedAt,
      'verified': verified,
    };
  }
}

/// Modelo para erro de ownership (conteúdo não verificado)
class OwnershipErrorModel {
  final String error;
  final String message;
  final String timestamp;

  const OwnershipErrorModel({
    required this.error,
    required this.message,
    required this.timestamp,
  });

  factory OwnershipErrorModel.fromJson(Map<String, dynamic> json) {
    return OwnershipErrorModel(
      error: json['error'] as String,
      message: json['message'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

/// Resultado da verificação de ownership (wrapper para sucesso ou erro)
class OwnershipResult {
  final List<OwnershipContentModel>? contents;
  final OwnershipErrorModel? error;
  final bool isOwner;

  const OwnershipResult({
    this.contents,
    this.error,
    required this.isOwner,
  });

  /// Factory para criar resultado de sucesso
  factory OwnershipResult.success(List<OwnershipContentModel> contents) {
    return OwnershipResult(
      contents: contents,
      isOwner: true,
    );
  }

  /// Factory para criar resultado de erro (não é dono)
  factory OwnershipResult.notOwner(OwnershipErrorModel error) {
    return OwnershipResult(
      error: error,
      isOwner: false,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 🆕 MODELO PARA VALIDAÇÃO DE AUTORIA (POST /api/v1/ownership/validate)
/// ═══════════════════════════════════════════════════════════════════════════

/// Modelo para resposta da validação de autoria via POST
/// Trata tanto sucesso (VERIFIED) quanto rejeição (REJECTED)
class OwnershipValidationResponse {
  final String ownershipId;
  final String userId;
  final String contentId;
  final String youtubeChannelId;
  final String contentChannelId;
  final String status; // 'VERIFIED' ou 'REJECTED'
  final String validationHash; // Vazio em caso de REJECTED
  final String? verifiedAt; // Null em caso de REJECTED
  final String createdAt;
  final String message;

  const OwnershipValidationResponse({
    required this.ownershipId,
    required this.userId,
    required this.contentId,
    required this.youtubeChannelId,
    required this.contentChannelId,
    required this.status,
    required this.validationHash,
    this.verifiedAt,
    required this.createdAt,
    required this.message,
  });

  /// Verifica se a validação foi bem-sucedida (status VERIFIED)
  bool get isVerified => status == 'VERIFIED';

  /// Verifica se a validação foi rejeitada (status REJECTED)
  bool get isRejected => status == 'REJECTED';

  factory OwnershipValidationResponse.fromJson(Map<String, dynamic> json) {
    return OwnershipValidationResponse(
      ownershipId: json['ownershipId'] as String,
      userId: json['userId'] as String,
      contentId: json['contentId'] as String,
      youtubeChannelId: json['youtubeChannelId'] as String,
      contentChannelId: json['contentChannelId'] as String? ?? '',
      status: json['status'] as String,
      validationHash: json['validationHash'] as String? ?? '',
      verifiedAt: json['verifiedAt'] as String?,
      createdAt: json['createdAt'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownershipId': ownershipId,
      'userId': userId,
      'contentId': contentId,
      'youtubeChannelId': youtubeChannelId,
      'contentChannelId': contentChannelId,
      'status': status,
      'validationHash': validationHash,
      'verifiedAt': verifiedAt,
      'createdAt': createdAt,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'OwnershipValidationResponse(ownershipId: $ownershipId, status: $status, message: $message)';
  }
}
