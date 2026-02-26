import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user_verified_content/user_verified_content_model.dart';
import 'package:portugal_guide/features/user_verified_content/user_verified_content_repository_interface.dart';

/// Implementação mocada do repositório de verificação de conteúdo
/// Simula operações de persistência sem consumir endpoints reais
class UserVerifiedContentRepository
    implements UserVerifiedContentRepositoryInterface {
  // Armazenamento em memória para simulação
  final List<UserVerifiedContentModel> _mockDatabase = [];
  int _idCounter = 1;

  @override
  Future<UserVerifiedContentModel> submitVerificationRequest(
    UserVerifiedContentModel request,
  ) async {
    // Simula delay de rede
    await Future.delayed(const Duration(seconds: 2));

    // Gera ID único
    final newRequest = request.copyWith(
      id: 'mock_${_idCounter++}',
      createdAt: DateTime.now(),
      status: 'pending',
    );

    _mockDatabase.add(newRequest);

    if (kDebugMode) {
      debugPrint(
        '✅ [UserVerifiedContentRepository] Solicitação criada: ${newRequest.id}',
      );
    }

    return newRequest;
  }

  @override
  Future<List<UserVerifiedContentModel>> findByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockDatabase.where((item) => item.status == status).toList();
  }

  @override
  Future<List<UserVerifiedContentModel>> findByCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: retorna todas as solicitações
    return List.from(_mockDatabase);
  }

  @override
  Future<bool> hasExistingRequestForUrl(String contentUrl) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockDatabase.any((item) => item.contentUrl == contentUrl);
  }

  // Métodos herdados de GenCrudRepositoryInterface
  @override
  Future<UserVerifiedContentModel> create(
    UserVerifiedContentModel entity,
  ) async {
    return submitVerificationRequest(entity);
  }

  @override
  Future<bool> destroy(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _mockDatabase.length;
    _mockDatabase.removeWhere((item) => item.id == id);
    return _mockDatabase.length < initialLength;
  }

  @override
  Future<List<UserVerifiedContentModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockDatabase);
  }

  @override
  Future<UserVerifiedContentModel?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockDatabase.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserVerifiedContentModel> update(
    UserVerifiedContentModel entity,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockDatabase.indexWhere((item) => item.id == entity.id);
    if (index != -1) {
      _mockDatabase[index] = entity;
      return entity;
    }
    throw Exception('Entity not found');
  }
}
