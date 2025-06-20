import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/chat_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/message_model.dart';
import 'package:lucasbeatsfederacao/widgets/permission_widget.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class ChatWidget extends StatefulWidget {
  final String entityId;
  final String chatType; // 'clan', 'federation', 'global'
  final String title;

  const ChatWidget({
    super.key,
    required this.entityId,
    required this.chatType,
    required this.title,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.getMessages(
        entityId: widget.entityId,
        chatType: widget.chatType,
      );
    } catch (e) {
      Logger.error('Erro ao carregar mensagens', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar mensagens')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.sendMessage(
        entityId: widget.entityId,
        message: message,
        chatType: widget.chatType,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      Logger.error('Erro ao enviar mensagem', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar mensagem')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        // Tentar usar stream em tempo real se disponível
        try {
          return StreamBuilder<List<Message>>(
            stream: chatService.listenToMessages(
              entityId: widget.entityId,
              chatType: widget.chatType,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                Logger.error('Erro no stream de mensagens', error: snapshot.error);
                // Fallback para mensagens em cache
                return _buildCachedMessagesList(chatService);
              }

              final messages = snapshot.data ?? [];
              return _buildMessagesListView(messages);
            },
          );
        } catch (e) {
          // Firebase não disponível, usar mensagens em cache
          Logger.info('Firebase não disponível, usando cache: $e');
          return _buildCachedMessagesList(chatService);
        }
      },
    );
  }

  Widget _buildCachedMessagesList(ChatService chatService) {
    final cacheKey = widget.chatType == 'global' ? 'global' : widget.entityId;
    final messages = chatService.getCachedMessagesForEntity(cacheKey);
    return _buildMessagesListView(messages);
  }

  Widget _buildMessagesListView(List<Message> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('Nenhuma mensagem ainda. Seja o primeiro a conversar!'),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isMyMessage = message.senderId == authService.currentUser?.id;

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMyMessage ? Colors.blue[600] : Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMyMessage)
              Row(
                children: [
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isMyMessage ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Adicionar badge de role se disponível
                  Consumer<AuthService>(
                    builder: (context, authService, _) {
                      // Aqui você poderia buscar informações do usuário pelo senderId
                      // Por simplicidade, vamos mostrar apenas se for admin conhecido
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: TextStyle(
                color: isMyMessage ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMyMessage ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return PermissionWidget(
      requiredAction: 'send_${widget.chatType}_message',
      clanId: widget.chatType == 'clan' ? widget.entityId : null,
      federationId: widget.chatType == 'federation' ? widget.entityId : null,
      fallback: Container(
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          'Você não tem permissão para enviar mensagens neste chat.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}

