import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final String _baseUrl =  '${EnvKeyHelperConfig.mocApi2}/users/';

  final String _tokenTest = 'my-token-super-recur-12345';

  // Headers padrão para todas as requisições
  Map<String, String> get _headersFull => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $_tokenTest',
  };

  Future<List<UserModel>> fetchUsers() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {'Authorization': 'Bearer $_tokenTest'}, // GET geralmente não precisa de Content-Type
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // CORRIGIDO: Usar fromMap pois data já é um Map, não um String
      return data.map((json) => UserModel.fromMap(json)).toList();
    } else {
      throw Exception('Erro ao carregar usuários');
    }
  }

  // Assinatura e corpo atualizados para corresponder à API
  Future<void> addUser(String name, String surname, String email, String password) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headersFull, // Usando o getter com headers separados
      body: json.encode({
        'name': name,
        'surname': surname,
        'email': email,
        'passwd': password,
      }),
    );
    
    if (response.statusCode != 201) {
      print('Falha ao adicionar usuário. Status: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Erro ao adicionar usuário');
    }
  }

  // ID agora é uma String
  Future<void> updateUser(String id, String name, String surname, String email) async {
    print(
      'Atualizando usuário: id=$id, name=$name, surname=$surname, email=$email',
    );
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: _headersFull,
      body: json.encode({
        'name': name,
        'surname': surname,
        'email': email,
      }),
    );
    if (response.statusCode != 200) {
      print('Erro ao atualizar. Status: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Erro ao atualizar usuário');
    }
  }

  // ID agora é uma String
  Future<void> deleteUser(String id) async {
    print('Deletando usuário com ID: $id');
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Authorization': 'Bearer $_tokenTest'}, // DELETE não precisa de Content-Type
    );
    
    if (response.statusCode != 204 && response.statusCode != 200) {
      print('Erro ao deletar. Status: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Erro ao deletar usuário');
    }
  }

}