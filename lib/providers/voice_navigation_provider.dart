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

  VoiceNavigationProvider() {
    _voiceService.addListener(_onVoiceServiceChanged);
    _initializeVoiceNavigation();
  }

  Future<void> _initializeVoiceNavigation() async {
    if (_isInitializing) return;
    
    _isInitializing = true;
    notifyListeners();
    
    try {
      // Ensure voice service is properly initialized
      if (!_voiceService.isInitialized) {
        await _voiceService.initialize();
      }
      
      if (_isVoiceNavigationEnabled && _voiceService.isInitialized) {
        await _voiceService.startContinuousListening();
      }
    } catch (e) {
      debugPrint('Voice navigation initialization error: $e');
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
    }
    
    // Only notify if listening state actually changed to reduce unnecessary rebuilds
    if (wasListening != _isListening) {
      notifyListeners();
    }
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
        if (!_voiceService.isInitialized) {
          await _voiceService.initialize();
        }
        if (_voiceService.isInitialized) {
          await _voiceService.startContinuousListening();
        }
        await _ttsService.speakWithPriority('Voice navigation enabled');
      } else {
        _voiceService.stopContinuousListening();
        await _ttsService.speakWithPriority('Voice navigation disabled');
      }
    } catch (e) {
      debugPrint('Toggle voice navigation error: $e');
      // Retry initialization if there was an error
      if (_isVoiceNavigationEnabled) {
        await Future.delayed(const Duration(seconds: 1));
        await restartVoiceNavigation();
      }
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
      _voiceService.stopContinuousListening();
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!_voiceService.isInitialized) {
        await _voiceService.initialize();
      }
      
      if (_voiceService.isInitialized) {
        await _voiceService.startContinuousListening();
        debugPrint('Voice navigation restarted successfully');
      } else {
        debugPrint('Failed to restart voice navigation - service not initialized');
      }
    } catch (e) {
      debugPrint('Restart voice navigation error: $e');
      // Try one more time after a longer delay
      await Future.delayed(const Duration(seconds: 2));
      try {
        await _voiceService.initialize();
        if (_voiceService.isInitialized) {
          await _voiceService.startContinuousListening();
        }
      } catch (retryError) {
        debugPrint('Voice navigation restart retry failed: $retryError');
      }
    }
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChanged);
    super.dispose();
  }
}