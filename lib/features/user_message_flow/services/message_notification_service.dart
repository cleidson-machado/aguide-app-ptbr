import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_repository_interface.dart';

/// Event emitted when a new incoming message is detected via polling
class NewMessageEvent {
  final String conversationId;
  final String senderName;
  final String preview;
  final DateTime occurredAt;

  const NewMessageEvent({
    required this.conversationId,
    required this.senderName,
    required this.preview,
    required this.occurredAt,
  });
}

/// Singleton background service that periodically polls the conversations
/// endpoint and emits events when new messages from other users are detected.
///
/// Designed to run app-wide (independent of any specific screen) so the user
/// can be notified via top snackbar even when not on the messages tab.
///
/// **Detection Strategy:** Compares each conversation's `unreadCount` and
/// `lastMessageAt` against the previous snapshot. Any increase in unread
/// count OR a newer `lastMessageAt` triggers an event. The first poll only
/// captures a baseline snapshot and never emits (avoids notifying on app open).
///
/// **Lifecycle:** Auto-pauses polling when app is backgrounded, resumes on
/// foreground, and immediately re-polls on resume to catch missed updates.
class MessageNotificationService with WidgetsBindingObserver {
  MessageNotificationService({
    required UserMessageFlowRepositoryInterface repository,
    required AuthTokenManager tokenManager,
  })  : _repository = repository,
        _tokenManager = tokenManager;

  final UserMessageFlowRepositoryInterface _repository;
  final AuthTokenManager _tokenManager;

  /// Polling interval (15s balances freshness vs battery/network usage).
  static const Duration _pollInterval = Duration(seconds: 15);

  Timer? _timer;
  bool _started = false;
  bool _isFirstSnapshot = true;
  final Map<String, _ConversationSnapshot> _snapshots = {};

  /// Listenable that emits the latest unread incoming message.
  /// Listeners must call [consume] after handling the event to clear it
  /// (prevents repeat notifications on rebuild).
  final ValueNotifier<NewMessageEvent?> events = ValueNotifier<NewMessageEvent?>(null);

  /// Idempotent start - safe to call from multiple screens' initState.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _log('start (poll every ${_pollInterval.inSeconds}s)');
    _timer = Timer.periodic(_pollInterval, (_) => _tick());
    // Fire baseline immediately so first real change is detected at next tick
    _tick();
  }

  /// Stops polling and removes lifecycle observer. Typically called on logout.
  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    _isFirstSnapshot = true;
    _snapshots.clear();
    _log('stop');
  }

  /// Mark the current event as consumed (clears the notifier value).
  /// UI should call this after showing the snackbar to avoid duplicate displays.
  void consume() {
    events.value = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (state == AppLifecycleState.resumed) {
      _log('app resumed → restart polling');
      _timer?.cancel();
      _timer = Timer.periodic(_pollInterval, (_) => _tick());
      _tick(); // immediate poll on resume
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _log('app paused → pause polling');
      _timer?.cancel();
    }
  }

  Future<void> _tick() async {
    final userId = _tokenManager.getUserId();
    if (userId == null || userId.isEmpty) {
      // Not authenticated - skip silently
      return;
    }

    try {
      final conversations = await _repository.getConversations();
      final wasFirstSnapshot = _isFirstSnapshot;
      _isFirstSnapshot = false;

      NewMessageEvent? latestEvent;
      DateTime latestTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

      for (final conv in conversations) {
        final previous = _snapshots[conv.id];
        final newSnapshot = _ConversationSnapshot(
          lastMessageAt: conv.lastMessageAt,
          unreadCount: conv.unreadCount,
          contactName: conv.contactName,
          lastMessage: conv.lastMessage,
        );
        _snapshots[conv.id] = newSnapshot;

        // First poll establishes the baseline - never emits events
        if (wasFirstSnapshot) continue;

        // 🔑 Critério para notificar: APENAS quando unreadCount aumenta.
        // Isso garante que o REMETENTE não receba snackbar das próprias msgs:
        // - Quando A envia → B, a conversa de A tem lastMessageAt atualizado,
        //   mas unreadCount permanece 0 (mensagens enviadas não contam como "não-lidas").
        // - Já a conversa de B tem unreadCount incrementado → snackbar exibido.
        // Mudanças de lastMessageAt sem aumento de unreadCount são ignoradas
        // (cobre o caso de auto-eco do envio para o próprio remetente).
        final previousUnread = previous?.unreadCount ?? 0;
        final unreadIncreased = previousUnread < conv.unreadCount;

        if (unreadIncreased) {
          final ts = conv.lastMessageAt ?? DateTime.now();
          if (latestEvent == null || ts.isAfter(latestTimestamp)) {
            latestTimestamp = ts;
            latestEvent = NewMessageEvent(
              conversationId: conv.id,
              senderName: conv.contactName,
              preview: conv.lastMessage,
              occurredAt: ts,
            );
          }
        }
      }

      if (latestEvent != null) {
        _log('🔔 new message from ${latestEvent.senderName}');
        events.value = latestEvent;
      }
    } catch (e) {
      // Silent failure - background polling errors must not bother the user
      _log('tick error (silent): $e');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🔔 [MessageNotificationService] $message');
    }
  }
}

class _ConversationSnapshot {
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String contactName;
  final String lastMessage;

  const _ConversationSnapshot({
    required this.lastMessageAt,
    required this.unreadCount,
    required this.contactName,
    required this.lastMessage,
  });
}
