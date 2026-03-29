// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/auth/auth_http_interceptor.dart';
import 'package:portugal_guide/app/core/config/correlation_id_interceptor.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_model.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_repository_interface.dart';

/// Implementação concreta do UserTrackingDataRepository
/// Consome endpoints da API de User Rankings (/api/v1/user-rankings)
/// 
/// Documentação: .local_knowledge/FLUTTER_USER_TRACKING_MVP_GUIDE.md
/// 
/// 🎯 Padrão de Arquitetura: Repository Pattern + Dependency Injection
/// ✅ Usa AuthHttpInterceptor para JWT token management automático
/// ✅ Logging extensivo em debug mode
/// ✅ Error handling robusto (não crashar app)
class UserTrackingDataRepository
    implements UserTrackingDataRepositoryInterface {
  final Dio _dio;

  UserTrackingDataRepository() : _dio = _setupDio();

  /// Configuração do Dio com interceptor de autenticação
  /// ✅ Usa AuthHttpInterceptor global para JWT token management
  /// ✅ Usa CorrelationIdInterceptor para rastreamento end-to-end
  /// ✅ Usa LatencyInterceptor para métricas de performance
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
    
    // ✅ Interceptor de Correlation ID (rastreamento de requisições)
    dio.interceptors.add(CorrelationIdInterceptor());
    
    // ✅ Interceptor de Latência (métricas de performance)
    dio.interceptors.add(LatencyInterceptor());

    return dio;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 MÉTODOS HELPER PRIVADOS - DRY PRINCIPLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// ✅ DRY: Método helper privado para construir endpoint base
  /// Single Source of Truth para URL de user-rankings
  String _buildBaseEndpoint() {
    return '/user-rankings';
  }

  /// ✅ DRY: Endpoint específico por userId
  String _buildUserEndpoint(String userId) {
    return '${_buildBaseEndpoint()}/user/$userId';
  }

  /// ✅ DRY: Endpoint específico por ID do ranking
  String _buildRankingByIdEndpoint(String id) {
    return '${_buildBaseEndpoint()}/$id';
  }

  /// ✅ DRY: Endpoint para adicionar pontos
  String _buildAddPointsEndpoint(String userId) {
    return '${_buildUserEndpoint(userId)}/add-points';
  }

  /// ✅ DRY: Endpoint para top rankings
  String _buildTopEndpoint() {
    return '${_buildBaseEndpoint()}/top';
  }

  /// ✅ DRY: Endpoint para buscar por engagement level
  String _buildEngagementLevelEndpoint(String level) {
    return '${_buildBaseEndpoint()}/engagement/$level';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 CRUD BÁSICO
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<UserTrackingDataModel?> createUserTracking(
      UserTrackingDataModel tracking) async {
    try {
      if (kDebugMode) {
        print('🏁 [UserTrackingDataRepository] Criando ranking inicial:');
        print('   - userId: ${tracking.userId}');
        print('   - totalScore: ${tracking.totalScore}');
        print('   - totalActiveDays: ${tracking.totalActiveDays}');
        print('   - streak: ${tracking.consecutiveDaysStreak}');
      }

      final response = await _dio.post(
        _buildBaseEndpoint(),
        data: tracking.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserTrackingDataRepository] Ranking criado com sucesso!');
          print('   - ID retornado: ${response.data['id']}');
          print(
              '   - Engagement Level: ${response.data['engagementLevel']}');
        }

        return UserTrackingDataModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      if (kDebugMode) {
        print(
            '⚠️  [UserTrackingDataRepository] Status inesperado: ${response.statusCode}');
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro ao criar ranking:');
        print('   - Tipo: ${e.type}');
        print('   - Status Code: ${e.response?.statusCode}');
        print('   - Mensagem: ${e.message}');

        if (e.response?.statusCode == 409) {
          print(
              '   ⚠️  Conflict: Usuário já tem ranking (usar getUserTrackingByUserId)');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro inesperado: $e');
      }
      return null;
    }
  }

  @override
  Future<UserTrackingDataModel?> updateUserTracking(
      String id, UserTrackingDataModel tracking) async {
    try {
      if (kDebugMode) {
        print('🔄 [UserTrackingDataRepository] Atualizando ranking:');
        print('   - ID: $id');
        print('   - totalActiveDays: ${tracking.totalActiveDays}');
        print('   - streak: ${tracking.consecutiveDaysStreak}');
      }

      final response = await _dio.put(
        _buildRankingByIdEndpoint(id),
        data: tracking.toJson(),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserTrackingDataRepository] Ranking atualizado!');
        }

        return UserTrackingDataModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro ao atualizar ranking:');
        print('   - Status Code: ${e.response?.statusCode}');
        print('   - Mensagem: ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro inesperado: $e');
      }
      return null;
    }
  }

  @override
  Future<UserTrackingDataModel?> getUserTrackingByUserId(String userId) async {
    try {
      if (kDebugMode) {
        print('🔍 [UserTrackingDataRepository] Buscando ranking do usuário:');
        print('   - userId: $userId');
      }

      final response = await _dio.get(_buildUserEndpoint(userId));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserTrackingDataRepository] Ranking encontrado!');
          print('   - Score: ${response.data['totalScore']}');
          print('   - Level: ${response.data['engagementLevel']}');
        }

        return UserTrackingDataModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        if (e.response?.statusCode == 404) {
          print(
              '⚠️  [UserTrackingDataRepository] Ranking não encontrado (404)');
          print('   → Usuário ainda não tem ranking. Criar com POST.');
        } else {
          print('❌ [UserTrackingDataRepository] Erro ao buscar ranking:');
          print('   - Status Code: ${e.response?.statusCode}');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro inesperado: $e');
      }
      return null;
    }
  }

  @override
  Future<UserTrackingDataModel?> getUserTrackingById(String id) async {
    try {
      final response = await _dio.get(_buildRankingByIdEndpoint(id));

      if (response.statusCode == 200) {
        return UserTrackingDataModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro ao buscar por ID: $e');
      }
      return null;
    }
  }

  @override
  Future<bool> deleteUserTracking(String id) async {
    try {
      if (kDebugMode) {
        print('🗑️  [UserTrackingDataRepository] Deletando ranking: $id');
      }

      final response = await _dio.delete(_buildRankingByIdEndpoint(id));

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) {
          print('✅ [UserTrackingDataRepository] Ranking deletado!');
        }
        return true;
      }

      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro ao deletar: $e');
      }
      return false;
    }
  }

  @override
  Future<UserTrackingDataModel?> restoreUserTracking(String id) async {
    try {
      if (kDebugMode) {
        print('♻️  [UserTrackingDataRepository] Restaurando ranking: $id');
      }

      final response =
          await _dio.put('${_buildRankingByIdEndpoint(id)}/restore');

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserTrackingDataRepository] Ranking restaurado!');
        }

        return UserTrackingDataModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro ao restaurar: $e');
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 OPERAÇÕES ESPECÍFICAS DE GAMIFICAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<UserTrackingDataModel?> addPoints(String userId, int points) async {
    try {
      if (kDebugMode) {
        print('➕ [UserTrackingDataRepository] Adicionando pontos:');
        print('   - userId: $userId');
        print('   - pontos: +$points');
      }

      final response = await _dio.post(
        _buildAddPointsEndpoint(userId),
        queryParameters: {'points': points},
      );

      if (response.statusCode == 200) {
        final updated = UserTrackingDataModel.fromJson(
            response.data as Map<String, dynamic>);

        if (kDebugMode) {
          print('✅ [UserTrackingDataRepository] Pontos adicionados!');
          print('   - Novo score: ${updated.totalScore}');
          print('   - Nível: ${updated.engagementLevel}');
          print('   - Streak: ${updated.consecutiveDaysStreak} dias');
        }

        return updated;
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro ao adicionar pontos:');
        print('   - Status Code: ${e.response?.statusCode}');
        print('   - Mensagem: ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro inesperado: $e');
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏆 RANKING E LEADERBOARDS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<UserTrackingDataModel>> getTopUsersByScore(
      {int limit = 10}) async {
    try {
      if (kDebugMode) {
        print('🏆 [UserTrackingDataRepository] Buscando top $limit usuários');
      }

      final response = await _dio.get(
        _buildTopEndpoint(),
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;

        if (kDebugMode) {
          print('✅ [UserTrackingDataRepository] Top ${data.length} carregado!');
        }

        return data
            .map((json) =>
                UserTrackingDataModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro ao buscar top: $e');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro inesperado: $e');
      }
      return [];
    }
  }

  @override
  Future<List<UserTrackingDataModel>> getUsersByEngagementLevel(
      String level) async {
    try {
      if (kDebugMode) {
        print(
            '📊 [UserTrackingDataRepository] Buscando usuários nível: $level');
      }

      final response = await _dio.get(_buildEngagementLevelEndpoint(level));

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;

        return data
            .map((json) =>
                UserTrackingDataModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print(
            '❌ [UserTrackingDataRepository] Erro ao buscar por engagement: $e');
      }
      return [];
    }
  }

  @override
  Future<List<UserTrackingDataModel>> getAllUserTrackings() async {
    try {
      if (kDebugMode) {
        print('📋 [UserTrackingDataRepository] Buscando todos os rankings');
      }

      final response = await _dio.get(_buildBaseEndpoint());

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;

        if (kDebugMode) {
          print(
              '✅ [UserTrackingDataRepository] ${data.length} rankings carregados');
        }

        return data
            .map((json) =>
                UserTrackingDataModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataRepository] Erro ao buscar todos: $e');
      }
      return [];
    }
  }
}
