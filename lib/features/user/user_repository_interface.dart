// lib/features/user/i_user_repository.dart

import 'package:portugal_guide/app/core/repositories/gen_crud_repo_interface.dart';
import 'package:portugal_guide/features/user/user_model.dart';

// Este é o "Cinto de Ferramentas do Eletricista"
abstract class UserRepositoryInterface extends GenCrudRepoInterface<UserModel> {
  // Ele já vem com as ferramentas genéricas (getAll, create, etc.) por herança.

  // E AGORA, ADICIONAMOS AS FERRAMENTAS ESPECIAIS:
  Future<UserModel?> findByEmail(String email);

  Future<bool> isEmailAlreadyRegistered(String email);

  Future<void> changeUserPassword(String userId, String newPassword);
}