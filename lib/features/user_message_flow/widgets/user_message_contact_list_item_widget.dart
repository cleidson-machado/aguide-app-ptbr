import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';

/// Custom list item widget for message contacts/conversations
/// Displays: circular avatar with initials, contact name, message preview,
/// timestamp, and online status indicator
class UserMessageContactListItemWidget extends StatelessWidget {
  final UserMessageContactModel contact;
  final VoidCallback onTap;

  const UserMessageContactListItemWidget({
    super.key,
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with initials and online indicator
            _buildAvatar(),
            const SizedBox(width: 12),
            
            // Contact name and message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact name (bold)
                  Text(
                    contact.contactName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Last message preview
                  Text(
                    contact.lastMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Timestamp
            const SizedBox(width: 8),
            Text(
              contact.timestamp,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds circular avatar with initials and online status indicator
  Widget _buildAvatar() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          // Circular avatar with initials
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAvatarColor(),
            ),
            child: Center(
              child: Text(
                contact.getInitials(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
          
          // Online status indicator (bottom-right)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: contact.isOnline
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemGrey3,
                border: Border.all(
                  color: CupertinoColors.systemBackground,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a consistent color for avatar based on contact ID
  /// Generates variety of colors for different contacts
  Color _getAvatarColor() {
    final colors = [
      const Color(0xFF1565C0), // Blue
      const Color(0xFFD32F2F), // Red
      const Color(0xFF388E3C), // Green
      const Color(0xFFF57C00), // Orange
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFF0097A7), // Cyan
      const Color(0xFFC2185B), // Pink
      const Color(0xFF5D4037), // Brown
      const Color(0xFF455A64), // Blue Grey
    ];
    
    // Use contact ID to consistently assign color
    final index = contact.id.hashCode.abs() % colors.length;
    return colors[index];
  }
}
