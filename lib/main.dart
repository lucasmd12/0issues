import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart'; // <-- Adicionado

// Import Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/call_page.dart';
import 'screens/clan_management_screen.dart';
import 'screens/call_history_page.dart';
import 'screens/call_contacts_screen.dart';

// Import Services, Providers and Models
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/federation_service.dart';
import 'services/clan_service.dart';
import 'services/socket_service.dart';
import 'services/chat_service.dart';
import 'services/signaling_service.dart';
import 'services/voip_service.dart';
import 'services/notification_service.dart';
import 'services/mission_service.dart';
import 'services/firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/call_provider.dart';
import 'providers/mission_provider.dart';
import 'utils/logger.dart';
import 'utils/theme_constants.dart';
import 'widgets/app_lifecycle_reactor.dart';
import 'widgets/incoming_call_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://a561c5c87b25dfea7864b2fb292a25c1@o4509510833995776.ingest.us.sentry.io/4509510909820928';
      options.tracesSampleRate = 1.0; // ajuste conforme necessidade
      options.debug = true; // para ajudar no desenvolvimento, remova ou coloque false em produção
    },
    appRunner: () async {
      Logger.info("App Initialization Started.");

      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        Logger.info('Screen orientation set to portrait.');
      } catch (e, stackTrace) {
        Logger.error('Failed to set screen orientation', error: e, stackTrace: stackTrace);
        await Sentry.captureException(e, stackTrace: stackTrace);
      }

      Logger.info("Running FEDERACAOMAD App.");
      runApp(const FEDERACAOMADApp());
    },
  );
}

class FEDERACAOMADApp extends StatelessWidget {
  const FEDERACAOMADApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.info("Building FEDERACAOMADApp Widget.");

    final apiService = ApiService();
    final authService = AuthService();
    final socketService = SocketService();
    final signalingService = SignalingService(socketService);
    final clanService = ClanService(apiService, authService);
    final missionService = MissionService(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<SocketService>.value(value: socketService),
        ChangeNotifierProvider<SignalingService>.value(value: signalingService),
        Provider<FederationService>.value(value: FederationService(apiService)),
        Provider<ClanService>.value(value: clanService),
        Provider<MissionService>.value(value: missionService),
        ChangeNotifierProvider<NotificationService>.value(value: NotificationService()),
        ChangeNotifierProvider<VoipService>(create: (context) => VoipService(context.read<ApiService>(), context.read<AuthService>())),
        ChangeNotifierProvider<FirebaseService>(create: (context) => FirebaseService(context.read<AuthService>())),
        ChangeNotifierProvider<ChatService>(create: (context) => ChatService(firebaseService: context.read<FirebaseService>())),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<SocketService>(),
            context.read<AuthService>(), // Passar a instância do AuthService
          ),
        ),
        ChangeNotifierProvider<CallProvider>(
          create: (context) => CallProvider(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider<MissionProvider>(
          create: (context) => MissionProvider(context.read<MissionService>()),
        ),
      ],
      child: AppLifecycleReactor(
        child: MaterialApp(
          title: 'FEDERACAOMAD',
          debugShowCheckedModeBanner: false,
          theme: ThemeConstants.darkTheme,
          home: IncomingCallManager(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.authStatus == AuthStatus.unknown) {
                  return const SplashScreen();
                } else if (authProvider.authStatus == AuthStatus.authenticated) {
                  return const HomeScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
          ),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/call': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final roomName = args?['roomName'] ?? 'default_room';
              final contactName = args?['contactName'];
              final contactId = args?['contactId'];
              final isIncomingCall = args?['isIncomingCall'] ?? false;
              
              return CallPage(
                roomName: roomName,
                contactName: contactName,
                contactId: contactId,
                isIncomingCall: isIncomingCall,
              );
            },
            '/call-history': (context) => const CallHistoryPage(),
            '/call-contacts': (context) => const CallContactsScreen(),
            '/clan-management': (context) {
              final clanId = ModalRoute.of(context)?.settings.arguments as String?;
              if (clanId != null) {
                return ClanManagementScreen(clanId: clanId);
              } else {
                return Scaffold(
                  appBar: AppBar(title: const Text('Erro')),
                  body: const Center(child: Text('ID do Clã não fornecido.')),
                );
              }
            },
          },
        ),
      ),
    );
  }
}
