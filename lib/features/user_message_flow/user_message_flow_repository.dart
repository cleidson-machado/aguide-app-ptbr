import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
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

  /// Helper: Constructs endpoint for creating direct conversations (DRY principle)
  String _directConversationsEndpoint() => 'conversations/direct';

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

      // Extract contact name from participants
      String contactName = 'Unknown Contact';
      if (conversationData['type'] == 'DIRECT' &&
          conversationData['participants'] is List) {
        final participants = conversationData['participants'] as List<dynamic>;
        final otherParticipant = participants.firstWhere(
          (p) =>
              p is Map<String, dynamic> &&
              p['userId']?.toString() != currentUserId,
          orElse: () => null,
        );

        if (otherParticipant != null &&
            otherParticipant is Map<String, dynamic>) {
          contactName = otherParticipant['userFullName']?.toString() ??
              otherParticipant['userName']?.toString() ??
              'Unknown Contact';
        }
      } else if (conversationData['name'] != null) {
        contactName = conversationData['name'].toString();
      }

      return UserMessageContactModel(
        id: conversationData['id']?.toString() ?? '',
        contactName: contactName,
        lastMessage: conversationData['lastMessagePreview']?.toString() ?? '',
        timestamp: formatConversationTimestamp(
          conversationData['lastMessageAt'] != null
              ? DateTime.tryParse(
                  conversationData['lastMessageAt'].toString(),
                )
              : null,
        ),
        avatarUrl: conversationData['iconUrl']?.toString(),
        isOnline: false,
        unreadCount: conversationData['unreadCount'] as int? ?? 0,
        type: conversationData['type']?.toString() ?? 'DIRECT',
        isPinned: conversationData['isPinned'] as bool? ?? false,
        isArchived: conversationData['isArchived'] as bool? ?? false,
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

      // Extract conversation name for DIRECT conversations
      // For DIRECT type, backend returns name=null, so we need to get other participant's name
      String contactName = 'Unknown Contact';
      if (conversationData['type'] == 'DIRECT' &&
          conversationData['participants'] is List) {
        final participants = conversationData['participants'] as List<dynamic>;
        final currentUserId = injector<AuthTokenManager>().getUserId();

        // Find the OTHER participant (not the current user)
        final otherParticipant = participants.firstWhere(
          (p) =>
              p is Map<String, dynamic> &&
              p['userId']?.toString() != currentUserId,
          orElse: () => null,
        );

        if (otherParticipant != null && otherParticipant is Map<String, dynamic>) {
          contactName =
              otherParticipant['userFullName']?.toString() ??
              otherParticipant['userName']?.toString() ??
              'Unknown Contact';
        }
      } else if (conversationData['name'] != null) {
        // For GROUP conversations, use the group name
        contactName = conversationData['name'].toString();
      }

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
          backendMessage ?? 'Usuário não encontrado ou não é possível iniciar conversa',
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
