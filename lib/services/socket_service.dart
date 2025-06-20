// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/utils/constants.dart'; // For backendBaseUrl
import 'package:lucasbeatsfederacao/utils/logger.dart'; // For logging

import 'dart:async';
import 'package:flutter/foundation.dart'; // For kDebugMode

class SocketService {
  IO.Socket? _socket;
  final _secureStorage = const FlutterSecureStorage();
  final String _socketUrl = backendBaseUrl; // Use ws:// for local, wss:// for production usually handled by base URL

  // Stream controllers to broadcast received data
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  final _signalController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get signalStream => _signalController.stream;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // VoIP specific streams
  final _incomingCallController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get incomingCallStream => _incomingCallController.stream;

  final _callAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callAcceptedStream => _callAcceptedController.stream;

  final _callRejectedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callRejectedStream => _callRejectedController.stream;

  final _callEndedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callEndedStream => _callEndedController.stream;

  final _statsUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsUpdateStream => _statsUpdateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // Construtor
  SocketService();

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      Logger.info('Socket already connected.');
      return;
    }

    final token = await _secureStorage.read(key: 'jwt_token');
    final userId = await _secureStorage.read(key: 'userId'); // Assuming userId is stored

    if (token == null || userId == null) {
      Logger.warning('Socket connection attempt failed: No JWT token or userId found.');
      _connectionStatusController.add(false);
      return; // Don't attempt connection without a token or userId
    }

    if (kDebugMode) {
      Logger.info('Attempting to connect to Socket.IO server at $_socketUrl');
    }
    try {
      _socket = IO.io(_socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {
          'token': token // Send JWT token for authentication
        },
      });

      _socket!.onConnect((_) {
        if (kDebugMode) {
          Logger.info('Socket connected: ${_socket!.id}');
        }
        _connectionStatusController.add(true);
        _setupListeners(); // Setup listeners only after successful connection
        _socket!.emit('user_connected', userId); // Emit user_connected with userId
      });

      _socket!.onDisconnect((reason) {
        if (kDebugMode) {
          Logger.info('Socket disconnected: $reason');
        }
        _connectionStatusController.add(false);
      });

      _socket!.onConnectError((data) {
        if (kDebugMode) {
          Logger.error('Socket connection error: $data');
        }
        _connectionStatusController.add(false);
        if (data.toString().contains('Authentication error')) {
          // Maybe trigger logout or token refresh via AuthService
        }
      });

      _socket!.onError((data) {
        if (kDebugMode) {
          Logger.error('Socket error: $data');
        }
      });

      _socket!.connect(); // Manually initiate connection

    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error initializing socket connection: ${e.toString()}');
      }
      _connectionStatusController.add(false);
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    // Listen for new messages
    _socket!.on('receive_message', (data) {
      if (kDebugMode) {
        Logger.info('Received message: $data');
      }
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else {
        Logger.warning('Received message data is not a Map: $data');
      }
    });

    // Listen for WebRTC signals
    _socket!.on('webrtc_signal', (data) {
      if (kDebugMode) {
        Logger.info('Received WebRTC signal: $data');
      }
       if (data is Map<String, dynamic>) {
        _signalController.add(data);
      } else {
        Logger.warning('Received WebRTC signal data is not a Map: $data');
      }
    });

    // VoIP event listeners
    _socket!.on('incoming_call', (data) {
      if (kDebugMode) {
        Logger.info('Received incoming call: $data');
      }
      if (data is Map<String, dynamic>) {
        _incomingCallController.add(data);
      }
    });

    _socket!.on('call_accepted', (data) {
      if (kDebugMode) {
        Logger.info('Call accepted: $data');
      }
      if (data is Map<String, dynamic>) {
        _callAcceptedController.add(data);
      }
    });

    _socket!.on('call_rejected', (data) {
      if (kDebugMode) {
        Logger.info('Call rejected: $data');
      }
      if (data is Map<String, dynamic>) {
        _callRejectedController.add(data);
      }
    });

    _socket!.on('call_ended', (data) {
      if (kDebugMode) {
        Logger.info('Call ended: $data');
      }
      if (data is Map<String, dynamic>) {
        _callEndedController.add(data);
      }
    });

    // Add listeners for other custom events from server if needed (e.g., user_joined, user_left)
  }

  // --- Emit Events ---

  void emit(String event, dynamic data) {
    if (!isConnected) {
      Logger.warning('Cannot emit event \'$event\': Socket not connected.');
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting event \'$event\' with data: $data');
    }
    _socket!.emit(event, data);
  }

  void emitWithAck(String event, dynamic data, Function(dynamic) callback) {
    if (!isConnected) {
      Logger.warning('Cannot emit event \'$event\': Socket not connected.');
      callback({'status': 'error', 'message': 'Not connected'});
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting event \'$event\' with data: $data');
    }
    _socket!.emitWithAck(event, data, ack: (response) {
      if (kDebugMode) {
        Logger.info('Ack for \'$event\': $response');
      }
      callback(response);
    });
  }

  void joinChannel(String channelId, Function(Map<String, dynamic>) callback) {
    emitWithAck('join_channel', {'channelId': channelId}, (response) {
      if (response is Map<String, dynamic>) {
        callback(response);
      } else {
        callback({'status': 'error', 'message': 'Invalid response format'});
      }
    });
  }

  void sendMessage(String channelId, String content, Function(Map<String, dynamic>) callback) {
    emitWithAck('send_message', {'channelId': channelId, 'content': content}, (response) {
      if (response is Map<String, dynamic>) {
        callback(response);
      } else {
        callback({'status': 'error', 'message': 'Invalid response format'});
      }
    });
  }

  void sendSignal(String targetUserId, String signalType, Map<String, dynamic> signalData) {
    emit('webrtc_signal', {
      'targetUserId': targetUserId,
      'signalType': signalType,
      'signalData': signalData,
    });
  }

  void leaveChannel(String channelId) {
    emit('leave_channel', {'channelId': channelId});
  }

  // VoIP specific methods
  void joinVoiceCall(String channelId) {
    emit('join_voice_call', {'channelId': channelId});
  }

  void leaveVoiceCall(String channelId) {
    emit('leave_voice_call', {'channelId': channelId});
  }

  void disconnect() {
    if (kDebugMode) {
      Logger.info('Disconnecting socket...');
    }
    _socket?.disconnect();
    _connectionStatusController.add(false);
  }

  void dispose() {
    if (kDebugMode) {
      Logger.info('Disposing SocketService...');
    }
    _messageController.close();
    _signalController.close();
    _connectionStatusController.close();
    _incomingCallController.close();
    _callAcceptedController.close();
    _callRejectedController.close();
    _callEndedController.close();
    _socket?.dispose();
    _socket = null; // Explicitly nullify on dispose
  }
}

