import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';

/// Interface do Repository de Ownership
/// Define contrato para verificação de autoria de conteúdos
abstract class OwnershipRepositoryInterface {
  /// Verifica se o usuário logado é dono do conteúdo especificado
  /// 
  /// [userId] - ID do usuário a verificar
  /// [contentId] - ID do conteúdo a verificar
  /// 
  /// Retorna [OwnershipResult] contendo:
  /// - Lista de conteúdos verificados (se isOwner = true)
  /// - Informações do erro (se isOwner = false)
  Future<OwnershipResult> checkContentOwnership({
    required String userId,
    required String contentId,
  });

  /// Obtém todos os conteúdos verificados de um usuário
  /// 
  /// [userId] - ID do usuário
  /// 
  /// Retorna [OwnershipResult] contendo lista de conteúdos ou erro
  Future<OwnershipResult> getUserVerifiedContents({
    required String userId,
  });
}
