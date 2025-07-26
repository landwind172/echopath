import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../services/dependency_injection.dart';

class VoiceNavigationProvider extends ChangeNotifier {
  final VoiceService _voiceService = getIt<VoiceService>();
  final TTSService _ttsService = getIt<TTSService>();

  bool _isVoiceNavigationEnabled = true;
  bool _isListening = false;
  String _lastCommand = '';
  final List<String> _commandHistory = [];
  bool _isInitializing = false;

  bool get isVoiceNavigationEnabled => _isVoiceNavigationEnabled;
  bool get isListening => _isListening;
  String get lastCommand => _lastCommand;
  List<String> get commandHistory => _commandHistory;
  bool get isInitializing => _isInitializing;
  String get currentLanguage => _voiceService.currentLanguage;

  VoiceNavigationProvider() {
    _voiceService.addListener(_onVoiceServiceChanged);
    _initializeVoiceNavigation();
  }

  Future<void> _initializeVoiceNavigation() async {
    if (_isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      // Ensure voice service is properly initialized with retry logic
      int retryCount = 0;
      const maxRetries = 3;

      while (!_voiceService.isInitialized && retryCount < maxRetries) {
        try {
          await _voiceService.initialize();
          retryCount++;

          if (!_voiceService.isInitialized) {
            debugPrint(
              'Voice service initialization attempt $retryCount failed, retrying...',
            );
            await Future.delayed(
              Duration(seconds: retryCount * 2),
            ); // Exponential backoff
          }
        } catch (e) {
          debugPrint(
            'Voice service initialization error (attempt $retryCount): $e',
          );
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      if (_voiceService.isInitialized && _isVoiceNavigationEnabled) {
        await _voiceService.startContinuousListening();
        debugPrint('Voice navigation initialized successfully');
      } else {
        debugPrint(
          'Voice navigation initialization failed after $maxRetries attempts',
        );
        // Disable voice navigation if initialization fails
        _isVoiceNavigationEnabled = false;
        await _ttsService.speakWithPriority(
          'Voice navigation could not be initialized. Please check your microphone permissions and try again.',
        );
      }
    } catch (e) {
      debugPrint('Voice navigation initialization error: $e');
      _isVoiceNavigationEnabled = false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _onVoiceServiceChanged() {
    final wasListening = _isListening;
    _isListening = _voiceService.isListening;

    if (_voiceService.lastWords.isNotEmpty &&
        _voiceService.lastWords != _lastCommand) {
      _lastCommand = _voiceService.lastWords;
      _addToCommandHistory(_lastCommand);

      // Handle global voice commands
      _handleGlobalCommand(_lastCommand);
    }

    // Only notify if listening state actually changed to reduce unnecessary rebuilds
    if (wasListening != _isListening) {
      notifyListeners();
    }
  }

  // Handle global voice commands that work from any screen
  Future<void> _handleGlobalCommand(String command) async {
    try {
      debugPrint('Handling global command: "$command"');

      // First try to handle as a global command
      await _voiceService.handleGlobalVoiceCommand(command);

      debugPrint('Global command processed: "$command"');
    } catch (e) {
      debugPrint('Global command handling error: $e');
      await _ttsService.speakWithPriority(
        'Voice command processing encountered an error. Please try again.',
      );
    }
  }

  // Update current screen context for voice service
  void updateCurrentScreen(String screenName) {
    _voiceService.updateCurrentScreen(screenName);
    debugPrint('Updated voice service screen context to: $screenName');
  }

  void _addToCommandHistory(String command) {
    if (command.trim().isEmpty) return;

    _commandHistory.insert(0, command);
    if (_commandHistory.length > 10) {
      _commandHistory.removeLast();
    }
  }

  Future<void> toggleVoiceNavigation() async {
    _isVoiceNavigationEnabled = !_isVoiceNavigationEnabled;

    try {
      if (_isVoiceNavigationEnabled) {
        // Try to initialize if not already initialized
        if (!_voiceService.isInitialized) {
          await _voiceService.initialize();
        }

        if (_voiceService.isInitialized) {
          await _voiceService.startContinuousListening();
          await _ttsService.speakWithPriority('Voice navigation enabled');
        } else {
          // If initialization fails, disable voice navigation
          _isVoiceNavigationEnabled = false;
          await _ttsService.speakWithPriority(
            'Voice navigation could not be enabled. Please check microphone permissions and try again.',
          );
        }
      } else {
        _voiceService.stopContinuousListening();
        await _ttsService.speakWithPriority('Voice navigation disabled');
      }
    } catch (e) {
      debugPrint('Toggle voice navigation error: $e');
      // If there was an error, disable voice navigation for safety
      _isVoiceNavigationEnabled = false;
      await _ttsService.speakWithPriority(
        'Voice navigation encountered an error and has been disabled. Please try again later.',
      );
    }

    notifyListeners();
  }

  Future<void> startListening() async {
    if (_isVoiceNavigationEnabled && !_isListening) {
      await _voiceService.startListening();
    }
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  Future<void> speakFeedback(String message) async {
    await _ttsService.speak(message);
  }

  Future<void> speakFeedbackWithPriority(String message) async {
    await _ttsService.speakWithPriority(message);
  }

  Future<void> setLanguageToEnUS() async {
    try {
      await _voiceService.setLanguageToEnUS();
      debugPrint('Language set to en-US successfully');
      await _ttsService.speakWithPriority(
        'Voice navigation language set to US English',
      );
    } catch (e) {
      debugPrint('Error setting language to en-US: $e');
    }
  }

  void clearCommandHistory() {
    _commandHistory.clear();
    notifyListeners();
  }

  void clearLastCommand() {
    _lastCommand = '';
    // Don't notify listeners for this change to reduce rebuilds
  }

  Future<void> restartVoiceNavigation() async {
    if (!_isVoiceNavigationEnabled) return;

    try {
      debugPrint('Restarting voice navigation...');
      _voiceService.stopContinuousListening();
      await Future.delayed(const Duration(milliseconds: 500));

      // Reinitialize the voice service
      if (!_voiceService.isInitialized) {
        await _voiceService.initialize();
      }

      if (_voiceService.isInitialized) {
        await _voiceService.startContinuousListening();
        debugPrint('Voice navigation restarted successfully');
        await _ttsService.speakWithPriority('Voice navigation restarted');
      } else {
        debugPrint(
          'Failed to restart voice navigation - service not initialized',
        );
        _isVoiceNavigationEnabled = false;
        await _ttsService.speakWithPriority(
          'Voice navigation could not be restarted. Please check microphone permissions.',
        );
      }
    } catch (e) {
      debugPrint('Restart voice navigation error: $e');
      _isVoiceNavigationEnabled = false;
      await _ttsService.speakWithPriority(
        'Voice navigation restart failed. Please try again later.',
      );
    }

    notifyListeners();
  }

  Future<void> forceRestartVoiceNavigation() async {
    debugPrint('Force restarting voice navigation...');
    _isVoiceNavigationEnabled = true;
    _voiceService.stopContinuousListening();

    // Wait longer for a complete reset
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Force reinitialize
      await _voiceService.initialize();

      if (_voiceService.isInitialized) {
        // Force en-US language
        await _voiceService.setLanguageToEnUS();
        await _voiceService.startContinuousListening();
        debugPrint('Voice navigation force restarted successfully with en-US');
        await _ttsService.speakWithPriority(
          'Voice navigation has been reset and is now active with US English',
        );
      } else {
        _isVoiceNavigationEnabled = false;
        await _ttsService.speakWithPriority(
          'Voice navigation reset failed. Please check your device settings.',
        );
      }
    } catch (e) {
      debugPrint('Force restart voice navigation error: $e');
      _isVoiceNavigationEnabled = false;
      await _ttsService.speakWithPriority(
        'Voice navigation reset encountered an error. Please try again.',
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChanged);
    super.dispose();
  }
}
