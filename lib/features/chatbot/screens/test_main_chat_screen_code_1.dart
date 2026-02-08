import 'package:flutter/material.dart';
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
  List<Message> get messages => List.unmodifiable(_messages);

  /// Adds a new message to the chat history and simulates an AI response.
  void sendMessage(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return; // Do not send empty messages
    }

    // Add the user's message
    _messages.add(
      Message(text: trimmedText, isSender: true, timestamp: DateTime.now()),
    );
    notifyListeners();

    // Simulate an AI response after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
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
    return MaterialApp(
      title: 'Chat Interface',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
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
          _MessageInput(
            textEditingController: _textEditingController,
            onSend: _sendMessage,
          ),
        ],
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isSender = message.isSender;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color:
              isSender
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
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
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A widget for the message input area and send button.
class _MessageInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final VoidCallback onSend;

  const _MessageInput({
    required this.textEditingController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: textEditingController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onSubmitted: (_) => onSend(), // Send on enter key
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
