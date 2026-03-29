import 'package:device_info_plus/device_info_plus.dart';

/// Value Object: Metadados do Dispositivo
/// 
/// Representa informações imutáveis sobre o dispositivo físico e sistema operacional.
/// Usado para telemetria e analytics na feature de User Engagement.
class UserEngagementDeviceModel {
  final String model;
  final String manufacturer;
  final String brand;
  final String os;
  final String osVersion;
  final bool isPhysicalDevice;
  final int? sdkInt; // Android only

  const UserEngagementDeviceModel({
    required this.model,
    required this.manufacturer,
    required this.brand,
    required this.os,
    required this.osVersion,
    required this.isPhysicalDevice,
    this.sdkInt,
  });

  /// Factory: Cria a partir de AndroidDeviceInfo
  factory UserEngagementDeviceModel.fromAndroid(AndroidDeviceInfo info) {
    return UserEngagementDeviceModel(
      model: info.model,
      manufacturer: info.manufacturer,
      brand: info.brand,
      os: 'Android',
      osVersion: info.version.release,
      isPhysicalDevice: info.isPhysicalDevice,
      sdkInt: info.version.sdkInt,
    );
  }

  /// Factory: Cria a partir de IosDeviceInfo
  factory UserEngagementDeviceModel.fromIOS(IosDeviceInfo info) {
    return UserEngagementDeviceModel(
      model: info.model,
      manufacturer: 'Apple',
      brand: 'Apple',
      os: 'iOS',
      osVersion: info.systemVersion,
      isPhysicalDevice: info.isPhysicalDevice,
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementDeviceModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementDeviceModel(
      model: json['model'] as String? ?? 'Unknown',
      manufacturer: json['manufacturer'] as String? ?? 'Unknown',
      brand: json['brand'] as String? ?? 'Unknown',
      os: json['os'] as String? ?? 'Unknown',
      osVersion: json['osVersion'] as String? ?? 'Unknown',
      isPhysicalDevice: json['isPhysicalDevice'] as bool? ?? false,
      sdkInt: json['sdkInt'] as int?,
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'manufacturer': manufacturer,
      'brand': brand,
      'os': os,
      'osVersion': osVersion,
      'isPhysicalDevice': isPhysicalDevice,
      if (sdkInt != null) 'sdkInt': sdkInt,
    };
  }

  /// Cria cópia com modificações
  UserEngagementDeviceModel copyWith({
    String? model,
    String? manufacturer,
    String? brand,
    String? os,
    String? osVersion,
    bool? isPhysicalDevice,
    int? sdkInt,
  }) {
    return UserEngagementDeviceModel(
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      brand: brand ?? this.brand,
      os: os ?? this.os,
      osVersion: osVersion ?? this.osVersion,
      isPhysicalDevice: isPhysicalDevice ?? this.isPhysicalDevice,
      sdkInt: sdkInt ?? this.sdkInt,
    );
  }

  @override
  String toString() {
    return 'UserEngagementDeviceModel(model: $model, os: $os $osVersion)';
  }
}
