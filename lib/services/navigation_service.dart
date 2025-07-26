import 'package:flutter/material.dart';
import 'tts_service.dart';
import 'navigation_coordinator.dart';
import 'dependency_injection.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;
  final TTSService _ttsService = getIt<TTSService>();
  final NavigationCoordinator _navigationCoordinator = NavigationCoordinator();

  Future<void> navigateToHome() async {
    if (context != null) {
      await _navigationCoordinator.navigateToScreen(context!, 'home');
    }
  }

  Future<void> navigateToMap() async {
    if (context != null) {
      await _navigationCoordinator.navigateToScreen(context!, 'map');
    }
  }

  Future<void> navigateToDiscover() async {
    if (context != null) {
      await _navigationCoordinator.navigateToScreen(context!, 'discover');
    }
  }

  Future<void> navigateToDownloads() async {
    if (context != null) {
      await _navigationCoordinator.navigateToScreen(context!, 'downloads');
    }
  }

  Future<void> navigateToHelpSupport() async {
    if (context != null) {
      await _navigationCoordinator.navigateToScreen(context!, 'help');
    }
  }

  Future<void> navigateToOnboarding() async {
    if (context != null) {
      await _navigationCoordinator.navigateToScreen(context!, 'onboarding');
    }
  }

  void goBack() {
    if (context != null && Navigator.of(context!).canPop()) {
      Navigator.of(context!).pop();
    }
  }

  // Enhanced navigation with voice feedback
  Future<void> navigateWithVoiceFeedback(
    String route,
    String screenName,
  ) async {
    if (context != null) {
      await _ttsService.speakWithPriority('Navigating to $screenName');
      Navigator.of(context!).pushNamedAndRemoveUntil(route, (route) => false);
    }
  }

  // Get current screen name
  String get currentScreen => _navigationCoordinator.currentScreen;

  // Get available commands for current screen
  List<String> getAvailableCommands() {
    return _navigationCoordinator.getAvailableCommands();
  }

  // Speak available commands
  Future<void> speakAvailableCommands() async {
    await _navigationCoordinator.speakAvailableCommands();
  }
}
