import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart'; // Import User model
import '../../services/auth_service.dart';
import '../../services/clan_service.dart'; // Service to get clan/channel data
import '../../providers/call_provider.dart'; // To join/leave voice calls
import '../../utils/logger.dart';
import '../../models/channel_model.dart'; // Use Channel

class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key});
  
  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  ClanService? _clanService;
  AuthService? _authService;
  CallProvider? _callProvider;

  String? _currentVoiceChannelId;
  bool _isLoadingChannels = false;
  // CORREÇÃO: Usar Channel, a filtragem pode ser feita depois se necessário
  List<Channel> _voiceChannels = [];
  String? _errorLoadingChannels;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initServicesAndLoadData();
        _callProvider?.addListener(_updateCurrentChannelState);
      }
    });
  }

  void _initServicesAndLoadData() {
    if (!mounted) return;
    _authService = Provider.of<AuthService>(context, listen: false);
    _clanService = Provider.of<ClanService>(context, listen: false);
    _callProvider = Provider.of<CallProvider>(context, listen: false);
    _updateCurrentChannelState(); // Initial state
    _loadVoiceChannels(); // Load channels initially
  }

  @override
  void dispose() {
    _callProvider?.removeListener(_updateCurrentChannelState);
    super.dispose();
  }

  void _updateCurrentChannelState() {
    if (!mounted) return;
    final newChannelId = _callProvider?.currentChannelId;
    if (_currentVoiceChannelId != newChannelId) {
      setState(() {
        _currentVoiceChannelId = newChannelId;
        Logger.info("ChatListTab updated current channel ID: $_currentVoiceChannelId");
      });
    }
  }

  Future<void> _loadVoiceChannels() async {
    if (_isLoadingChannels || _clanService == null || _authService == null || !mounted) return;

    // CORREÇÃO: Usar authService diretamente
    final UserModel? currentUser = _authService!.currentUser;

    // CORREÇÃO: Acessar clanId diretamente
    if (currentUser?.clan == null) {
      Logger.warning("Cannot load channels: User not in a clan.");
      if (mounted) {
        setState(() {
          _errorLoadingChannels = "Você não está em um clã para ver os canais.";
          _voiceChannels = [];
        });
      }
      return;
    }

    final String clanId = currentUser!.clan!;

    setState(() {
      _isLoadingChannels = true;
      _errorLoadingChannels = null;
    });

    try {
      // CORREÇÃO: Chamar getClanChannels corretamente
      // Assumindo que getClanChannels retorna List<Channel>
      // e que queremos canais de voz (precisa ajustar o serviço ou filtrar aqui)
      // Vamos chamar com type=\'clan\' para buscar canais de clã
      final List<Channel> channels = await _clanService!.getClanChannels(clanId);

      if (mounted) {
        setState(() {
          _voiceChannels = channels; // Atribui os canais de voz diretamente
        });
      }
      // CORREÇÃO: Usar clanId da variável
      Logger.info("Loaded ${_voiceChannels.length} voice channels for clan $clanId.");
    } catch (e, s) {
      Logger.error("Erro ao carregar canais de voz", error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _errorLoadingChannels = "Erro ao carregar canais: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChannels = false;
        });
      }
    }
  }

  Future<void> _entrarNoCanal(String channelId, String channelName) async {
    if (_callProvider == null || !mounted) return;
    Logger.info("Attempting to join voice channel: $channelId ($channelName)");
    try {
      await _callProvider!.joinChannel(channelId);
    } catch (e) {
      Logger.error("Error joining channel $channelId from UI", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao entrar no canal: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _sairDoCanal() async {
    if (_callProvider == null || !mounted) return;
    Logger.info("Attempting to leave current voice channel: $_currentVoiceChannelId");
    try {
      await _callProvider!.leaveChannel();
    } catch (e) {
      Logger.error("Error leaving channel $_currentVoiceChannelId from UI", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao sair do canal: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingChannels) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLoadingChannels != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_errorLoadingChannels!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent), textAlign: TextAlign.center),
      ));
    }

    if (_voiceChannels.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Nenhum canal de voz encontrado para seu clã.", style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
      ));
    }

    return RefreshIndicator(
      onRefresh: _loadVoiceChannels,
      child: ListView.builder(
        itemCount: _voiceChannels.length,
        itemBuilder: (context, index) {
          final canal = _voiceChannels[index];
          final bool estouNesteCanal = canal.id == _currentVoiceChannelId;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: estouNesteCanal ? theme.primaryColor.withOpacity(0.3) : theme.cardColor,
            child: ListTile(
              leading: Icon(
                Icons.headset_mic,
                color: estouNesteCanal ? theme.primaryColor : theme.iconTheme.color,
              ),
              // CORREÇÃO: Usar \'nome\' do ChatChannelModel
              title: Text(canal.name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
              // Subtitle pode ser adicionado se necessário (ex: membros online)
              trailing: estouNesteCanal
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text("Sair"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _sairDoCanal,
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      // CORREÇÃO: Usar \'nome\' do ChatChannelModel
                      onPressed: () => _entrarNoCanal(canal.id, canal.name),
                      child: const Text("Entrar"),
                    ),
            ),
          );
        },
      ),
    );
  }
}


