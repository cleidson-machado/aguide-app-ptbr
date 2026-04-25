import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_page_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/block_status_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/clear_conversation_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/mute_status_model.dart';
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

  /// Toggle mute status for current participant in a conversation
  /// Endpoint: PUT /conversations/{conversationId}/mute
  Future<MuteStatusModel> toggleMuteConversation(String conversationId);

  /// Clear conversation history for current participant
  /// Endpoint: PUT /conversations/{conversationId}/clear
  Future<ClearConversationModel> clearConversation(String conversationId);

  /// Block a user by id
  /// Endpoint: PUT /users/{userId}/block
  Future<BlockStatusModel> blockUser(String userId);

  /// Remove block from a user by id
  /// Endpoint: DELETE /users/{userId}/block
  Future<void> unblockUser(String userId);

  /// List all blocked users for current user
  /// Endpoint: GET /users/blocks
  Future<List<BlockStatusModel>> getBlockedUsers();

  /// Resolve DIRECT conversation other participant id from details endpoint.
  Future<String?> getDirectConversationOtherUserId(String conversationId);
}
