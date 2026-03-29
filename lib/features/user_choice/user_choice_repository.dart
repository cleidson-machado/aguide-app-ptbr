// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/repositories/gen_crud_repository.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/auth/auth_http_interceptor.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user_choice/user_choice_model.dart';
import 'package:portugal_guide/features/user_choice/user_choice_repository_interface.dart';

/// Implementação do Repository de UserChoice
/// Consome API REST: /api/v1/user-choices
class UserChoiceRepository extends GenCrudRepository<UserChoiceModel>
    implements UserChoiceRepositoryInterface {
  UserChoiceRepository()
      : super(
          endpoint: '/user-choices',
          fromMap: UserChoiceModel.fromMap,
          dio: _setupDio(),
        );

  /// Configuração do Dio com autenticação e interceptors
  static Dio _setupDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvKeyHelperConfig.apiBaseUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Adicionar interceptor de autenticação global
    final tokenManager = injector<AuthTokenManager>();
    final devToken = EnvKeyHelperConfig.tokenKeyForMocApi2;

    dio.interceptors.add(
      AuthHttpInterceptor(
        tokenManager,
        fallbackToken: devToken,
      ),
    );

    // Adicionar interceptor de logs (apenas em dev)
    if (EnvKeyHelperConfig.label.toUpperCase() == 'DEV') {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => print('🌐 [UserChoiceRepository] $obj'),
        ),
      );
    }

    return dio;
  }

  /// Helper privado: Endpoint para buscar perfil ativo do usuário
  String _getUserActiveProfileEndpoint(String userId) {
    return '/user-choices/user/$userId/active';
  }

  /// Helper privado: Endpoint para buscar todos os perfís de um usuário
  String _getUserProfilesEndpoint(String userId) {
    return '/user-choices/user/$userId';
  }

  /// Helper privado: Endpoint para buscar por tipo de perfil
  String _getByProfileTypeEndpoint(String profileType) {
    return '/user-choices/profile-type/$profileType';
  }

  /// Helper privado: Endpoint para buscar por nicho
  String _getByNicheEndpoint(String nicheContext) {
    return '/user-choices/niche/$nicheContext';
  }

  // ==================== ENDPOINTS ESPECÍFICOS ====================

  @override
  Future<UserChoiceModel?> getUserActiveProfile(String userId) async {
    try {
      print('📍 [UserChoiceRepository] Buscando perfil ativo do usuário: $userId');

      final response = await dioGenCrudRepo.get(
        _getUserActiveProfileEndpoint(userId),
      );

      if (response.statusCode == 200 && response.data != null) {
        print('✅ [UserChoiceRepository] Perfil ativo encontrado');
        return UserChoiceModel.fromMap(response.data);
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print('ℹ️ [UserChoiceRepository] Usuário não possui perfil ativo');
        return null;
      }

      print('❌ [UserChoiceRepository] Erro ao buscar perfil ativo: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [UserChoiceRepository] Erro inesperado: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserChoiceModel>> getUserProfiles(
    String userId, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      print('📍 [UserChoiceRepository] Buscando perfis do usuário: $userId (page: $page, size: $size)');

      final response = await dioGenCrudRepo.get(
        _getUserProfilesEndpoint(userId),
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> items = response.data['items'] ?? [];
        print('✅ [UserChoiceRepository] ${items.length} perfis encontrados');

        return items
            .map((item) => UserChoiceModel.fromMap(item))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ [UserChoiceRepository] Erro ao buscar perfis: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<List<UserChoiceModel>> getByProfileType(
    String profileType, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      print('📍 [UserChoiceRepository] Buscando perfis do tipo: $profileType');

      final response = await dioGenCrudRepo.get(
        _getByProfileTypeEndpoint(profileType),
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> items = response.data['items'] ?? [];
        print('✅ [UserChoiceRepository] ${items.length} perfis encontrados');

        return items
            .map((item) => UserChoiceModel.fromMap(item))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ [UserChoiceRepository] Erro ao buscar por tipo: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<List<UserChoiceModel>> getByNiche(
    String nicheContext, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      print('📍 [UserChoiceRepository] Buscando perfis do nicho: $nicheContext');

      final response = await dioGenCrudRepo.get(
        _getByNicheEndpoint(nicheContext),
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> items = response.data['items'] ?? [];
        print('✅ [UserChoiceRepository] ${items.length} perfis encontrados');

        return items
            .map((item) => UserChoiceModel.fromMap(item))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ [UserChoiceRepository] Erro ao buscar por nicho: ${e.message}');
      rethrow;
    }
  }

  // ==================== CRUD BÁSICO (HERDADO) ====================
  // create(), getById(), getAll(), update(), destroy()
  // Já implementados em GenCrudRepository
}
