import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/repositories/gen_crud_repo.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user/user_model.dart';

class UserRepository extends GenCrudRepo<UserModel> {

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
}