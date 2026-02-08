import 'dart:async';

class ChatService {
  Future<String> sendMessageToApi(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (userMessage.toLowerCase().contains('olá')) {
      return 'Olá! Como posso te ajudar hoje?';
    }
    return "Obrigado pela sua mensagem. Eu sou uma IA e ainda estou aprendendo!";
  }
}
