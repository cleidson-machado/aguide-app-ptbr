import 'dart:convert';
import 'package:portugal_guide/app/core/base/base_model.dart';

/// Model representing a message contact/conversation in the chat list
/// Follows MVVM/DDD pattern with full serialization support
class UserMessageContactModel implements BaseModel {
  @override
  final String id;

  final String contactName;
  final String lastMessage;
  final String timestamp;
  final String? avatarUrl;
  final bool isOnline;
  final int unreadCount;
  final String type;
  final bool isPinned;
  final bool isArchived;

  const UserMessageContactModel({
    required this.id,
    required this.contactName,
    required this.lastMessage,
    required this.timestamp,
    this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
    this.type = 'DIRECT',
    this.isPinned = false,
    this.isArchived = false,
  });

  UserMessageContactModel copyWith({
    String? id,
    String? contactName,
    String? lastMessage,
    String? timestamp,
    String? avatarUrl,
    bool? isOnline,
    int? unreadCount,
    String? type,
    bool? isPinned,
    bool? isArchived,
  }) {
    return UserMessageContactModel(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'contactName': contactName,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'unreadCount': unreadCount,
      'type': type,
      'isPinned': isPinned,
      'isArchived': isArchived,
    };
  }

  factory UserMessageContactModel.fromMap(Map<String, dynamic> map) {
    return UserMessageContactModel(
      id: map['id'] ?? '',
      contactName: map['contactName'] ?? 'Unknown Contact',
      lastMessage: map['lastMessage'] ?? '',
      timestamp: map['timestamp'] ?? '',
      avatarUrl: map['avatarUrl'],
      isOnline: map['isOnline'] ?? false,
      unreadCount: map['unreadCount'] ?? 0,
      type: map['type'] ?? 'DIRECT',
      isPinned: map['isPinned'] ?? false,
      isArchived: map['isArchived'] ?? false,
    );
  }

  factory UserMessageContactModel.fromConversationSummaryMap(
    Map<String, dynamic> map,
  ) {
    return UserMessageContactModel(
      id: map['id']?.toString() ?? '',
      contactName: map['name']?.toString() ?? 'Unknown Contact',
      lastMessage: map['lastMessagePreview']?.toString() ?? '',
      timestamp: map['formattedTimestamp']?.toString() ?? '',
      avatarUrl: map['iconUrl']?.toString(),
      isOnline: false,
      unreadCount: map['unreadCount'] as int? ?? 0,
      type: map['type']?.toString() ?? 'DIRECT',
      isPinned: map['isPinned'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserMessageContactModel.fromJson(String source) =>
      UserMessageContactModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'UserMessageContactModel(id: $id, contactName: $contactName, lastMessage: $lastMessage, timestamp: $timestamp, isOnline: $isOnline, unreadCount: $unreadCount, type: $type, isPinned: $isPinned, isArchived: $isArchived)';
  }

  @override
  bool operator ==(covariant UserMessageContactModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.contactName == contactName &&
        other.lastMessage == lastMessage &&
        other.timestamp == timestamp &&
        other.avatarUrl == avatarUrl &&
        other.isOnline == isOnline &&
        other.unreadCount == unreadCount &&
        other.type == type &&
        other.isPinned == isPinned &&
        other.isArchived == isArchived;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        contactName.hashCode ^
        lastMessage.hashCode ^
        timestamp.hashCode ^
        avatarUrl.hashCode ^
        isOnline.hashCode ^
        unreadCount.hashCode ^
        type.hashCode ^
        isPinned.hashCode ^
        isArchived.hashCode;
  }

  /// Helper method to get initials from contact name for avatar placeholders
  String getInitials() {
    final parts = contactName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
