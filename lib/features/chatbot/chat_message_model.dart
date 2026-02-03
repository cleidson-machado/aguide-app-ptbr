class ChatMessageModel {
  final String text;
  final bool isSender;
  final bool? isMachine;
  final DateTime timestamp;

  ChatMessageModel({
    required this.text,
    required this.isSender,
    this.isMachine,
    required this.timestamp,
  });
}
