class AppConstants {
  // Voice Commands
  static const List<String> navigationCommands = [
    'go home',
    'open home',
    'navigate home',
    'go to map',
    'open map',
    'show map',
    'go to discover',
    'open discover',
    'show tours',
    'go to downloads',
    'open downloads',
    'offline content',
    'go to help',
    'open help',
    'get support',
  ];

  static const List<String> playbackCommands = [
    'play',
    'pause',
    'stop',
    'resume',
    'next',
    'previous',
    'repeat',
    'volume up',
    'volume down',
  ];

  static const List<String> mapCommands = [
    'zoom in',
    'zoom out',
    'find location',
    'where am i',
    'navigate to',
    'start navigation',
    'stop navigation',
    'nearby places',
  ];

  // Audio Settings
  static const double defaultSpeechRate = 0.5;
  static const double defaultPitch = 1.0;
  static const String defaultLanguage = 'en-US';

  // Firebase Collections
  static const String toursCollection = 'tours';
  static const String userPreferencesCollection = 'user_preferences';
  static const String downloadedContentCollection = 'downloaded_content';

  // Shared Preferences Keys
  static const String firstLaunchKey = 'first_launch';
  static const String speechRateKey = 'speech_rate';
  static const String pitchKey = 'pitch';
  static const String languageKey = 'language';
  static const String voiceNavigationEnabledKey = 'voice_navigation_enabled';
}