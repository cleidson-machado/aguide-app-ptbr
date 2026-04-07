import 'dart:convert';
import 'package:portugal_guide/app/core/base/base_model.dart';

/// Model representing a single chat message in a conversation
/// Follows MVVM/DDD pattern with full serialization support
class ChatMessageModel implements BaseModel {
  @override
  final String id;

  final String text;
  final String timestamp;
  final bool isSentByMe;
  final String? avatarUrl;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.avatarUrl,
  });

  ChatMessageModel copyWith({
    String? id,
    String? text,
    String? timestamp,
    bool? isSentByMe,
    String? avatarUrl,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      text: map['text'] as String,
      timestamp: map['timestamp'] as String,
      isSentByMe: map['isSentByMe'] as bool,
      avatarUrl: map['avatarUrl'] != null ? map['avatarUrl'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessageModel.fromJson(String source) =>
      ChatMessageModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Factory method for mocked messages (development/testing)
  /// Returns a conversation matching the wireframe design
  static List<ChatMessageModel> getMockedMessages({String? contactId}) {
    return [
      const ChatMessageModel(
        id: 'msg_1',
        text: 'Hello, we are trying to design UI/UX for app',
        timestamp: '08:22 am',
        isSentByMe: false,
        avatarUrl: null,
      ),
      const ChatMessageModel(
        id: 'msg_2',
        text: 'Oh, Hello Angela Young',
        timestamp: '09:24 am',
        isSentByMe: true,
      ),
      const ChatMessageModel(
        id: 'msg_3',
        text: 'At first i need to know about your project details',
        timestamp: '09:24 am',
        isSentByMe: true,
      ),
      const ChatMessageModel(
        id: 'msg_4',
        text: 'Yes sure, please wait',
        timestamp: '09:26 am',
        isSentByMe: false,
        avatarUrl: null,
      ),
      const ChatMessageModel(
        id: 'msg_5',
        text: 'Can we talk about the project other platform',
        timestamp: '09:27 am',
        isSentByMe: true,
      ),
    ];
  }

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, text: $text, timestamp: $timestamp, isSentByMe: $isSentByMe, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(covariant ChatMessageModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.text == text &&
        other.timestamp == timestamp &&
        other.isSentByMe == isSentByMe &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        text.hashCode ^
        timestamp.hashCode ^
        isSentByMe.hashCode ^
        avatarUrl.hashCode;
  }
}
