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

  /// 🆕 Valida a autoria de um conteúdo via POST
  /// 📍 ENDPOINT: POST /api/v1/ownership/validate
  /// 
  /// [userId] - ID do usuário logado
  /// [contentId] - ID do conteúdo a validar
  /// 
  /// Retorna [OwnershipValidationResponse] com resultado da validação:
  /// - status: 'VERIFIED' (autoria confirmada) ou 'REJECTED' (autoria negada)
  /// - validationHash: Hash de validação (vazio se REJECTED)
  /// - message: Mensagem descritiva do resultado
  Future<OwnershipValidationResponse> validateOwnership({
    required String userId,
    required String contentId,
  });
}
