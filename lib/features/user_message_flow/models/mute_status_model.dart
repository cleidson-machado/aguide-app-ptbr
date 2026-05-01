class MuteStatusModel {
  final String conversationId;
  final bool isMuted;
  final DateTime? mutedAt;

  const MuteStatusModel({
    required this.conversationId,
    required this.isMuted,
    this.mutedAt,
  });

  factory MuteStatusModel.fromMap(Map<String, dynamic> map) {
    return MuteStatusModel(
      conversationId: map['conversationId']?.toString() ?? '',
      isMuted: map['isMuted'] as bool? ?? false,
      mutedAt:
          map['mutedAt'] != null
              ? DateTime.tryParse(map['mutedAt'].toString())
              : null,
    );
  }
}
