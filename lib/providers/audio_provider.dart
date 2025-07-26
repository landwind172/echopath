import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';
import '../services/dependency_injection.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _audioService = getIt<AudioService>();

  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  String? _currentAudioPath;
  List<String> _playlist = [];
  int _currentIndex = 0;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get duration => _duration;
  Duration get position => _position;
  double get volume => _volume;
  String? get currentAudioPath => _currentAudioPath;
  List<String> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  AudioProvider() {
    _audioService.addListener(_onAudioServiceChanged);
  }

  void _onAudioServiceChanged() {
    _isPlaying = _audioService.isPlaying;
    _isPaused = _audioService.isPaused;
    _duration = _audioService.duration;
    _position = _audioService.position;
    _volume = _audioService.volume;
    _currentAudioPath = _audioService.currentAudioPath;
    notifyListeners();
  }

  Future<void> playFromAssets(String assetPath) async {
    await _audioService.playFromAssets(assetPath);
    _currentAudioPath = assetPath;
    notifyListeners();
  }

  Future<void> playFromFile(String filePath) async {
    await _audioService.playFromFile(filePath);
    _currentAudioPath = filePath;
    notifyListeners();
  }

  Future<void> playFromUrl(String url) async {
    await _audioService.playFromUrl(url);
    _currentAudioPath = url;
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> resume() async {
    await _audioService.resume();
  }

  Future<void> stop() async {
    await _audioService.stop();
    _currentAudioPath = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
    _volume = volume;
    notifyListeners();
  }

  void setPlaylist(List<String> playlist) {
    _playlist = playlist;
    _currentIndex = 0;
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await playFromFile(_playlist[_currentIndex]);
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      await playFromFile(_playlist[_currentIndex]);
    }
  }

  Future<void> playAtIndex(int index) async {
    if (_playlist.isNotEmpty && index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      await playFromFile(_playlist[_currentIndex]);
    }
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioServiceChanged);
    super.dispose();
  }
}