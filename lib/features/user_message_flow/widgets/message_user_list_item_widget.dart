import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user_message_flow/models/message_user_data.dart';

/// Widget de lista de usuários específico para feature user_message_flow
/// 
/// Exibe: Avatar + Nome + Role Designation (PRODUTOR/CONSUMIDOR)
/// 
/// **Princípio DDD:** Widget isolado da feature 'user' core.
/// Usa MessageUserData (modelo híbrido) em vez de depender de UserDetailsModel.
class MessageUserListItemWidget extends StatelessWidget {
  final MessageUserData user;
  final VoidCallback onTap;

  const MessageUserListItemWidget({
    super.key,
    required this.user,
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
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with initials
            _buildAvatar(),
            const SizedBox(width: 12),

            // User full name + role designation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full name
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Role designation (PRODUTOR / CONSUMIDOR)
                  Text(
                    user.roleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.systemRed,
                    ),
                  ),

                  // Last message preview (only if conversation exists)
                  if (user.lastMessagePreview != null &&
                      user.lastMessagePreview!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.lastMessagePreview!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Right column: timestamp + unread badge / chevron
            const SizedBox(width: 8),
            _buildTrailing(),
          ],
        ),
      ),
    );
  }

  /// Builds trailing widget: timestamp of last message + unread badge,
  /// or chevron if user never had a conversation.
  Widget _buildTrailing() {
    final formattedTimestamp = user.formattedLastMessageAt;

    if (formattedTimestamp == null) {
      // Nunca conversou: apenas chevron (mantém comportamento legado)
      return const Icon(
        CupertinoIcons.chevron_right,
        size: 18,
        color: CupertinoColors.systemGrey3,
      );
    }

    final hasUnread = user.unreadCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTimestamp,
          style: TextStyle(
            fontSize: 12,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
            color: hasUnread
                ? CupertinoColors.activeBlue
                : CupertinoColors.secondaryLabel,
          ),
        ),
        if (hasUnread) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: const BoxDecoration(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              user.unreadCount > 99 ? '99+' : '${user.unreadCount}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds circular avatar with initials
  /// 
  /// Reutiliza lógica de cor de UserModelExtensions (getAvatarColor)
  /// baseado no hash do ID para garantir cor consistente
  Widget _buildAvatar() {
    // Gera cor consistente baseada no hash do ID
    final hash = user.id.hashCode;
    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemPink,
    ];
    final avatarColor = colors[hash.abs() % colors.length];

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor,
      ),
      child: Center(
        child: Text(
          user.getInitials(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}
