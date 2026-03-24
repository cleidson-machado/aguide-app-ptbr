import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

/// Coletor de metadados do dispositivo, app e sessão para telemetria
/// 
/// Coleta informações contextuais úteis para:
/// - Analytics e métricas de uso
/// - Debugging e reprodução de bugs
/// - Auditoria e segurança
/// - Otimização de performance e UX
/// 
/// Referência: x_temp_files/METADATA_TELEMETRIA_OPCOES_DISPONIVEIS.md
class UserEngagamentMetadataRepository {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final Connectivity _connectivity = Connectivity();
  static final Battery _battery = Battery();

  // Cache de informações estáticas (coletadas uma vez)
  static Map<String, dynamic>? _cachedStaticInfo;
  static DateTime? _sessionStartTime;

  /// Coleta todos os metadados escolhidos pelo usuário
  /// 
  /// Retorna um Map estruturado em categorias:
  /// - device: Informações do dispositivo e SO
  /// - app: Versão do app e configurações
  /// - network: Tipo de conexão e velocidade
  /// - session: Duração e contexto da sessão
  /// - context: Hora, dia e configurações temporais
  /// - performance: Bateria, memória e recursos
  static Future<Map<String, dynamic>> collectMetadata({
    String? previousScreen,
    int? screenCount,
  }) async {
    try {
      // Coleta informações estáticas (cache para otimizar)
      _cachedStaticInfo ??= await _collectStaticInfo();

      // Coleta informações dinâmicas (sempre atualizar)
      final dynamicInfo = await _collectDynamicInfo(
        previousScreen: previousScreen,
        screenCount: screenCount,
      );

      // Combina informações estáticas + dinâmicas
      return {
        ..._cachedStaticInfo!,
        ...dynamicInfo,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UserEngagamentMetadataRepository] Erro ao coletar metadados: $e');
      }
      return _getFallbackMetadata();
    }
  }

  /// Coleta informações estáticas (só precisa coletar uma vez por sessão)
  static Future<Map<String, dynamic>> _collectStaticInfo() async {
    if (kDebugMode) {
      debugPrint('🔧 [UserEngagamentMetadataRepository] Coletando informações estáticas...');
    }

    final metadata = <String, dynamic>{};

    // 1. DISPOSITIVO + SO (Alta prioridade)
    metadata['device'] = await _getDeviceInfo();

    // 2. VERSÃO DO APP (Alta prioridade)
    metadata['app'] = await _getAppInfo();

    // 4. IDIOMA/LOCALE (Alta prioridade)
    metadata['app']['locale'] = _getLocaleInfo();

    // 6. RESOLUÇÃO DE TELA (Média prioridade)
    metadata['device']['screen'] = _getScreenInfo();

    if (kDebugMode) {
      debugPrint('✅ [UserEngagamentMetadataRepository] Informações estáticas coletadas');
    }

    return metadata;
  }

  /// Coleta informações dinâmicas (atualizar a cada log)
  static Future<Map<String, dynamic>> _collectDynamicInfo({
    String? previousScreen,
    int? screenCount,
  }) async {
    final metadata = <String, dynamic>{};

    // 3. TIPO DE CONEXÃO (Alta prioridade)
    metadata['network'] = await _getNetworkInfo();

    // 5. HORA DO DIA (Alta prioridade)
    metadata['context'] = _getContextInfo();

    // 8. DURAÇÃO DA SESSÃO (Média prioridade)
    metadata['session'] = _getSessionInfo(
      previousScreen: previousScreen,
      screenCount: screenCount,
    );

    // 11. BATERIA (Baixa prioridade)
    metadata['performance'] = await _getPerformanceInfo();

    // 12. VELOCIDADE NET (Baixa prioridade)
    metadata['network']['speed'] = await _getNetworkSpeed();

    // 13. MEMÓRIA RAM (Baixa prioridade)
    metadata['performance']['memory'] = _getMemoryInfo();

    return metadata;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS DE COLETA ESPECÍFICA
  // ═══════════════════════════════════════════════════════════════════════════

  /// 1. Informações do Dispositivo e Sistema Operacional
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'brand': androidInfo.brand,
          'os': 'Android',
          'osVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'os': 'iOS',
          'osVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      }
      return {'os': 'Unknown'};
    } catch (e) {
      return {'os': 'Error', 'error': e.toString()};
    }
  }

  /// 2. Informações da Versão do App
  static Future<Map<String, dynamic>> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
        'appName': packageInfo.appName,
      };
    } catch (e) {
      return {'version': 'Unknown', 'error': e.toString()};
    }
  }

  /// 3. Tipo de Conexão de Rede
  static Future<Map<String, dynamic>> _getNetworkInfo() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      // connectivity_plus retorna uma lista de tipos de conexão
      final connectionTypes = connectivityResults.map((result) {
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
      }).toList();

      return {
        'connectionType': connectionTypes.isNotEmpty ? connectionTypes.first : 'none',
        'connectionTypes': connectionTypes,
        'isConnected': !connectionTypes.contains('none'),
      };
    } catch (e) {
      return {'connectionType': 'error', 'error': e.toString()};
    }
  }

  /// 4. Idioma e Localização do Dispositivo
  static Map<String, dynamic> _getLocaleInfo() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      return {
        'languageCode': locale.languageCode,
        'countryCode': locale.countryCode,
        'fullLocale': locale.toString(),
      };
    } catch (e) {
      return {'languageCode': 'unknown', 'error': e.toString()};
    }
  }

  /// 5. Contexto Temporal (Hora do Dia, Dia da Semana)
  static Map<String, dynamic> _getContextInfo() {
    try {
      final now = DateTime.now();
      final weekday = _getWeekdayName(now.weekday);
      final isWeekend = now.weekday >= 6; // Sábado = 6, Domingo = 7
      final isBusinessHours = now.hour >= 9 && now.hour < 17;

      return {
        'timestamp': now.toIso8601String(),
        'hourOfDay': now.hour,
        'dayOfWeek': weekday,
        'dayOfMonth': now.day,
        'month': now.month,
        'year': now.year,
        'isWeekend': isWeekend,
        'isBusinessHours': isBusinessHours,
        'timezone': now.timeZoneName,
        'timezoneOffset': now.timeZoneOffset.inHours,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 6. Resolução e Densidade de Tela
  static Map<String, dynamic> _getScreenInfo() {
    try {
      final view = ui.PlatformDispatcher.instance.views.first;
      final physicalSize = view.physicalSize;
      final devicePixelRatio = view.devicePixelRatio;
      final logicalSize = view.physicalSize / devicePixelRatio;

      return {
        'physicalWidth': physicalSize.width.toInt(),
        'physicalHeight': physicalSize.height.toInt(),
        'logicalWidth': logicalSize.width.toInt(),
        'logicalHeight': logicalSize.height.toInt(),
        'pixelRatio': devicePixelRatio,
        'resolution': '${physicalSize.width.toInt()}x${physicalSize.height.toInt()}',
        'aspectRatio': (physicalSize.width / physicalSize.height).toStringAsFixed(2),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 8. Informações da Sessão (Duração, telas visitadas)
  static Map<String, dynamic> _getSessionInfo({
    String? previousScreen,
    int? screenCount,
  }) {
    try {
      _sessionStartTime ??= DateTime.now();
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);

      return {
        'sessionStartedAt': _sessionStartTime!.toIso8601String(),
        'sessionDurationSeconds': sessionDuration.inSeconds,
        'sessionDurationMinutes': sessionDuration.inMinutes,
        if (previousScreen != null) 'previousScreen': previousScreen,
        if (screenCount != null) 'screenViewCount': screenCount,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 11. Informações de Bateria
  static Future<Map<String, dynamic>> _getPerformanceInfo() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

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

      return {
        'batteryLevel': batteryLevel,
        'batteryState': stateString,
        'isCharging': batteryState == BatteryState.charging,
        'isBatteryLow': batteryLevel < 20,
      };
    } catch (e) {
      return {'batteryLevel': -1, 'error': e.toString()};
    }
  }

  /// 12. Velocidade de Rede (Estimativa)
  /// Nota: Para precisão, seria necessário fazer download/upload de arquivo teste
  /// Aqui fornecemos uma estimativa baseada no tipo de conexão
  static Future<Map<String, dynamic>> _getNetworkSpeed() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      if (connectivityResults.contains(ConnectivityResult.wifi)) {
        return {
          'estimated': true,
          'downloadSpeedMbps': 50.0, // WiFi típico
          'quality': 'excellent',
        };
      } else if (connectivityResults.contains(ConnectivityResult.mobile)) {
        return {
          'estimated': true,
          'downloadSpeedMbps': 10.0, // 4G típico
          'quality': 'good',
        };
      } else if (connectivityResults.contains(ConnectivityResult.ethernet)) {
        return {
          'estimated': true,
          'downloadSpeedMbps': 100.0, // Ethernet típico
          'quality': 'excellent',
        };
      }

      return {
        'estimated': true,
        'downloadSpeedMbps': 0.0,
        'quality': 'unavailable',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 13. Uso de Memória RAM (Estimativa básica)
  /// Nota: Dart não expõe memória do sistema diretamente
  /// Retorna informações limitadas do processo atual
  static Map<String, dynamic> _getMemoryInfo() {
    try {
      // Em Flutter, não temos acesso direto à memória total do sistema
      // Podemos apenas estimar com base no dispositivo
      return {
        'note': 'Limited info available in Dart',
        'processInfo': 'Use platform channels for detailed memory stats',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS AUXILIARES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Converte o Map de metadados para String JSON
  static String toJsonString(Map<String, dynamic> metadata) {
    try {
      return jsonEncode(metadata);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UserEngagamentMetadataRepository] Erro ao serializar JSON: $e');
      }
      return '{}';
    }
  }

  /// Retorna metadados mínimos em caso de falha total
  static Map<String, dynamic> _getFallbackMetadata() {
    return {
      'error': 'Failed to collect metadata',
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
    };
  }

  /// Reseta o cache (útil em logout ou troca de usuário)
  static void clearCache() {
    _cachedStaticInfo = null;
    _sessionStartTime = null;
    if (kDebugMode) {
      debugPrint('🗑️  [UserEngagamentMetadataRepository] Cache limpo');
    }
  }

  /// Converte número do dia da semana em nome
  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  /// Inicializa a sessão (chamar no início do app)
  static void startSession() {
    _sessionStartTime = DateTime.now();
    if (kDebugMode) {
      debugPrint('🚀 [UserEngagamentMetadataRepository] Sessão iniciada: $_sessionStartTime');
    }
  }
}
