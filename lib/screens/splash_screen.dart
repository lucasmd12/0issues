import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:audioplayers/audioplayers.dart';

class SplashScreen extends StatefulWidget {
  final bool showIndicator;
  final Duration duration;
  
  const SplashScreen({
    super.key, 
    this.showIndicator = true,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    Logger.info("SplashScreen initialized. Indicator: ${widget.showIndicator}");
    
    // Inicializar animações
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Iniciar animações
    _fadeController.forward();
    _scaleController.forward();
    
    // Iniciar progresso simulado
    _startProgressSimulation();
    
    // Tocar som de inicialização
    await _playSplashSound();
  }

  void _startProgressSimulation() {
    if (!widget.showIndicator) return;
    
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _loadingProgress += 0.02;
        if (_loadingProgress >= 1.0) {
          _loadingProgress = 1.0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _playSplashSound() async {
    try {
      Logger.info("Reproduzindo som de inicialização...");
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      // Tentar tocar o som de splash
      await _audioPlayer.play(AssetSource('audio/splash_sound.mp3'));
      Logger.info("Som de inicialização reproduzido com sucesso.");
    } catch (e, stackTrace) {
      Logger.error("Falha ao reproduzir som de inicialização", error: e, stackTrace: stackTrace);
      // Continuar sem som se houver erro
    }
  }

  @override
  void dispose() {
    Logger.info("Disposing SplashScreen...");
    _progressTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a1a), // Cinza escuro no topo
              Color(0xFF000000), // Preto na base
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images_png/app_logo.png',
                            height: 120,
                            width: 120,
                            errorBuilder: (context, error, stackTrace) {
                              Logger.error("Falha ao carregar logo", error: error, stackTrace: stackTrace);
                              return Container(
                                height: 120,
                                width: 120,
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Nome do app
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'FEDERACAO MADOUT',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.purple.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtítulo
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Comunicação e organização para o clã',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Indicador de carregamento
                if (widget.showIndicator) ...[
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: 200 * _loadingProgress,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.blue],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando... ${(_loadingProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

