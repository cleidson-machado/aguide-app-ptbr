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

  String _messagesByConversationEndpoint(String conversationId) {
    return 'messages/conversation/$conversationId';
  }

  String _messagesEndpoint() => 'messages';

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

      if (response.statusCode != 200 || rawList == null) {
        throw const UserMessageFlowException('Failed to load conversations');
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

      _log('Mapped conversations count=${mapped.length}');
      return mapped;
    } on DioException catch (e) {
      _log(
        'Conversations request failed status=${e.response?.statusCode} message=${e.message}',
      );
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

      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        throw const UserMessageFlowException('Failed to load messages');
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

      if (response.statusCode != 201 ||
          response.data is! Map<String, dynamic>) {
        throw const UserMessageFlowException('Failed to send message');
      }

      _log('Message sent status=${response.statusCode}');

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
