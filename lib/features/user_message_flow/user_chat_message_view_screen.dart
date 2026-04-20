import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';
import 'package:portugal_guide/features/user_message_flow/user_chat_message_view_model.dart';
import 'package:portugal_guide/features/user_message_flow/widgets/user_message_bubble_widget.dart';

/// Chat detail screen showing 1-on-1 conversation with message bubbles
/// Displays messages in WhatsApp-style layout with blue sent messages (right)
/// and gray received messages (left) with avatars
///
/// ✅ This is a NAVIGATED route (not a TAB), so it has NavigationBar with back button
class UserChatMessageViewScreen extends StatefulWidget {
  final UserMessageContactModel contact;

  const UserChatMessageViewScreen({super.key, required this.contact});

  @override
  State<UserChatMessageViewScreen> createState() =>
      _UserChatMessageViewScreenState();
}

class _UserChatMessageViewScreenState extends State<UserChatMessageViewScreen> {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  late UserChatMessageViewModel _viewModel;
  String? _composerValidationMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _viewModel = injector<UserChatMessageViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadInitialMessages(widget.contact.id);

    // Auto-mark messages as read when conversation is opened
    // This will update unreadCount on backend and clear badges
    _viewModel.markAllAsRead();

    // Auto-scroll to bottom after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});

    if (kDebugMode) {
      debugPrint(
        '📜 [UserChatMessageViewScreen] messages=${_viewModel.messages.length} loading=${_viewModel.isLoading} sending=${_viewModel.isSending} error=${_viewModel.error} contact=${widget.contact.contactName}',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  /// Scrolls to bottom of message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Handles send button tap - sends message via real API (POST /messages)
  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _composerValidationMessage = 'Digite uma mensagem antes de enviar.';
      });
      return;
    }
    if (_viewModel.isSending) {
      return;
    }

    setState(() {
      _composerValidationMessage = null;
    });

    await _viewModel.sendTextMessage(
      conversationId: widget.contact.id,
      content: text,
    );
    _messageController.clear();

    // Auto-scroll to show new message
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    if (kDebugMode) {
      debugPrint('📤 [UserChatMessageViewScreen] Mensagem enviada: $text');
    }
  }

  /// Handles ellipsis menu tap (top-right)
  void _handleMenuTap() {
    if (kDebugMode) {
      debugPrint('⚙️ [UserChatMessageViewScreen] Menu acionado');
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(widget.contact.contactName),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  if (kDebugMode) {
                    debugPrint('🔇 Silenciar conversa');
                  }
                },
                child: const Text('Silenciar conversa'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  if (kDebugMode) {
                    debugPrint('🗑️ Limpar conversa');
                  }
                },
                child: const Text('Limpar conversa'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  if (kDebugMode) {
                    debugPrint('🚫 Bloquear usuário');
                  }
                },
                isDestructiveAction: true,
                child: const Text('Bloquear usuário'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: _buildNavigationBarMiddle(),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleMenuTap,
          child: const Icon(CupertinoIcons.ellipsis, size: 24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child:
                  _viewModel.isLoading && _viewModel.messages.isEmpty
                      ? const Center(
                        child: CupertinoActivityIndicator(radius: 16),
                      )
                      : _viewModel.messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _viewModel.messages.length,
                        itemBuilder: (context, index) {
                          final message = _viewModel.messages[index];
                          return UserMessageBubbleWidget(
                            message: message,
                            contactName: widget.contact.contactName,
                            showAvatar: !message.isSentByMe,
                          );
                        },
                      ),
            ),

            // Message input field
            _buildMessageInputField(),
          ],
        ),
      ),
    );
  }

  /// Builds navigation bar middle section with avatar + name + status
  Widget _buildNavigationBarMiddle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar (smaller version)
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getAvatarColor(widget.contact.contactName),
          ),
          child: Center(
            child: Text(
              _getInitials(widget.contact.contactName),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Name and status
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contact.contactName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.contact.isOnline ? 'Online' : 'Offline',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds message input field with send button
  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_composerValidationMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6),
                    child: Text(
                      _composerValidationMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  )
                else if (_viewModel.error != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6),
                    child: Text(
                      _viewModel.error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ),
                CupertinoTextField(
                  controller: _messageController,
                  placeholder: 'Message...',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendMessage(),
                  onChanged: (_) {
                    if (_composerValidationMessage != null) {
                      setState(() {
                        _composerValidationMessage = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _viewModel.isSending ? null : _handleSendMessage,
            child: Icon(
              CupertinoIcons.arrow_up_circle_fill,
              color:
                  _viewModel.isSending
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemBlue,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty state when no messages
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.chat_bubble_2,
            size: 80,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sem mensagens ainda',
            style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 8),
          Text(
            'Envie uma mensagem para ${widget.contact.contactName}',
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey2,
            ),
          ),
        ],
      ),
    );
  }

  /// Generates initials from contact name
  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0]
          .substring(0, words[0].length > 2 ? 2 : words[0].length)
          .toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Generates consistent color based on contact name
  Color _getAvatarColor(String name) {
    const colors = [
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
