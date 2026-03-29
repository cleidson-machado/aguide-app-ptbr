import 'package:portugal_guide/app/core/repositories/gen_crud_repository_interface.dart';
import 'package:portugal_guide/features/user_choice/user_choice_model.dart';

/// Interface do Repository de UserChoice
/// Define contratos específicos além do CRUD básico
abstract class UserChoiceRepositoryInterface
    extends GenCrudRepositoryInterface<UserChoiceModel> {
  /// Busca o perfil ativo do usuário (endpoint específico da API)
  /// GET /api/v1/user-choices/user/{userId}/active
  Future<UserChoiceModel?> getUserActiveProfile(String userId);

  /// Busca todos os perfis de um usuário (incluindo deletados)
  /// GET /api/v1/user-choices/user/{userId}
  Future<List<UserChoiceModel>> getUserProfiles(String userId, {
    int page = 0,
    int size = 10,
  });

  /// Busca perfis por tipo (CREATOR ou CONSUMER)
  /// GET /api/v1/user-choices/profile-type/{profileType}
  Future<List<UserChoiceModel>> getByProfileType(String profileType, {
    int page = 0,
    int size = 10,
  });

  /// Busca perfis por nicho
  /// GET /api/v1/user-choices/niche/{nicheContext}
  Future<List<UserChoiceModel>> getByNiche(String nicheContext, {
    int page = 0,
    int size = 10,
  });
}
