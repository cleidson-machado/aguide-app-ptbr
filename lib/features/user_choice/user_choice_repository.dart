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

  /// Helper privado: Endpoint para buscar perfil do usuário (Find By User Id)
  /// Documentação: GET /api/v1/user-choices/user/{userId}
  String _getUserActiveProfileEndpoint(String userId) {
    return '/user-choices/user/$userId';
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
      print('\n🌐 [UserChoiceRepository] ==================== INÍCIO CHAMADA API ====================');
      print('📍 [UserChoiceRepository] Buscando user-choice do usuário: $userId');
      print('📌 [UserChoiceRepository] userId = ID da chave primária na tabela users (PostgreSQL)');
      
      final endpoint = _getUserActiveProfileEndpoint(userId);
      print('🔗 [UserChoiceRepository] Endpoint: $endpoint');
      print('🌍 [UserChoiceRepository] URL completa: ${EnvKeyHelperConfig.apiBaseUrl}$endpoint');

      final response = await dioGenCrudRepo.get(endpoint);

      print('📡 [UserChoiceRepository] Status HTTP: ${response.statusCode}');
      print('📦 [UserChoiceRepository] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        print('✅ [UserChoiceRepository] User-choice encontrado - convertendo para model...');
        final model = UserChoiceModel.fromMap(response.data);
        print('✅ [UserChoiceRepository] Model criado:');
        print('   - id: ${model.id}');
        print('   - userId: ${model.userId}');
        print('   - profileType: ${model.profileType}');
        print('🌐 [UserChoiceRepository] ==================== FIM CHAMADA API (SUCESSO) ====================\n');
        return model;
      }

      print('ℹ️ [UserChoiceRepository] Status 200 mas data é null → retornando null');
      print('🌐 [UserChoiceRepository] ==================== FIM CHAMADA API (NULL) ====================\n');
      return null;
    } on DioException catch (e) {
      print('🚨 [UserChoiceRepository] DioException capturada:');
      print('   - Status code: ${e.response?.statusCode}');
      print('   - Response data: ${e.response?.data}');
      print('   - Message: ${e.message}');
      
      if (e.response?.statusCode == 404) {
        print('ℹ️ [UserChoiceRepository] 404 - Usuário não possui perfil ativo');
        print('🌐 [UserChoiceRepository] ==================== FIM CHAMADA API (404) ====================\n');
        return null;
      }

      print('❌ [UserChoiceRepository] Erro HTTP ${e.response?.statusCode} - rethrowing...');
      print('🌐 [UserChoiceRepository] ==================== FIM CHAMADA API (ERRO) ====================\n');
      rethrow;
    } catch (e) {
      print('❌ [UserChoiceRepository] Erro inesperado:');
      print('   - Tipo: ${e.runtimeType}');
      print('   - Mensagem: $e');
      print('🌐 [UserChoiceRepository] ==================== FIM CHAMADA API (EXCEÇÃO) ====================\n');
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
