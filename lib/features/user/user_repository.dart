import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/repositories/gen_crud_repo.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user/user_model.dart';

class UserRepository extends GenCrudRepo<UserModel> implements UserRepositoryInterface {

  UserRepository()
      : super(
          endpoint: '/users',
          fromMap: UserModel.fromMap,
          dio: _setupDio(),
        );

  static Dio _setupDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvKeyHelperConfig.mocApi2,
        headers: {'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          const String tokenTest = 'my-token-super-recur-12345';
          options.headers['Authorization'] = 'Bearer $tokenTest';
          return handler.next(options);
        },
      ),
    );

    return dio;
  }
  
  @override
  Future<void> changeUserPassword(String userId, String newPassword) {
    // TODO: implement changeUserPassword
    throw UnimplementedError();
  }
  
  @override
  Future<UserModel?> findByEmail(String email) {
    // TODO: implement findByEmail
    throw UnimplementedError();
  }
  
  @override
  Future<bool> isEmailAlreadyRegistered(String email) {
    // TODO: implement isEmailAlreadyRegistered
    throw UnimplementedError();
  }
}