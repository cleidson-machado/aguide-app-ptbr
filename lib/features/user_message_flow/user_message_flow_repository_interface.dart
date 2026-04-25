import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_page_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';

abstract class UserMessageFlowRepositoryInterface {
  /// Get all conversations for the current user (inbox list)
  /// Endpoint: GET /conversations
  Future<List<UserMessageContactModel>> getConversations({
    bool includeArchived,
  });

  /// Get detailed information about a specific conversation
  /// Endpoint: GET /conversations/{conversationId}
  /// Returns full conversation details including participants
  Future<UserMessageContactModel> getConversationDetails(String conversationId);

  Future<UserChatMessagePageModel> getMessagesByConversation({
    required String conversationId,
    required int page,
    int size,
  });

  Future<UserChatMessageModel> sendTextMessage({
    required String conversationId,
    required String content,
  });

  /// Mark a specific message as read
  /// Endpoint: PUT /messages/{messageId}/read
  /// Updates lastReadAt timestamp for the conversation participant
  Future<void> markMessageAsRead(String messageId);

  /// Create or retrieve a direct conversation with another user
  /// Endpoint: POST /conversations/direct
  /// Returns conversation (creates new if doesn't exist, or returns existing)
  Future<UserMessageContactModel> createDirectConversation({
    required String otherUserId,
  });
}
