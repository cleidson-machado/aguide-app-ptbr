import 'package:flutter/cupertino.dart'; // Changed from material.dart
import 'package:provider/provider.dart';
import 'dart:async'; // Required for Timer or Future.delayed

/// DATA_MODEL
/// Represents a single message in the chat.
class Message {
  final String text;
  final bool isSender; // true if sent by user, false if received
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isSender,
    required this.timestamp,
  });
}

/// The data model for the chat screen, managing messages.
class ChatData extends ChangeNotifier {
  final List<Message> _messages;

  ChatData() : _messages = [] {
    // Initialize with an opening message from the AI.
    _messages.add(
      Message(
        text: "Hello! How can I help you today?",
        isSender: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  // Provides an unmodifiable view of the messages list.
  List<Message> get messages => List<Message>.unmodifiable(_messages);

  /// Adds a new message to the chat history and simulates an AI response.
  void sendMessage(String text) {
    final String trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return; // Do not send empty messages
    }

    // Add the user's message
    _messages.add(
      Message(text: trimmedText, isSender: true, timestamp: DateTime.now()),
    );
    notifyListeners();

    // Simulate an AI response after a short delay
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      _messages.add(
        Message(
          text: "Thank you for your message. I'm an AI and still learning!",
          isSender: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    });
  }
}

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Chat Interface',
      theme: const CupertinoThemeData(
        primaryColor:
            CupertinoColors
                .activeBlue, // A common primary color for Cupertino apps
        brightness:
            Brightness.light, // Ensure light mode for consistent appearance
      ),
      home: ChangeNotifierProvider<ChatData>(
        create: (BuildContext context) => ChatData(),
        builder: (BuildContext context, Widget? child) {
          return const ChatScreen();
        },
      ),
    );
  }
}

/// The main chat screen widget.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _textEditingController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _scrollController = ScrollController();
    // Listen for new messages to scroll to the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatData>(
        context,
        listen: false,
      ).addListener(_scrollToBottom);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final String messageText = _textEditingController.text;
    if (messageText.trim().isNotEmpty) {
      Provider.of<ChatData>(context, listen: false).sendMessage(messageText);
      _textEditingController.clear();
      // Scrolling will happen automatically due to listener in initState
    }
  }

  @override
  void dispose() {
    Provider.of<ChatData>(
      context,
      listen: false,
    ).removeListener(_scrollToBottom);
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text('AI Chat'), // Title for the navigation bar
      ),
      backgroundColor:
          CupertinoColors
              .systemGroupedBackground, // Typical iOS background color
      child: SafeArea(
        // Ensures content is not obscured by system UI
        child: Column(
          children: <Widget>[
            Expanded(
              child: Consumer<ChatData>(
                builder: (
                  BuildContext context,
                  ChatData chatData,
                  Widget? child,
                ) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: chatData.messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Message message = chatData.messages[index];
                      return ChatMessageBubble(message: message);
                    },
                  );
                },
              ),
            ),
            MessageInput(
              textEditingController: _textEditingController,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget to display a single chat message bubble.
class ChatMessageBubble extends StatelessWidget {
  final Message message;

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
                  ? CupertinoColors
                      .activeBlue // Sender's bubble color
                  : CupertinoColors.systemGrey5, // Receiver's bubble color
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft:
                isSender
                    ? const Radius.circular(16.0)
                    : const Radius.circular(4.0),
            bottomRight:
                isSender
                    ? const Radius.circular(4.0)
                    : const Radius.circular(16.0),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color:
                isSender
                    ? CupertinoColors
                        .white // Text color for sender
                    : CupertinoColors.label, // Text color for receiver
          ),
        ),
      ),
    );
  }
}

/// A widget for the message input area and send button.
class MessageInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final VoidCallback onSend;

  const MessageInput({
    required this.textEditingController,
    required this.onSend,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: CupertinoColors.systemGrey6, // Background for the input bar
      child: Row(
        children: <Widget>[
          Expanded(
            child: CupertinoTextField(
              controller: textEditingController,
              placeholder: 'Type your message...', // Cupertino-style hint text
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(), // Send on enter key
              decoration: BoxDecoration(
                color:
                    CupertinoColors
                        .systemBackground, // White background for the text field
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: CupertinoColors.systemGrey4, // Subtle border
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          CupertinoButton(
            padding: EdgeInsets.zero, // Remove default button padding
            onPressed: onSend,
            child: Container(
              width: 40.0, // Fixed width for circular button
              height: 40.0, // Fixed height for circular button
              decoration: const BoxDecoration(
                color:
                    CupertinoColors
                        .activeBlue, // Background color for send button
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.arrow_up_circle_fill, // Cupertino send icon
                color: CupertinoColors.white, // Icon color
                size: 24.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
