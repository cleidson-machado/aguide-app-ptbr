class BlockStatusModel {
  final String blockedUserId;
  final bool isBlocked;
  final DateTime? blockedAt;

  const BlockStatusModel({
    required this.blockedUserId,
    required this.isBlocked,
    this.blockedAt,
  });

  factory BlockStatusModel.fromMap(Map<String, dynamic> map) {
    return BlockStatusModel(
      blockedUserId: map['blockedUserId']?.toString() ?? '',
      isBlocked: map['isBlocked'] as bool? ?? true,
      blockedAt:
          map['blockedAt'] != null
              ? DateTime.tryParse(map['blockedAt'].toString())
              : null,
    );
  }
}
