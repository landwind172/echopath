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

  bool get isVoiceNavigationEnabled => _isVoiceNavigationEnabled;
  bool get isListening => _isListening;
  String get lastCommand => _lastCommand;
  List<String> get commandHistory => _commandHistory;

  VoiceNavigationProvider() {
    _voiceService.addListener(_onVoiceServiceChanged);
    // Start continuous listening when provider is created
    _initializeVoiceNavigation();
  }

  Future<void> _initializeVoiceNavigation() async {
    if (_isVoiceNavigationEnabled) {
      await _voiceService.startContinuousListening();
    }
  }

  void _onVoiceServiceChanged() {
    _isListening = _voiceService.isListening;
    if (_voiceService.lastWords.isNotEmpty &&
        _voiceService.lastWords != _lastCommand) {
      _lastCommand = _voiceService.lastWords;
      _addToCommandHistory(_lastCommand);
    }
    notifyListeners();
  }

  void _addToCommandHistory(String command) {
    _commandHistory.insert(0, command);
    if (_commandHistory.length > 10) {
      _commandHistory.removeLast();
    }
  }

  Future<void> toggleVoiceNavigation() async {
    _isVoiceNavigationEnabled = !_isVoiceNavigationEnabled;

    if (_isVoiceNavigationEnabled) {
      await _voiceService.startContinuousListening();
      await _ttsService.speak('Voice navigation enabled');
    } else {
      _voiceService.stopContinuousListening();
      await _ttsService.speak('Voice navigation disabled');
    }

    notifyListeners();
  }

  Future<void> startListening() async {
    if (_isVoiceNavigationEnabled) {
      await _voiceService.startListening();
    }
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  Future<void> speakFeedback(String message) async {
    await _ttsService.speak(message);
  }

  void clearCommandHistory() {
    _commandHistory.clear();
    notifyListeners();
  }

  void clearLastCommand() {
    _lastCommand = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChanged);
    super.dispose();
  }
}
