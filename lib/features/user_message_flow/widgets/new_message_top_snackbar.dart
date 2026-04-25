import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user_message_flow/services/message_notification_service.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

/// Displays a top snackbar notifying the user about a new incoming message.
///
/// Color choice: `CupertinoColors.activeBlue` (#007AFF) — matches the
/// app's iOS/Cupertino design system and provides high-contrast readability
/// against the white nav bars used in main screens.
///
/// Truncates long previews to keep the banner compact.
void showNewMessageTopSnackBar(
  BuildContext context,
  NewMessageEvent event,
) {
  const accentColor = CupertinoColors.activeBlue;

  // Trim long previews so the banner stays a single readable line
  final preview = event.preview.trim();
  final truncatedPreview = preview.length > 80
      ? '${preview.substring(0, 80)}…'
      : preview;

  final message = truncatedPreview.isEmpty
      ? '${event.senderName} enviou uma nova mensagem'
      : '${event.senderName}: $truncatedPreview';

  showTopSnackBar(
    Overlay.of(context),
    CustomSnackBar.info(
      message: message,
      backgroundColor: accentColor,
      icon: const Icon(
        CupertinoIcons.chat_bubble_2_fill,
        color: Color(0x66FFFFFF),
        size: 100,
      ),
      textStyle: const TextStyle(
        color: CupertinoColors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    displayDuration: const Duration(milliseconds: 2500),
    animationDuration: const Duration(milliseconds: 600),
    reverseAnimationDuration: const Duration(milliseconds: 400),
    dismissType: DismissType.onTap,
  );
}
