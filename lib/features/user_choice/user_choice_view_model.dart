// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user_choice/user_choice_model.dart';
import 'package:portugal_guide/features/user_choice/user_choice_repository_interface.dart';

/// ViewModel para gerenciar o estado do formulário de UserChoice
class UserChoiceViewModel extends ChangeNotifier {
  final UserChoiceRepositoryInterface _repository;

  UserChoiceViewModel(this._repository);

  // Estado
  bool _isLoading = false;
  String? _error;
  UserChoiceModel? _userChoice;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserChoiceModel? get userChoice => _userChoice;

  /// Busca perfil ativo do usuário
  Future<void> fetchUserActiveProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📋 [UserChoiceViewModel] Buscando perfil ativo do usuário...');
      _userChoice = await _repository.getUserActiveProfile(userId);

      if (_userChoice != null) {
        print('✅ [UserChoiceViewModel] Perfil encontrado: ${_userChoice!.id}');
      } else {
        print('ℹ️ [UserChoiceViewModel] Usuário não possui perfil ativo');
      }
    } catch (e) {
      _error = 'Erro ao buscar perfil: $e';
      print('❌ [UserChoiceViewModel] Erro: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria novo perfil de usuário
  Future<bool> createUserChoice(UserChoiceModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 [UserChoiceViewModel] Criando novo perfil...');
      _userChoice = await _repository.create(model);

      print('✅ [UserChoiceViewModel] Perfil criado com sucesso: ${_userChoice!.id}');
      return true;
    } catch (e) {
      _error = 'Erro ao criar perfil: $e';
      print('❌ [UserChoiceViewModel] Erro: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza perfil existente
  Future<bool> updateUserChoice(UserChoiceModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 [UserChoiceViewModel] Atualizando perfil: ${model.id}');
      _userChoice = await _repository.update(model);

      print('✅ [UserChoiceViewModel] Perfil atualizado com sucesso');
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar perfil: $e';
      print('❌ [UserChoiceViewModel] Erro: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deleta perfil (soft delete)
  Future<bool> deleteUserChoice(String profileId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🗑️ [UserChoiceViewModel] Deletando perfil: $profileId');
      final success = await _repository.destroy(profileId);

      if (success) {
        print('✅ [UserChoiceViewModel] Perfil deletado com sucesso');
        _userChoice = null;
      }

      return success;
    } catch (e) {
      _error = 'Erro ao deletar perfil: $e';
      print('❌ [UserChoiceViewModel] Erro: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpa erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reseta estado
  void reset() {
    _isLoading = false;
    _error = null;
    _userChoice = null;
    notifyListeners();
  }
}
