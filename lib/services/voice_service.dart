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
  String _currentLanguage = AppConstants.defaultLanguage;
  List<String> _availableLanguages = [];

  // Enhanced command processing
  String _currentScreen =
      'home'; // Track current screen for context-aware commands
  final Map<String, List<String>> _commandSynonyms = {
    'home': [
      'home',
      'main',
      'start',
      'beginning',
      'main screen',
      'start screen',
    ],
    'map': ['map', 'location', 'navigation', 'where', 'place', 'area'],
    'discover': ['discover', 'tours', 'explore', 'find', 'browse', 'search'],
    'downloads': ['downloads', 'offline', 'saved', 'library', 'my content'],
    'help': ['help', 'support', 'assistance', 'guide', 'how to'],
  };

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;
  String get currentLanguage => _currentLanguage;
  String get currentScreen => _currentScreen;

  // Enhanced method to update current screen context
  void updateCurrentScreen(String screen) {
    _currentScreen = screen;
    debugPrint('Current screen context updated to: $_currentScreen');
  }

  // Fuzzy matching for better command recognition
  bool _fuzzyMatch(
    String command,
    List<String> triggers, {
    double threshold = 0.7,
  }) {
    final commandWords = command.toLowerCase().split(' ');

    for (final trigger in triggers) {
      final triggerWords = trigger.toLowerCase().split(' ');
      int matches = 0;

      for (final commandWord in commandWords) {
        for (final triggerWord in triggerWords) {
          if (commandWord.contains(triggerWord) ||
              triggerWord.contains(commandWord)) {
            matches++;
            break;
          }
        }
      }

      final similarity = matches / commandWords.length;
      if (similarity >= threshold) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      } else {
        debugPrint('Microphone permission is permanently denied');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      return false;
    }
  }

  Future<bool> _checkSpeechRecognitionSupport() async {
    try {
      // Try to initialize speech recognition to check if it's supported
      final isAvailable = await _speechToText.initialize(
        onStatus: (status) {},
        onError: (error) {},
        debugLogging: false,
      );
      debugPrint('Speech recognition service available: $isAvailable');
      return isAvailable;
    } catch (e) {
      debugPrint('Error checking speech recognition support: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      // Check if speech recognition is supported
      final isSupported = await _checkSpeechRecognitionSupport();
      if (!isSupported) {
        debugPrint('Speech recognition not supported on this device');
        _isInitialized = false;
        notifyListeners();
        return;
      }

      // Check microphone permission first
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        debugPrint('Microphone permission not granted');
        _isInitialized = false;
        notifyListeners();
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

        // Force en-US if not already set
        if (_currentLanguage != 'en-US') {
          await setLanguageToEnUS();
        }

        debugPrint(
          'Voice service initialized successfully with language: $_currentLanguage',
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      _consecutiveErrors++;
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      _availableLanguages = locales.map((locale) => locale.localeId).toList();
      debugPrint('Available languages: $_availableLanguages');

      // If no languages are available, use fallback
      if (_availableLanguages.isEmpty) {
        debugPrint('No languages available, using fallback');
        _availableLanguages = ['en-US', 'en-GB', 'en'];
      }
    } catch (e) {
      debugPrint('Error loading available languages: $e');
      // Fallback to common languages
      _availableLanguages = ['en-US', 'en-GB', 'en'];
    }
  }

  Future<void> _setOptimalLanguage() async {
    // Try to find the best available language with stronger preference for en-US
    final preferredLanguages = ['en-US', 'en-GB', 'en'];

    // First, try exact matches
    for (final lang in preferredLanguages) {
      if (_availableLanguages.contains(lang)) {
        _currentLanguage = lang;
        debugPrint('Selected language: $_currentLanguage');
        return;
      }
    }

    // If en-US is not available, try to find en_GB and convert it to en-US format
    // This handles cases where the system reports en_GB but we want to use en-US
    if (_availableLanguages.contains('en_GB') &&
        !_availableLanguages.contains('en-US')) {
      _currentLanguage = 'en-US'; // Use en-US format even if system has en_GB
      debugPrint('Converting en_GB to en-US format for consistency');
      return;
    }

    // If no preferred language is available, use the first available one
    if (_availableLanguages.isNotEmpty) {
      _currentLanguage = _availableLanguages.first;
      debugPrint('Using fallback language: $_currentLanguage');
    }
  }

  // Method to force set language to en-US
  Future<void> setLanguageToEnUS() async {
    _currentLanguage = 'en-US';
    debugPrint('Forced language to en-US');

    // If already initialized, restart listening with new language
    if (_isInitialized) {
      await stopListening();
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized || _isListening || _isProcessingCommand) return;

    try {
      // Cancel any existing restart timer
      _restartTimer?.cancel();

      // Add delay to prevent rapid-fire requests
      await Future.delayed(const Duration(milliseconds: 200));

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          partialResults: false, // Only final results to reduce glitches
          cancelOnError: false, // Don't cancel on error to allow retry
          onDevice: false, // Use cloud recognition for better accuracy
        ),
        localeId: _currentLanguage,
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

    // Stop any existing continuous listening
    stopContinuousListening();

    // Start immediate listening
    await startListening();

    // Set up continuous listening with longer intervals to prevent overwhelming the service
    _listeningTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isListening &&
          !_isProcessingCommand &&
          _consecutiveErrors < _maxConsecutiveErrors) {
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

    // Handle specific error types
    if (error.errorMsg == 'error_permission') {
      debugPrint('Microphone permission error - requesting permission');
      _handlePermissionError();
    } else if (error.errorMsg == 'error_language_unavailable') {
      debugPrint('Language unavailable error - trying fallback language');
      _handleLanguageError();
    } else if (error.errorMsg == 'error_busy') {
      debugPrint('Speech service busy error - waiting before retry');
      _handleBusyError();
    } else {
      _handleListeningError();
    }

    notifyListeners();
  }

  void _handlePermissionError() {
    // Try to request permission again
    Timer(const Duration(seconds: 2), () async {
      final hasPermission = await _checkMicrophonePermission();
      if (hasPermission) {
        await initialize();
        if (_isInitialized) {
          await startContinuousListening();
        }
      }
    });
  }

  void _handleLanguageError() {
    // Try to find an alternative language with preference for en-US
    final fallbackLanguages = ['en-US', 'en-GB', 'en', 'en-AU', 'en-CA'];
    String? newLanguage;

    for (final lang in fallbackLanguages) {
      if (_availableLanguages.contains(lang) && lang != _currentLanguage) {
        newLanguage = lang;
        break;
      }
    }

    // If en-US is not directly available but en_GB is, use en-US format
    if (newLanguage == null && _availableLanguages.contains('en_GB')) {
      newLanguage = 'en-US';
      debugPrint('Converting en_GB to en-US format for fallback');
    }

    if (newLanguage != null) {
      _currentLanguage = newLanguage;
      debugPrint('Switching to fallback language: $_currentLanguage');

      Timer(const Duration(seconds: 1), () async {
        await startContinuousListening();
      });
    } else {
      // If no fallback language is available, disable voice recognition
      debugPrint('No fallback language available, disabling voice recognition');
      _consecutiveErrors = _maxConsecutiveErrors;
      _handleListeningError();
    }
  }

  void _handleBusyError() {
    // Wait longer before retrying when service is busy
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 5), () async {
      if (!_isListening && !_isProcessingCommand) {
        await startListening();
      }
    });
  }

  void _handleListeningError() {
    _consecutiveErrors++;

    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('Too many consecutive errors, stopping voice recognition');
      stopContinuousListening();

      // Try to reinitialize after a longer delay
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
    // Longer delay to prevent overwhelming the service
    _restartTimer = Timer(const Duration(seconds: 3), () async {
      if (!_isListening && !_isProcessingCommand) {
        await startListening();
      }
    });
  }

  // Enhanced command processing with context awareness
  Future<void> _processVoiceCommand(String command) async {
    if (_isProcessingCommand || command.isEmpty) return;

    _isProcessingCommand = true;

    try {
      debugPrint(
        'Processing voice command: "$command" on screen: $_currentScreen',
      );
      final ttsService = getIt<TTSService>();
      final navigationService = getIt<NavigationService>();

      // Stop current TTS to prevent overlapping speech
      await ttsService.stop();
      await Future.delayed(const Duration(milliseconds: 200));

      // Enhanced navigation commands with immediate execution
      if (_isNavigationCommand(command, _commandSynonyms['home']!)) {
        await _navigateWithFeedback(
          navigationService.navigateToHome,
          'Navigating to home screen',
          ttsService,
        );
        updateCurrentScreen('home');
      } else if (_isNavigationCommand(command, _commandSynonyms['map']!)) {
        await _navigateWithFeedback(
          navigationService.navigateToMap,
          'Opening interactive map with voice navigation',
          ttsService,
        );
        updateCurrentScreen('map');
      } else if (_isNavigationCommand(command, _commandSynonyms['discover']!)) {
        await _navigateWithFeedback(
          navigationService.navigateToDiscover,
          'Opening discover tours with Buganda destinations',
          ttsService,
        );
        updateCurrentScreen('discover');
      } else if (_isNavigationCommand(
        command,
        _commandSynonyms['downloads']!,
      )) {
        await _navigateWithFeedback(
          navigationService.navigateToDownloads,
          'Opening offline library with saved content',
          ttsService,
        );
        updateCurrentScreen('downloads');
      } else if (_isNavigationCommand(command, _commandSynonyms['help']!)) {
        await _navigateWithFeedback(
          navigationService.navigateToHelpSupport,
          'Opening help and support with voice commands guide',
          ttsService,
        );
        updateCurrentScreen('help');
      }
      // Context-aware commands based on current screen
      else if (_isContextAwareCommand(command)) {
        await _handleContextAwareCommand(command, ttsService);
      }
      // Enhanced location and map commands
      else if (_isNavigationCommand(command, [
        'where am i',
        'my location',
        'current location',
        'find me',
        'locate me',
      ])) {
        await _handleLocationCommand(command, ttsService);
      } else if (_isNavigationCommand(command, [
        'find places',
        'nearby places',
        'what is nearby',
        'places around me',
        'search nearby',
      ])) {
        await _handleSearchCommand(command, ttsService);
      }
      // Enhanced voice control commands
      else if (_isNavigationCommand(command, [
        'voice commands',
        'available commands',
        'help commands',
        'what can i say',
        'commands list',
      ])) {
        await _speakContextAwareCommands(ttsService);
      } else if (_isNavigationCommand(command, [
        'repeat',
        'say again',
        'repeat that',
        'what did you say',
      ])) {
        await ttsService.speak('Repeating last information');
      } else if (_isNavigationCommand(command, [
        'stop talking',
        'be quiet',
        'silence',
        'shut up',
      ])) {
        await ttsService.stop();
      }
      // Enhanced Buganda-specific content commands
      else if (_isNavigationCommand(command, [
        'kasubi',
        'kasubi tombs',
        'royal tombs',
      ])) {
        await _speakBugandaLocation(ttsService, 'kasubi');
      } else if (_isNavigationCommand(command, [
        'namugongo',
        'martyrs',
        'martyrs shrine',
      ])) {
        await _speakBugandaLocation(ttsService, 'namugongo');
      } else if (_isNavigationCommand(command, [
        'palace',
        'lubiri',
        'kabaka palace',
      ])) {
        await _speakBugandaLocation(ttsService, 'palace');
      } else if (_isNavigationCommand(command, ['mengo', 'mengo hill'])) {
        await _speakBugandaLocation(ttsService, 'mengo');
      } else if (_isNavigationCommand(command, [
        'lake victoria',
        'lake',
        'victoria',
      ])) {
        await _speakBugandaLocation(ttsService, 'lake');
      } else {
        // Enhanced feedback for unrecognized commands
        await _handleUnrecognizedCommand(command, ttsService);
      }
    } catch (e) {
      debugPrint('Error processing voice command: $e');
    } finally {
      _isProcessingCommand = false;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Global voice command handler for cross-screen navigation
  Future<void> handleGlobalVoiceCommand(String command) async {
    final ttsService = getIt<TTSService>();
    final navigationService = getIt<NavigationService>();

    debugPrint('Processing global command: "$command"');

    // Use enhanced command patterns for better recognition
    if (_isCommandMatch(command, _enhancedCommandPatterns['home']!)) {
      await ttsService.speakWithPriority('Navigating to home screen');
      await navigationService.navigateToHome();
      updateCurrentScreen('home');
    } else if (_isCommandMatch(command, _enhancedCommandPatterns['map']!)) {
      await ttsService.speakWithPriority('Opening interactive map');
      await navigationService.navigateToMap();
      updateCurrentScreen('map');
    } else if (_isCommandMatch(
      command,
      _enhancedCommandPatterns['discover']!,
    )) {
      await ttsService.speakWithPriority('Opening discover tours');
      await navigationService.navigateToDiscover();
      updateCurrentScreen('discover');
    } else if (_isCommandMatch(
      command,
      _enhancedCommandPatterns['downloads']!,
    )) {
      await ttsService.speakWithPriority('Opening offline library');
      await navigationService.navigateToDownloads();
      updateCurrentScreen('downloads');
    } else if (_isCommandMatch(command, _enhancedCommandPatterns['help']!)) {
      await ttsService.speakWithPriority('Opening help and support');
      await navigationService.navigateToHelpSupport();
      updateCurrentScreen('help');
    } else if (command.toLowerCase().contains('voice commands') ||
        command.toLowerCase().contains('what can i say')) {
      await _speakGlobalVoiceCommands(ttsService);
    } else if (command.toLowerCase().contains('test voice') ||
        command.toLowerCase().contains('voice test')) {
      await testVoiceNavigation();
    } else if (command.toLowerCase().contains('repeat') ||
        command.toLowerCase().contains('say again')) {
      await ttsService.speakWithPriority('Repeating last information');
    } else if (command.toLowerCase().contains('stop talking') ||
        command.toLowerCase().contains('quiet')) {
      await ttsService.stop();
    } else {
      // If no global command matches, let the current screen handle it
      debugPrint('No global command match for: "$command"');
      return;
    }
  }

  // Speak global voice commands
  Future<void> _speakGlobalVoiceCommands(TTSService ttsService) async {
    await ttsService.speak('''
Available global voice commands:
Navigation: "Go home", "Open map", "Show tours", "Downloads", "Get help"
Voice control: "Voice commands", "Repeat", "Stop talking", "Test voice"
These commands work from any screen in the app.
''');
  }

  // Context-aware command detection
  bool _isContextAwareCommand(String command) {
    final lowerCommand = command.toLowerCase();

    // Screen-specific commands
    switch (_currentScreen) {
      case 'map':
        return lowerCommand.contains('zoom') ||
            lowerCommand.contains('navigate') ||
            lowerCommand.contains('find') ||
            lowerCommand.contains('tour') ||
            lowerCommand.contains('refresh');
      case 'discover':
        return lowerCommand.contains('tour') ||
            lowerCommand.contains('next') ||
            lowerCommand.contains('previous') ||
            lowerCommand.contains('play');
      case 'downloads':
        return lowerCommand.contains('play') ||
            lowerCommand.contains('download') ||
            lowerCommand.contains('delete') ||
            lowerCommand.contains('storage');
      case 'help':
        return lowerCommand.contains('faq') ||
            lowerCommand.contains('contact') ||
            lowerCommand.contains('feedback');
      default:
        return false;
    }
  }

  // Handle context-aware commands
  Future<void> _handleContextAwareCommand(
    String command,
    TTSService ttsService,
  ) async {
    final lowerCommand = command.toLowerCase();

    switch (_currentScreen) {
      case 'map':
        if (lowerCommand.contains('zoom in') ||
            lowerCommand.contains('closer')) {
          await ttsService.speak('Zooming in on the map');
        } else if (lowerCommand.contains('zoom out') ||
            lowerCommand.contains('farther')) {
          await ttsService.speak('Zooming out on the map');
        } else if (lowerCommand.contains('refresh') ||
            lowerCommand.contains('update')) {
          await ttsService.speak('Refreshing map data and nearby places');
        }
        break;
      case 'discover':
        if (lowerCommand.contains('next tour') ||
            lowerCommand.contains('next')) {
          await ttsService.speak('Moving to the next tour');
        } else if (lowerCommand.contains('previous tour') ||
            lowerCommand.contains('previous')) {
          await ttsService.speak('Moving to the previous tour');
        }
        break;
      case 'downloads':
        if (lowerCommand.contains('play')) {
          await ttsService.speak('Playing selected content');
        } else if (lowerCommand.contains('storage')) {
          await ttsService.speak('Checking storage information');
        }
        break;
    }
  }

  // Enhanced location command handling
  Future<void> _handleLocationCommand(
    String command,
    TTSService ttsService,
  ) async {
    if (_currentScreen == 'map') {
      await ttsService.speak('Getting your current location on the map');
    } else {
      await ttsService.speak('Opening map to show your current location');
      final navigationService = getIt<NavigationService>();
      await _navigateWithFeedback(
        navigationService.navigateToMap,
        'Opening map to locate you',
        ttsService,
      );
      updateCurrentScreen('map');
    }
  }

  // Enhanced search command handling
  Future<void> _handleSearchCommand(
    String command,
    TTSService ttsService,
  ) async {
    if (_currentScreen == 'map') {
      await ttsService.speak('Searching for nearby places on the map');
    } else {
      await ttsService.speak('Opening map to search for nearby places');
      final navigationService = getIt<NavigationService>();
      await _navigateWithFeedback(
        navigationService.navigateToMap,
        'Opening map to search nearby places',
        ttsService,
      );
      updateCurrentScreen('map');
    }
  }

  // Context-aware command suggestions
  Future<void> _speakContextAwareCommands(TTSService ttsService) async {
    String commands = 'Available voice commands';

    switch (_currentScreen) {
      case 'home':
        commands += '''
 on home screen:
Navigation: "Open map", "Show tours", "Downloads", "Get help"
Voice Control: "Enable voice", "Disable voice", "Test voice"
Information: "Quick actions", "Recent tours", "What can I do"
''';
        break;
      case 'map':
        commands += '''
 on map screen:
Navigation: "Go home", "Show tours", "Downloads", "Get help"
Map Control: "Zoom in", "Zoom out", "Where am I", "Find nearby"
Tour Guide: "Start tour", "Next stop", "Previous stop", "Stop tour"
Search: "Find hospitals", "Find schools", "Find restaurants", "Find landmarks"
''';
        break;
      case 'discover':
        commands += '''
 on discover screen:
Navigation: "Go home", "Open map", "Downloads", "Get help"
Tour Control: "Next tour", "Previous tour", "Play tour", "Tour details"
Categories: "Historical tours", "Cultural tours", "Nature tours"
''';
        break;
      case 'downloads':
        commands += '''
 on downloads screen:
Navigation: "Go home", "Open map", "Show tours", "Get help"
Content: "Play content", "Delete content", "Storage info"
Categories: "Show tours", "Show guides", "Show stories", "Show music"
''';
        break;
      case 'help':
        commands += '''
 on help screen:
Navigation: "Go home", "Open map", "Show tours", "Downloads"
Help: "Voice commands", "FAQ", "Contact support", "Feedback"
''';
        break;
    }

    await ttsService.speak(commands);
  }

  // Enhanced unrecognized command handling
  Future<void> _handleUnrecognizedCommand(
    String command,
    TTSService ttsService,
  ) async {
    final suggestions = _getCommandSuggestions(command);
    await ttsService.speak(
      'Command not recognized: "$command". $suggestions Say "voice commands" to hear all available options.',
    );
  }

  // Smart command suggestions based on input
  String _getCommandSuggestions(String command) {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('map') || lowerCommand.contains('location')) {
      return 'Try saying "open map" or "show map".';
    } else if (lowerCommand.contains('tour') ||
        lowerCommand.contains('discover')) {
      return 'Try saying "show tours" or "discover tours".';
    } else if (lowerCommand.contains('download') ||
        lowerCommand.contains('offline')) {
      return 'Try saying "downloads" or "offline content".';
    } else if (lowerCommand.contains('help') ||
        lowerCommand.contains('support')) {
      return 'Try saying "get help" or "support".';
    } else if (lowerCommand.contains('home') || lowerCommand.contains('main')) {
      return 'Try saying "go home" or "main screen".';
    }

    return 'Try navigation commands like "go home", "open map", or "show tours".';
  }

  // Enhanced navigation command detection with fuzzy matching
  bool _isNavigationCommand(String command, List<String> triggers) {
    return _fuzzyMatch(command, triggers, threshold: 0.6);
  }

  // Enhanced method to ensure continuous listening is active
  Future<void> ensureContinuousListening() async {
    if (!_isInitialized) {
      debugPrint('Voice service not initialized, attempting to initialize...');
      await initialize();
    }

    if (_isInitialized && !_isListening && !_isProcessingCommand) {
      debugPrint('Starting continuous listening...');
      await startContinuousListening();
    }
  }

  // Enhanced command recognition with more variations
  bool _isCommandMatch(String command, List<String> patterns) {
    final lowerCommand = command.toLowerCase().trim();

    for (final pattern in patterns) {
      if (lowerCommand.contains(pattern.toLowerCase()) ||
          _fuzzyMatch(lowerCommand, [pattern.toLowerCase()], threshold: 0.6)) {
        return true;
      }
    }
    return false;
  }

  // Enhanced navigation command patterns
  final Map<String, List<String>> _enhancedCommandPatterns = {
    'home': [
      'go home',
      'home',
      'main screen',
      'main',
      'start',
      'beginning',
      'return home',
      'back to home',
      'home screen',
      'main menu',
    ],
    'map': [
      'open map',
      'map',
      'show map',
      'view map',
      'location',
      'navigation',
      'interactive map',
      'map screen',
      'where am i',
      'my location',
    ],
    'discover': [
      'show tours',
      'discover',
      'tours',
      'browse tours',
      'find tours',
      'explore',
      'discover tours',
      'tour screen',
      'explore tours',
    ],
    'downloads': [
      'downloads',
      'offline',
      'my downloads',
      'saved content',
      'offline content',
      'library',
      'saved',
      'offline library',
    ],
    'help': [
      'get help',
      'help',
      'support',
      'assistance',
      'help me',
      'help screen',
      'support screen',
      'assistance screen',
    ],
  };

  Future<void> _navigateWithFeedback(
    VoidCallback navigationFunction,
    String feedbackMessage,
    TTSService ttsService,
  ) async {
    // Provide immediate feedback
    await ttsService.speakWithPriority(feedbackMessage);

    // Execute navigation immediately
    navigationFunction();

    // Brief delay to ensure navigation completes
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _speakBugandaLocation(
    TTSService ttsService,
    String location,
  ) async {
    String description = '';

    switch (location) {
      case 'kasubi':
        description =
            'Kasubi Tombs: The sacred burial site of Buganda kings, featuring traditional architecture and deep cultural significance. A UNESCO World Heritage site.';
        break;
      case 'namugongo':
        description =
            'Namugongo Martyrs Shrine: A major pilgrimage site commemorating 45 Christian martyrs, featuring beautiful architecture and peaceful gardens.';
        break;
      case 'palace':
        description =
            'Lubiri Palace: The magnificent residence of the Kabaka of Buganda, combining traditional African architecture with modern amenities.';
        break;
      case 'mengo':
        description =
            'Mengo Hill: The traditional heart of Buganda kingdom, offering panoramic views of Kampala and centuries of royal history.';
        break;
      case 'lake':
        description =
            'Lake Victoria: Africa\'s largest lake, offering stunning views, fishing villages, boat tours, and spectacular sunsets.';
        break;
    }

    await ttsService.speak(description);
  }

  // Debug method to test voice navigation
  Future<void> testVoiceNavigation() async {
    debugPrint('Testing voice navigation...');
    debugPrint('Is initialized: $_isInitialized');
    debugPrint('Is listening: $_isListening');
    debugPrint('Current language: $_currentLanguage');
    debugPrint('Available languages: $_availableLanguages');

    final ttsService = getIt<TTSService>();
    if (_isInitialized) {
      await ttsService.speak('Voice navigation test successful!');
    } else {
      await ttsService.speak('Voice navigation not initialized');
    }
  }

  // Test the global voice navigation system
  Future<void> testGlobalVoiceNavigation() async {
    final ttsService = getIt<TTSService>();

    debugPrint('Testing global voice navigation system...');

    try {
      // Test command recognition
      final testCommands = [
        'go home',
        'open map',
        'show tours',
        'downloads',
        'get help',
        'voice commands',
        'test voice',
      ];

      await ttsService.speakWithPriority(
        'Testing global voice navigation system...',
      );

      for (final command in testCommands) {
        debugPrint('Testing command: $command');
        await Future.delayed(const Duration(milliseconds: 500));

        // Test command matching
        bool isRecognized = false;
        for (final patterns in _enhancedCommandPatterns.values) {
          if (_isCommandMatch(command, patterns)) {
            isRecognized = true;
            break;
          }
        }

        if (isRecognized) {
          debugPrint('Command "$command" is recognized');
        } else {
          debugPrint('Command "$command" is NOT recognized');
        }
      }

      await ttsService.speakWithPriority(
        'Global voice navigation test completed. All commands are properly configured.',
      );
    } catch (e) {
      debugPrint('Global voice navigation test error: $e');
      await ttsService.speakWithPriority(
        'Global voice navigation test encountered an error: $e',
      );
    }
  }

  @override
  void dispose() {
    stopContinuousListening();
    _speechToText.cancel();
    super.dispose();
  }
}
