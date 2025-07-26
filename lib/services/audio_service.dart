import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  String? _currentAudioPath;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get duration => _duration;
  Duration get position => _position;
  double get volume => _volume;
  String? get currentAudioPath => _currentAudioPath;

  Future<void> initialize() async {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      _isPaused = state == PlayerState.paused;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      _position = position;
      notifyListeners();
    });
  }

  Future<void> playFromAssets(String assetPath) async {
    try {
      _currentAudioPath = assetPath;
      await _audioPlayer.play(AssetSource(assetPath));
      notifyListeners();
    } catch (e) {
      debugPrint('Audio play from assets error: $e');
    }
  }

  Future<void> playFromFile(String filePath) async {
    try {
      _currentAudioPath = filePath;
      await _audioPlayer.play(DeviceFileSource(filePath));
      notifyListeners();
    } catch (e) {
      debugPrint('Audio play from file error: $e');
    }
  }

  Future<void> playFromUrl(String url) async {
    try {
      _currentAudioPath = url;
      await _audioPlayer.play(UrlSource(url));
      notifyListeners();
    } catch (e) {
      debugPrint('Audio play from URL error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      notifyListeners();
    } catch (e) {
      debugPrint('Audio pause error: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
      notifyListeners();
    } catch (e) {
      debugPrint('Audio resume error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentAudioPath = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      notifyListeners();
    } catch (e) {
      debugPrint('Audio seek error: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      debugPrint('Audio set volume error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}