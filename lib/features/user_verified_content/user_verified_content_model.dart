import 'dart:convert';
import 'package:portugal_guide/app/core/base/base_model.dart';

/// Modelo de dados para solicitação de verificação de conteúdo
/// Representa os dados coletados ao longo das 3 etapas do wizard
class UserVerifiedContentModel implements BaseModel {
  @override
  final String id;

  // Etapa 1: Informações do Conteúdo
  final String contentTitle;
  final String contentUrl;
  final String contentType; // 'video', 'article', 'course'

  // Etapa 2: Prova de Propriedade
  final String
  proofType; // 'youtube_channel', 'domain_ownership', 'social_media'
  final String proofValue; // ID do canal, domínio, @ da rede social

  // Etapa 3: Informações Adicionais
  final String description;
  final String contactEmail;

  // Metadados
  final DateTime createdAt;
  final String status; // 'pending', 'approved', 'rejected'

  UserVerifiedContentModel({
    required this.id,
    required this.contentTitle,
    required this.contentUrl,
    required this.contentType,
    required this.proofType,
    required this.proofValue,
    required this.description,
    required this.contactEmail,
    required this.createdAt,
    this.status = 'pending',
  });

  UserVerifiedContentModel copyWith({
    String? id,
    String? contentTitle,
    String? contentUrl,
    String? contentType,
    String? proofType,
    String? proofValue,
    String? description,
    String? contactEmail,
    DateTime? createdAt,
    String? status,
  }) {
    return UserVerifiedContentModel(
      id: id ?? this.id,
      contentTitle: contentTitle ?? this.contentTitle,
      contentUrl: contentUrl ?? this.contentUrl,
      contentType: contentType ?? this.contentType,
      proofType: proofType ?? this.proofType,
      proofValue: proofValue ?? this.proofValue,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'contentTitle': contentTitle,
      'contentUrl': contentUrl,
      'contentType': contentType,
      'proofType': proofType,
      'proofValue': proofValue,
      'description': description,
      'contactEmail': contactEmail,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory UserVerifiedContentModel.fromMap(Map<String, dynamic> map) {
    return UserVerifiedContentModel(
      id: map['id'] ?? '',
      contentTitle: map['contentTitle'] ?? '',
      contentUrl: map['contentUrl'] ?? '',
      contentType: map['contentType'] ?? 'video',
      proofType: map['proofType'] ?? '',
      proofValue: map['proofValue'] ?? '',
      description: map['description'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserVerifiedContentModel.fromJson(String source) =>
      UserVerifiedContentModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'UserVerifiedContentModel(id: $id, contentTitle: $contentTitle, contentUrl: $contentUrl, '
        'contentType: $contentType, proofType: $proofType, status: $status)';
  }

  @override
  bool operator ==(covariant UserVerifiedContentModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.contentTitle == contentTitle &&
        other.contentUrl == contentUrl &&
        other.contentType == contentType &&
        other.proofType == proofType &&
        other.proofValue == proofValue &&
        other.description == description &&
        other.contactEmail == contactEmail &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        contentTitle.hashCode ^
        contentUrl.hashCode ^
        contentType.hashCode ^
        proofType.hashCode ^
        proofValue.hashCode ^
        description.hashCode ^
        contactEmail.hashCode ^
        status.hashCode;
  }
}
