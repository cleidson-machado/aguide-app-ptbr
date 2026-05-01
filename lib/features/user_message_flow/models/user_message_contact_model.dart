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
  final DateTime? lastMessageAt;
  final String? avatarUrl;
  final bool isOnline;
  final int unreadCount;
  final String type;
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;
  final DateTime? mutedAt;

  const UserMessageContactModel({
    required this.id,
    required this.contactName,
    required this.lastMessage,
    required this.timestamp,
    this.lastMessageAt,
    this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
    this.type = 'DIRECT',
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
    this.mutedAt,
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
    bool? isMuted,
    DateTime? mutedAt,
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
      isMuted: isMuted ?? this.isMuted,
      mutedAt: mutedAt ?? this.mutedAt,
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
      'isMuted': isMuted,
      'mutedAt': mutedAt?.toIso8601String(),
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
      isMuted: map['isMuted'] ?? false,
      mutedAt:
          map['mutedAt'] != null
              ? DateTime.tryParse(map['mutedAt'].toString())
              : null,
    );
  }

  factory UserMessageContactModel.fromConversationSummaryMap(
    Map<String, dynamic> map,
  ) {
    final rawLastMessageAt = map['lastMessageAt'];
    // ⚠️ ORDEM DE PRIORIDADE OBRIGATÓRIA (backend fix 2026-04-25):
    // 1º) `displayName` → backend calcula o nome do "outro participante" para DIRECT
    // 2º) `name`        → preenchido apenas em GROUP/CHANNEL (sempre null em DIRECT)
    // 3º) fallback hardcoded
    // Sem ler `displayName` primeiro, conversas DIRECT exibem "Unknown Contact".
    final resolvedName =
        (map['displayName']?.toString().trim().isNotEmpty ?? false)
            ? map['displayName'].toString()
            : (map['name']?.toString().trim().isNotEmpty ?? false)
            ? map['name'].toString()
            : 'Unknown Contact';
    return UserMessageContactModel(
      id: map['id']?.toString() ?? '',
      contactName: resolvedName,
      lastMessage: map['lastMessagePreview']?.toString() ?? '',
      timestamp: map['formattedTimestamp']?.toString() ?? '',
      lastMessageAt:
          rawLastMessageAt != null
              ? DateTime.tryParse(rawLastMessageAt.toString())
              : null,
      avatarUrl: map['iconUrl']?.toString(),
      isOnline: false,
      unreadCount: map['unreadCount'] as int? ?? 0,
      type: map['type']?.toString() ?? 'DIRECT',
      isPinned: map['isPinned'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      isMuted: map['isMuted'] as bool? ?? false,
      mutedAt:
          map['mutedAt'] != null
              ? DateTime.tryParse(map['mutedAt'].toString())
              : null,
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
        other.isArchived == isArchived &&
        other.isMuted == isMuted &&
        other.mutedAt == mutedAt;
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
        isArchived.hashCode ^
        isMuted.hashCode ^
        mutedAt.hashCode;
  }

  /// Helper method to get initials from contact name for avatar placeholders
  String getInitials() {
    final parts = contactName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
