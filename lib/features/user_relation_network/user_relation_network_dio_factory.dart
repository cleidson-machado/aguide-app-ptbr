import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/auth/auth_http_interceptor.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/correlation_id_interceptor.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';

/// Cliente Dio autenticado compartilhado pelos repositórios da tela de relações.
Dio buildUserRelationNetworkDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvKeyHelperConfig.apiBaseUrl,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.addAll([
    AuthHttpInterceptor(
      injector<AuthTokenManager>(),
      fallbackToken: EnvKeyHelperConfig.tokenKeyForMocApi2,
    ),
    CorrelationIdInterceptor(),
    LatencyInterceptor(),
  ]);

  return dio;
}
