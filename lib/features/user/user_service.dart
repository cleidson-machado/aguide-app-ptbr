import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user/user_model.dart';
import 'package:portugal_guide/util/error_messages.dart';
import 'package:portugal_guide/util/service_data_exception.dart';


final String apiUrl = EnvKeyHelperConfig.mocApi1;

class UserService {
  final Logger _logger = Logger();

  Future<List<UserModel>> fetchUsersBasicWay() async {

    final result = await Dio().get('$apiUrl/user/');

    if (result.statusCode == 200) {
      List<dynamic> data = result.data; 
      return data.map((user) => UserModel.fromMap(user)).toList();
    } else {
      throw ServiceDataException.handler(ErrorMessages.FAILED_TO_LOAD_USERS_MESSAGE);
    } 

  }

  Future<List<UserModel>> fetchUsers() async {
    await Future.delayed(const Duration(seconds: 5)); // Simulate a 5-second delay

    try {
      final result = await Dio().get('$apiUrl/user/');
      if (result.statusCode == 200) {
        List<dynamic> data = result.data;
        return data.map((user) => UserModel.fromMap(user)).toList();
      } else {
        throw ServiceDataException.handler(ErrorMessages.FAILED_TO_LOAD_USERS_MESSAGE);
      }
    } catch (e) {
      _logger.e('Error fetching users', error: e);
      throw ServiceDataException.handler('${ErrorMessages.ERROR_FETCHING_USERS_MESSAGE}: $e');
    }
  }
}