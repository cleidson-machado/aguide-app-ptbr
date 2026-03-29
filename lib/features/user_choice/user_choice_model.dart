import 'package:portugal_guide/app/core/base/base_model.dart';

/// Modelo de dados para o perfil de escolhas do usuário (Creator ou Consumer)
/// Baseado na API REST: /api/v1/user-choices
class UserChoiceModel implements BaseModel {
  @override
  final String id;

  // Campos Comuns (CREATOR e CONSUMER)
  final String userId;
  final String profileType; // 'CREATOR' ou 'CONSUMER'
  final String nicheContext; // Nicho macro da plataforma

  // ========== Campos CREATOR ==========
  final String? channelName;
  final String? channelHandle;
  final String? channelAgeRange; // Enum: LESS_THAN_6_MONTHS, SIX_MONTHS_TO_1_YEAR, etc.
  final String? subscriberRange; // Enum: LESS_THAN_1K, ONE_K_TO_10K, etc.
  final String? monetizationStatus; // Enum: MONETIZED, NOT_MONETIZED, IN_PROGRESS
  final String? mainNiche;
  final List<String>? contentFormats; // Array: ["VLOG", "TUTORIAL", "SHORTS"]
  final String? commercialIntent; // Enum: BRAND_PARTNERSHIP, SELL_OWN_SERVICES, etc.
  final String? offeredService;
  final String? publishingFrequency; // Enum: DAILY, WEEKLY, MONTHLY, etc.
  final String? contentDifferential;

  // ========== Campos CONSUMER (não usados nesta tela CREATOR) ==========
  final String? currentSituation;
  final String? mainObjective;
  final String? visaTypeInterest;
  final String? knowledgeLevel;
  final List<String>? currentInfoSources;
  final String? mainDifficulty;
  final String? preferredContentType;
  final String? serviceHiringIntent;
  final String? immigrationTimeframe;
  final String? platformExpectation;

  // Metadados
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  UserChoiceModel({
    required this.id,
    required this.userId,
    required this.profileType,
    required this.nicheContext,
    // CREATOR
    this.channelName,
    this.channelHandle,
    this.channelAgeRange,
    this.subscriberRange,
    this.monetizationStatus,
    this.mainNiche,
    this.contentFormats,
    this.commercialIntent,
    this.offeredService,
    this.publishingFrequency,
    this.contentDifferential,
    // CONSUMER
    this.currentSituation,
    this.mainObjective,
    this.visaTypeInterest,
    this.knowledgeLevel,
    this.currentInfoSources,
    this.mainDifficulty,
    this.preferredContentType,
    this.serviceHiringIntent,
    this.immigrationTimeframe,
    this.platformExpectation,
    // Metadados
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Factory para criar a partir de JSON da API
  factory UserChoiceModel.fromMap(Map<String, dynamic> json) {
    return UserChoiceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      profileType: json['profileType'] ?? '',
      nicheContext: json['nicheContext'] ?? '',
      // CREATOR
      channelName: json['channelName'],
      channelHandle: json['channelHandle'],
      channelAgeRange: json['channelAgeRange'],
      subscriberRange: json['subscriberRange'],
      monetizationStatus: json['monetizationStatus'],
      mainNiche: json['mainNiche'],
      contentFormats: json['contentFormats'] != null
          ? List<String>.from(json['contentFormats'])
          : null,
      commercialIntent: json['commercialIntent'],
      offeredService: json['offeredService'],
      publishingFrequency: json['publishingFrequency'],
      contentDifferential: json['contentDifferential'],
      // CONSUMER
      currentSituation: json['currentSituation'],
      mainObjective: json['mainObjective'],
      visaTypeInterest: json['visaTypeInterest'],
      knowledgeLevel: json['knowledgeLevel'],
      currentInfoSources: json['currentInfoSources'] != null
          ? List<String>.from(json['currentInfoSources'])
          : null,
      mainDifficulty: json['mainDifficulty'],
      preferredContentType: json['preferredContentType'],
      serviceHiringIntent: json['serviceHiringIntent'],
      immigrationTimeframe: json['immigrationTimeframe'],
      platformExpectation: json['platformExpectation'],
      // Metadados
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'profileType': profileType,
      'nicheContext': nicheContext,
    };

    // Adicionar campos CREATOR se não forem nulos
    if (channelName != null) data['channelName'] = channelName;
    if (channelHandle != null) data['channelHandle'] = channelHandle;
    if (channelAgeRange != null) data['channelAgeRange'] = channelAgeRange;
    if (subscriberRange != null) data['subscriberRange'] = subscriberRange;
    if (monetizationStatus != null) {
      data['monetizationStatus'] = monetizationStatus;
    }
    if (mainNiche != null) data['mainNiche'] = mainNiche;
    if (contentFormats != null) data['contentFormats'] = contentFormats;
    if (commercialIntent != null) data['commercialIntent'] = commercialIntent;
    if (offeredService != null) data['offeredService'] = offeredService;
    if (publishingFrequency != null) {
      data['publishingFrequency'] = publishingFrequency;
    }
    if (contentDifferential != null) {
      data['contentDifferential'] = contentDifferential;
    }

    // Adicionar campos CONSUMER se não forem nulos
    if (currentSituation != null) data['currentSituation'] = currentSituation;
    if (mainObjective != null) data['mainObjective'] = mainObjective;
    if (visaTypeInterest != null) data['visaTypeInterest'] = visaTypeInterest;
    if (knowledgeLevel != null) data['knowledgeLevel'] = knowledgeLevel;
    if (currentInfoSources != null) {
      data['currentInfoSources'] = currentInfoSources;
    }
    if (mainDifficulty != null) data['mainDifficulty'] = mainDifficulty;
    if (preferredContentType != null) {
      data['preferredContentType'] = preferredContentType;
    }
    if (serviceHiringIntent != null) {
      data['serviceHiringIntent'] = serviceHiringIntent;
    }
    if (immigrationTimeframe != null) {
      data['immigrationTimeframe'] = immigrationTimeframe;
    }
    if (platformExpectation != null) {
      data['platformExpectation'] = platformExpectation;
    }

    return data;
  }

  /// Helper para verificar se é perfil CREATOR
  bool get isCreator => profileType == 'CREATOR';

  /// Helper para verificar se é perfil CONSUMER
  bool get isConsumer => profileType == 'CONSUMER';

  /// Helper para verificar se perfil está ativo (não deletado)
  bool get isActive => deletedAt == null;

  UserChoiceModel copyWith({
    String? id,
    String? userId,
    String? profileType,
    String? nicheContext,
    String? channelName,
    String? channelHandle,
    String? channelAgeRange,
    String? subscriberRange,
    String? monetizationStatus,
    String? mainNiche,
    List<String>? contentFormats,
    String? commercialIntent,
    String? offeredService,
    String? publishingFrequency,
    String? contentDifferential,
    String? currentSituation,
    String? mainObjective,
    String? visaTypeInterest,
    String? knowledgeLevel,
    List<String>? currentInfoSources,
    String? mainDifficulty,
    String? preferredContentType,
    String? serviceHiringIntent,
    String? immigrationTimeframe,
    String? platformExpectation,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return UserChoiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileType: profileType ?? this.profileType,
      nicheContext: nicheContext ?? this.nicheContext,
      channelName: channelName ?? this.channelName,
      channelHandle: channelHandle ?? this.channelHandle,
      channelAgeRange: channelAgeRange ?? this.channelAgeRange,
      subscriberRange: subscriberRange ?? this.subscriberRange,
      monetizationStatus: monetizationStatus ?? this.monetizationStatus,
      mainNiche: mainNiche ?? this.mainNiche,
      contentFormats: contentFormats ?? this.contentFormats,
      commercialIntent: commercialIntent ?? this.commercialIntent,
      offeredService: offeredService ?? this.offeredService,
      publishingFrequency: publishingFrequency ?? this.publishingFrequency,
      contentDifferential: contentDifferential ?? this.contentDifferential,
      currentSituation: currentSituation ?? this.currentSituation,
      mainObjective: mainObjective ?? this.mainObjective,
      visaTypeInterest: visaTypeInterest ?? this.visaTypeInterest,
      knowledgeLevel: knowledgeLevel ?? this.knowledgeLevel,
      currentInfoSources: currentInfoSources ?? this.currentInfoSources,
      mainDifficulty: mainDifficulty ?? this.mainDifficulty,
      preferredContentType: preferredContentType ?? this.preferredContentType,
      serviceHiringIntent: serviceHiringIntent ?? this.serviceHiringIntent,
      immigrationTimeframe: immigrationTimeframe ?? this.immigrationTimeframe,
      platformExpectation: platformExpectation ?? this.platformExpectation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
