import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/chatbot/chat_service.dart';
import 'package:portugal_guide/features/chatbot/chat_message_model.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService;
  ChatController(this._chatService);

  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isLoading) return;

    _addMessage(trimmedText, isSender: true);
    _setLoading(true);

    try {
      final aiResponse = await _chatService.sendMessageToApi(trimmedText);
      _addMessage(aiResponse, isSender: false);
    } catch (e) {
      _addMessage("Desculpe, ocorreu um erro.", isSender: false);
    } finally {
      _setLoading(false);
    }
  }

  void _addMessage(String text, {required bool isSender}) {
    _messages.add(
      ChatMessageModel(
        text: text,
        isSender: isSender,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void _setLoading(bool loadingState) {
    _isLoading = loadingState;
    notifyListeners();
  }
}
