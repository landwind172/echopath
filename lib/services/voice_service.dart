import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';
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
  
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;

  Future<void> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );
      
      if (_isInitialized) {
        _consecutiveErrors = 0;
        debugPrint('Voice service initialized successfully');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      _consecutiveErrors++;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized || _isListening || _isProcessingCommand) return;

    try {
      // Cancel any existing restart timer
      _restartTimer?.cancel();
      
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          partialResults: false, // Only final results to reduce glitches
          cancelOnError: true,
          onDevice: true, // Use on-device recognition when available
        ),
        localeId: AppConstants.defaultLanguage,
      );
      
      _isListening = true;
      _consecutiveErrors = 0;
      notifyListeners();
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
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }
  }

  Future<void> startContinuousListening() async {
    if (!_isInitialized) return;

    // Start immediate listening
    await startListening();

    // Set up continuous listening with smart restart
    _listeningTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isListening && !_isProcessingCommand && _consecutiveErrors < _maxConsecutiveErrors) {
        await startListening();
      }
    });
  }

  void stopContinuousListening() {
    _listeningTimer?.cancel();
    _listeningTimer = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    stopListening();
  }

  void _onSpeechResult(result) {
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      _lastWords = result.recognizedWords.toLowerCase().trim();
      notifyListeners();
      
      // Process command with debouncing to prevent glitches
      if (!_isProcessingCommand) {
        _processVoiceCommand(_lastWords);
      }
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');
    
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
    debugPrint('Speech error: $error');
    _isListening = false;
    _handleListeningError();
    notifyListeners();
  }

  void _handleListeningError() {
    _consecutiveErrors++;
    
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('Too many consecutive errors, stopping voice recognition');
      stopContinuousListening();
      
      // Try to reinitialize after a delay
      Timer(const Duration(seconds: 5), () async {
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
    _restartTimer = Timer(const Duration(milliseconds: 1000), () async {
      if (!_isListening && !_isProcessingCommand) {
        await startListening();
      }
    });
  }

  Future<void> _processVoiceCommand(String command) async {
    if (_isProcessingCommand || command.isEmpty) return;
    
    _isProcessingCommand = true;
    
    try {
      debugPrint('Processing voice command: $command');
      final ttsService = getIt<TTSService>();
      final navigationService = getIt<NavigationService>();

      // Stop current TTS to prevent overlapping speech
      await ttsService.stop();
      
      // Wait a brief moment to ensure TTS has stopped
      await Future.delayed(const Duration(milliseconds: 200));

      // Enhanced navigation commands with multiple variations
      if (_isNavigationCommand(command, ['home', 'go home', 'main screen', 'main menu', 'start screen'])) {
        navigationService.navigateToHome();
        await ttsService.speak('Navigating to home screen');
      } 
      else if (_isNavigationCommand(command, ['map', 'show map', 'open map', 'view map', 'location', 'navigation'])) {
        navigationService.navigateToMap();
        await ttsService.speak('Opening map screen');
      } 
      else if (_isNavigationCommand(command, ['discover', 'tours', 'show tours', 'browse tours', 'find tours', 'explore'])) {
        navigationService.navigateToDiscover();
        await ttsService.speak('Opening discover screen');
      } 
      else if (_isNavigationCommand(command, ['downloads', 'offline', 'my downloads', 'saved content', 'offline content'])) {
        navigationService.navigateToDownloads();
        await ttsService.speak('Opening downloads screen');
      } 
      else if (_isNavigationCommand(command, ['help', 'support', 'get help', 'assistance', 'help me'])) {
        navigationService.navigateToHelpSupport();
        await ttsService.speak('Opening help and support screen');
      }
      // Enhanced location and map commands
      else if (_isNavigationCommand(command, ['where am i', 'my location', 'current location', 'find me'])) {
        await ttsService.speak('Getting your current location');
      }
      else if (_isNavigationCommand(command, ['find places', 'nearby places', 'what is nearby', 'places around me'])) {
        await ttsService.speak('Searching for nearby places');
      }
      else if (_isNavigationCommand(command, ['find hotels', 'nearby hotels', 'hotels around me', 'accommodation'])) {
        await ttsService.speak('Searching for nearby hotels');
      }
      else if (_isNavigationCommand(command, ['find restaurants', 'nearby restaurants', 'food places', 'dining options'])) {
        await ttsService.speak('Searching for nearby restaurants');
      }
      else if (_isNavigationCommand(command, ['find markets', 'nearby markets', 'shopping places', 'market places'])) {
        await ttsService.speak('Searching for nearby markets');
      }
      else if (_isNavigationCommand(command, ['find tours', 'nearby tours', 'tour guides', 'guided tours'])) {
        await ttsService.speak('Searching for nearby tours');
      }
      // Zoom and map control commands
      else if (_isNavigationCommand(command, ['zoom in', 'closer', 'zoom closer'])) {
        await ttsService.speak('Zooming in');
      }
      else if (_isNavigationCommand(command, ['zoom out', 'farther', 'zoom farther'])) {
        await ttsService.speak('Zooming out');
      }
      // Voice control commands
      else if (_isNavigationCommand(command, ['voice commands', 'available commands', 'help commands', 'what can i say'])) {
        await _speakGlobalVoiceCommands(ttsService);
      }
      else if (_isNavigationCommand(command, ['repeat', 'say again', 'repeat that'])) {
        await ttsService.speak('Repeating last information');
      }
      else if (_isNavigationCommand(command, ['stop talking', 'be quiet', 'silence'])) {
        await ttsService.stop();
      }
      // Buganda-specific content commands
      else if (_isNavigationCommand(command, ['kasubi', 'kasubi tombs', 'royal tombs'])) {
        await _speakBugandaLocation(ttsService, 'kasubi');
      }
      else if (_isNavigationCommand(command, ['namugongo', 'martyrs', 'martyrs shrine'])) {
        await _speakBugandaLocation(ttsService, 'namugongo');
      }
      else if (_isNavigationCommand(command, ['palace', 'lubiri', 'kabaka palace'])) {
        await _speakBugandaLocation(ttsService, 'palace');
      }
      else if (_isNavigationCommand(command, ['mengo', 'mengo hill'])) {
        await _speakBugandaLocation(ttsService, 'mengo');
      }
      else if (_isNavigationCommand(command, ['lake victoria', 'lake', 'victoria'])) {
        await _speakBugandaLocation(ttsService, 'lake');
      }
      else {
        // Provide helpful feedback for unrecognized commands
        await ttsService.speak('Command not recognized. Say "voice commands" to hear available options.');
      }
    } catch (e) {
      debugPrint('Error processing voice command: $e');
    } finally {
      _isProcessingCommand = false;
      
      // Brief delay before allowing new commands to prevent rapid-fire commands
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  bool _isNavigationCommand(String command, List<String> triggers) {
    return triggers.any((trigger) => command.contains(trigger));
  }

  Future<void> _speakGlobalVoiceCommands(TTSService ttsService) async {
    await ttsService.speak('''
Available voice commands:
Navigation: "Go home", "Open map", "Show tours", "Downloads", "Get help"
Map features: "Find places", "Find hotels", "Find restaurants", "Find markets", "Find tours"
Map controls: "Zoom in", "Zoom out", "Where am I"
Buganda locations: "Kasubi tombs", "Namugongo shrine", "Lubiri palace", "Mengo hill", "Lake Victoria"
Voice control: "Voice commands", "Repeat", "Stop talking"
Say any of these commands clearly for navigation and control.
''');
  }

  Future<void> _speakBugandaLocation(TTSService ttsService, String location) async {
    String description = '';
    
    switch (location) {
      case 'kasubi':
        description = 'Kasubi Tombs: The sacred burial site of Buganda kings, featuring traditional architecture and deep cultural significance. A UNESCO World Heritage site.';
        break;
      case 'namugongo':
        description = 'Namugongo Martyrs Shrine: A major pilgrimage site commemorating 45 Christian martyrs, featuring beautiful architecture and peaceful gardens.';
        break;
      case 'palace':
        description = 'Lubiri Palace: The magnificent residence of the Kabaka of Buganda, combining traditional African architecture with modern amenities.';
        break;
      case 'mengo':
        description = 'Mengo Hill: The traditional heart of Buganda kingdom, offering panoramic views of Kampala and centuries of royal history.';
        break;
      case 'lake':
        description = 'Lake Victoria: Africa\'s largest lake, offering stunning views, fishing villages, boat tours, and spectacular sunsets.';
        break;
    }
    
    await ttsService.speak(description);
  }

  @override
  void dispose() {
    stopContinuousListening();
    _speechToText.cancel();
    super.dispose();
  }
}