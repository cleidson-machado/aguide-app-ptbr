import 'package:portugal_guide/app/core/repositories/gen_crud_repository_interface.dart';
import 'package:portugal_guide/features/user_verified_content/user_verified_content_model.dart';

/// Interface do repositório de verificação de conteúdo
/// Define o contrato para operações de persistência
abstract class UserVerifiedContentRepositoryInterface
    extends GenCrudRepositoryInterface<UserVerifiedContentModel> {
  /// Submete uma nova solicitação de verificação de conteúdo
  Future<UserVerifiedContentModel> submitVerificationRequest(
    UserVerifiedContentModel request,
  );

  /// Busca solicitações por status
  Future<List<UserVerifiedContentModel>> findByStatus(String status);

  /// Busca solicitações do usuário atual
  Future<List<UserVerifiedContentModel>> findByCurrentUser();

  /// Verifica se já existe solicitação para determinada URL
  Future<bool> hasExistingRequestForUrl(String contentUrl);
}
