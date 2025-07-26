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
      debugPrint('Voice navigation: Initializing...');
      
      // Initialize voice service with retry logic
      int retryCount = 0;
      const maxRetries = 3;

      while (!_voiceService.isInitialized && retryCount < maxRetries) {
        try {
          await _voiceService.initialize();
          if (_voiceService.isInitialized) {
            debugPrint('Voice navigation: Initialization successful');
            break;
          }
          retryCount++;
          if (retryCount < maxRetries) {
            debugPrint('Voice navigation: Retry $retryCount...');
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        } catch (e) {
          debugPrint('Voice navigation: Initialization error (attempt $retryCount): $e');
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      if (_voiceService.isInitialized && _isVoiceNavigationEnabled) {
        await _voiceService.startContinuousListening();
        debugPrint('Voice navigation: Started continuous listening');
        await _ttsService.speakWithPriority(
          'Voice navigation is now active and ready for commands.'
        );
      } else {
        debugPrint('Voice navigation: Failed to initialize after $maxRetries attempts');
        _isVoiceNavigationEnabled = false;
        await _ttsService.speakWithPriority(
          'Voice navigation could not be initialized. Please check microphone permissions.'
        );
      }
    } catch (e) {
      debugPrint('Voice navigation: Initialization error: $e');
      _isVoiceNavigationEnabled = false;
      await _ttsService.speakWithPriority(
        'Voice navigation initialization failed. Please try again later.'
      );
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _onVoiceServiceChanged() {
    final wasListening = _isListening;
    _isListening = _voiceService.isListening;

    if (_voiceService.lastWords.isNotEmpty && _voiceService.lastWords != _lastCommand) {
      _lastCommand = _voiceService.lastWords;
      _addToCommandHistory(_lastCommand);
      debugPrint('Voice navigation: New command received: "$_lastCommand"');
    }

    // Only notify if listening state changed
    if (wasListening != _isListening) {
      notifyListeners();
    }
  }

  void updateCurrentScreen(String screenName) {
    _voiceService.updateCurrentScreen(screenName);
    debugPrint('Voice navigation: Updated screen context to $screenName');
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
    debugPrint('Voice navigation: Toggled to ${_isVoiceNavigationEnabled ? "enabled" : "disabled"}');

    try {
      if (_isVoiceNavigationEnabled) {
        if (!_voiceService.isInitialized) {
          await _voiceService.initialize();
        }

        if (_voiceService.isInitialized) {
          await _voiceService.startContinuousListening();
          await _ttsService.speakWithPriority('Voice navigation enabled and ready');
        } else {
          _isVoiceNavigationEnabled = false;
          await _ttsService.speakWithPriority(
            'Voice navigation could not be enabled. Please check microphone permissions.'
          );
        }
      } else {
        _voiceService.stopContinuousListening();
        await _ttsService.speakWithPriority('Voice navigation disabled');
      }
    } catch (e) {
      debugPrint('Voice navigation: Toggle error: $e');
      _isVoiceNavigationEnabled = false;
      await _ttsService.speakWithPriority(
        'Voice navigation encountered an error and has been disabled.'
      );
    }

    notifyListeners();
  }

  Future<void> restartVoiceNavigation() async {
    if (!_isVoiceNavigationEnabled) return;

    try {
      debugPrint('Voice navigation: Restarting...');
      _voiceService.stopContinuousListening();
      await Future.delayed(const Duration(milliseconds: 500));

      if (!_voiceService.isInitialized) {
        await _voiceService.initialize();
      }

      if (_voiceService.isInitialized) {
        await _voiceService.startContinuousListening();
        debugPrint('Voice navigation: Restart successful');
        await _ttsService.speakWithPriority('Voice navigation restarted successfully');
      } else {
        _isVoiceNavigationEnabled = false;
        await _ttsService.speakWithPriority(
          'Voice navigation restart failed. Please check device settings.'
        );
      }
    } catch (e) {
      debugPrint('Voice navigation: Restart error: $e');
      _isVoiceNavigationEnabled = false;
      await _ttsService.speakWithPriority(
        'Voice navigation restart failed. Please try again.'
      );
    }

    notifyListeners();
  }

  Future<void> forceRestartVoiceNavigation() async {
    debugPrint('Voice navigation: Force restarting...');
    _isVoiceNavigationEnabled = true;
    _voiceService.stopContinuousListening();

    await Future.delayed(const Duration(seconds: 1));

    try {
      await _voiceService.initialize();

      if (_voiceService.isInitialized) {
        await _voiceService.setLanguageToEnUS();
        await _voiceService.startContinuousListening();
        debugPrint('Voice navigation: Force restart successful');
        await _ttsService.speakWithPriority(
          'Voice navigation has been reset and is now active with enhanced global commands'
        );
      } else {
        _isVoiceNavigationEnabled = false;
        await _ttsService.speakWithPriority(
          'Voice navigation reset failed. Please check your device settings.'
        );
      }
    } catch (e) {
      debugPrint('Voice navigation: Force restart error: $e');
      _isVoiceNavigationEnabled = false;
      await _ttsService.speakWithPriority(
        'Voice navigation reset encountered an error. Please try again.'
      );
    }

    notifyListeners();
  }

  Future<void> speakFeedback(String message) async {
    await _ttsService.speak(message);
  }

  Future<void> speakFeedbackWithPriority(String message) async {
    await _ttsService.speakWithPriority(message);
  }

  void clearCommandHistory() {
    _commandHistory.clear();
    notifyListeners();
  }

  void clearLastCommand() {
    _lastCommand = '';
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChanged);
    super.dispose();
  }
}