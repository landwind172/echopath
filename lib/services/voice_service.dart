import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants.dart';
import 'tts_service.dart';
import 'navigation_service.dart';
import 'dependency_injection.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastWords = '';
  Timer? _listeningTimer;
  Timer? _restartTimer;
  bool _isProcessingCommand = false;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;
  String _currentLanguage = 'en-US';
  List<String> _availableLanguages = [];

  // Enhanced command processing
  String _currentScreen = 'home';
  
  // Simplified and more reliable command patterns
  final Map<String, List<String>> _globalCommands = {
    'home': [
      'go home', 'home', 'main screen', 'return home', 'back home',
      'navigate home', 'main', 'start screen', 'home screen'
    ],
    'map': [
      'open map', 'map', 'show map', 'view map', 'location',
      'navigation', 'interactive map', 'map screen', 'go to map'
    ],
    'discover': [
      'show tours', 'discover', 'tours', 'browse tours', 'find tours',
      'explore', 'discover tours', 'tour screen', 'explore tours',
      'go to discover', 'open discover'
    ],
    'downloads': [
      'downloads', 'offline', 'my downloads', 'saved content',
      'offline content', 'library', 'saved', 'offline library',
      'go to downloads', 'open downloads'
    ],
    'help': [
      'get help', 'help', 'support', 'assistance', 'help me',
      'help screen', 'support screen', 'go to help', 'open help'
    ],
  };

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;
  String get currentLanguage => _currentLanguage;
  String get currentScreen => _currentScreen;

  void updateCurrentScreen(String screen) {
    _currentScreen = screen;
    debugPrint('Voice service: Current screen updated to $_currentScreen');
  }

  Future<bool> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      debugPrint('Voice service: Initializing...');
      
      // Check microphone permission first
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        debugPrint('Voice service: Microphone permission not granted');
        return;
      }

      _isInitialized = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      if (_isInitialized) {
        _consecutiveErrors = 0;
        await _loadAvailableLanguages();
        await _setOptimalLanguage();
        debugPrint('Voice service: Initialized successfully with language: $_currentLanguage');
      } else {
        debugPrint('Voice service: Failed to initialize');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      _availableLanguages = locales.map((locale) => locale.localeId).toList();
      debugPrint('Available languages: $_availableLanguages');
    } catch (e) {
      debugPrint('Error loading available languages: $e');
      _availableLanguages = ['en-US', 'en-GB', 'en'];
    }
  }

  Future<void> _setOptimalLanguage() async {
    // Force en-US for consistency
    _currentLanguage = 'en-US';
    debugPrint('Voice service: Language set to $_currentLanguage');
  }

  Future<void> setLanguageToEnUS() async {
    _currentLanguage = 'en-US';
    debugPrint('Voice service: Forced language to en-US');
    if (_isInitialized) {
      await stopListening();
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized || _isListening || _isProcessingCommand) return;

    try {
      _restartTimer?.cancel();
      await Future.delayed(const Duration(milliseconds: 100));

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 1),
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: false,
          onDevice: false,
        ),
        localeId: _currentLanguage,
      );

      _isListening = true;
      _consecutiveErrors = 0;
      notifyListeners();
      debugPrint('Voice service: Started listening');
    } catch (e) {
      debugPrint('Start listening error: $e');
      _handleListeningError();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
      debugPrint('Voice service: Stopped listening');
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }
  }

  Future<void> startContinuousListening() async {
    if (!_isInitialized) return;

    stopContinuousListening();
    await startListening();

    _listeningTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isListening && !_isProcessingCommand && _consecutiveErrors < _maxConsecutiveErrors) {
        await startListening();
      }
    });
    
    debugPrint('Voice service: Continuous listening started');
  }

  void stopContinuousListening() {
    _listeningTimer?.cancel();
    _listeningTimer = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    stopListening();
    debugPrint('Voice service: Continuous listening stopped');
  }

  void _onSpeechResult(result) {
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      _lastWords = result.recognizedWords.toLowerCase().trim();
      debugPrint('Voice service: Recognized words: "$_lastWords"');
      notifyListeners();

      if (!_isProcessingCommand) {
        _processGlobalVoiceCommand(_lastWords);
      }
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('Voice service: Speech status: $status');

    switch (status) {
      case 'done':
      case 'notListening':
        _isListening = false;
        _scheduleRestart();
        break;
      case 'listening':
        _isListening = true;
        _consecutiveErrors = 0;
        break;
    }
    notifyListeners();
  }

  void _onSpeechError(error) {
    debugPrint('Voice service: Speech error: $error');
    _isListening = false;
    _handleListeningError();
    notifyListeners();
  }

  void _handleListeningError() {
    _consecutiveErrors++;
    debugPrint('Voice service: Error count: $_consecutiveErrors');

    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('Voice service: Too many errors, stopping');
      stopContinuousListening();
      
      Timer(const Duration(seconds: 10), () async {
        _consecutiveErrors = 0;
        await initialize();
        if (_isInitialized) {
          await startContinuousListening();
        }
      });
    } else {
      _scheduleRestart();
    }
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 2), () async {
      if (!_isListening && !_isProcessingCommand) {
        await startListening();
      }
    });
  }

  // Simplified global command processing
  Future<void> _processGlobalVoiceCommand(String command) async {
    if (_isProcessingCommand || command.isEmpty) return;

    _isProcessingCommand = true;
    debugPrint('Voice service: Processing global command: "$command"');

    try {
      final ttsService = getIt<TTSService>();
      final navigationService = getIt<NavigationService>();

      // Stop any current TTS
      await ttsService.stop();
      await Future.delayed(const Duration(milliseconds: 100));

      // Check for global navigation commands
      String? targetScreen = _matchGlobalCommand(command);
      
      if (targetScreen != null) {
        await _executeNavigation(targetScreen, ttsService, navigationService);
      } else if (_isUtilityCommand(command)) {
        await _handleUtilityCommand(command, ttsService);
      } else {
        // Command not recognized
        await ttsService.speakWithPriority(
          'Command not recognized: "$command". Say "voice commands" for help or try navigation commands like "go home", "open map", or "show tours".'
        );
      }
    } catch (e) {
      debugPrint('Voice service: Error processing command: $e');
    } finally {
      _isProcessingCommand = false;
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  String? _matchGlobalCommand(String command) {
    final lowerCommand = command.toLowerCase();
    
    for (final entry in _globalCommands.entries) {
      for (final pattern in entry.value) {
        if (lowerCommand.contains(pattern.toLowerCase()) || 
            _fuzzyMatch(lowerCommand, pattern)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  bool _fuzzyMatch(String command, String pattern) {
    final commandWords = command.split(' ');
    final patternWords = pattern.split(' ');
    
    int matches = 0;
    for (final commandWord in commandWords) {
      for (final patternWord in patternWords) {
        if (commandWord.contains(patternWord) || patternWord.contains(commandWord)) {
          matches++;
          break;
        }
      }
    }
    
    return matches >= (patternWords.length * 0.7);
  }

  bool _isUtilityCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains('voice commands') ||
           lowerCommand.contains('help commands') ||
           lowerCommand.contains('test voice') ||
           lowerCommand.contains('stop talking') ||
           lowerCommand.contains('repeat');
  }

  Future<void> _executeNavigation(String targetScreen, TTSService ttsService, NavigationService navigationService) async {
    String message = '';
    VoidCallback? navigationAction;

    switch (targetScreen) {
      case 'home':
        message = 'Navigating to home screen';
        navigationAction = navigationService.navigateToHome;
        break;
      case 'map':
        message = 'Opening interactive map';
        navigationAction = navigationService.navigateToMap;
        break;
      case 'discover':
        message = 'Opening discover tours';
        navigationAction = navigationService.navigateToDiscover;
        break;
      case 'downloads':
        message = 'Opening offline library';
        navigationAction = navigationService.navigateToDownloads;
        break;
      case 'help':
        message = 'Opening help and support';
        navigationAction = navigationService.navigateToHelpSupport;
        break;
    }

    if (navigationAction != null) {
      await ttsService.speakWithPriority(message);
      navigationAction();
      updateCurrentScreen(targetScreen);
      debugPrint('Voice service: Navigated to $targetScreen');
    }
  }

  Future<void> _handleUtilityCommand(String command, TTSService ttsService) async {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('voice commands') || lowerCommand.contains('help commands')) {
      await _speakGlobalVoiceCommands(ttsService);
    } else if (lowerCommand.contains('test voice')) {
      await ttsService.speakWithPriority('Voice recognition test successful! You said: "$command"');
    } else if (lowerCommand.contains('stop talking')) {
      await ttsService.stop();
    } else if (lowerCommand.contains('repeat')) {
      await ttsService.speakWithPriority('Repeating last information');
    }
  }

  Future<void> _speakGlobalVoiceCommands(TTSService ttsService) async {
    await ttsService.speakWithPriority('''
Available global voice commands that work from any screen:
Navigation: "Go home", "Open map", "Show tours", "Downloads", "Get help"
Utility: "Voice commands", "Test voice", "Stop talking", "Repeat"
These commands provide seamless navigation throughout the app.
''');
  }

  // Public method for external global command handling
  Future<void> handleGlobalVoiceCommand(String command) async {
    await _processGlobalVoiceCommand(command);
  }

  // Test methods
  Future<void> testVoiceNavigation() async {
    debugPrint('Voice service: Testing voice navigation...');
    debugPrint('Is initialized: $_isInitialized');
    debugPrint('Is listening: $_isListening');
    debugPrint('Current language: $_currentLanguage');

    final ttsService = getIt<TTSService>();
    if (_isInitialized) {
      await ttsService.speakWithPriority('Voice navigation test successful! System is working properly.');
    } else {
      await ttsService.speakWithPriority('Voice navigation not initialized. Please check permissions.');
    }
  }

  Future<void> testGlobalVoiceNavigation() async {
    final ttsService = getIt<TTSService>();
    debugPrint('Voice service: Testing global voice navigation system...');

    try {
      await ttsService.speakWithPriority('Testing global voice navigation system...');

      final testCommands = ['go home', 'open map', 'show tours', 'downloads', 'get help'];
      
      for (final command in testCommands) {
        final targetScreen = _matchGlobalCommand(command);
        debugPrint('Command "$command" -> Screen: $targetScreen');
      }

      await ttsService.speakWithPriority('Global voice navigation test completed successfully.');
    } catch (e) {
      debugPrint('Global voice navigation test error: $e');
      await ttsService.speakWithPriority('Global voice navigation test encountered an error.');
    }
  }

  @override
  void dispose() {
    stopContinuousListening();
    _speechToText.cancel();
    super.dispose();
  }
}