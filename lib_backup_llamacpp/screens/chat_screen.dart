import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_ai_companion/providers/chat_provider.dart';
import 'package:offline_ai_companion/providers/ai_model_provider.dart';
import 'package:offline_ai_companion/widgets/message_bubble.dart';
import 'package:offline_ai_companion/widgets/chat_input.dart';
import 'package:offline_ai_companion/widgets/session_drawer.dart';
import 'package:offline_ai_companion/widgets/twinkling_bot.dart';
import 'package:offline_ai_companion/utils/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    final aiModelProvider = context.read<AIModelProvider>();
    
    print('ChatScreen: Sending message: "$message"');
    print('ChatScreen: Selected model: ${aiModelProvider.selectedModel?.name} (${aiModelProvider.selectedModel?.id})');
    
    chatProvider.sendMessage(message);

    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final currentSession = chatProvider.currentSession;
            return Text(
              currentSession?.title ?? 'New Chat',
              style: const TextStyle(fontWeight: FontWeight.w600),
            );
          },
        ),
        actions: [
          // Debug button to show model info
          Consumer<AIModelProvider>(
            builder: (context, aiModelProvider, child) {
              return IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  _showModelInfo(aiModelProvider);
                },
                tooltip: 'Model Info',
              );
            },
          ),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'new_chat':
                      chatProvider.createNewSession();
                      break;
                    case 'clear_chat':
                      await _showClearChatDialog(chatProvider);
                      break;
                    case 'export_chat':
                      await _exportCurrentChat(chatProvider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'new_chat',
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('New Chat'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_chat',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear Chat'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_chat',
                    child: Row(
                      children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('Export Chat'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: const SessionDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final currentSession = chatProvider.currentSession;
                
                if (currentSession == null || currentSession.messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: currentSession.messages.length,
                  itemBuilder: (context, index) {
                    final message = currentSession.messages[index];
                    return MessageBubble(
                      message: message,
                      isLast: index == currentSession.messages.length - 1,
                    );
                  },
                );
              },
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.isGenerating) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Small twinkling bot avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: TwinklingBot(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Small typing indicator
                      Text(
                        'Qwen2 is typing',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Three bouncing dots
                      TypingDots(),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            isGenerating: context.watch<ChatProvider>().isGenerating,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything! I\'m here to help.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AIModelProvider>(
            builder: (context, aiModelProvider, child) {
              final selectedModel = aiModelProvider.selectedModel;
              if (selectedModel != null) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Using: ${selectedModel.name}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showClearChatDialog(ChatProvider chatProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      chatProvider.clearSession();
    }
  }

  Future<void> _exportCurrentChat(ChatProvider chatProvider) async {
    final currentSession = chatProvider.currentSession;
    if (currentSession == null) return;

    try {
      final exportData = await chatProvider.exportChatData();
      // TODO: Implement share functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export chat: $e')),
      );
    }
  }

  void _showModelInfo(AIModelProvider aiModelProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Model: ${aiModelProvider.selectedModel?.name ?? "None"}'),
            Text('Model ID: ${aiModelProvider.selectedModel?.id ?? "None"}'),
            Text('Available Models: ${aiModelProvider.availableModels.length}'),
            const SizedBox(height: 8),
            ...aiModelProvider.availableModels.map((model) => 
              Text('• ${model.name} (${model.id}) - Available: ${model.isAvailable}')
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 