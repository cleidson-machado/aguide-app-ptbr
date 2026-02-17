import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/chatbot/chat_controller.dart';
import 'package:portugal_guide/features/chatbot/chat_message_model.dart';
import 'package:provider/provider.dart';

// A View é responsável apenas pela UI e por delegar eventos ao Controller.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    final controller = Provider.of<ChatController>(context, listen: false);
    controller.addListener(_scrollToBottom);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final controller = Provider.of<ChatController>(context, listen: false);
    controller.sendMessage(_textController.text);
    _textController.clear();
  }

  @override
  void dispose() {
    Provider.of<ChatController>(
      context,
      listen: false,
    ).removeListener(_scrollToBottom);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, child) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            transitionBetweenRoutes: false,
            middle: Text('AI Chat (MVC)'),
          ),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return ChatMessageBubble(message: message);
                    },
                  ),
                ),
                if (controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CupertinoActivityIndicator(),
                  ),
                MessageInput(
                  textEditingController: _textController,
                  onSend: _sendMessage,
                  isEnabled: !controller.isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widgets de UI podem ficar no mesmo arquivo da view ou separados.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const ChatMessageBubble({required this.message, super.key});
  @override
  Widget build(BuildContext context) {
    final bool isSender = message.isSender;
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color:
              isSender
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isSender ? CupertinoColors.white : CupertinoColors.label,
          ),
        ),
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final VoidCallback onSend;
  final bool isEnabled;

  const MessageInput({
    required this.textEditingController,
    required this.onSend,
    this.isEnabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: CupertinoColors.systemGrey6,
      child: Row(
        children: <Widget>[
          Expanded(
            child: CupertinoTextField(
              controller: textEditingController,
              placeholder: 'Digite sua mensagem...',
              enabled: isEnabled,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8.0),
          CupertinoButton(
            onPressed: isEnabled ? onSend : null,
            child: const Icon(CupertinoIcons.arrow_up_circle_fill),
          ),
        ],
      ),
    );
  }
}
