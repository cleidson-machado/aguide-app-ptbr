import 'dart:ui' as ui;

/// Value Object: Metadados de Locale/Idioma
/// 
/// Representa informações imutáveis sobre idioma e localização do dispositivo.
/// Usado para telemetria e analytics na feature de User Engagement.
class UserEngagementLocaleModel {
  final String languageCode;
  final String? countryCode;
  final String fullLocale;

  const UserEngagementLocaleModel({
    required this.languageCode,
    this.countryCode,
    required this.fullLocale,
  });

  /// Factory: Cria a partir de Locale
  factory UserEngagementLocaleModel.fromLocale(ui.Locale locale) {
    return UserEngagementLocaleModel(
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      fullLocale: locale.toString(),
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementLocaleModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementLocaleModel(
      languageCode: json['languageCode'] as String? ?? 'unknown',
      countryCode: json['countryCode'] as String?,
      fullLocale: json['fullLocale'] as String? ?? 'unknown',
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      if (countryCode != null) 'countryCode': countryCode,
      'fullLocale': fullLocale,
    };
  }

  /// Cria cópia com modificações
  UserEngagementLocaleModel copyWith({
    String? languageCode,
    String? countryCode,
    String? fullLocale,
  }) {
    return UserEngagementLocaleModel(
      languageCode: languageCode ?? this.languageCode,
      countryCode: countryCode ?? this.countryCode,
      fullLocale: fullLocale ?? this.fullLocale,
    );
  }

  @override
  String toString() {
    return 'UserEngagementLocaleMetadata(locale: $fullLocale)';
  }
}
