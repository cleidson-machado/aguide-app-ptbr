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
  bool _hasNewMessagesFromPolling = false;
  bool _isConversationMuted = false;
  bool _isConversationBlocked = false;
  String? _blockedUserId;
  bool _isTogglingMute = false;
  bool _isClearingConversation = false;
  bool _isBlockingUser = false;

  List<UserChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get hasNextPage => _hasNextPage;
  int get currentPage => _currentPage;
  String? get error => _error;
  bool get isConversationMuted => _isConversationMuted;
  bool get isConversationBlocked => _isConversationBlocked;
  bool get isTogglingMute => _isTogglingMute;
  bool get isClearingConversation => _isClearingConversation;
  bool get isBlockingUser => _isBlockingUser;

  /// True when the last silent poll fetched new messages from other participants.
  /// Used by the screen to decide whether to auto-scroll to bottom.
  /// Consumed once - reset to false after read.
  bool consumeHasNewMessagesFromPolling() {
    final value = _hasNewMessagesFromPolling;
    _hasNewMessagesFromPolling = false;
    return value;
  }

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

  Future<void> initializeConversationActions({
    required String conversationId,
    bool initialMuted = false,
  }) async {
    _isConversationMuted = initialMuted;
    _blockedUserId = await _repository.getDirectConversationOtherUserId(
      conversationId,
    );

    if (_blockedUserId == null || _blockedUserId!.isEmpty) {
      _log('initializeConversationActions: otherUserId not resolved');
      notifyListeners();
      return;
    }

    try {
      final blockedUsers = await _repository.getBlockedUsers();
      _isConversationBlocked = blockedUsers.any(
        (entry) => entry.blockedUserId == _blockedUserId,
      );
      _log(
        'initializeConversationActions: blocked=$_isConversationBlocked userId=$_blockedUserId',
      );
    } catch (e) {
      _log('initializeConversationActions failed (non-critical): $e');
    } finally {
      notifyListeners();
    }
  }

  /// Silent polling refresh - fetches latest messages without showing loading
  /// spinner or surfacing errors to the user. Designed for auto-refresh timers.
  ///
  /// Behavior:
  /// - Does NOT set _isLoading=true (no UI flash)
  /// - Skips if currently loading or sending (avoid race conditions)
  /// - Only notifies listeners if message list actually changed
  /// - Sets _hasNewMessagesFromPolling=true if new messages from others arrived
  /// - Errors are silently logged (non-critical)
  Future<void> silentRefreshMessages(String conversationId) async {
    if (_isLoading || _isSending) {
      _log(
        'silentRefresh skipped (busy: loading=$_isLoading sending=$_isSending)',
      );
      return;
    }

    try {
      final page = await _repository.getMessagesByConversation(
        conversationId: conversationId,
        page: 0,
      );

      // Diff: detect if there are new messages or message count changed
      final previousCount = _messages.length;
      final previousLastId = _messages.isNotEmpty ? _messages.last.id : null;
      final newLastId = page.messages.isNotEmpty ? page.messages.last.id : null;

      final hasChanges =
          page.messages.length != previousCount || previousLastId != newLastId;

      if (!hasChanges) {
        _log('silentRefresh: no changes (count=$previousCount)');
        return;
      }

      // Detect if any new message is from someone else (not me)
      final newMessages = page.messages.where(
        (m) => !_messages.any((existing) => existing.id == m.id),
      );
      final hasIncomingFromOthers = newMessages.any((m) => !m.isSentByMe);

      _messages = page.messages;
      _currentPage = page.currentPage;
      _hasNextPage = page.hasNextPage;
      _hasNewMessagesFromPolling = hasIncomingFromOthers;

      _log(
        'silentRefresh: applied changes count=${_messages.length} (was $previousCount) hasIncoming=$hasIncomingFromOthers',
      );
      notifyListeners();
    } catch (e) {
      // Silent failure - polling errors must NOT bother the user
      _log('silentRefresh: error (silent): $e');
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

    if (_isConversationBlocked) {
      _error = 'Nao e possivel enviar mensagem para este usuario.';
      notifyListeners();
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
      if (e.isConflict) {
        _isConversationBlocked = true;
      }
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

  Future<void> toggleMuteConversation(String conversationId) async {
    if (_isTogglingMute) return;

    _isTogglingMute = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.toggleMuteConversation(conversationId);
      _isConversationMuted = result.isMuted;
      _log('toggleMuteConversation success muted=${result.isMuted}');
    } on UserMessageFlowException catch (e) {
      _error = _mapExceptionToMessage(e, 'Erro ao silenciar conversa.');
      _log(
        'toggleMuteConversation mapped error=$_error (status=${e.statusCode})',
      );
    } catch (_) {
      _error = 'Erro ao silenciar conversa.';
    } finally {
      _isTogglingMute = false;
      notifyListeners();
    }
  }

  Future<void> clearConversation(String conversationId) async {
    if (_isClearingConversation) return;

    _isClearingConversation = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.clearConversation(conversationId);
      // Re-fetch from backend because clear is applied server-side per participant.
      await loadInitialMessages(conversationId);
      _log('clearConversation success');
    } on UserMessageFlowException catch (e) {
      _error = _mapExceptionToMessage(e, 'Erro ao limpar conversa.');
      _log('clearConversation mapped error=$_error (status=${e.statusCode})');
    } catch (_) {
      _error = 'Erro ao limpar conversa.';
    } finally {
      _isClearingConversation = false;
      notifyListeners();
    }
  }

  Future<void> toggleBlockForCurrentConversationUser(
    String conversationId,
  ) async {
    if (_isBlockingUser) return;

    _isBlockingUser = true;
    _error = null;
    notifyListeners();

    try {
      _blockedUserId ??= await _repository.getDirectConversationOtherUserId(
        conversationId,
      );
      final targetUserId = _blockedUserId;
      if (targetUserId == null || targetUserId.isEmpty) {
        throw const UserMessageFlowException(
          'Nao foi possivel identificar o usuario desta conversa.',
          statusCode: 400,
        );
      }

      if (_isConversationBlocked) {
        await _repository.unblockUser(targetUserId);
        _isConversationBlocked = false;
      } else {
        await _repository.blockUser(targetUserId);
        _isConversationBlocked = true;
      }

      _log(
        'toggleBlock success blocked=$_isConversationBlocked user=$targetUserId',
      );
    } on UserMessageFlowException catch (e) {
      _error = _mapExceptionToMessage(
        e,
        _isConversationBlocked
            ? 'Erro ao desbloquear usuario.'
            : 'Erro ao bloquear usuario.',
      );
      _log('toggleBlock mapped error=$_error (status=${e.statusCode})');
    } catch (_) {
      _error =
          _isConversationBlocked
              ? 'Erro ao desbloquear usuario.'
              : 'Erro ao bloquear usuario.';
    } finally {
      _isBlockingUser = false;
      notifyListeners();
    }
  }

  /// Mark all unread messages in the conversation as read
  /// Called automatically when user opens a conversation
  /// This is a non-critical operation - failures are logged but not shown to user
  Future<void> markAllAsRead() async {
    try {
      // Filter messages that are not sent by me and not yet read
      final unreadMessages =
          _messages.where((msg) => !msg.isSentByMe && !msg.isRead).toList();

      if (unreadMessages.isEmpty) {
        _log('markAllAsRead: no unread messages to mark');
        return;
      }

      _log('markAllAsRead: marking ${unreadMessages.length} messages as read');

      // Mark each unread message as read
      for (final message in unreadMessages) {
        await _repository.markMessageAsRead(message.id);
        // Update local state (optimistic update)
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index >= 0) {
          _messages[index] = _messages[index].copyWith(isRead: true);
        }
      }

      _log(
        'markAllAsRead: successfully marked ${unreadMessages.length} messages',
      );
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
    if (exception.isConflict) {
      return exception.message.trim().isNotEmpty
          ? exception.message
          : 'Nao e possivel enviar mensagem para este usuario.';
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
