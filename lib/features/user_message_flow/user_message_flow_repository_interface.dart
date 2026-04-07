import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_page_model.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';

abstract class UserMessageFlowRepositoryInterface {
  Future<List<UserMessageContactModel>> getConversations({
    bool includeArchived,
  });

  Future<UserChatMessagePageModel> getMessagesByConversation({
    required String conversationId,
    required int page,
    int size,
  });

  Future<UserChatMessageModel> sendTextMessage({
    required String conversationId,
    required String content,
  });
}
