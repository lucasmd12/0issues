import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
// CORREÇÃO: Importar UserModel
// CORREÇÃO: Remover import não utilizado de UserProvider, pois os dados virão de AuthService/AuthProvider
// import '../providers/user_provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart'; // Usar AuthProvider
import '../utils/logger.dart';

// Import Tab Widgets
import '../screens/tabs/home_tab.dart';
import '../screens/tabs/members_tab.dart';
import '../screens/tabs/missions_tab.dart';
import '../screens/tabs/settings_tab.dart';
import '../screens/tabs/chat_list_tab.dart';
import '../screens/voice_rooms_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Default to Home tab

  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    MembersTab(),
    ChatListTab(),
    MissionsTab(),
    SettingsTab(),
  ];

  final List<String> _backgroundImages = [
    'assets/images_png/backgrounds/bg_mercedes_forest.png',
    'assets/images_png/backgrounds/bg_bmw_smoke_01.png',
    'assets/images_png/backgrounds/bg_joker_smoke.png',
    'assets/images_png/backgrounds/bg_cards_dice.png',
    'assets/images_png/backgrounds/bg_audi_autumn.png',
    'assets/images_png/backgrounds/bg_mustang_autumn.png',
    'assets/images_png/backgrounds/bg_gtr_night.png',
    'assets/images_png/backgrounds/bg_bmw_smoke_02.png',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    Logger.info("Requesting necessary permissions...");
    PermissionStatus notificationStatus = await Permission.notification.request();
    if (notificationStatus.isGranted) {
      Logger.info("Notification permission granted.");
    } else if (notificationStatus.isDenied) {
      Logger.warning("Notification permission denied.");
    } else if (notificationStatus.isPermanentlyDenied) {
      Logger.error("Notification permission permanently denied.");
      _showSettingsDialog("Notificações");
    }

    PermissionStatus storageStatus = await Permission.storage.request();
     if (storageStatus.isGranted) {
      Logger.info("Storage permission granted.");
    } else if (storageStatus.isDenied) {
      Logger.warning("Storage permission denied.");
    } else if (storageStatus.isPermanentlyDenied) {
      Logger.error("Storage permission permanently denied.");
      _showSettingsDialog("Armazenamento");
    }

    PermissionStatus microphoneStatus = await Permission.microphone.request();
     if (microphoneStatus.isGranted) {
      Logger.info("Microphone permission granted.");
    } else if (microphoneStatus.isDenied) {
      Logger.warning("Microphone permission denied.");
    } else if (microphoneStatus.isPermanentlyDenied) {
      Logger.error("Microphone permission permanently denied.");
       _showSettingsDialog("Microfone");
    }
  }

  void _showSettingsDialog(String permissionName) {
     if (!mounted) return;
     showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Permissão Necessária"),
          content: Text("A permissão de $permissionName foi negada permanentemente. Por favor, habilite-a nas configurações do aplicativo para usar todas as funcionalidades."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Abrir Configurações"),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Logger.info("Switched to tab index: $index");
  }

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Usar AuthProvider para obter o usuário atual
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final textTheme = Theme.of(context).textTheme;

    // CORREÇÃO: Verificar status do AuthProvider, não UserProvider
    if (authProvider.authStatus == AuthStatus.unknown) {
      // Ainda verificando o estado de autenticação
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
             valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    // CORREÇÃO: Verificar se currentUser é nulo após autenticação
    if (currentUser == null) {
       Logger.warning("HomeScreen build: User is null even though authenticated. This shouldn't happen.");
       // Idealmente, o Consumer em main.dart já deveria ter redirecionado para Login
       // Mas como fallback, mostramos uma mensagem de erro.
       return Scaffold(
         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
         body: Center(child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text("Erro crítico ao carregar dados do usuário. Por favor, tente reiniciar o aplicativo.", textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
         )),
       );
    }

    return Scaffold(
      appBar: AppBar(
        // CORREÇÃO: Usar apenas o username do usuário atual com ícone pequeno
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currentUser.username,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'Salas de Voz',
            onPressed: () {
              Logger.info("Voice rooms button pressed.");
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const VoiceRoomsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notificações',
            onPressed: () {
              Logger.info("Notifications button pressed.");
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImages[_selectedIndex % _backgroundImages.length]),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: IndexedStack(
           index: _selectedIndex,
           children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Membros',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Missões',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

