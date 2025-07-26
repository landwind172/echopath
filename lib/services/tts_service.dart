import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/constants.dart';

class TTSService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _speechRate = AppConstants.defaultSpeechRate;
  double _pitch = AppConstants.defaultPitch;
  String _language = AppConstants.defaultLanguage;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get language => _language;

  Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage(_language);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_speechRate);
      
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        notifyListeners();
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized || text.isEmpty) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  Future<void> pause() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('TTS pause error: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) return;

    try {
      _speechRate = rate.clamp(0.1, 1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      notifyListeners();
    } catch (e) {
      debugPrint('TTS set speech rate error: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) return;

    try {
      _pitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
      notifyListeners();
    } catch (e) {
      debugPrint('TTS set pitch error: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    if (!_isInitialized) return;

    try {
      _language = language;
      await _flutterTts.setLanguage(_language);
      notifyListeners();
    } catch (e) {
      debugPrint('TTS set language error: $e');
    }
  }
}