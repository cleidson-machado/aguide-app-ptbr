import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 🐛 Debug Logger para OAuth Google
/// 
/// Salva dados JSON de autenticação Google em arquivo .log
/// para fins de análise e estudo durante desenvolvimento.
/// 
/// **ATENÇÃO:** Este logger só funciona em modo DEBUG.
/// Dados sensíveis NUNCA são salvos em produção.
class OAuthDebugLogger {
  /// Flag para ativar/desativar logging
  /// 
  /// ⚠️ Defina como `false` ao comitar código
  static const bool isEnabled = true;

  /// Nome do arquivo de log
  static const String _logFileName = 'google_oauth_debug.log';

  /// Formato de timestamp
  static final DateFormat _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  /// Salva dados do Google OAuth em arquivo .log
  /// 
  /// **Estrutura do Log:**
  /// ```json
  /// {
  ///   "timestamp": "2026-02-15 14:30:45.123",
  ///   "loginEvent": "GOOGLE_OAUTH_SUCCESS",
  ///   "googleData": {
  ///     "id": "...",
  ///     "email": "...",
  ///     "displayName": "...",
  ///     "photoUrl": "...",
  ///     "accessToken": "...",
  ///     "idToken": "...",
  ///     "scopes": [...]
  ///   },
  ///   "backendResponse": {
  ///     "token": "...",
  ///     "user": {...}
  ///   }
  /// }
  /// ```
  static Future<void> logOAuthData({
    required Map<String, dynamic> googleData,
    Map<String, dynamic>? backendResponse,
    String? errorMessage,
  }) async {
    // 🚫 Apenas em modo DEBUG
    if (!kDebugMode || !isEnabled) {
      return;
    }

    try {
      final file = await _getLogFile();
      
      // Estrutura do log
      final logEntry = {
        'timestamp': _timestampFormat.format(DateTime.now()),
        'loginEvent': errorMessage == null ? 'GOOGLE_OAUTH_SUCCESS' : 'GOOGLE_OAUTH_ERROR',
        if (errorMessage != null) 'error': errorMessage,
        'googleData': googleData,
        if (backendResponse != null) 'backendResponse': backendResponse,
      };

      // JSON formatado com indentação
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(logEntry);

      // Sobrescreve o arquivo (sempre mantém apenas o último login)
      await file.writeAsString(prettyJson);

      debugPrint('📝 [OAuthDebugLogger] Log salvo em: ${file.path}');
      debugPrint('📂 [OAuthDebugLogger] Acesse o arquivo via: Files > On My iPhone > Portugal Guide');
    } catch (e) {
      debugPrint('❌ [OAuthDebugLogger] Erro ao salvar log: $e');
    }
  }

  /// Obtém referência ao arquivo de log
  /// 
  /// **Localização:**
  /// - iOS: Documents/google_oauth_debug.log (visível no Files app)
  /// - Android: Documents/google_oauth_debug.log (visível no File Manager)
  static Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_logFileName');
  }

  /// Lê o conteúdo atual do log (para debug no console)
  static Future<String?> readLog() async {
    if (!kDebugMode || !isEnabled) {
      return null;
    }

    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('❌ [OAuthDebugLogger] Erro ao ler log: $e');
      return null;
    }
  }

  /// Deleta o arquivo de log (limpeza)
  static Future<void> clearLog() async {
    if (!kDebugMode) {
      return;
    }

    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ [OAuthDebugLogger] Log deletado');
      }
    } catch (e) {
      debugPrint('❌ [OAuthDebugLogger] Erro ao deletar log: $e');
    }
  }

  /// Imprime caminho do arquivo de log no console
  static Future<void> printLogPath() async {
    if (!kDebugMode || !isEnabled) {
      return;
    }

    try {
      final file = await _getLogFile();
      debugPrint('📂 [OAuthDebugLogger] Caminho do log: ${file.path}');
      debugPrint('📂 [OAuthDebugLogger] Arquivo existe: ${await file.exists()}');
    } catch (e) {
      debugPrint('❌ [OAuthDebugLogger] Erro ao obter caminho: $e');
    }
  }

  /// 🚀 HELPER: Imprime conteúdo completo do log no console
  /// Útil quando não tem acesso ao adb (Android) ou não encontra o arquivo
  static Future<void> printLogToConsole() async {
    if (!kDebugMode || !isEnabled) {
      return;
    }

    try {
      final content = await readLog();
      if (content != null) {
        debugPrint('\n' + '=' * 80);
        debugPrint('📜 [OAuthDebugLogger] CONTEÚDO DO LOG:');
        debugPrint('=' * 80);
        debugPrint(content);
        debugPrint('=' * 80 + '\n');
      } else {
        debugPrint('⚠️ [OAuthDebugLogger] Log ainda não existe. Faça login com Google primeiro.');
      }
    } catch (e) {
      debugPrint('❌ [OAuthDebugLogger] Erro ao ler log: $e');
    }
  }
}
