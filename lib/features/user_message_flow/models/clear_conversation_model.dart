class ClearConversationModel {
  final String conversationId;
  final DateTime? clearedAt;

  const ClearConversationModel({required this.conversationId, this.clearedAt});

  factory ClearConversationModel.fromMap(Map<String, dynamic> map) {
    return ClearConversationModel(
      conversationId: map['conversationId']?.toString() ?? '',
      clearedAt:
          map['clearedAt'] != null
              ? DateTime.tryParse(map['clearedAt'].toString())
              : null,
    );
  }
}
