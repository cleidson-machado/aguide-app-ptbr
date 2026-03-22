import 'package:flutter/foundation.dart';
import 'package:get_ip_address/get_ip_address.dart';

/// Serviço para coletar o IP público do usuário
/// 
/// Utilizado para enriquecer logs de telemetria, auditoria de sessão e rastreamento de ações.
/// 
/// Referência: FLUTTER_ENGAGEMENT_COLETA_IP_ADDRESS_E_AFINS.md
class IpService {
  static String? _cachedIP;

  /// Retorna o IP público do usuário.
  /// Faz a requisição apenas uma vez por sessão (cache em memória).
  /// 
  /// Retorna:
  /// - IP público do usuário (ex: "200.123.45.67")
  /// - 'unknown' se a API retornar dados inválidos
  /// - 'unavailable' se houver erro de conexão ou rede
  /// - 'error' se houver qualquer outro erro
  static Future<String> getPublicIP() async {
    // Se já foi coletado na sessão, reutilizar
    if (_cachedIP != null) {
      if (kDebugMode) {
        debugPrint('🌐 [IpService] IP público em cache: $_cachedIP');
      }
      return _cachedIP!;
    }

    try {
      if (kDebugMode) {
        debugPrint('🌐 [IpService] Coletando IP público via api64.ipify.org...');
      }

      final ipAddress = IpAddress(type: RequestType.json);
      final dynamic data = await ipAddress.getIpAddress();
      
      _cachedIP = data['ip'] as String? ?? 'unknown';
      
      if (kDebugMode) {
        debugPrint('✅ [IpService] IP público coletado com sucesso: $_cachedIP');
      }
    } on IpAddressException catch (e) {
      _cachedIP = 'unavailable';
      if (kDebugMode) {
        debugPrint('⚠️  [IpService] Falha ao coletar IP público (IpAddressException): $e');
      }
    } catch (e) {
      _cachedIP = 'error';
      if (kDebugMode) {
        debugPrint('❌ [IpService] Erro ao coletar IP público: $e');
      }
    }

    return _cachedIP!;
  }

  /// Limpa o cache do IP público.
  /// 
  /// Útil em:
  /// - Logout do usuário
  /// - Troca de rede (WiFi → Dados móveis)
  /// - Nova sessão de autenticação
  static void clearCache() {
    if (kDebugMode && _cachedIP != null) {
      debugPrint('🗑️  [IpService] Cache de IP limpo (valor anterior: $_cachedIP)');
    }
    _cachedIP = null;
  }

  /// Retorna o IP em cache sem fazer nova requisição.
  /// Retorna null se ainda não foi coletado.
  static String? getCachedIP() => _cachedIP;
}
