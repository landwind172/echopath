import 'package:flutter/material.dart';
import '../core/routes.dart';
import 'tts_service.dart';
import 'voice_service.dart';
import 'dependency_injection.dart';

class NavigationCoordinator {
  static final NavigationCoordinator _instance =
      NavigationCoordinator._internal();
  factory NavigationCoordinator() => _instance;
  NavigationCoordinator._internal();

  final TTSService _ttsService = getIt<TTSService>();
  final VoiceService _voiceService = getIt<VoiceService>();

  String _currentScreen = 'home';
  final List<String> _navigationHistory = [];
  bool _isNavigating = false;

  String get currentScreen => _currentScreen;
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  // Centralized navigation method with enhanced feedback
  Future<void> navigateToScreen(
    BuildContext context,
    String screenName, {
    String? customMessage,
    bool addToHistory = true,
  }) async {
    if (_isNavigating) return;

    _isNavigating = true;
    final previousScreen = _currentScreen;

    try {
      // Update voice service context
      _voiceService.updateCurrentScreen(screenName);

      // Determine route and navigation message
      final route = _getRouteForScreen(screenName);
      final message = customMessage ?? _getNavigationMessage(screenName);

      // Provide immediate feedback
      await _ttsService.speakWithPriority(message);

      // Execute navigation
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }

      // Update internal state
      _currentScreen = screenName;
      if (addToHistory && previousScreen != screenName) {
        _navigationHistory.add(previousScreen);
        if (_navigationHistory.length > 10) {
          _navigationHistory.removeAt(0);
        }
      }

      // Provide post-navigation feedback
      await _speakScreenContext(screenName);
    } catch (e) {
      debugPrint('Navigation error: $e');
      await _ttsService.speakWithPriority(
        'Navigation failed. Please try again.',
      );
    } finally {
      _isNavigating = false;
    }
  }

  // Get route for screen name
  String _getRouteForScreen(String screenName) {
    switch (screenName.toLowerCase()) {
      case 'home':
        return Routes.home;
      case 'map':
        return Routes.map;
      case 'discover':
        return Routes.discover;
      case 'downloads':
        return Routes.downloads;
      case 'help':
      case 'help-support':
        return Routes.helpSupport;
      case 'onboarding':
        return Routes.onboarding;
      default:
        return Routes.home;
    }
  }

  // Get appropriate navigation message
  String _getNavigationMessage(String screenName) {
    switch (screenName.toLowerCase()) {
      case 'home':
        return 'Navigating to home screen';
      case 'map':
        return 'Opening interactive map with voice navigation and dynamic place discovery';
      case 'discover':
        return 'Opening discover tours with Buganda destinations and cultural experiences';
      case 'downloads':
        return 'Opening offline library with saved content and downloads';
      case 'help':
      case 'help-support':
        return 'Opening help and support with voice commands guide';
      case 'onboarding':
        return 'Starting app introduction and setup';
      default:
        return 'Navigating to $screenName';
    }
  }

  // Provide context-specific information after navigation
  Future<void> _speakScreenContext(String screenName) async {
    switch (screenName.toLowerCase()) {
      case 'home':
        await _ttsService.speak(
          'Home screen loaded. You can navigate to any section using voice commands or quick action cards.',
        );
        break;
      case 'map':
        await _ttsService.speak(
          'Interactive map loaded. Dynamic place discovery is active. Say "find nearby" to explore your surroundings.',
        );
        break;
      case 'discover':
        await _ttsService.speak(
          'Discover screen loaded. Browse Buganda tours and cultural experiences. Say "next tour" to explore.',
        );
        break;
      case 'downloads':
        await _ttsService.speak(
          'Downloads screen loaded. Access your offline content and manage downloads.',
        );
        break;
      case 'help':
      case 'help-support':
        await _ttsService.speak(
          'Help and support screen loaded. Find answers to common questions and voice command guides.',
        );
        break;
    }
  }

  // Quick navigation methods
  Future<void> goHome(BuildContext context) async {
    await navigateToScreen(context, 'home');
  }

  Future<void> openMap(BuildContext context) async {
    await navigateToScreen(context, 'map');
  }

  Future<void> showTours(BuildContext context) async {
    await navigateToScreen(context, 'discover');
  }

  Future<void> openDownloads(BuildContext context) async {
    await navigateToScreen(context, 'downloads');
  }

  Future<void> getHelp(BuildContext context) async {
    await navigateToScreen(context, 'help');
  }

  // Context-aware navigation suggestions
  Future<void> suggestNavigation(BuildContext context, String command) async {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('map') || lowerCommand.contains('location')) {
      await openMap(context);
    } else if (lowerCommand.contains('tour') ||
        lowerCommand.contains('discover')) {
      await showTours(context);
    } else if (lowerCommand.contains('download') ||
        lowerCommand.contains('offline')) {
      await openDownloads(context);
    } else if (lowerCommand.contains('help') ||
        lowerCommand.contains('support')) {
      await getHelp(context);
    } else if (lowerCommand.contains('home') || lowerCommand.contains('main')) {
      await goHome(context);
    } else {
      await _ttsService.speak(
        'I\'m not sure where you want to go. Try saying "open map", "show tours", "downloads", or "get help".',
      );
    }
  }

  // Get available commands for current screen
  List<String> getAvailableCommands() {
    switch (_currentScreen.toLowerCase()) {
      case 'home':
        return [
          'Open map',
          'Show tours',
          'Downloads',
          'Get help',
          'Test voice',
          'Voice commands',
        ];
      case 'map':
        return [
          'Go home',
          'Show tours',
          'Downloads',
          'Get help',
          'Where am I',
          'Find nearby',
          'Zoom in',
          'Zoom out',
          'Start tour',
          'Find hospitals',
          'Find schools',
          'Find landmarks',
        ];
      case 'discover':
        return [
          'Go home',
          'Open map',
          'Downloads',
          'Get help',
          'Next tour',
          'Previous tour',
          'Play tour',
          'Tour details',
        ];
      case 'downloads':
        return [
          'Go home',
          'Open map',
          'Show tours',
          'Get help',
          'Play content',
          'Delete content',
          'Storage info',
        ];
      case 'help':
        return [
          'Go home',
          'Open map',
          'Show tours',
          'Downloads',
          'Voice commands',
          'FAQ',
          'Contact support',
        ];
      default:
        return ['Go home', 'Open map', 'Show tours', 'Downloads', 'Get help'];
    }
  }

  // Speak available commands for current screen
  Future<void> speakAvailableCommands() async {
    final commands = getAvailableCommands();
    final commandList = commands.join(', ');

    await _ttsService.speak(
      'Available commands on $_currentScreen screen: $commandList. You can also use general navigation commands from any screen.',
    );
  }

  // Check if navigation is in progress
  bool get isNavigating => _isNavigating;

  // Get navigation history for debugging
  String getNavigationHistoryString() {
    return _navigationHistory.join(' → ');
  }

  // Clear navigation history
  void clearNavigationHistory() {
    _navigationHistory.clear();
  }

  // Go back to previous screen if available
  Future<void> goBack(BuildContext context) async {
    if (_navigationHistory.isNotEmpty) {
      final previousScreen = _navigationHistory.removeLast();
      await navigateToScreen(context, previousScreen, addToHistory: false);
    } else {
      await goHome(context);
    }
  }
}
