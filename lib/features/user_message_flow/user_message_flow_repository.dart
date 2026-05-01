import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user_message_flow/models/block_status_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/clear_conversation_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/mute_status_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_page_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_exception.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_repository_interface.dart';

class UserMessageFlowRepository implements UserMessageFlowRepositoryInterface {
  UserMessageFlowRepository() : _dio = _setupDio();

  final Dio _dio;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('💬 [UserMessageFlowRepository] $message');
    }
  }

  static Dio _setupDio() {
    final normalizedBaseUrl = _normalizeBaseUrl(EnvKeyHelperConfig.apiBaseUrl);

    final dio = Dio(
      BaseOptions(
        baseUrl: normalizedBaseUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final authToken =
              injector<AuthTokenManager>().getAuthorizationHeader();
          if (authToken != null) {
            options.headers['Authorization'] = authToken;
          }

          if (kDebugMode) {
            debugPrint(
              '🌐 [UserMessageFlowRepository] ${options.method} ${options.uri} authHeader=${authToken != null}',
            );
          }

          return handler.next(options);
        },
      ),
    );

    return dio;
  }

  static String _normalizeBaseUrl(String rawBaseUrl) {
    final trimmed = rawBaseUrl.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  String _conversationsEndpoint() => 'conversations';

  String _conversationDetailsEndpoint(String conversationId) {
    return 'conversations/$conversationId';
  }

  String _messagesByConversationEndpoint(String conversationId) {
    return 'messages/conversation/$conversationId';
  }

  String _messagesEndpoint() => 'messages';

  /// Helper: Constructs endpoint for marking message as read (DRY principle)
  String _markMessageAsReadEndpoint(String messageId) =>
      'messages/$messageId/read';

  /// Helper: Constructs endpoint for creating direct conversations (DRY principle)
  String _directConversationsEndpoint() => 'conversations/direct';

  String _muteConversationEndpoint(String conversationId) {
    return 'conversations/$conversationId/mute';
  }

  String _clearConversationEndpoint(String conversationId) {
    return 'conversations/$conversationId/clear';
  }

  String _blockUserEndpoint(String userId) => 'users/$userId/block';

  String _blockedUsersEndpoint() => 'users/blocks';

  @override
  Future<List<UserMessageContactModel>> getConversations({
    bool includeArchived = false,
  }) async {
    try {
      _log('GET ${_conversationsEndpoint()} includeArchived=$includeArchived');
      final response = await _dio.get(
        _conversationsEndpoint(),
        queryParameters: {'includeArchived': includeArchived},
      );

      _log(
        'Response conversations status=${response.statusCode}, dataType=${response.data.runtimeType}',
      );

      if (response.statusCode == 204 || response.data == null) {
        _log('Conversations response is empty (204/null).');
        return [];
      }

      final rawList = _extractConversationList(response.data);

      if (rawList == null) {
        _log(
          '⚠️ CRITICAL: Cannot extract conversation list from payload: ${response.data}',
        );
        throw const UserMessageFlowException(
          'Formato de resposta invalido do servidor',
          statusCode: 500,
        );
      }

      if (rawList.isEmpty) {
        _log('Conversations list is empty after extraction.');
        return [];
      }

      final mapped =
          rawList.whereType<Map<String, dynamic>>().map((item) {
            final parsedLastMessageAt =
                item['lastMessageAt'] != null
                    ? DateTime.tryParse(item['lastMessageAt'].toString())
                    : null;
            final enriched = {
              ...item,
              'formattedTimestamp': formatConversationTimestamp(
                parsedLastMessageAt,
              ),
            };
            return UserMessageContactModel.fromConversationSummaryMap(enriched);
          }).toList();

      _log('✅ Mapped conversations count=${mapped.length}');
      return mapped;
    } on DioException catch (e) {
      _log(
        '❌ Conversations request failed status=${e.response?.statusCode} message=${e.message}',
      );
      _log('❌ Response data: ${e.response?.data}');
      throw _mapDioException(e, fallback: 'Failed to load conversations');
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected conversations error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<UserChatMessagePageModel> getMessagesByConversation({
    required String conversationId,
    required int page,
    int size = 20,
  }) async {
    if (page < 0) {
      throw const UserMessageFlowException(
        'Invalid pagination: page must be greater than or equal to 0',
        statusCode: 400,
      );
    }
    if (size < 1 || size > 100) {
      throw const UserMessageFlowException(
        'Invalid pagination: size must be between 1 and 100',
        statusCode: 400,
      );
    }

    try {
      _log(
        'GET ${_messagesByConversationEndpoint(conversationId)} page=$page size=$size',
      );
      final response = await _dio.get(
        _messagesByConversationEndpoint(conversationId),
        queryParameters: {'page': page, 'size': size},
      );

      _log(
        'Response messages status=${response.statusCode}, dataType=${response.data.runtimeType}',
      );

      if (response.data is! Map<String, dynamic>) {
        _log('⚠️ CRITICAL: Response data is not a Map: ${response.data}');
        throw const UserMessageFlowException(
          'Formato de resposta invalido do servidor',
          statusCode: 500,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final List<dynamic> rawMessages =
          (data['content'] as List<dynamic>?) ??
          (data['data'] as List<dynamic>?) ??
          <dynamic>[];
      final currentUserId = injector<AuthTokenManager>().getUserId();

      final messages =
          rawMessages
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => UserChatMessageModel.fromApiMap(
                  item,
                  currentUserId: currentUserId,
                ),
              )
              .toList();

      // ✅ FIX: Ordenar mensagens por sentAt (ascendente - mais antigas primeiro)
      // Garante timeline cronológica mesmo se dados SQL tiverem timestamps fora de ordem
      messages.sort((a, b) {
        if (a.sentAt == null && b.sentAt == null) return 0;
        if (a.sentAt == null) return 1; // null vai pro final
        if (b.sentAt == null) return -1;
        return a.sentAt!.compareTo(b.sentAt!); // Crescente (antigas → recentes)
      });

      _log('✅ Messages sorted by sentAt (${messages.length} messages)');

      return UserChatMessagePageModel(
        messages: messages,
        totalItems:
            data['totalItems'] as int? ??
            data['totalElements'] as int? ??
            messages.length,
        totalPages: data['totalPages'] as int? ?? 1,
        currentPage: data['currentPage'] as int? ?? page,
      );
    } on DioException catch (e) {
      _log(
        'Messages list request failed status=${e.response?.statusCode} message=${e.message}',
      );
      throw _mapDioException(e, fallback: 'Failed to load messages');
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected messages list error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<UserChatMessageModel> sendTextMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      _log('POST ${_messagesEndpoint()} conversationId=$conversationId');
      final response = await _dio.post(
        _messagesEndpoint(),
        data: {
          'conversationId': conversationId,
          'content': content,
          'messageType': 'TEXT',
          'parentMessageId': null,
        },
      );

      if (response.data is! Map<String, dynamic>) {
        _log('⚠️ CRITICAL: Send response data is not a Map: ${response.data}');
        throw const UserMessageFlowException(
          'Formato de resposta invalido do servidor',
          statusCode: 500,
        );
      }

      _log('✅ Message sent status=${response.statusCode}');

      final currentUserId = injector<AuthTokenManager>().getUserId();

      return UserChatMessageModel.fromApiMap(
        response.data as Map<String, dynamic>,
        currentUserId: currentUserId,
      );
    } on DioException catch (e) {
      _log(
        'Send message failed status=${e.response?.statusCode} message=${e.message}',
      );
      throw _mapDioException(e, fallback: 'Failed to send message');
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected send message error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      _log('PUT ${_markMessageAsReadEndpoint(messageId)}');
      final response = await _dio.put(_markMessageAsReadEndpoint(messageId));

      if (response.statusCode == 204) {
        _log('✅ Message marked as read messageId=$messageId');
      } else {
        _log(
          '⚠️ Unexpected status code when marking as read: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _log(
        'Mark as read failed status=${e.response?.statusCode} message=${e.message}',
      );
      // Don't throw - marking as read is non-critical
      // User can still use the app even if read receipts fail
      if (kDebugMode) {
        debugPrint(
          '⚠️ Failed to mark message as read (non-critical): ${e.message}',
        );
      }
    } catch (e) {
      _log('Unexpected mark as read error (non-critical): $e');
      // Don't throw - non-critical operation
    }
  }

  @override
  Future<UserMessageContactModel> getConversationDetails(
    String conversationId,
  ) async {
    try {
      _log('GET ${_conversationDetailsEndpoint(conversationId)}');
      final response = await _dio.get(
        _conversationDetailsEndpoint(conversationId),
      );

      if (response.data is! Map<String, dynamic>) {
        throw const UserMessageFlowException(
          'Formato de resposta inválido do servidor',
          statusCode: 500,
        );
      }

      final conversationData = response.data as Map<String, dynamic>;
      final currentUserId = injector<AuthTokenManager>().getUserId();
      _log(
        '🔑 currentUserId=$currentUserId type=${conversationData['type']} hasDisplayName=${conversationData['displayName'] != null} participantsCount=${(conversationData['participants'] as List?)?.length ?? 0}',
      );

      // Extract contact name — order: displayName (backend fix) → participants[] → name → fallback
      String contactName = _resolveContactName(
        conversationData: conversationData,
        currentUserId: currentUserId,
      );

      return UserMessageContactModel(
        id: conversationData['id']?.toString() ?? '',
        contactName: contactName,
        lastMessage: conversationData['lastMessagePreview']?.toString() ?? '',
        timestamp: formatConversationTimestamp(
          conversationData['lastMessageAt'] != null
              ? DateTime.tryParse(conversationData['lastMessageAt'].toString())
              : null,
        ),
        avatarUrl: conversationData['iconUrl']?.toString(),
        isOnline: false,
        unreadCount: conversationData['unreadCount'] as int? ?? 0,
        type: conversationData['type']?.toString() ?? 'DIRECT',
        isPinned: conversationData['isPinned'] as bool? ?? false,
        isArchived: conversationData['isArchived'] as bool? ?? false,
        isMuted: conversationData['isMuted'] as bool? ?? false,
        mutedAt:
            conversationData['mutedAt'] != null
                ? DateTime.tryParse(conversationData['mutedAt'].toString())
                : null,
      );
    } on DioException catch (e) {
      _log(
        'Get conversation details failed status=${e.response?.statusCode} message=${e.message}',
      );
      throw _mapDioException(
        e,
        fallback: 'Erro ao carregar detalhes da conversa',
      );
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected get conversation details error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<UserMessageContactModel> createDirectConversation({
    required String otherUserId,
  }) async {
    try {
      _log('POST ${_directConversationsEndpoint()} otherUserId=$otherUserId');
      final response = await _dio.post(
        _directConversationsEndpoint(),
        data: {'otherUserId': otherUserId},
      );

      if (response.data is! Map<String, dynamic>) {
        _log(
          '⚠️ CRITICAL: Create conversation response is not a Map: ${response.data}',
        );
        throw const UserMessageFlowException(
          'Formato de resposta inválido do servidor',
          statusCode: 500,
        );
      }

      _log(
        '✅ Direct conversation created/retrieved status=${response.statusCode}',
      );

      final conversationData = response.data as Map<String, dynamic>;
      final currentUserId = injector<AuthTokenManager>().getUserId();
      _log(
        '🔑 createDirect currentUserId=$currentUserId type=${conversationData['type']} hasDisplayName=${conversationData['displayName'] != null} participantsCount=${(conversationData['participants'] as List?)?.length ?? 0}',
      );

      // Extract contact name — order: displayName (backend fix) → participants[] → name → fallback
      final String contactName = _resolveContactName(
        conversationData: conversationData,
        currentUserId: currentUserId,
      );

      // Build UserMessageContactModel from conversation response
      return UserMessageContactModel(
        id: conversationData['id']?.toString() ?? '',
        contactName: contactName,
        lastMessage: '', // New conversation has no messages yet
        timestamp: formatConversationTimestamp(
          conversationData['createdAt'] != null
              ? DateTime.tryParse(conversationData['createdAt'].toString())
              : null,
        ),
        avatarUrl: conversationData['iconUrl']?.toString(),
        isOnline: false,
        unreadCount: 0,
        type: conversationData['type']?.toString() ?? 'DIRECT',
        isPinned: false,
        isArchived: false,
        isMuted: conversationData['isMuted'] as bool? ?? false,
        mutedAt:
            conversationData['mutedAt'] != null
                ? DateTime.tryParse(conversationData['mutedAt'].toString())
                : null,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      _log(
        'Create direct conversation failed status=$statusCode message=${e.message}',
      );

      // Handle specific error cases from API documentation
      if (statusCode == 400) {
        final backendMessage = _extractBackendMessage(e.response?.data);
        // "Trying to create conversation with yourself"
        throw UserMessageFlowException(
          backendMessage ?? 'Não é possível criar conversa consigo mesmo',
          statusCode: 400,
        );
      }

      if (statusCode == 404) {
        // Backend pode retornar 404 se:
        // 1. Outro usuário não existe
        // 2. Tentou criar conversa consigo mesmo (bug backend - deveria ser 400)
        final backendMessage = _extractBackendMessage(e.response?.data);
        throw UserMessageFlowException(
          backendMessage ??
              'Usuário não encontrado ou não é possível iniciar conversa',
          statusCode: 404,
        );
      }

      throw _mapDioException(
        e,
        fallback: 'Erro ao criar conversa. Tente novamente.',
      );
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected create conversation error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<MuteStatusModel> toggleMuteConversation(String conversationId) async {
    try {
      _log('PUT ${_muteConversationEndpoint(conversationId)}');
      final response = await _dio.put(
        _muteConversationEndpoint(conversationId),
      );

      if (response.data is! Map<String, dynamic>) {
        throw const UserMessageFlowException(
          'Formato de resposta invalido do servidor',
          statusCode: 500,
        );
      }

      return MuteStatusModel.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log(
        'Toggle mute failed status=${e.response?.statusCode} message=${e.message}',
      );
      throw _mapDioException(e, fallback: 'Erro ao silenciar conversa');
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected toggle mute error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<ClearConversationModel> clearConversation(
    String conversationId,
  ) async {
    try {
      _log('PUT ${_clearConversationEndpoint(conversationId)}');
      final response = await _dio.put(
        _clearConversationEndpoint(conversationId),
      );

      if (response.data is! Map<String, dynamic>) {
        throw const UserMessageFlowException(
          'Formato de resposta invalido do servidor',
          statusCode: 500,
        );
      }

      return ClearConversationModel.fromMap(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _log(
        'Clear conversation failed status=${e.response?.statusCode} message=${e.message}',
      );
      throw _mapDioException(e, fallback: 'Erro ao limpar conversa');
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected clear conversation error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<BlockStatusModel> blockUser(String userId) async {
    try {
      _log('PUT ${_blockUserEndpoint(userId)}');
      final response = await _dio.put(_blockUserEndpoint(userId));

      if (response.data is! Map<String, dynamic>) {
        throw const UserMessageFlowException(
          'Formato de resposta invalido do servidor',
          statusCode: 500,
        );
      }

      return BlockStatusModel.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log(
        'Block user failed status=${e.response?.statusCode} message=${e.message}',
      );
      throw _mapDioException(e, fallback: 'Erro ao bloquear usuario');
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected block user error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    try {
      _log('DELETE ${_blockUserEndpoint(userId)}');
      await _dio.delete(_blockUserEndpoint(userId));
    } on DioException catch (e) {
      _log(
        'Unblock user failed status=${e.response?.statusCode} message=${e.message}',
      );
      throw _mapDioException(e, fallback: 'Erro ao desbloquear usuario');
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected unblock user error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<List<BlockStatusModel>> getBlockedUsers() async {
    try {
      _log('GET ${_blockedUsersEndpoint()}');
      final response = await _dio.get(_blockedUsersEndpoint());

      if (response.statusCode == 204 || response.data == null) {
        return [];
      }

      if (response.data is! List<dynamic>) {
        throw const UserMessageFlowException(
          'Formato de resposta invalido do servidor',
          statusCode: 500,
        );
      }

      return (response.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(BlockStatusModel.fromMap)
          .toList();
    } on DioException catch (e) {
      _log(
        'Get blocked users failed status=${e.response?.statusCode} message=${e.message}',
      );
      throw _mapDioException(e, fallback: 'Erro ao listar usuarios bloqueados');
    } on UserMessageFlowException {
      rethrow;
    } catch (e) {
      _log('Unexpected get blocked users error: $e');
      throw UserMessageFlowException(e.toString());
    }
  }

  @override
  Future<String?> getDirectConversationOtherUserId(
    String conversationId,
  ) async {
    try {
      _log(
        'GET ${_conversationDetailsEndpoint(conversationId)} (resolve otherUserId)',
      );
      final response = await _dio.get(
        _conversationDetailsEndpoint(conversationId),
      );

      if (response.data is! Map<String, dynamic>) {
        return null;
      }

      final conversationData = response.data as Map<String, dynamic>;
      if (conversationData['type']?.toString() != 'DIRECT') {
        return null;
      }

      final participants = conversationData['participants'];
      if (participants is! List<dynamic>) {
        return null;
      }

      final currentUserId = injector<AuthTokenManager>().getUserId();
      final otherParticipant = participants.firstWhere((p) {
        if (p is! Map<String, dynamic>) return false;
        final pid = p['userId']?.toString();
        return pid != null && pid.isNotEmpty && pid != currentUserId;
      }, orElse: () => null);

      if (otherParticipant is Map<String, dynamic>) {
        return otherParticipant['userId']?.toString();
      }

      return null;
    } catch (e) {
      _log('Resolve otherUserId failed (non-critical): $e');
      return null;
    }
  }

  /// Resolve o nome de exibição de uma conversa (DRY — usado por
  /// `getConversationDetails` e `createDirectConversation`).
  ///
  /// Ordem de prioridade (alinhada com backend fix 2026-04-25):
  /// 1. `displayName` (backend calcula nome do "outro participante" para DIRECT)
  /// 2. Inspeção do array `participants[]` (DIRECT, busca o "outro" via `userId`)
  /// 3. `name` (preenchido em GROUP/CHANNEL)
  /// 4. Fallback `'Unknown Contact'` (nunca deveria ocorrer com backend correto)
  String _resolveContactName({
    required Map<String, dynamic> conversationData,
    required String? currentUserId,
  }) {
    // 1) displayName tem prioridade absoluta (campo novo, calculado pelo backend)
    final displayName = conversationData['displayName']?.toString();
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName;
    }

    final type = conversationData['type']?.toString();

    // 2) Para DIRECT, varrer participants[] em busca do "outro" usuário
    if (type == 'DIRECT' && conversationData['participants'] is List) {
      final participants = conversationData['participants'] as List<dynamic>;
      _log(
        '🔎 Scanning ${participants.length} participants (currentUserId=$currentUserId)',
      );

      final otherParticipant = participants.firstWhere((p) {
        if (p is! Map<String, dynamic>) return false;
        final pid = p['userId']?.toString();
        return pid != null && pid.isNotEmpty && pid != currentUserId;
      }, orElse: () => null);

      if (otherParticipant is Map<String, dynamic>) {
        final fullName = otherParticipant['userFullName']?.toString();
        if (fullName != null && fullName.trim().isNotEmpty) return fullName;
        final userName = otherParticipant['userName']?.toString();
        if (userName != null && userName.trim().isNotEmpty) return userName;
        _log(
          '⚠️ Other participant found but userFullName/userName are empty: $otherParticipant',
        );
      } else {
        _log(
          '⚠️ No "other" participant found. currentUserId=$currentUserId, participants=$participants',
        );
      }
    }

    // 3) GROUP/CHANNEL → usar `name`
    final name = conversationData['name']?.toString();
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }

    // 4) Fallback (sintoma do bug — backend não está retornando dados esperados)
    _log(
      '⚠️ Falling back to "Unknown Contact". Payload keys=${conversationData.keys.toList()}',
    );
    return 'Unknown Contact';
  }

  List<dynamic>? _extractConversationList(dynamic payload) {
    if (payload is List<dynamic>) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      final content = payload['content'];
      if (content is List<dynamic>) {
        return content;
      }

      final data = payload['data'];
      if (data is List<dynamic>) {
        return data;
      }

      final items = payload['items'];
      if (items is List<dynamic>) {
        return items;
      }
    }

    return null;
  }

  UserMessageFlowException _mapDioException(
    DioException exception, {
    required String fallback,
  }) {
    final statusCode = exception.response?.statusCode;
    final backendMessage = _extractBackendMessage(exception.response?.data);

    if (statusCode == 400) {
      return UserMessageFlowException(
        backendMessage ?? 'Request validation failed',
        statusCode: 400,
      );
    }

    return UserMessageFlowException(
      backendMessage ?? fallback,
      statusCode: statusCode,
    );
  }

  String? _extractBackendMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return null;
  }

  static String formatChatTimestamp(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime).toLowerCase();
  }

  static String formatConversationTimestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    }

    if (diff.inDays == 1) {
      return 'Ontem';
    }

    if (diff.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    }

    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  @visibleForTesting
  Dio get dio => _dio;
}
