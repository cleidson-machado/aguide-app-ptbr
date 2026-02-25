// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/auth/auth_http_interceptor.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_repository_interface.dart';

/// Implementação concreta do Repository de Ownership
class OwnershipRepository implements OwnershipRepositoryInterface {
  final Dio _dio;

  OwnershipRepository({Dio? dio}) : _dio = dio ?? _setupDio();

  /// Configurações customizadas do Dio para Ownership
  /// Usa AuthHttpInterceptor global para autenticação
  static Dio _setupDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvKeyHelperConfig.mocApi2,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        validateStatus: (status) {
          // Aceitar tanto 200 (sucesso) quanto 404 (not found)
          // Ambos são respostas válidas da API
          return status != null && (status == 200 || status == 404);
        },
      ),
    );

    // Adicionar interceptor de autenticação
    final tokenManager = injector<AuthTokenManager>();
    final devToken = EnvKeyHelperConfig.tokenKeyForMocApi2;

    dio.interceptors.add(
      AuthHttpInterceptor(
        tokenManager,
        fallbackToken: devToken,
      ),
    );

    return dio;
  }

  @override
  Future<OwnershipResult> checkContentOwnership({
    required String userId,
    required String contentId,
  }) async {
    print('🔍 [OwnershipRepository] Verificando ownership');
    print('   User ID: $userId');
    print('   Content ID: $contentId');

    try {
      final endpoint = '/ownership/user/$userId/content';
      
      final response = await _dio.get(endpoint);

      print('📡 [OwnershipRepository] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // ✅ Sucesso: usuário tem conteúdos verificados
        final List<dynamic> dataList = response.data as List<dynamic>;
        final contents = dataList
            .map((json) => OwnershipContentModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Verificar se o contentId específico está na lista
        final hasContent = contents.any((c) => c.contentId == contentId);
        
        if (hasContent) {
          print('✅ [OwnershipRepository] Ownership confirmado!');
          return OwnershipResult.success(contents);
        } else {
          // Usuário tem conteúdos, mas não este específico
          print('⚠️  [OwnershipRepository] Conteúdo não pertence ao usuário');
          final error = OwnershipErrorModel(
            error: 'NOT_OWNER',
            message: 'Este conteúdo não pertence ao usuário logado',
            timestamp: DateTime.now().toIso8601String(),
          );
          return OwnershipResult.notOwner(error);
        }
      } else if (response.statusCode == 404) {
        // ❌ Erro: usuário não tem conteúdos verificados
        final errorData = response.data as Map<String, dynamic>;
        final error = OwnershipErrorModel.fromJson(errorData);
        
        print('❌ [OwnershipRepository] Ownership não encontrado');
        print('   Erro: ${error.error}');
        print('   Mensagem: ${error.message}');
        
        return OwnershipResult.notOwner(error);
      } else {
        // Status code inesperado
        throw Exception('Status code inesperado: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [OwnershipRepository] Erro Dio: ${e.message}');
      
      if (e.response?.statusCode == 404) {
        // Tratar 404 como "não é dono"
        final errorData = e.response?.data as Map<String, dynamic>?;
        if (errorData != null) {
          final error = OwnershipErrorModel.fromJson(errorData);
          return OwnershipResult.notOwner(error);
        }
      }
      
      // Outros erros
      final error = OwnershipErrorModel(
        error: 'NETWORK_ERROR',
        message: 'Erro ao verificar autoria: ${e.message}',
        timestamp: DateTime.now().toIso8601String(),
      );
      return OwnershipResult.notOwner(error);
    } catch (e) {
      print('❌ [OwnershipRepository] Erro inesperado: $e');
      
      final error = OwnershipErrorModel(
        error: 'UNEXPECTED_ERROR',
        message: 'Erro inesperado ao verificar autoria',
        timestamp: DateTime.now().toIso8601String(),
      );
      return OwnershipResult.notOwner(error);
    }
  }

  @override
  Future<OwnershipResult> getUserVerifiedContents({
    required String userId,
  }) async {
    print('📋 [OwnershipRepository] Buscando conteúdos verificados');
    print('   User ID: $userId');

    try {
      final endpoint = '/ownership/user/$userId/content';
      
      final response = await _dio.get(endpoint);

      print('📡 [OwnershipRepository] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // ✅ Sucesso: usuário tem conteúdos verificados
        final List<dynamic> dataList = response.data as List<dynamic>;
        final contents = dataList
            .map((json) => OwnershipContentModel.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ [OwnershipRepository] ${contents.length} conteúdo(s) encontrado(s)');
        return OwnershipResult.success(contents);
      } else if (response.statusCode == 404) {
        // ❌ Erro: usuário não tem conteúdos verificados
        final errorData = response.data as Map<String, dynamic>;
        final error = OwnershipErrorModel.fromJson(errorData);
        
        print('❌ [OwnershipRepository] Nenhum conteúdo verificado');
        return OwnershipResult.notOwner(error);
      } else {
        throw Exception('Status code inesperado: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [OwnershipRepository] Erro Dio: ${e.message}');
      
      if (e.response?.statusCode == 404) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        if (errorData != null) {
          final error = OwnershipErrorModel.fromJson(errorData);
          return OwnershipResult.notOwner(error);
        }
      }
      
      final error = OwnershipErrorModel(
        error: 'NETWORK_ERROR',
        message: 'Erro ao buscar conteúdos: ${e.message}',
        timestamp: DateTime.now().toIso8601String(),
      );
      return OwnershipResult.notOwner(error);
    } catch (e) {
      print('❌ [OwnershipRepository] Erro inesperado: $e');
      
      final error = OwnershipErrorModel(
        error: 'UNEXPECTED_ERROR',
        message: 'Erro inesperado ao buscar conteúdos',
        timestamp: DateTime.now().toIso8601String(),
      );
      return OwnershipResult.notOwner(error);
    }
  }
}
