import 'package:portugal_guide/features/user_message_flow/models/user_chat_message_model.dart';

class UserChatMessagePageModel {
  final List<UserChatMessageModel> messages;
  final int totalItems;
  final int totalPages;
  final int currentPage;

  const UserChatMessagePageModel({
    required this.messages,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
  });

  bool get hasNextPage => currentPage < totalPages - 1;
}
