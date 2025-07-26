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
  final List<String> _speechQueue = [];
  bool _isProcessingQueue = false;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get language => _language;

  Future<void> initialize() async {
    try {
      // Configure TTS for optimal performance
      await _flutterTts.setLanguage(_language);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);

      // Set TTS engine preferences for better quality
      // Note: setSharedInstance is not available on web
      if (!kIsWeb) {
        try {
          await _flutterTts.setSharedInstance(true);
        } catch (e) {
          debugPrint('setSharedInstance not available: $e');
        }
      }

      try {
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (e) {
        debugPrint('awaitSpeakCompletion not available: $e');
      }

      // Configure handlers for smooth operation
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
        _processNextInQueue();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        notifyListeners();
        debugPrint('TTS Error: $msg');
        _processNextInQueue();
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
      debugPrint('TTS service initialized successfully');
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized || text.isEmpty) return;

    // Clean and optimize text for speech
    final cleanText = _cleanTextForSpeech(text);

    try {
      // Stop current speech and clear queue for immediate response
      await stop();

      // Wait a brief moment to ensure stop completed
      await Future.delayed(const Duration(milliseconds: 50));

      await _flutterTts.speak(cleanText);

      // Wait for speech to complete
      while (_isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      // Retry once if there's an error
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        await _flutterTts.speak(cleanText);
        while (_isSpeaking) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (retryError) {
        debugPrint('TTS retry speak error: $retryError');
      }
    }
  }

  Future<void> speakQueued(String text) async {
    if (!_isInitialized || text.isEmpty) return;

    final cleanText = _cleanTextForSpeech(text);
    _speechQueue.add(cleanText);

    if (!_isProcessingQueue && !_isSpeaking) {
      _processNextInQueue();
    }
  }

  Future<void> _processNextInQueue() async {
    if (_speechQueue.isEmpty || _isProcessingQueue) return;

    _isProcessingQueue = true;

    while (_speechQueue.isNotEmpty && _isInitialized) {
      final text = _speechQueue.removeAt(0);

      try {
        await _flutterTts.speak(text);
        // Wait for completion before processing next item
        while (_isSpeaking) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        debugPrint('TTS queue processing error: $e');
      }
    }

    _isProcessingQueue = false;
  }

  String _cleanTextForSpeech(String text) {
    // Remove excessive whitespace and clean up text for better speech
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s.,!?;:-]'), '')
        .trim();
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      _speechQueue.clear();
      _isProcessingQueue = false;
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

  Future<void> speakWithPriority(String text) async {
    // High priority speech that interrupts current speech and clears queue
    try {
      _speechQueue.clear();
      _isProcessingQueue = false;
      await stop();

      // Brief delay to ensure stop completed
      await Future.delayed(const Duration(milliseconds: 50));

      await speak(text);
    } catch (e) {
      debugPrint('TTS speak with priority error: $e');
      // Fallback: try direct speak
      try {
        await _flutterTts.speak(_cleanTextForSpeech(text));
      } catch (fallbackError) {
        debugPrint('TTS fallback speak error: $fallbackError');
      }
    }
  }

  Future<void> speakImmediate(String text) async {
    // Immediate speech for critical navigation feedback
    if (!_isInitialized || text.isEmpty) return;

    try {
      final cleanText = _cleanTextForSpeech(text);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('TTS immediate speak error: $e');
    }
  }

  Future<void> speakSequential(List<String> texts) async {
    if (!_isInitialized || texts.isEmpty) return;

    try {
      // Stop any current speech
      await stop();
      await Future.delayed(const Duration(milliseconds: 100));

      for (final text in texts) {
        if (text.isEmpty) continue;

        final cleanText = _cleanTextForSpeech(text);
        await _flutterTts.speak(cleanText);

        // Wait for this utterance to complete before starting the next
        while (_isSpeaking) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Brief pause between utterances
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      debugPrint('TTS sequential speak error: $e');
    }
  }
}
