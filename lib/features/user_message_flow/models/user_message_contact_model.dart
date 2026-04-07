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

  const UserMessageContactModel({
    required this.id,
    required this.contactName,
    required this.lastMessage,
    required this.timestamp,
    this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
  });

  UserMessageContactModel copyWith({
    String? id,
    String? contactName,
    String? lastMessage,
    String? timestamp,
    String? avatarUrl,
    bool? isOnline,
    int? unreadCount,
  }) {
    return UserMessageContactModel(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      unreadCount: unreadCount ?? this.unreadCount,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory UserMessageContactModel.fromJson(String source) =>
      UserMessageContactModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserMessageContactModel(id: $id, contactName: $contactName, lastMessage: $lastMessage, timestamp: $timestamp, isOnline: $isOnline, unreadCount: $unreadCount)';
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
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        contactName.hashCode ^
        lastMessage.hashCode ^
        timestamp.hashCode ^
        avatarUrl.hashCode ^
        isOnline.hashCode ^
        unreadCount.hashCode;
  }

  /// Factory method to generate mocked contacts for testing/development
  /// Returns a list of realistic conversation entries matching the screenshot
  static List<UserMessageContactModel> getMockedContacts() {
    return [
      const UserMessageContactModel(
        id: '1',
        contactName: 'Bessie Cooper',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: 'Just Now',
        isOnline: true,
        unreadCount: 0,
      ),
      const UserMessageContactModel(
        id: '2',
        contactName: 'Courtney Henry',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: '4 hours ago',
        isOnline: true,
        unreadCount: 0,
      ),
      const UserMessageContactModel(
        id: '3',
        contactName: 'Ronald Richards',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: '2 days ago',
        isOnline: false,
        unreadCount: 0,
      ),
      const UserMessageContactModel(
        id: '4',
        contactName: 'Albert Flores',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: '1 week ago',
        isOnline: false,
        unreadCount: 0,
      ),
      const UserMessageContactModel(
        id: '5',
        contactName: 'Brooklyn Simmons',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: '26 Jun 2023',
        isOnline: false,
        unreadCount: 0,
      ),
      const UserMessageContactModel(
        id: '6',
        contactName: 'Cody Fisher',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: '26 Jun 2023',
        isOnline: false,
        unreadCount: 0,
      ),
      const UserMessageContactModel(
        id: '7',
        contactName: 'Guy Hawkins',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: '26 Jun 2023',
        isOnline: false,
        unreadCount: 0,
      ),
      const UserMessageContactModel(
        id: '8',
        contactName: 'Kristin Watson',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: '26 Jun 2023',
        isOnline: true,
        unreadCount: 0,
      ),
      const UserMessageContactModel(
        id: '9',
        contactName: 'Robert Fox',
        lastMessage: 'Hello Sir, How are you?',
        timestamp: '26 Jun 2023',
        isOnline: true,
        unreadCount: 0,
      ),
    ];
  }

  /// Helper method to get initials from contact name for avatar placeholders
  String getInitials() {
    final parts = contactName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
