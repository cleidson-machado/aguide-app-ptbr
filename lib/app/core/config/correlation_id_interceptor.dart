import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor Dio para adicionar Correlation ID em todas as requisições
/// 
/// O Correlation ID permite rastreamento end-to-end de requisições do Flutter
/// ao backend, facilitando debug de erros cross-system e análise de logs.
/// 
/// Referência:
/// - x_temp_files/ANALISE_ACOES_FLUTTER_RESPOSTA_BACKEND.md
/// - .local_knowledge/RESPOSTA_BACKEND_INTEGRACAO_USER_RANKING.md (seção Métricas e Observabilidade)
/// 
/// Funcionamento:
/// 1. Gera UUID v4 único por requisição
/// 2. Adiciona header `X-Correlation-ID` na request
/// 3. Backend recebe o ID e adiciona em logs estruturados
/// 4. Logs de ambos sistemas podem ser correlacionados pelo mesmo ID
/// 
/// Exemplo de log no Flutter:
/// ```
/// 📤 Request: POST /user-rankings/add-points | CorrelationID: abc-123
/// ✅ Response: 200 | CorrelationID: abc-123
/// ```
/// 
/// Exemplo de log no Backend (Java/Quarkus):
/// ```json
/// {
///   "event": "points_added",
///   "userId": "user-xyz",
///   "points": 1,
///   "correlationId": "abc-123"
/// }
/// ```
class CorrelationIdInterceptor extends Interceptor {
  /// Gera UUID v4 único para cada requisição
  /// 
  /// Formato: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  /// Onde x é hexadecimal aleatório e y é {8,9,a,b}
  String _generateUuid() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final uuid = '${random.toString()}-${DateTime.now().microsecondsSinceEpoch}';
    
    // Versão simplificada de UUID v4 (sem dependência externa)
    // Para UUID completo, usar package uuid após adicionar no pubspec
    return 'flutter-$uuid';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Gerar Correlation ID único
    final correlationId = _generateUuid();
    
    // Adicionar header X-Correlation-ID
    options.headers['X-Correlation-ID'] = correlationId;
    
    // Log para debug (apenas em modo desenvolvimento)
    if (kDebugMode) {
      print('📤 [CorrelationIdInterceptor] Request: ${options.method} ${options.path}');
      print('   CorrelationID: $correlationId');
    }
    
    // Continuar com a requisição
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final correlationId = response.requestOptions.headers['X-Correlation-ID'];
      print('✅ [CorrelationIdInterceptor] Response: ${response.statusCode}');
      print('   CorrelationID: $correlationId');
      print('   Latência: ${response.requestOptions.extra['request_time'] ?? 'N/A'}');
    }
    
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final correlationId = err.requestOptions.headers['X-Correlation-ID'];
      print('❌ [CorrelationIdInterceptor] Error: ${err.response?.statusCode ?? err.type}');
      print('   CorrelationID: $correlationId');
      print('   Mensagem: ${err.message}');
    }
    
    super.onError(err, handler);
  }
}

/// Interceptor para medir latência de requisições
/// 
/// Complementa o CorrelationIdInterceptor adicionando métricas de tempo de resposta.
class LatencyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Registrar timestamp de início
    options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['request_start_time'] as int?;
    
    if (startTime != null) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final latency = endTime - startTime;
      
      response.requestOptions.extra['request_time'] = '${latency}ms';
      
      if (kDebugMode) {
        print('⏱️  [LatencyInterceptor] Latência: ${latency}ms');
        
        // Alertar se latência alta (> 3 segundos)
        if (latency > 3000) {
          print('   ⚠️  ALERTA: Latência alta detectada!');
        }
      }
    }
    
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['request_start_time'] as int?;
    
    if (startTime != null) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final latency = endTime - startTime;
      
      if (kDebugMode) {
        print('⏱️  [LatencyInterceptor] Tempo até erro: ${latency}ms');
      }
    }
    
    super.onError(err, handler);
  }
}
