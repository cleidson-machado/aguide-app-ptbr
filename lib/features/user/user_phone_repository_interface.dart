import 'package:portugal_guide/features/user/user_phone_model.dart';

/// Interface para operações de repositório de telefones de usuário
/// 
/// Documentação: .local_knowledge/add-user-tracking-phase-b/PROMPT_FRONTEND_PHONE_INTEGRATION_RANKING.md
/// 
/// 🎯 Responsabilidades:
/// - Buscar lista de telefones de um usuário
/// - Criar, atualizar e deletar telefones
/// - Definir telefone principal
/// 
/// Endpoints:
/// - GET /api/v1/users/{userId}/phones - Listar telefones
/// - POST /api/v1/users/{userId}/phones - Criar telefone
/// - PUT /api/v1/phones/{id} - Atualizar telefone
/// - DELETE /api/v1/phones/{id} - Deletar telefone
/// - PUT /api/v1/users/{userId}/phones/{phoneId}/primary - Definir principal
abstract class UserPhoneRepositoryInterface {
  /// Busca todos os telefones de um usuário
  /// 
  /// Endpoint: GET /api/v1/users/{userId}/phones
  /// 
  /// Retorna lista vazia se usuário não tem telefones
  /// Lança exceção em caso de erro de rede ou servidor
  Future<List<UserPhoneModel>> getUserPhones(String userId);

  /// Cria novo telefone para usuário
  /// 
  /// Endpoint: POST /api/v1/users/{userId}/phones
  Future<UserPhoneModel> createPhone(String userId, Map<String, dynamic> phoneData);

  /// Atualiza telefone existente
  /// 
  /// Endpoint: PUT /api/v1/phones/{id}
  Future<UserPhoneModel> updatePhone(String phoneId, Map<String, dynamic> phoneData);

  /// Deleta telefone
  /// 
  /// Endpoint: DELETE /api/v1/phones/{id}
  Future<void> deletePhone(String phoneId);

  /// Define telefone como principal
  /// 
  /// Endpoint: PUT /api/v1/users/{userId}/phones/{phoneId}/primary
  Future<void> setPrimaryPhone(String userId, String phoneId);
}
