import 'dart:ui' as ui;

/// Value Object: Metadados de Tela
/// 
/// Representa informações imutáveis sobre resolução e densidade da tela.
/// Usado para telemetria e analytics na feature de User Engagement.
class UserEngagementScreenModel {
  final int physicalWidth;
  final int physicalHeight;
  final int logicalWidth;
  final int logicalHeight;
  final double pixelRatio;
  final String resolution;
  final String aspectRatio;

  const UserEngagementScreenModel({
    required this.physicalWidth,
    required this.physicalHeight,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.pixelRatio,
    required this.resolution,
    required this.aspectRatio,
  });

  /// Factory: Cria a partir de FlutterView
  factory UserEngagementScreenModel.fromView(ui.FlutterView view) {
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    final logicalSize = physicalSize / devicePixelRatio;

    final physicalWidth = physicalSize.width.toInt();
    final physicalHeight = physicalSize.height.toInt();
    final logicalWidth = logicalSize.width.toInt();
    final logicalHeight = logicalSize.height.toInt();

    return UserEngagementScreenModel(
      physicalWidth: physicalWidth,
      physicalHeight: physicalHeight,
      logicalWidth: logicalWidth,
      logicalHeight: logicalHeight,
      pixelRatio: devicePixelRatio,
      resolution: '${physicalWidth}x$physicalHeight',
      aspectRatio: (physicalSize.width / physicalSize.height).toStringAsFixed(2),
    );
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementScreenModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementScreenModel(
      physicalWidth: json['physicalWidth'] as int? ?? 0,
      physicalHeight: json['physicalHeight'] as int? ?? 0,
      logicalWidth: json['logicalWidth'] as int? ?? 0,
      logicalHeight: json['logicalHeight'] as int? ?? 0,
      pixelRatio: (json['pixelRatio'] as num?)?.toDouble() ?? 1.0,
      resolution: json['resolution'] as String? ?? '0x0',
      aspectRatio: json['aspectRatio'] as String? ?? '0.00',
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'physicalWidth': physicalWidth,
      'physicalHeight': physicalHeight,
      'logicalWidth': logicalWidth,
      'logicalHeight': logicalHeight,
      'pixelRatio': pixelRatio,
      'resolution': resolution,
      'aspectRatio': aspectRatio,
    };
  }

  /// Cria cópia com modificações
  UserEngagementScreenModel copyWith({
    int? physicalWidth,
    int? physicalHeight,
    int? logicalWidth,
    int? logicalHeight,
    double? pixelRatio,
    String? resolution,
    String? aspectRatio,
  }) {
    return UserEngagementScreenModel(
      physicalWidth: physicalWidth ?? this.physicalWidth,
      physicalHeight: physicalHeight ?? this.physicalHeight,
      logicalWidth: logicalWidth ?? this.logicalWidth,
      logicalHeight: logicalHeight ?? this.logicalHeight,
      pixelRatio: pixelRatio ?? this.pixelRatio,
      resolution: resolution ?? this.resolution,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  @override
  String toString() {
    return 'UserEngagementScreenMetadata(resolution: $resolution, ratio: $pixelRatio)';
  }
}
