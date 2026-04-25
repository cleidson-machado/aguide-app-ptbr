import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_exception.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_repository_interface.dart';
import 'package:portugal_guide/util/error_messages.dart';

class UserMessageBucketViewModel extends ChangeNotifier {
  UserMessageBucketViewModel({
    required UserMessageFlowRepositoryInterface repository,
  }) : _repository = repository;

  final UserMessageFlowRepositoryInterface _repository;

  List<UserMessageContactModel> _conversations = [];
  bool _isLoading = false;
  String? _error;

  List<UserMessageContactModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📥 [UserMessageBucketViewModel] $message');
    }
  }

  Future<void> loadConversations({bool includeArchived = false}) async {
    _isLoading = true;
    _error = null;
    _log('loadConversations start includeArchived=$includeArchived');
    notifyListeners();

    try {
      _conversations = await _repository.getConversations(
        includeArchived: includeArchived,
      );
      _log('loadConversations success count=${_conversations.length}');
    } on UserMessageFlowException catch (e) {
      _conversations = [];
      _error = _mapExceptionToMessage(
        e,
        ErrorMessages.defaultMsnFailedToLoadData,
      );
      _log('loadConversations mapped error: $_error (status=${e.statusCode})');
    } catch (_) {
      _conversations = [];
      _error = ErrorMessages.defaultMsnFailedToLoadData;
      _log('loadConversations generic error fallback=$_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshConversations({bool includeArchived = false}) async {
    _log('refreshConversations start includeArchived=$includeArchived');
    try {
      _conversations = await _repository.getConversations(
        includeArchived: includeArchived,
      );
      _error = null;
      _log('refreshConversations success count=${_conversations.length}');
    } on UserMessageFlowException catch (e) {
      _error = _mapExceptionToMessage(
        e,
        ErrorMessages.defaultMsnFailedToLoadData,
      );
      _log(
        'refreshConversations mapped error: $_error (status=${e.statusCode})',
      );
    } catch (_) {
      _error = ErrorMessages.defaultMsnFailedToLoadData;
      _log('refreshConversations generic error fallback=$_error');
    } finally {
      notifyListeners();
    }
  }

  String _mapExceptionToMessage(
    UserMessageFlowException exception,
    String fallback,
  ) {
    // Priorizar status codes específicos ANTES de checar mensagem genérica
    if (exception.isUnauthorized) {
      return 'Sessao expirada. Faca login novamente.';
    }
    if (exception.isForbidden) {
      return 'Voce nao tem permissao para acessar as conversas.';
    }
    if (exception.isNotFound) {
      return 'Recurso nao encontrado.';
    }
    if (exception.isServerError) {
      return 'Erro no servidor. Tente novamente mais tarde.';
    }
    if (exception.isBadRequest && exception.message.trim().isNotEmpty) {
      return exception.message; // 400 com mensagem específica do backend
    }

    // Só retorna mensagem genérica se não for status code específico
    if (exception.message.trim().isNotEmpty &&
        exception.message != fallback &&
        exception.message != 'Failed to load conversations') {
      return exception.message;
    }

    return fallback;
  }
}
