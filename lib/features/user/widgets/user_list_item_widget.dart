import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user/user_model.dart';
import 'package:portugal_guide/features/user/user_model_extensions.dart';

/// Custom list item widget for displaying system users
/// Minimalist design: circular avatar with initials + full name
/// Follows DRY principle by using UserModelExtensions for avatar logic
class UserListItemWidget extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const UserListItemWidget({
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

            // User full name
            Expanded(
              child: Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  /// Builds circular avatar with initials (uses UserModelExtensions)
  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user.getAvatarColor(), // Uses extension method (DRY)
      ),
      child: Center(
        child: Text(
          user.getInitials(), // Uses extension method (DRY)
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
