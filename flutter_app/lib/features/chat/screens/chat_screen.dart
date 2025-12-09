import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/models/chat.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;

  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<Message> _messages = [];
  List<AIProvider> _providers = [];
  AIProvider? _selectedProvider;
  String? _selectedModel;
  String? _currentConversationId;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final providers = await SupabaseService.instance.getAIProviders();

      setState(() {
        _providers = providers;
        if (_providers.isNotEmpty) {
          _selectedProvider = _providers.first;
          _selectedModel = _selectedProvider!.models.firstOrNull;
        }
      });

      if (_currentConversationId != null && _currentConversationId != 'new') {
        final messages =
            await SupabaseService.instance.getMessages(_currentConversationId!);
        setState(() => _messages = messages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _selectedProvider == null ||
        _selectedModel == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Add user message to UI immediately
    final userMessage = Message(
      conversationId: _currentConversationId ?? 'temp',
      role: 'user',
      content: messageText,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final request = ChatRequest(
        conversationId: _currentConversationId != 'new' ? _currentConversationId : null,
        message: messageText,
        providerId: _selectedProvider!.id,
        model: _selectedModel!,
      );

      final response = await SupabaseService.instance.sendMessage(request);

      // Update conversation ID if it was a new conversation
      if (_currentConversationId == null || _currentConversationId == 'new') {
        _currentConversationId = response.conversationId;
      }

      // Add assistant message
      final assistantMessage = Message(
        id: response.messageId,
        conversationId: response.conversationId,
        role: 'assistant',
        content: response.content,
        providerId: _selectedProvider!.id,
        model: response.model,
        tokensUsed: response.tokensUsed,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('chat')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (_selectedProvider != null && _selectedModel != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.psychology_outlined),
              tooltip: context.tr('select_model'),
              onSelected: (model) {
                setState(() => _selectedModel = model);
              },
              itemBuilder: (context) => _selectedProvider!.models
                  .map((model) => PopupMenuItem(
                        value: model,
                        child: Text(model),
                      ))
                  .toList(),
            ),
          PopupMenuButton<AIProvider>(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch Provider',
            onSelected: (provider) {
              setState(() {
                _selectedProvider = provider;
                _selectedModel = provider.models.firstOrNull;
              });
            },
            itemBuilder: (context) => _providers
                .map((provider) => PopupMenuItem(
                      value: provider,
                      child: Text(provider.displayName),
                    ))
                .toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Model selector banner
                if (_selectedProvider != null && _selectedModel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedProvider!.displayName} - $_selectedModel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _MessageBubble(message: _messages[index]);
                          },
                        ),
                ),

                // Loading indicator
                if (_isSending)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        Text(context.tr('loading')),
                      ],
                    ),
                  ),

                // Input field
                _buildInputField(),
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
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('start_chatting'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: context.tr('type_message'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}
