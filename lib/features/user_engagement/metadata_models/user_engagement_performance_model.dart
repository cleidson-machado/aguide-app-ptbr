import 'package:battery_plus/battery_plus.dart';

/// Value Object: Metadados de Performance
/// 
/// Representa informações imutáveis sobre bateria e recursos do dispositivo.
/// Usado para telemetria e analytics na feature de User Engagement.
class UserEngagementPerformanceModel {
  final int batteryLevel;
  final String batteryState;
  final bool isCharging;
  final bool isBatteryLow;
  final UserEngagementMemoryModel? memory;

  const UserEngagementPerformanceModel({
    required this.batteryLevel,
    required this.batteryState,
    required this.isCharging,
    required this.isBatteryLow,
    this.memory,
  });

  /// Factory: Cria a partir de Battery info
  factory UserEngagementPerformanceModel.fromBattery({
    required int batteryLevel,
    required BatteryState batteryState,
    int batteryLowThreshold = 20,
    UserEngagementMemoryModel? memory,
  }) {
    String stateString;
    switch (batteryState) {
      case BatteryState.charging:
        stateString = 'charging';
        break;
      case BatteryState.discharging:
        stateString = 'discharging';
        break;
      case BatteryState.full:
        stateString = 'full';
        break;
      case BatteryState.connectedNotCharging:
        stateString = 'connectedNotCharging';
        break;
      default:
        stateString = 'unknown';
    }

    return UserEngagementPerformanceModel(
      batteryLevel: batteryLevel,
      batteryState: stateString,
      isCharging: batteryState == BatteryState.charging,
      isBatteryLow: batteryLevel < batteryLowThreshold,
      memory: memory,
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementPerformanceModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementPerformanceModel(
      batteryLevel: json['batteryLevel'] as int? ?? -1,
      batteryState: json['batteryState'] as String? ?? 'unknown',
      isCharging: json['isCharging'] as bool? ?? false,
      isBatteryLow: json['isBatteryLow'] as bool? ?? false,
      memory: json['memory'] != null
          ? UserEngagementMemoryModel.fromJson(
              json['memory'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'batteryLevel': batteryLevel,
      'batteryState': batteryState,
      'isCharging': isCharging,
      'isBatteryLow': isBatteryLow,
      if (memory != null) 'memory': memory!.toJson(),
    };
  }

  /// Cria cópia com modificações
  UserEngagementPerformanceModel copyWith({
    int? batteryLevel,
    String? batteryState,
    bool? isCharging,
    bool? isBatteryLow,
    UserEngagementMemoryModel? memory,
  }) {
    return UserEngagementPerformanceModel(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryState: batteryState ?? this.batteryState,
      isCharging: isCharging ?? this.isCharging,
      isBatteryLow: isBatteryLow ?? this.isBatteryLow,
      memory: memory ?? this.memory,
    );
  }

  @override
  String toString() {
    return 'UserEngagementPerformanceModel(battery: $batteryLevel%, state: $batteryState)';
  }
}

/// Value Object: Metadados de Memória
/// 
/// Representa informações limitadas sobre memória (Dart não expõe memória completa).
class UserEngagementMemoryModel {
  final String note;
  final String processInfo;

  const UserEngagementMemoryModel({
    required this.note,
    required this.processInfo,
  });

  /// Factory: Cria com informação limitada padrão
  factory UserEngagementMemoryModel.limited() {
    return const UserEngagementMemoryModel(
      note: 'Limited info available in Dart',
      processInfo: 'Use platform channels for detailed memory stats',
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementMemoryModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementMemoryModel(
      note: json['note'] as String? ?? 'Limited info',
      processInfo: json['processInfo'] as String? ?? 'Unknown',
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'note': note,
      'processInfo': processInfo,
    };
  }

  @override
  String toString() {
    return 'UserEngagementMemoryModel(note: $note)';
  }
}
