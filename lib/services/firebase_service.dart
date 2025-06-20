import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class FirebaseService with ChangeNotifier {
  final AuthService _authService;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  FirebaseService(this._authService);

  // Inicializar o serviço Firebase
  Future<void> initialize() async {
    try {
      // Configurar permissões de notificação
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      Logger.info('Permissões de notificação: ${settings.authorizationStatus}');

      // Configurar handlers de mensagens
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Obter token FCM
      String? token = await _messaging.getToken();
      if (token != null) {
        Logger.info('Token FCM: $token');
        await _saveTokenToDatabase(token);
      }

      // Listener para atualizações de token
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

      Logger.info('Firebase Service inicializado com sucesso');
    } catch (e, stackTrace) {
      Logger.error('Erro ao inicializar Firebase Service', error: e, stackTrace: stackTrace);
    }
  }

  // Salvar token FCM no banco de dados
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _database.ref('users/${user.id}/fcmToken').set(token);
        Logger.info('Token FCM salvo no banco de dados');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao salvar token FCM', error: e, stackTrace: stackTrace);
    }
  }

  // Enviar mensagem para um usuário específico
  Future<void> sendMessageToUser(String userId, String message, {Map<String, dynamic>? data}) async {
    try {
      final messageRef = _database.ref('messages').push();
      await messageRef.set({
        'senderId': _authService.currentUser?.id,
        'receiverId': userId,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'data': data,
      });
      Logger.info('Mensagem enviada para usuário $userId');
    } catch (e, stackTrace) {
      Logger.error('Erro ao enviar mensagem', error: e, stackTrace: stackTrace);
    }
  }

  // Enviar mensagem para uma sala/canal
  Future<void> sendMessageToRoom(String roomId, String message, {Map<String, dynamic>? data}) async {
    try {
      final messageRef = _database.ref('rooms/$roomId/messages').push();
      await messageRef.set({
        'senderId': _authService.currentUser?.id,
        'senderName': _authService.currentUser?.username,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'data': data,
      });
      Logger.info('Mensagem enviada para sala $roomId');
    } catch (e, stackTrace) {
      Logger.error('Erro ao enviar mensagem para sala', error: e, stackTrace: stackTrace);
    }
  }

  // Escutar mensagens de uma sala específica
  Stream<DatabaseEvent> listenToRoomMessages(String roomId) {
    return _database.ref('rooms/$roomId/messages').orderByChild('timestamp').onValue;
  }

  // Escutar mensagens diretas para o usuário atual
  Stream<DatabaseEvent> listenToDirectMessages() {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }
    return _database.ref('messages').orderByChild('receiverId').equalTo(userId).onValue;
  }

  // Criar ou atualizar informações de uma sala de voz
  Future<void> createVoiceRoom({
    required String roomId,
    required String roomName,
    required String roomType, // 'clan', 'federation', 'global', 'admin'
    required String creatorId,
    String? clanId,
    String? federationId,
    List<String>? allowedUsers,
  }) async {
    try {
      await _database.ref('voiceRooms/$roomId').set({
        'roomName': roomName,
        'roomType': roomType,
        'creatorId': creatorId,
        'clanId': clanId,
        'federationId': federationId,
        'allowedUsers': allowedUsers,
        'createdAt': ServerValue.timestamp,
        'isActive': true,
        'participants': {},
      });
      Logger.info('Sala de voz criada: $roomId');
    } catch (e, stackTrace) {
      Logger.error('Erro ao criar sala de voz', error: e, stackTrace: stackTrace);
    }
  }

  // Adicionar participante à sala de voz
  Future<void> joinVoiceRoom(String roomId, String userId, String userName) async {
    try {
      await _database.ref('voiceRooms/$roomId/participants/$userId').set({
        'userName': userName,
        'joinedAt': ServerValue.timestamp,
      });
      Logger.info('Usuário $userId entrou na sala $roomId');
    } catch (e, stackTrace) {
      Logger.error('Erro ao entrar na sala de voz', error: e, stackTrace: stackTrace);
    }
  }

  // Remover participante da sala de voz
  Future<void> leaveVoiceRoom(String roomId, String userId) async {
    try {
      await _database.ref('voiceRooms/$roomId/participants/$userId').remove();
      Logger.info('Usuário $userId saiu da sala $roomId');
    } catch (e, stackTrace) {
      Logger.error('Erro ao sair da sala de voz', error: e, stackTrace: stackTrace);
    }
  }

  // Escutar participantes de uma sala de voz
  Stream<DatabaseEvent> listenToVoiceRoomParticipants(String roomId) {
    return _database.ref('voiceRooms/$roomId/participants').onValue;
  }

  // Listar salas de voz ativas
  Stream<DatabaseEvent> listenToActiveVoiceRooms() {
    return _database.ref('voiceRooms').orderByChild('isActive').equalTo(true).onValue;
  }

  // Encerrar sala de voz
  Future<void> endVoiceRoom(String roomId) async {
    try {
      await _database.ref('voiceRooms/$roomId').update({
        'isActive': false,
        'endedAt': ServerValue.timestamp,
      });
      Logger.info('Sala de voz encerrada: $roomId');
    } catch (e, stackTrace) {
      Logger.error('Erro ao encerrar sala de voz', error: e, stackTrace: stackTrace);
    }
  }

  // Handler para mensagens em primeiro plano
  void _handleForegroundMessage(RemoteMessage message) {
    Logger.info('Mensagem recebida em primeiro plano: ${message.notification?.title}');
    // Aqui você pode mostrar uma notificação local ou atualizar a UI
  }

  // Handler para quando o app é aberto através de uma notificação
  void _handleMessageOpenedApp(RemoteMessage message) {
    Logger.info('App aberto através de notificação: ${message.notification?.title}');
    // Aqui você pode navegar para uma tela específica baseada na mensagem
  }

}

// Handler para mensagens em background (deve ser uma função top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger.info('Mensagem recebida em background: ${message.notification?.title}');
}

