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
                      fontWeight: FontWeight.w700, // Bold
                      color: CupertinoColors.systemRed, // Vermelho
                    ),
                  ),
                ],
              ),
            ),

            // Chevron right indicator
            const Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
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
