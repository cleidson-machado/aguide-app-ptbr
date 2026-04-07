import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_model.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_exception.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_repository_interface.dart';
import 'package:portugal_guide/util/error_messages.dart';

class UserChatMessageViewModel extends ChangeNotifier {
  UserChatMessageViewModel({
    required UserMessageFlowRepositoryInterface repository,
  }) : _repository = repository;

  final UserMessageFlowRepositoryInterface _repository;

  List<UserChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _hasNextPage = false;
  int _currentPage = 0;
  String? _error;

  List<UserChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get hasNextPage => _hasNextPage;
  int get currentPage => _currentPage;
  String? get error => _error;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('💭 [UserChatMessageViewModel] $message');
    }
  }

  Future<void> loadInitialMessages(String conversationId) async {
    _isLoading = true;
    _error = null;
    _log('loadInitialMessages start conversationId=$conversationId');
    notifyListeners();

    try {
      final page = await _repository.getMessagesByConversation(
        conversationId: conversationId,
        page: 0,
      );

      _messages = page.messages;
      _currentPage = page.currentPage;
      _hasNextPage = page.hasNextPage;
      _log(
        'loadInitialMessages success count=${_messages.length} currentPage=$_currentPage hasNextPage=$_hasNextPage',
      );
    } on UserMessageFlowException catch (e) {
      _messages = [];
      _error = _mapExceptionToMessage(
        e,
        ErrorMessages.defaultMsnFailedToLoadData,
      );
      _log('loadInitialMessages mapped error=$_error (status=${e.statusCode})');
    } catch (_) {
      _messages = [];
      _error = ErrorMessages.defaultMsnFailedToLoadData;
      _log('loadInitialMessages generic error fallback=$_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMessages(String conversationId) async {
    _log('refreshMessages start conversationId=$conversationId');
    try {
      final page = await _repository.getMessagesByConversation(
        conversationId: conversationId,
        page: 0,
      );

      _messages = page.messages;
      _currentPage = page.currentPage;
      _hasNextPage = page.hasNextPage;
      _error = null;
      _log('refreshMessages success count=${_messages.length}');
    } on UserMessageFlowException catch (e) {
      _error = _mapExceptionToMessage(
        e,
        ErrorMessages.defaultMsnFailedToLoadData,
      );
      _log('refreshMessages mapped error=$_error (status=${e.statusCode})');
    } catch (_) {
      _error = ErrorMessages.defaultMsnFailedToLoadData;
      _log('refreshMessages generic error fallback=$_error');
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String content,
  }) async {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      _log('sendTextMessage blocked: empty message');
      return;
    }

    _isSending = true;
    _log('sendTextMessage start conversationId=$conversationId');
    notifyListeners();

    try {
      final sentMessage = await _repository.sendTextMessage(
        conversationId: conversationId,
        content: normalized,
      );

      _messages = [..._messages, sentMessage];
      _error = null;
      _log('sendTextMessage success totalMessages=${_messages.length}');
    } on UserMessageFlowException catch (e) {
      _error = _mapExceptionToMessage(
        e,
        ErrorMessages.defaultMsnFailedToSaveData,
      );
      _log('sendTextMessage mapped error=$_error (status=${e.statusCode})');
    } catch (_) {
      _error = ErrorMessages.defaultMsnFailedToSaveData;
      _log('sendTextMessage generic error fallback=$_error');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  String _mapExceptionToMessage(
    UserMessageFlowException exception,
    String fallback,
  ) {
    if (exception.message.trim().isNotEmpty) {
      return exception.message;
    }
    if (exception.isBadRequest) {
      return exception.message;
    }
    if (exception.isUnauthorized) {
      return 'Sessao expirada. Faca login novamente.';
    }
    if (exception.isForbidden) {
      return 'Voce nao tem permissao para acessar esta conversa.';
    }
    return fallback;
  }
}
