// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/auth/auth_http_interceptor.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user_engagement/user_engagement_model.dart';
import 'package:portugal_guide/features/user_engagement/user_engagement_repository_interface.dart';

/// Implementação concreta do UserEngagementRepository
/// Consome endpoints da API de Engagement (/api/v1/engagements)
/// 
/// Documentação: FLUTTER_ENGAGEMENT_API_INTEGRATION_GUIDE.md
class UserEngagementRepository implements UserEngagementRepositoryInterface {
  final Dio _dio;

  UserEngagementRepository() : _dio = _setupDio();

  /// Configuração do Dio com interceptor de autenticação
  /// ✅ Usa AuthHttpInterceptor global para JWT token management
  static Dio _setupDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvKeyHelperConfig.apiBaseUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // ✅ Interceptor de autenticação (adiciona JWT automaticamente)
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

  /// ✅ DRY: Método helper privado para construir endpoint base
  /// Single Source of Truth para URL de engagements
  String _buildBaseEndpoint() {
    return '/engagements';
  }

  /// ✅ DRY: Endpoint para engagements de um conteúdo específico
  String _buildContentEndpoint(String contentId) {
    return '${_buildBaseEndpoint()}/content/$contentId';
  }

  /// ✅ DRY: Endpoint para engagementss de um usuário
  String _buildUserEndpoint(String userId) {
    return '${_buildBaseEndpoint()}/user/$userId';
  }

  /// ✅ DRY: Endpoint para um engagement específico por ID
  String _buildEngagementByIdEndpoint(String engagementId) {
    return '${_buildBaseEndpoint()}/$engagementId';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 MÉTODO PRINCIPAL: Criar Engagement (Usado ao clicar em conteúdo)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<UserEngagementModel?> createEngagement(UserEngagementModel engagement) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Criando engagement:');
        print('   - userId: ${engagement.userId}');
        print('   - contentId: ${engagement.contentId}');
        print('   - type: ${engagement.engagementType}');
        print('   - source: ${engagement.source}');
        print('   - platform: ${engagement.platform}');
      }

      final response = await _dio.post(
        _buildBaseEndpoint(),
        data: engagement.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserEngagementRepository] Engagement criado com sucesso!');
          print('   - ID retornado: ${response.data['id']}');
          print('   - Status: ${response.data['engagementStatus']}');
        }

        return UserEngagementModel.fromJson(response.data as Map<String, dynamic>);
      }

      if (kDebugMode) {
        print('⚠️  [UserEngagementRepository] Status inesperado: ${response.statusCode}');
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro DioException ao criar engagement:');
        print('   - Tipo: ${e.type}');
        print('   - Mensagem: ${e.message}');
        print('   - Response: ${e.response?.data}');
      }
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro inesperado ao criar engagement: $e');
        print('   - StackTrace: $stackTrace');
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔄 Atualizar Engagement (Ex: adicionar tempo de visualização)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<UserEngagementModel?> updateEngagement(
    String engagementId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Atualizando engagement $engagementId');
        print('   - Updates: $updates');
      }

      final response = await _dio.put(
        _buildEngagementByIdEndpoint(engagementId),
        data: updates,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserEngagementRepository] Engagement atualizado com sucesso!');
        }
        return UserEngagementModel.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao atualizar engagement: ${e.message}');
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 Buscar Engagements de um Conteúdo
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<UserEngagementModel>> getContentEngagements(String contentId) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Buscando engagements do conteúdo: $contentId');
      }

      final response = await _dio.get(_buildContentEndpoint(contentId));

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final engagements = (data['engagements'] as List<dynamic>)
            .map((json) => UserEngagementModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print('✅ [UserEngagementRepository] ${engagements.length} engagements encontrados');
        }

        return engagements;
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao buscar engagements: ${e.message}');
      }
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 Estatísticas de um Conteúdo (Views, Likes, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getContentStats(String contentId) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Buscando stats do conteúdo: $contentId');
      }

      final response = await _dio.get('${_buildContentEndpoint(contentId)}/stats');

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserEngagementRepository] Stats obtidas com sucesso');
        }
        return response.data as Map<String, dynamic>;
      }

      return {};
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao buscar stats: ${e.message}');
      }
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 👤 Buscar Engagements de um Usuário (Histórico Completo)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<UserEngagementModel>> getUserEngagements(String userId) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Buscando engagements do usuário: $userId');
      }

      final response = await _dio.get(_buildUserEndpoint(userId));

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final engagements = (data['engagements'] as List<dynamic>)
            .map((json) => UserEngagementModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print('✅ [UserEngagementRepository] ${engagements.length} engagements do usuário');
        }

        return engagements;
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao buscar engagements: ${e.message}');
      }
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 Engagements Recentes do Usuário (Para "Assistidos Recentemente")
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<UserEngagementModel>> getUserRecentEngagements(
    String userId, {
    int days = 7,
  }) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Buscando engagements recentes (últimos $days dias)');
      }

      final response = await _dio.get(
        '${_buildUserEndpoint(userId)}/recent',
        queryParameters: {'days': days},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final engagements = (data['engagements'] as List<dynamic>)
            .map((json) => UserEngagementModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print('✅ [UserEngagementRepository] ${engagements.length} engagements recentes');
        }

        return engagements;
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao buscar recentes: ${e.message}');
      }
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📈 Estatísticas do Usuário
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Buscando stats do usuário: $userId');
      }

      final response = await _dio.get('${_buildUserEndpoint(userId)}/stats');

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserEngagementRepository] Stats do usuário obtidas');
        }
        return response.data as Map<String, dynamic>;
      }

      return {};
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao buscar stats: ${e.message}');
      }
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔝 Conteúdos Mais Interagidos (Para Recomendações)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getUserTopContents(
    String userId, {
    int limit = 10,
  }) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Buscando top $limit conteúdos do usuário');
      }

      final response = await _dio.get(
        '${_buildUserEndpoint(userId)}/top-contents',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final topContents = (data['topContents'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();

        if (kDebugMode) {
          print('✅ [UserEngagementRepository] ${topContents.length} top contents encontrados');
        }

        return topContents;
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao buscar top contents: ${e.message}');
      }
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔍 Buscar Engagement Específico por ID
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<UserEngagementModel?> getEngagementById(String engagementId) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Buscando engagement: $engagementId');
      }

      final response = await _dio.get(_buildEngagementByIdEndpoint(engagementId));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserEngagementRepository] Engagement encontrado');
        }
        return UserEngagementModel.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao buscar engagement: ${e.message}');
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🗑️ Deletar Engagement (Soft Delete)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> deleteEngagement(String engagementId) async {
    try {
      if (kDebugMode) {
        print('📊 [UserEngagementRepository] Deletando engagement: $engagementId');
      }

      final response = await _dio.delete(_buildEngagementByIdEndpoint(engagementId));

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserEngagementRepository] Engagement deletado com sucesso');
        }
        return true;
      }

      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserEngagementRepository] Erro ao deletar engagement: ${e.message}');
      }
      return false;
    }
  }
}
