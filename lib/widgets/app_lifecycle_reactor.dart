import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart'; // Import AuthService
import 'package:lucasbeatsfederacao/services/chat_service.dart'; // Para atualizar presença
// Para potencialmente sair do canal
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart'; // Import UserModel

/// Um widget que reage às mudanças no ciclo de vida do aplicativo.
/// Utilizado para atualizar o status de presença online/offline do usuário
/// e potencialmente limpar recursos de chamada ao ir para background.
class AppLifecycleReactor extends StatefulWidget {
  final Widget child;

  const AppLifecycleReactor({super.key, required this.child});

  @override
  State<AppLifecycleReactor> createState() => _AppLifecycleReactorState();
}

class _AppLifecycleReactorState extends State<AppLifecycleReactor> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Logger.info("AppLifecycleReactor initialized and observing.");
    // Define o status inicial como online ao iniciar/reativar
    // Atrasar um pouco para garantir que o Provider esteja pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if the widget is still mounted
        _updatePresence(true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    Logger.info("App lifecycle state changed: $state");

    switch (state) {
      case AppLifecycleState.resumed:
        _updatePresence(true);
        break;
      case AppLifecycleState.inactive:
      // App está inativo, mas ainda pode estar visível (ex: chamada do sistema)
      // Pode ser um bom momento para salvar estado, mas não necessariamente ficar offline.
        break;
      case AppLifecycleState.paused:
      // App está em background.
        _updatePresence(false);
        // Opcional: Desconectar da chamada ativa para economizar recursos/dados?
        // context.read<CallProvider>().leaveChannel(); // CUIDADO: Pode ser abrupto para o usuário.
        break;
      case AppLifecycleState.detached:
      // App está sendo finalizado. Tenta marcar como offline.
        _updatePresence(false);
        break;
      case AppLifecycleState.hidden: // Novo estado, similar a paused/detached
         _updatePresence(false);
         break;
    }
  }

  /// Atualiza o status de presença.
  Future<void> _updatePresence(bool isOnline) async {
    if (!mounted) return; // Check if widget is still in the tree
    final authService = context.read<AuthService>();
    final chatService = context.read<ChatService>();
    // Corrected: Use UserModel instead of User
    final UserModel? currentUser = authService.currentUser;

    if (currentUser != null) {
      final userId = currentUser.id;
      Logger.info("Updating presence for user $userId to: ${isOnline ? 'online' : 'offline'}");
      // Não aguarda aqui para não bloquear a UI
      chatService.atualizarStatusPresenca(userId, isOnline).catchError((e, s) {
         Logger.error("Error updating presence in background", error: e, stackTrace: s);
      });
    } else {
       Logger.warning("Cannot update presence: currentUser is null when trying to update.");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Logger.info("AppLifecycleReactor disposed and stopped observing.");
    // Tenta definir como offline ao fechar (pode não executar sempre)
    // A chamada a _updatePresence aqui pode falhar se o contexto não estiver mais disponível
    // _updatePresence(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

