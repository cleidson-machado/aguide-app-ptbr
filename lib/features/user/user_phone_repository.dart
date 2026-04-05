import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/user/user_phone_model.dart';
import 'package:portugal_guide/features/user/user_phone_repository_interface.dart';

/// Implementação do repositório de telefones de usuário
/// 
/// Usa Dio para chamadas HTTP com autenticação JWT automática
class UserPhoneRepository implements UserPhoneRepositoryInterface {
  late final Dio _dio;

  UserPhoneRepository() {
    _dio = _setupDio();
  }

  /// Configura cliente Dio com autenticação JWT
  static Dio _setupDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvKeyHelperConfig.apiBaseUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Obtém token JWT do usuário autenticado
          final authToken = injector<AuthTokenManager>().getAuthorizationHeader();
          if (authToken != null) {
            options.headers['Authorization'] = authToken;
          }
          return handler.next(options);
        },
      ),
    );

    return dio;
  }

  @override
  Future<List<UserPhoneModel>> getUserPhones(String userId) async {
    try {
      if (kDebugMode) {
        print('📞 [UserPhoneRepository] GET /api/v1/users/$userId/phones');
      }

      final response = await _dio.get('/api/v1/users/$userId/phones');

      if (kDebugMode) {
        print('📞 [UserPhoneRepository] Response status: ${response.statusCode}');
        print('📞 [UserPhoneRepository] Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        
        final phones = data
            .map((json) => UserPhoneModel.fromMap(json as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print('✅ [UserPhoneRepository] Loaded ${phones.length} phones');
        }

        return phones;
      } else if (response.statusCode == 404) {
        // Usuário sem telefones
        if (kDebugMode) {
          print('ℹ️ [UserPhoneRepository] User has no phones (404)');
        }
        return [];
      } else {
        throw Exception('Failed to load phones: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️ [UserPhoneRepository] User has no phones (404)');
        }
        return [];
      }

      if (kDebugMode) {
        print('❌ [UserPhoneRepository] Error loading phones: $e');
      }
      throw Exception('Error loading user phones: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserPhoneRepository] Unexpected error: $e');
      }
      throw Exception('Error loading user phones: $e');
    }
  }

  @override
  Future<UserPhoneModel> createPhone(String userId, Map<String, dynamic> phoneData) async {
    try {
      if (kDebugMode) {
        print('📞 [UserPhoneRepository] POST /api/v1/users/$userId/phones');
        print('   Data: $phoneData');
      }

      final response = await _dio.post(
        '/api/v1/users/$userId/phones',
        data: phoneData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final phone = UserPhoneModel.fromMap(response.data as Map<String, dynamic>);
        
        if (kDebugMode) {
          print('✅ [UserPhoneRepository] Phone created: ${phone.id}');
        }

        return phone;
      } else {
        throw Exception('Failed to create phone: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserPhoneRepository] Error creating phone: $e');
      }
      throw Exception('Error creating phone: $e');
    }
  }

  @override
  Future<UserPhoneModel> updatePhone(String phoneId, Map<String, dynamic> phoneData) async {
    try {
      if (kDebugMode) {
        print('📞 [UserPhoneRepository] PUT /api/v1/phones/$phoneId');
        print('   Data: $phoneData');
      }

      final response = await _dio.put(
        '/api/v1/phones/$phoneId',
        data: phoneData,
      );

      if (response.statusCode == 200) {
        final phone = UserPhoneModel.fromMap(response.data as Map<String, dynamic>);
        
        if (kDebugMode) {
          print('✅ [UserPhoneRepository] Phone updated: ${phone.id}');
        }

        return phone;
      } else {
        throw Exception('Failed to update phone: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserPhoneRepository] Error updating phone: $e');
      }
      throw Exception('Error updating phone: $e');
    }
  }

  @override
  Future<void> deletePhone(String phoneId) async {
    try {
      if (kDebugMode) {
        print('📞 [UserPhoneRepository] DELETE /api/v1/phones/$phoneId');
      }

      final response = await _dio.delete('/api/v1/phones/$phoneId');

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserPhoneRepository] Phone deleted: $phoneId');
        }
      } else {
        throw Exception('Failed to delete phone: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserPhoneRepository] Error deleting phone: $e');
      }
      throw Exception('Error deleting phone: $e');
    }
  }

  @override
  Future<void> setPrimaryPhone(String userId, String phoneId) async {
    try {
      if (kDebugMode) {
        print('📞 [UserPhoneRepository] PUT /api/v1/users/$userId/phones/$phoneId/primary');
      }

      final response = await _dio.put('/api/v1/users/$userId/phones/$phoneId/primary');

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [UserPhoneRepository] Primary phone set: $phoneId');
        }
      } else {
        throw Exception('Failed to set primary phone: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserPhoneRepository] Error setting primary phone: $e');
      }
      throw Exception('Error setting primary phone: $e');
    }
  }
}
