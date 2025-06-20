import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lucasbeatsfederacao/models/call_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart' show JitsiMeetingOptions, JitsiMeetingListener, JitsiMeetWrapper;

class VoipService with ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  Call? _currentCall;
  DateTime? _callStartTime;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;

  // Callbacks para a UI
  Function(String)? onCallStateChanged;

  Call? get currentCall => _currentCall;
  Duration get callDuration => _callDuration;

  bool get isInCall => _currentCall != null;
  bool get isCalling => _currentCall != null && (_currentCall!.status == CallStatus.pending || _currentCall!.status == CallStatus.active);

  VoipService(this._apiService, this._authService);

  Future<bool> initiateCall(String targetUserId, String targetUsername) async {
    Logger.info('Initiating call to $targetUsername ($targetUserId)');
    try {
      final response = await _apiService.post(
        '/api/voip/call/initiate',
        {
          'targetUserId': targetUserId,
          'callerId': _authService.currentUser!.id,
          'callerUsername': _authService.currentUser!.username,
        },
        requireAuth: true,
      );

      if (response != null && response['success'] == true) {
        final roomName = response['roomName'];
        await joinJitsiMeeting(
          roomName: roomName,
          userDisplayName: _authService.currentUser!.username,
          userEmail: _authService.currentUser!.email,
          userAvatarUrl: _authService.currentUser!.avatar,
        );
        return true;
      } else {
        Logger.error('Failed to initiate call: ${response?['message']}');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error initiating call', error: e, stackTrace: s);
      return false;
    }
  }

  Future<void> rejectCall(String callId) async {
    Logger.info('Rejecting call: $callId');
    try {
      await _apiService.post(
        '/api/voip/call/reject',
        {
          'callId': callId,
          'userId': _authService.currentUser!.id,
        },
        requireAuth: true,
      );
      _resetCallData();
      onCallStateChanged?.call('rejected');
    } catch (e, s) {
      Logger.error('Error rejecting call', error: e, stackTrace: s);
    }
  }

  Future<void> acceptCall(String callId, String roomName) async {
    Logger.info('Accepting call: $callId, room: $roomName');
    try {
      await _apiService.post(
        '/api/voip/call/accept',
        {
          'callId': callId,
          'userId': _authService.currentUser!.id,
        },
        requireAuth: true,
      );
      await joinJitsiMeeting(
        roomName: roomName,
        userDisplayName: _authService.currentUser!.username,
        userEmail: _authService.currentUser!.email,
        userAvatarUrl: _authService.currentUser!.avatar,
      );
      onCallStateChanged?.call('accepted');
    } catch (e, s) {
      Logger.error('Error accepting call', error: e, stackTrace: s);
    }
  }

  Future<void> joinJitsiMeeting({
    required String roomName,
    required String userDisplayName,
    String? userEmail,
    String? userAvatarUrl,
    bool audioMuted = false,
    bool videoMuted = true,
  }) async {
    Logger.info('Attempting to join Jitsi meeting: $roomName');

    var options = JitsiMeetingOptions(
      roomNameOrUrl: roomName,
      userDisplayName: userDisplayName,
      userEmail: userEmail,
      userAvatarUrl: userAvatarUrl,
      isAudioMuted: audioMuted,
      isVideoMuted: videoMuted,
      featureFlags: {
        "WELCOME_PAGE_ENABLED": false,
        "INVITE_ENABLED": false,
        "ADD_PEOPLE_ENABLED": false,
        "CALENDAR_ENABLED": false,
        "CALL_INTEGRATION_ENABLED": false,
        "CLOSE_CAPTIONS_ENABLED": false,
        "LIVE_STREAMING_ENABLED": false,
        "MEETING_NAME_ENABLED": false,
        "MEETING_PASSWORD_ENABLED": false,
        "PIP_ENABLED": false,
        "RAISE_HAND_ENABLED": false,
        "RECORDING_ENABLED": false,
        "TILE_VIEW_ENABLED": false,
        "TOOLBOX_ALWAYS_VISIBLE": false,
        "VIDEO_SHARE_BUTTON_ENABLED": false,
        "FULLSCREEN_ENABLED": false,
        "HELP_BUTTON_ENABLED": false,
        "KICK_OUT_ENABLED": false,
        "NOTIFICATION_ENABLED": false,
        "OVERFLOW_MENU_ENABLED": false,
        "PREJOIN_PAGE_ENABLED": false,
        "REPLACE_PARTICIPANT": false,
        "RESOLUTION": false,
        "SECURITY_OPTIONS_ENABLED": false,
        "SERVER_URL_CHANGE_ENABLED": false,
        "SETTINGS_ENABLED": false,
        "SPEAKERSTATS_ENABLED": false,
        "UNREAD_MESSAGES_ENABLED": false,
        "VIRTUAL_BACKGROUND_ENABLED": false,
        "IOS_RECORDING_ENABLED": false,
        "ANDROID_SCREEN_SHARING_ENABLED": false,
      },
    );

    try {await JitsiMeetWrapper.joinMeeting(options: options);
      Logger.info('Successfully joined Jitsi meeting: $roomName');
      _currentCall = Call(
        id: roomName, // Usando o nome da sala como ID da chamada
        callerId: _authService.currentUser!.id,
        receiverId: 'jitsi_room', // Placeholder para sala Jitsi
        type: CallType.audio, // Assumindo áudio por padrão, pode ser ajustado
        status: CallStatus.active,
        startTime: DateTime.now(),
      );
      _startCallTimer();
      onCallStateChanged?.call('active');
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error('Error joining Jitsi meeting: $error', stackTrace: stackTrace);
      onCallStateChanged?.call('failed');
      _resetCallData();
    }
  }

  // Lógica para gerar nomes de sala baseada na hierarquia
  String generateRoomName({
    required String type,
    String? clanId,
    String? federationId,
    String? userId,
    String? uuid,
    int? roomNumber,
    String? context,
  }) {
    switch (type) {
      case 'clan':
        return 'voz_clan_${clanId}_$roomNumber';
      case 'federation':
        return 'voz_fed_${federationId}_$roomNumber';
      case 'global':
        return 'voz_global_${userId}_$uuid';
      case 'admin':
        return 'voz_adm_${context}_${clanId ?? federationId ?? userId}_$uuid';
      default:
        return 'voz_default_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> endCall() async {
    Logger.info('Ending Jitsi call.');
    try {
      await JitsiMeetWrapper.hangUp();
      Logger.info('Successfully hung up Jitsi meeting.');
    } catch (error, stackTrace) {
      Logger.error('Error hanging up Jitsi meeting: $error', stackTrace: stackTrace);
    } finally {
      _resetCallData();
      onCallStateChanged?.call('ended');
    }
  }

  Future<List<Call>> getCallHistory() async {
    Logger.info('Fetching call history...');
    try {
      final response = await _apiService.get('/api/voip/call/history', requireAuth: true);

      if (response != null && response is List) {
        Logger.info('Call history fetched successfully: ${response.length} items.');
        return response.map((data) => Call.fromJson(data)).toList();
      } else {
        Logger.warning('Unexpected format for call history response: $response');
        return [];
      }
    } catch (e, s) {
      Logger.error('Error fetching call history', error: e, stackTrace: s);
      return [];
    }
  }

  void _startCallTimer() {
    Logger.info('Starting call timer.');
    _callStartTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCall?.status == CallStatus.active) {
        _callDuration = DateTime.now().difference(_callStartTime!);
        notifyListeners();
      } else {
        _durationTimer?.cancel();
      }
    });
  }

  void _resetCallData() {
    Logger.info('Resetting call data.');
    _currentCall = null;
    _callStartTime = null;
    _callDuration = Duration.zero;
    _durationTimer?.cancel();
    _durationTimer = null;
    notifyListeners();
  }

  String formatCallDuration() {
    final minutes = _callDuration.inMinutes;
    final seconds = _callDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Jitsi Meet não gerencia mute diretamente via API externa para o stream local
  // O controle de mute é feito dentro da interface do Jitsi
  Future<void> toggleMute() async {
    Logger.info('Toggle mute is handled within Jitsi Meet UI.');
    // JitsiMeetWrapper.setAudioMuted(!_audioMuted); // Exemplo se houvesse um método direto
  }

  @override
  void dispose() {
    Logger.info('Disposing VoipService...');
    _durationTimer?.cancel();
    _durationTimer = null;
    super.dispose();
  }
}



