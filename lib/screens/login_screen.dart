import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed Firebase import
import '../services/auth_service.dart'; // Use AuthService for login
import '../services/keep_alive_service.dart'; // Adicionar keep-alive service
import '../utils/logger.dart';
import '../widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Changed from email to username to match AuthService
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isWakingServer = false;
  final KeepAliveService _keepAliveService = KeepAliveService();

  @override
  void initState() {
    super.initState();
    // Iniciar keep-alive service quando a tela de login é carregada
    _keepAliveService.startKeepAlive();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ensureServerIsAwake() async {
    setState(() {
      _isWakingServer = true;
    });

    try {
      Logger.info('Checking if server is awake...');
      bool isAwake = await _keepAliveService.ensureServerAwake();
      
      if (!isAwake) {
        if (mounted) {
          CustomSnackbar.showInfo(context, 'Servidor iniciando... Isso pode levar até 1 minuto.');
        }
        // Tentar novamente após um delay
        await Future.delayed(const Duration(seconds: 5));
        await _keepAliveService.ensureServerAwake();
      }
    } catch (e) {
      Logger.warning('Failed to ensure server is awake: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isWakingServer = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Primeiro, garantir que o servidor está ativo
      await _ensureServerIsAwake();

      final authService = Provider.of<AuthService>(context, listen: false);
      Logger.info('Attempting login for: ${_usernameController.text}');

      // Use AuthService to login
      bool success = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        Logger.info('Login successful via AuthService for user: ${authService.currentUser?.username}');
        // Navigation is handled by the Consumer<AuthService> in main.dart
      } else {
        // AuthService handles logging errors, show generic message here
        if (mounted) {
           final errorMsg = authService.errorMessage ?? 'Falha no login. Verifique suas credenciais.';
           CustomSnackbar.showError(context, errorMsg);
        }
      }
    // Catch generic exceptions from AuthService/ApiService
    } catch (e) {
      Logger.error('Login Screen Error', error: e);
      if (mounted) {
        String errorMessage = e.toString().replaceFirst("Exception: ", "");
        
        // Mensagens mais amigáveis para erros comuns
        if (errorMessage.contains('TimeoutException')) {
          errorMessage = 'Servidor demorou para responder. Tente novamente em alguns segundos.';
        } else if (errorMessage.contains('SocketException')) {
          errorMessage = 'Problema de conexão. Verifique sua internet e tente novamente.';
        }
        
        CustomSnackbar.showError(context, 'Erro no login: $errorMessage');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // TODO: Implement password reset functionality via backend API
  Future<void> _handlePasswordReset() async {
     final username = _usernameController.text.trim();
     if (username.isEmpty) {
       CustomSnackbar.showError(context, 'Digite seu nome de usuário para solicitar a redefinição.');
       return;
     }
     // Placeholder - Requires backend endpoint and AuthService method
     Logger.warning("Password Reset functionality not implemented yet.");
     CustomSnackbar.showInfo(context, 'Funcionalidade de redefinição de senha ainda não implementada.');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images_png/app_icon_login_splash.jpg',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shield_moon,
                      size: 80,
                      color: Color(0xFF9147FF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'FEDERACAOMAD',
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faça login para continuar',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium,
                  ),
                  const SizedBox(height: 48),

                  // Username Field (Changed from Email)
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                    decoration: const InputDecoration(
                      labelText: 'Usuário',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu nome de usuário';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: (_isLoading || _isWakingServer) ? null : _handleLogin,
                    child: (_isLoading || _isWakingServer)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(_isWakingServer ? 'INICIANDO SERVIDOR...' : 'ENTRANDO...'),
                            ],
                          )
                        : const Text('ENTRAR'),
                  ),
                  const SizedBox(height: 16),

                  // Forgot Password & Register Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: (_isLoading || _isWakingServer) ? null : _handlePasswordReset,
                        child: const Text('Esqueceu a senha?'),
                      ),
                      TextButton(
                        onPressed: (_isLoading || _isWakingServer) ? null : () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Criar conta'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

