import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

import '../services/tts_service.dart';
import '../services/dependency_injection.dart';
import '../core/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  final TTSService _ttsService = getIt<TTSService>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Use post-frame callback to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize app state
      final appStateProvider = Provider.of<AppStateProvider>(
        context,
        listen: false,
      );
      await appStateProvider.initialize();

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Speak welcome message
      await _speakWelcomeMessage();

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Navigation will be handled automatically after speech completion
    } catch (e) {
      debugPrint('App initialization error: $e');
      if (mounted) {
        _navigateToNextScreen(true);
      }
    }
  }

  Future<void> _speakWelcomeMessage() async {
    if (!mounted) return;

    const welcomeMessage = '''
      Welcome to Echo Guide, your voice-powered tour companion. 
      I am your personal guide, ready to help you explore the world through immersive audio experiences.
      
      You can navigate between screens using voice commands like:
      - Say "go home" to return to the main screen
      - Say "open map" to view locations
      - Say "show tours" to discover new experiences
      - Say "open downloads" for offline content
      - Say "get help" for assistance
      
      Voice navigation is now active. Let's begin your journey.
    ''';

    await _ttsService.speak(welcomeMessage);

    // Automatically transition after speech completion
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        final appStateProvider = Provider.of<AppStateProvider>(
          context,
          listen: false,
        );
        if (appStateProvider.autoTransitionEnabled) {
          _navigateToNextScreen(appStateProvider.isFirstLaunch);
        }
      }
    }
  }

  void _navigateToNextScreen(bool isFirstLaunch) {
    if (!mounted) return;

    // Always go to onboarding for the automatic flow
    Navigator.of(context).pushReplacementNamed(Routes.onboarding);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(
                          context,
                        ).primaryColor.withAlpha((0.6 * 255).round()),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).primaryColor.withAlpha((0.3 * 255).round()),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 60),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Echo Guide',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Voice-Powered Tour Companion',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volume_up,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Initializing voice navigation...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
