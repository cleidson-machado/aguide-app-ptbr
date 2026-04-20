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

      // ✅ FIX: Adiciona nova mensagem e reordena para garantir cronologia
      _messages = [..._messages, sentMessage];
      _messages.sort((a, b) {
        if (a.sentAt == null && b.sentAt == null) return 0;
        if (a.sentAt == null) return 1;
        if (b.sentAt == null) return -1;
        return a.sentAt!.compareTo(b.sentAt!); // Crescente
      });

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

  /// Mark all unread messages in the conversation as read
  /// Called automatically when user opens a conversation
  /// This is a non-critical operation - failures are logged but not shown to user
  Future<void> markAllAsRead() async {
    try {
      // Filter messages that are not sent by me and not yet read
      final unreadMessages = _messages.where(
        (msg) => !msg.isSentByMe && !msg.isRead,
      ).toList();

      if (unreadMessages.isEmpty) {
        _log('markAllAsRead: no unread messages to mark');
        return;
      }

      _log('markAllAsRead: marking ${unreadMessages.length} messages as read');

      // Mark each unread message as read
      for (final message in unreadMessages) {
        await _repository.markMessageAsRead(message.id);
        // Update local state (optimistic update)
        message.copyWith(isRead: true);
      }

      _log('markAllAsRead: successfully marked ${unreadMessages.length} messages');
      notifyListeners();
    } catch (e) {
      // Don't show error to user - read receipts are non-critical
      _log('markAllAsRead: failed (non-critical): $e');
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
      return 'Voce nao tem permissao para ver esta conversa.';
    }
    if (exception.isNotFound) {
      return 'Conversa nao encontrada.';
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
        exception.message != 'Failed to load messages' &&
        exception.message != 'Failed to send message') {
      return exception.message;
    }

    return fallback;
  }
}
