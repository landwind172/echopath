import 'package:flutter/material.dart';
import '../core/routes.dart';
import 'tts_service.dart';
import 'dependency_injection.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;
  final TTSService _ttsService = getIt<TTSService>();

  void navigateToHome() {
    if (context != null) {
      Navigator.of(context!).pushNamedAndRemoveUntil(Routes.home, (route) => false);
    }
  }

  void navigateToMap() {
    if (context != null) {
      Navigator.of(context!).pushNamedAndRemoveUntil(Routes.map, (route) => false);
    }
  }

  void navigateToDiscover() {
    if (context != null) {
      Navigator.of(context!).pushNamedAndRemoveUntil(Routes.discover, (route) => false);
    }
  }

  void navigateToDownloads() {
    if (context != null) {
      Navigator.of(context!).pushNamedAndRemoveUntil(Routes.downloads, (route) => false);
    }
  }

  void navigateToHelpSupport() {
    if (context != null) {
      Navigator.of(context!).pushNamedAndRemoveUntil(Routes.helpSupport, (route) => false);
    }
  }

  void navigateToOnboarding() {
    if (context != null) {
      Navigator.of(
        context!,
      ).pushNamedAndRemoveUntil(Routes.onboarding, (route) => false);
    }
  }

  void goBack() {
    if (context != null && Navigator.of(context!).canPop()) {
      Navigator.of(context!).pop();
    }
  }

  // Enhanced navigation with voice feedback
  Future<void> navigateWithVoiceFeedback(String route, String screenName) async {
    if (context != null) {
      await _ttsService.speakWithPriority('Navigating to $screenName');
      Navigator.of(context!).pushNamedAndRemoveUntil(route, (route) => false);
    }
  }
}
