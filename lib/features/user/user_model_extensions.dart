import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user/user_model.dart';

/// Extensions for UserModel to avoid code duplication (DRY principle)
/// Provides helper methods for UI display (initials, avatar colors)
extension UserModelExtensions on UserModel {
  /// Returns full name for display (name + surname)
  String get fullName => '$name $surname'.trim();

  /// Helper method to get initials from user name for avatar placeholders
  /// Generates 2-letter initials (e.g., "João Silva" → "JS")
  /// Follows same logic as UserMessageContactModel.getInitials()
  String getInitials() {
    final fullName = '$name $surname'.trim();
    final parts = fullName.split(' ');
    
    if (parts.isEmpty || fullName.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Returns a consistent color for avatar based on user ID
  /// Generates variety of colors for different users
  /// Follows same logic as UserMessageContactListItemWidget._getAvatarColor()
  Color getAvatarColor() {
    const colors = [
      Color(0xFF1565C0), // Blue
      Color(0xFFD32F2F), // Red
      Color(0xFF388E3C), // Green
      Color(0xFFF57C00), // Orange
      Color(0xFF7B1FA2), // Purple
      Color(0xFF0097A7), // Cyan
      Color(0xFFC2185B), // Pink
      Color(0xFF5D4037), // Brown
      Color(0xFF455A64), // Blue Grey
    ];

    // Use user ID to consistently assign color
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }
}

