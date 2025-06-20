// lib/screens/call_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/models/call_model.dart';

class CallScreen extends StatefulWidget {
  final Call call;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.call,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    final voipService = Provider.of<VoipService>(context, listen: false);
    
    voipService.onCallStateChanged = (state) {
      if (state == 'ended') {
        Navigator.of(context).pop();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<VoipService>(
        builder: (context, voipService, child) {
          return SafeArea(
            child: Column(
              children: [
                // Header com informações da chamada
                _buildCallHeader(voipService),
                
                // Área de vídeo (para futuras implementações de vídeo)
                Expanded(
                  child: _buildVideoArea(voipService),
                ),
                
                // Controles da chamada
                _buildCallControls(voipService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallHeader(VoipService voipService) {
    final call = voipService.currentCall ?? widget.call;
    String statusText = '';
    
    switch (call.status) {
      case CallStatus.pending:
        statusText = widget.isIncoming ? 'Chamada recebida' : 'Chamando...';
        break;
      case CallStatus.active:
        statusText = voipService.formatCallDuration();
        break;
      case CallStatus.ended:
        statusText = 'Chamada encerrada';
        break;
      default:
        statusText = 'Conectando...';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar do usuário
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[800],
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Nome do usuário
          Text(
            widget.isIncoming ? 'Usuário ${call.callerId}' : 'Usuário ${call.receiverId}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Status da chamada
          Text(
            statusText,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea(VoipService voipService) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Vídeo remoto (placeholder por enquanto)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: Center(
              child: Icon(
                Icons.person,
                size: 100,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // Vídeo local (canto superior direito, para futuras implementações)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls(VoipService voipService) {
    final call = voipService.currentCall ?? widget.call;
    
    if (call.status == CallStatus.pending && widget.isIncoming) {
      // Controles para chamada recebida
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botão rejeitar
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.red,
              onPressed: () async {
                await voipService.rejectCall(call.id);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            
            // Botão aceitar
            _buildControlButton(
              icon: Icons.call,
              color: Colors.green,
              onPressed: () async {
                await voipService.acceptCall(call.id, call.id); // Usando call.id como roomName
              },
            ),
          ],
        ),
      );
    } else {
      // Controles para chamada ativa
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botão mute
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? Colors.red : Colors.grey[700]!,
              onPressed: () {
                setState(() {
                  _isMuted = !_isMuted;
                });
                voipService.toggleMute();
              },
            ),
            
            // Botão encerrar chamada
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.red,
              onPressed: () async {
                await voipService.endCall();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            
            // Botão speaker
            _buildControlButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              color: _isSpeakerOn ? Colors.blue : Colors.grey[700]!,
              onPressed: () {
                setState(() {
                  _isSpeakerOn = !_isSpeakerOn;
                });
                // TODO: Implementar toggle speaker
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 30),
        onPressed: onPressed,
      ),
    );
  }
}


