import 'package:package_info_plus/package_info_plus.dart';

/// Value Object: Metadados da Aplicação
/// 
/// Representa informações imutáveis sobre a versão e build do app.
/// Usado para telemetria e analytics na feature de User Engagement.
class UserEngagementAppModel {
  final String version;
  final String buildNumber;
  final String packageName;
  final String appName;

  const UserEngagementAppModel({
    required this.version,
    required this.buildNumber,
    required this.packageName,
    required this.appName,
  });

  /// Factory: Cria a partir de PackageInfo
  factory UserEngagementAppModel.fromPackageInfo(PackageInfo info) {
    return UserEngagementAppModel(
      version: info.version,
      buildNumber: info.buildNumber,
      packageName: info.packageName,
      appName: info.appName,
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementAppModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementAppModel(
      version: json['version'] as String? ?? 'Unknown',
      buildNumber: json['buildNumber'] as String? ?? 'Unknown',
      packageName: json['packageName'] as String? ?? 'Unknown',
      appName: json['appName'] as String? ?? 'Unknown',
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'packageName': packageName,
      'appName': appName,
    };
  }

  /// Cria cópia com modificações
  UserEngagementAppModel copyWith({
    String? version,
    String? buildNumber,
    String? packageName,
    String? appName,
  }) {
    return UserEngagementAppModel(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
    );
  }

  @override
  String toString() {
    return 'UserEngagementAppModel(appName: $appName, version: $version+$buildNumber)';
  }
}
