import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/call_page.dart'; // Importar CallPage

class CallContactsScreen extends StatefulWidget {
  const CallContactsScreen({super.key});

  @override
  State<CallContactsScreen> createState() => _CallContactsScreenState();
}

class _CallContactsScreenState extends State<CallContactsScreen> {
  List<UserModel> _onlineUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOnlineUsers();
  }

  Future<void> _loadOnlineUsers() async {
    try {
      setState(() => _isLoading = true);
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/api/users/online');
      
      if (response != null && response['users'] != null) {
        _onlineUsers = (response['users'] as List)
            .map((user) => UserModel.fromJson(user))
            .toList();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      Logger.error('Erro ao carregar usuários online: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer Chamada'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _onlineUsers.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum usuário online no momento',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _onlineUsers.length,
                  itemBuilder: (context, index) {
                    final user = _onlineUsers[index];
                    return Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          backgroundImage: user.avatar != null
                              ? NetworkImage(user.avatar!)
                              : null,
                          child: user.avatar == null
                              ? Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Online',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () => _initiateCall(user),
                              tooltip: 'Chamada de voz',
                            ),
                            IconButton(
                              icon: const Icon(Icons.videocam, color: Colors.blue),
                              onPressed: () => _initiateVideoCall(user),
                              tooltip: 'Chamada de vídeo',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOnlineUsers,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Future<void> _initiateCall(UserModel user) async {
    try {
      final voipService = Provider.of<VoipService>(context, listen: false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Iniciando Chamada', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chamando ${user.username}...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Gerar um roomName único para a chamada
      final roomName = 'call_${DateTime.now().millisecondsSinceEpoch}_${user.id}';

      final success = await voipService.initiateCall(user.id, user.username);
      
      // Usar mounted para verificar se o widget ainda está na árvore antes de interagir com o contexto
      if (mounted) {
        Navigator.pop(context); // Fechar diálogo de loading
      }
      
      if (success) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallPage(
                contactId: user.id,
                contactName: user.username,
                isIncomingCall: false,
                roomName: roomName, // Passar o roomName para CallPage
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog('Falha ao iniciar chamada. Tente novamente.');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar diálogo de loading
      }
      Logger.error('Erro ao iniciar chamada: $e');
      if (mounted) {
        _showErrorDialog('Erro ao iniciar chamada: $e');
      }
    }
  }

  Future<void> _initiateVideoCall(UserModel user) async {
    _showErrorDialog('Chamadas de vídeo ainda não estão disponíveis.');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Erro', style: TextStyle(color: Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


