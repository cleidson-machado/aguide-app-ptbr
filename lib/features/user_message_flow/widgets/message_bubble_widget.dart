import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user_message_flow/models/chat_message_model.dart';

/// Custom message bubble widget for chat conversations
/// Displays messages with different styles for sent vs received messages
/// - Sent messages: Blue background, white text, right-aligned, no avatar
/// - Received messages: Gray background, black text, left-aligned, with avatar
class MessageBubbleWidget extends StatelessWidget {
  final ChatMessageModel message;
  final String? contactName;
  final bool showAvatar;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    this.contactName,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: message.isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages (left side)
          if (!message.isSentByMe && showAvatar) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: message.isSentByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isSentByMe
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isSentByMe
                          ? CupertinoColors.white
                          : CupertinoColors.label,
                    ),
                  ),
                ),
                // Timestamp below bubble
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    message.timestamp,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Spacer for sent messages (to push avatar gap on left)
          if (message.isSentByMe && showAvatar) const SizedBox(width: 58),
        ],
      ),
    );
  }

  /// Builds circular avatar with initials for received messages
  Widget _buildAvatar(BuildContext context) {
    final initials = _getInitials(contactName ?? 'User');
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getAvatarColor(contactName ?? 'User'),
      ),
      child: Stack(
        children: [
          // Avatar with initials
          Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Online status indicator (green dot)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemGreen,
                border: Border.all(
                  color: CupertinoColors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generates initials from contact name (max 2 characters)
  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length > 2 ? 2 : words[0].length).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Generates consistent color based on contact name hash
  Color _getAvatarColor(String name) {
    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPink,
      CupertinoColors.systemPurple,
      CupertinoColors.systemRed,
      CupertinoColors.systemTeal,
    ];
    
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}
