class AppConstants {
  // Voice Commands
  static const List<String> navigationCommands = [
    // Home navigation
    'go home', 'open home', 'navigate home', 'main screen', 'home screen',
    // Map navigation  
    'go to map', 'open map', 'show map', 'view map', 'location', 'navigation',
    // Discover navigation
    'go to discover', 'open discover', 'show tours', 'browse tours', 'find tours', 'explore',
    // Downloads navigation
    'go to downloads', 'open downloads', 'offline content', 'saved content', 'my downloads',
    // Help navigation
    'go to help', 'open help', 'get support', 'assistance', 'help me',
    // Enhanced navigation commands
    'back to home', 'return home', 'main menu', 'start screen',
    'interactive map', 'map screen', 'location screen',
    'discover screen', 'tour screen', 'explore screen',
    'downloads screen', 'offline screen', 'library screen',
    'help screen', 'support screen', 'assistance screen',
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
    // Location commands
    'where am i', 'my location', 'current location', 'find me',
    'describe location', 'what is here', 'current view',
    // Search commands
    'find places', 'nearby places', 'find hotels', 'find restaurants', 'find markets', 'find tours',
    'find historical', 'find religious', 'historical sites', 'religious sites',
    'what is nearby', 'search nearby', 'list places', 'read markers',
    // Zoom commands
    'zoom in', 'zoom out', 'closer', 'farther',
    // Navigation commands
    'navigate to', 'directions to', 'start navigation', 'stop navigation', 'directions',
    'go to kasubi', 'go to namugongo', 'go to palace', 'go to mengo',
  ];

  // Audio Settings
  static const double defaultSpeechRate = 0.6; // Slightly faster for better responsiveness
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