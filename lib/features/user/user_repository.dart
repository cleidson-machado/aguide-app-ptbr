import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/repositories/gen_crud_repository.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user/user_model.dart';

class UserRepository extends GenCrudRepository<UserModel>
    implements UserRepositoryInterface {
  UserRepository()
    : super(endpoint: '/users', fromMap: UserModel.fromMap, dio: _setupDio());

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
          // Obtém o token dinâmico JWT do usuário autenticado via AuthTokenManager
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

  // ##################################################################
  // ### IMPLEMENTAÇÃO CORRIGIDA DOS MÉTODOS ESPECÍFICOS ###
  // ##################################################################

  @override
  Future<void> changeUserPassword(String userId, String newPassword) async {
    try {
      // MUDANÇA: Usa os getters 'dio' e 'endpoint'
      final response = await dioGenCrudRepo.put(
        '$endpointGenCrudRepo/$userId/password', // Usa o getter 'endpoint'
        data: {'password': newPassword},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing user password: $e');
    }
  }

  @override
  Future<UserModel?> findByEmail(String email) async {
    try {
      // MUDANÇA: Agora usamos os getters 'dio' e 'endpoint' da classe pai.
      final response = await dioGenCrudRepo.get(
        endpointGenCrudRepo, // Usa o getter 'endpoint'
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty) {
          // MUDANÇA: Usa o getter 'fromMap'
          return fromMap(data.first);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error finding user by email: $e');
    }
  }

  @override
  Future<bool> isEmailAlreadyRegistered(String email) async {
    try {
      final user = await findByEmail(email);
      return user != null;
    } catch (e) {
      throw Exception('Error checking if email is registered: $e');
    }
  }
}
