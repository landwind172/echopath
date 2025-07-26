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
  
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;

  Future<void> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
        localeId: AppConstants.defaultLanguage,
      );
      _isListening = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Start listening error: $e');
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

    _listeningTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isListening && _isInitialized) {
        await startListening();
      }
    });
  }

  void stopContinuousListening() {
    _listeningTimer?.cancel();
    _listeningTimer = null;
    stopListening();
  }

  void _onSpeechResult(result) {
    _lastWords = result.recognizedWords.toLowerCase();
    notifyListeners();
    
    if (result.finalResult) {
      _processVoiceCommand(_lastWords);
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      notifyListeners();
    }
  }

  void _onSpeechError(error) {
    debugPrint('Speech error: $error');
    _isListening = false;
    notifyListeners();
  }

  void _processVoiceCommand(String command) {
    debugPrint('Processing voice command: $command');
    final ttsService = getIt<TTSService>();
    final navigationService = getIt<NavigationService>();

    // Enhanced navigation commands for main screens
    if (command.contains('home') ||
        command.contains('go home') ||
        command.contains('main screen')) {
      navigationService.navigateToHome();
      ttsService.speak('Navigating to home screen');
    } else if (command.contains('map') ||
        command.contains('show map') ||
        command.contains('open map')) {
      navigationService.navigateToMap();
      ttsService.speak('Opening map screen');
    } else if (command.contains('discover') ||
        command.contains('tours') ||
        command.contains('show tours') ||
        command.contains('browse tours')) {
      navigationService.navigateToDiscover();
      ttsService.speak('Opening discover screen');
    } else if (command.contains('downloads') ||
        command.contains('offline') ||
        command.contains('my downloads')) {
      navigationService.navigateToDownloads();
      ttsService.speak('Opening downloads screen');
    } else if (command.contains('help') ||
        command.contains('support') ||
        command.contains('get help')) {
      navigationService.navigateToHelpSupport();
      ttsService.speak('Opening help and support screen');
    } else if (command.contains('go back') ||
        command.contains('back') ||
        command.contains('previous')) {
      navigationService.goBack();
      ttsService.speak('Going back');
    } else if (command.contains('where am i') ||
        command.contains('my location') ||
        command.contains('current location')) {
      // This will be handled by the map screen
      ttsService.speak('Checking your current location');
    } else if (command.contains('zoom in') || command.contains('closer')) {
      ttsService.speak('Zooming in on the map');
    } else if (command.contains('zoom out') || command.contains('farther')) {
      ttsService.speak('Zooming out on the map');
    } else if (command.contains('zoom to street') ||
        command.contains('street level')) {
      ttsService.speak('Zooming to street level');
    } else if (command.contains('zoom to city') ||
        command.contains('city level')) {
      ttsService.speak('Zooming to city level');
    } else if (command.contains('zoom to country') ||
        command.contains('country level')) {
      ttsService.speak('Zooming to country level');
    } else if (command.contains('move north') || command.contains('go north')) {
      ttsService.speak('Moving map north');
    } else if (command.contains('move south') || command.contains('go south')) {
      ttsService.speak('Moving map south');
    } else if (command.contains('move east') || command.contains('go east')) {
      ttsService.speak('Moving map east');
    } else if (command.contains('move west') || command.contains('go west')) {
      ttsService.speak('Moving map west');
    } else if (command.contains('navigate to') ||
        command.contains('directions to')) {
      ttsService.speak('Navigation feature coming soon');
    } else if (command.contains('nearby places') ||
        command.contains('find places')) {
      ttsService.speak('Searching for nearby places');
    } else if (command.contains('start navigation') ||
        command.contains('navigate')) {
      ttsService.speak('Starting navigation');
    } else if (command.contains('stop navigation') ||
        command.contains('end navigation')) {
      ttsService.speak('Stopping navigation');
    } else if (command.contains('toggle voice') ||
        command.contains('voice mode')) {
      ttsService.speak('Toggling voice mode');
    } else if (command.contains('help') || command.contains('commands')) {
      ttsService.speak('Speaking available commands');
    } else if (command.contains('clear markers') ||
        command.contains('remove markers')) {
      ttsService.speak('Clearing map markers');
    } else if (command.contains('map info') ||
        command.contains('map details')) {
      ttsService.speak('Getting map information');
    } else if (command.contains('last location') ||
        command.contains('previous location')) {
      ttsService.speak('Going to last location');
    } else if (command.contains('repeat command') ||
        command.contains('last command')) {
      ttsService.speak('Repeating last command');
    } else if (command.contains('command history')) {
      ttsService.speak('Speaking command history');
    } else if (command.contains('quick actions') ||
        command.contains('actions')) {
      ttsService.speak(
        'Quick actions are available: Map, Discover Tours, Downloads, and Help & Support',
      );
    } else if (command.contains('recent tours') ||
        command.contains('history')) {
      ttsService.speak('Recent tours section shows your recently played tours');
    } else if (command.contains('voice commands') ||
        command.contains('available commands') ||
        command.contains('help commands') ||
        command.contains('what can i say')) {
      _speakGlobalVoiceCommands(ttsService);
    } else if (command.contains('describe kasubi') ||
        command.contains('kasubi tombs') ||
        command.contains('royal tombs')) {
      ttsService.speak(
        'Kasubi Tombs is the sacred burial site of the Kabakas of Buganda. The main building features traditional architecture with a thatched roof and holds deep spiritual significance.',
      );
    } else if (command.contains('namugongo') ||
        command.contains('martyrs shrine')) {
      ttsService.speak(
        'Namugongo Martyrs Shrine commemorates 45 young men who were martyred for their Christian faith in 1886. It is a major pilgrimage site with beautiful architecture and peaceful gardens.',
      );
    } else if (command.contains('lubiri palace') ||
        command.contains('kabaka palace')) {
      ttsService.speak(
        'Lubiri Palace is the magnificent residence of the Kabaka of Buganda. It combines traditional African architecture with modern amenities and serves as a symbol of the enduring Buganda monarchy.',
      );
    } else if (command.contains('mengo hill')) {
      ttsService.speak(
        'Mengo Hill is the traditional heart of the Buganda kingdom, offering breathtaking panoramic views of Kampala city and serving as the seat of Buganda power for centuries.',
      );
    } else if (command.contains('bulange') || command.contains('parliament')) {
      ttsService.speak(
        'Bulange Parliament is where the Buganda kingdom\'s traditional parliament meets. The building features distinctive traditional architecture and represents the democratic traditions of the Buganda people.',
      );
    } else if (command.contains('lake victoria')) {
      ttsService.speak(
        'Lake Victoria, Africa\'s largest lake, offers stunning views and rich cultural experiences. Visit fishing villages, take boat tours, and enjoy spectacular sunsets over the water.',
      );
    } else if (command.contains('ndere') ||
        command.contains('cultural centre')) {
      ttsService.speak(
        'Ndere Cultural Centre is a vibrant hub of Ugandan culture, featuring traditional music, dance performances, and cultural workshops showcasing the diversity of Uganda\'s ethnic groups.',
      );
    } else if (command.contains('kampala markets') ||
        command.contains('owino market')) {
      ttsService.speak(
        'Kampala\'s markets are a sensory feast of colors, sounds, and smells. From the bustling Owino Market to craft markets, experience authentic Ugandan life, traditional crafts, and delicious street food.',
      );
    } else if (command.contains('offline content') ||
        command.contains('offline library') ||
        command.contains('downloads')) {
      ttsService.speak(
        'Offline library contains pre-downloaded guides, stories, music, and language lessons about Buganda, Uganda. All content is available without internet connection.',
      );
    } else if (command.contains('kasubi guide') ||
        command.contains('kasubi tombs guide')) {
      ttsService.speak(
        'Kasubi Tombs Complete Guide provides detailed audio descriptions, historical background, and cultural significance of the royal burial grounds. Available offline.',
      );
    } else if (command.contains('luganda guide') ||
        command.contains('language guide')) {
      ttsService.speak(
        'Learn Luganda guide helps you master basic phrases, greetings, and cultural expressions of the Buganda language. Includes pronunciation guides and cultural context.',
      );
    } else if (command.contains('buganda stories') ||
        command.contains('folktales')) {
      ttsService.speak(
        'Buganda Folktales collection features traditional stories, legends, and cultural narratives passed down through generations. Learn moral lessons and cultural values.',
      );
    } else if (command.contains('traditional music') ||
        command.contains('buganda music')) {
      ttsService.speak(
        'Traditional Buganda Music collection showcases royal drum music, traditional instruments, and folk songs from the kingdom\'s rich musical heritage.',
      );
    } else if (command.contains('kampala guide') ||
        command.contains('city guide')) {
      ttsService.speak(
        'Kampala City Guide provides comprehensive information about landmarks, markets, transportation, and cultural sites in Uganda\'s vibrant capital.',
      );
    } else if (command.contains('culture guide') ||
        command.contains('traditions')) {
      ttsService.speak(
        'Buganda Culture Guide explores traditions, customs, and social practices that have shaped the kingdom for centuries.',
      );
    } else {
      // Unknown command - provide helpful feedback
      ttsService.speak(
        'Command not recognized. Say "voice commands" to hear available options.',
      );
    }
  }

  void _speakGlobalVoiceCommands(TTSService ttsService) {
    ttsService.speak('''
Available global voice commands:
Navigation: "Go home", "Open map", "Show tours", "Downloads", "Get help"
Map controls: "Zoom in", "Zoom out", "Where am I", "Move north/south/east/west"
General: "Go back", "Voice commands", "Quick actions"
Say any of these commands from any screen to navigate or control the app.
''');
  }

  // Add more command processing as needed

  @override
  void dispose() {
    stopContinuousListening();
    _speechToText.cancel();
    super.dispose();
  }
}
