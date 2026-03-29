import 'package:connectivity_plus/connectivity_plus.dart';

/// Value Object: Metadados de Rede
/// 
/// Representa informações imutáveis sobre conexão de rede e qualidade.
/// Usado para telemetria e analytics na feature de User Engagement.
class UserEngagementNetworkModel {
  final String connectionType;
  final List<String> connectionTypes;
  final bool isConnected;
  final UserEngagementNetworkSpeed? speed;

  const UserEngagementNetworkModel({
    required this.connectionType,
    required this.connectionTypes,
    required this.isConnected,
    this.speed,
  });

  /// Factory: Cria a partir de ConnectivityResult
  factory UserEngagementNetworkModel.fromConnectivityResults(
    List<ConnectivityResult> results,
  ) {
    final connectionTypes = results.map(_mapConnectivityResult).toList();
    
    return UserEngagementNetworkModel(
      connectionType: connectionTypes.isNotEmpty ? connectionTypes.first : 'none',
      connectionTypes: connectionTypes,
      isConnected: !connectionTypes.contains('none'),
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementNetworkModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementNetworkModel(
      connectionType: json['connectionType'] as String? ?? 'none',
      connectionTypes: (json['connectionTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isConnected: json['isConnected'] as bool? ?? false,
      speed: json['speed'] != null
          ? UserEngagementNetworkSpeed.fromJson(
              json['speed'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'connectionType': connectionType,
      'connectionTypes': connectionTypes,
      'isConnected': isConnected,
      if (speed != null) 'speed': speed!.toJson(),
    };
  }

  /// Cria cópia com modificações
  UserEngagementNetworkModel copyWith({
    String? connectionType,
    List<String>? connectionTypes,
    bool? isConnected,
    UserEngagementNetworkSpeed? speed,
  }) {
    return UserEngagementNetworkModel(
      connectionType: connectionType ?? this.connectionType,
      connectionTypes: connectionTypes ?? this.connectionTypes,
      isConnected: isConnected ?? this.isConnected,
      speed: speed ?? this.speed,
    );
  }

  /// Helper: Mapeia ConnectivityResult para String
  static String _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'wifi';
      case ConnectivityResult.mobile:
        return 'mobile';
      case ConnectivityResult.ethernet:
        return 'ethernet';
      case ConnectivityResult.vpn:
        return 'vpn';
      case ConnectivityResult.bluetooth:
        return 'bluetooth';
      case ConnectivityResult.other:
        return 'other';
      case ConnectivityResult.none:
        return 'none';
    }
  }

  @override
  String toString() {
    return 'UserEngagementNetworkModel(type: $connectionType, connected: $isConnected)';
  }
}

/// Value Object: Velocidade de Rede (Estimativa)
class UserEngagementNetworkSpeed {
  final bool estimated;
  final double downloadSpeedMbps;
  final String quality;

  const UserEngagementNetworkSpeed({
    required this.estimated,
    required this.downloadSpeedMbps,
    required this.quality,
  });

  /// Factory: Estima velocidade baseada no tipo de conexão
  factory UserEngagementNetworkSpeed.estimate(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.ethernet)) {
      return const UserEngagementNetworkSpeed(
        estimated: true,
        downloadSpeedMbps: 100.0,
        quality: 'excellent',
      );
    } else if (results.contains(ConnectivityResult.wifi)) {
      return const UserEngagementNetworkSpeed(
        estimated: true,
        downloadSpeedMbps: 50.0,
        quality: 'excellent',
      );
    } else if (results.contains(ConnectivityResult.mobile)) {
      return const UserEngagementNetworkSpeed(
        estimated: true,
        downloadSpeedMbps: 10.0,
        quality: 'good',
      );
    }

    return const UserEngagementNetworkSpeed(
      estimated: true,
      downloadSpeedMbps: 0.0,
      quality: 'unavailable',
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementNetworkSpeed.fromJson(Map<String, dynamic> json) {
    return UserEngagementNetworkSpeed(
      estimated: json['estimated'] as bool? ?? true,
      downloadSpeedMbps: (json['downloadSpeedMbps'] as num?)?.toDouble() ?? 0.0,
      quality: json['quality'] as String? ?? 'unknown',
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'estimated': estimated,
      'downloadSpeedMbps': downloadSpeedMbps,
      'quality': quality,
    };
  }

  @override
  String toString() {
    return 'NetworkSpeed(${downloadSpeedMbps}Mbps, $quality)';
  }
}
