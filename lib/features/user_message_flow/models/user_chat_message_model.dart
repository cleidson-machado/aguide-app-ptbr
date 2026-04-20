import 'dart:convert';
import 'package:portugal_guide/app/core/base/base_model.dart';

/// Model representing a single chat message in a conversation
/// Follows MVVM/DDD pattern with full serialization support
class UserChatMessageModel implements BaseModel {
  @override
  final String id;

  final String text;
  final String timestamp;
  final bool isSentByMe;
  final String? avatarUrl;
  final String conversationId;
  final String senderId;
  final DateTime? sentAt;
  final String messageType;
  final bool isRead;

  const UserChatMessageModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.avatarUrl,
    this.conversationId = '',
    this.senderId = '',
    this.sentAt,
    this.messageType = 'TEXT',
    this.isRead = false,
  });

  UserChatMessageModel copyWith({
    String? id,
    String? text,
    String? timestamp,
    bool? isSentByMe,
    String? avatarUrl,
    String? conversationId,
    String? senderId,
    DateTime? sentAt,
    String? messageType,
    bool? isRead,
  }) {
    return UserChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      sentAt: sentAt ?? this.sentAt,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'timestamp': timestamp,
      'isSentByMe': isSentByMe,
      'avatarUrl': avatarUrl,
      'conversationId': conversationId,
      'senderId': senderId,
      'sentAt': sentAt?.toIso8601String(),
      'messageType': messageType,
      'isRead': isRead,
    };
  }

  factory UserChatMessageModel.fromMap(Map<String, dynamic> map) {
    return UserChatMessageModel(
      id: map['id'] as String,
      text: map['text'] as String,
      timestamp: map['timestamp'] as String,
      isSentByMe: map['isSentByMe'] as bool,
      avatarUrl: map['avatarUrl'] != null ? map['avatarUrl'] as String : null,
      conversationId: map['conversationId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      sentAt:
          map['sentAt'] != null
              ? DateTime.tryParse(map['sentAt'].toString())
              : null,
      messageType: map['messageType']?.toString() ?? 'TEXT',
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  factory UserChatMessageModel.fromApiMap(
    Map<String, dynamic> map, {
    required String? currentUserId,
  }) {
    final sender = map['sender'] as Map<String, dynamic>? ?? {};
    final senderId = sender['id']?.toString() ?? '';
    final sentAtRaw = map['sentAt']?.toString();
    final sentAt = sentAtRaw != null ? DateTime.tryParse(sentAtRaw) : null;

    return UserChatMessageModel(
      id: map['id']?.toString() ?? '',
      text: map['content']?.toString() ?? '',
      timestamp: _formatTimestamp(sentAt),
      isSentByMe: currentUserId != null && currentUserId == senderId,
      avatarUrl: null,
      conversationId: map['conversationId']?.toString() ?? '',
      senderId: senderId,
      sentAt: sentAt,
      messageType: map['messageType']?.toString() ?? 'TEXT',
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  static String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final hour =
        dateTime.hour > 12
            ? dateTime.hour - 12
            : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }

  String toJson() => json.encode(toMap());

  factory UserChatMessageModel.fromJson(String source) =>
      UserChatMessageModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserChatMessageModel(id: $id, text: $text, timestamp: $timestamp, isSentByMe: $isSentByMe, avatarUrl: $avatarUrl, conversationId: $conversationId, senderId: $senderId, sentAt: $sentAt, messageType: $messageType)';
  }

  @override
  bool operator ==(covariant UserChatMessageModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.text == text &&
        other.timestamp == timestamp &&
        other.isSentByMe == isSentByMe &&
        other.avatarUrl == avatarUrl &&
        other.conversationId == conversationId &&
        other.senderId == senderId &&
        other.sentAt == sentAt &&
        other.messageType == messageType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        text.hashCode ^
        timestamp.hashCode ^
        isSentByMe.hashCode ^
        avatarUrl.hashCode ^
        conversationId.hashCode ^
        senderId.hashCode ^
        sentAt.hashCode ^
        messageType.hashCode;
  }
}
