import 'package:flutter/material.dart';
import '../core/routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;

  void navigateToHome() {
    if (context != null) {
      Navigator.of(context!).pushReplacementNamed(Routes.home);
    }
  }

  void navigateToMap() {
    if (context != null) {
      Navigator.of(context!).pushReplacementNamed(Routes.map);
    }
  }

  void navigateToDiscover() {
    if (context != null) {
      Navigator.of(context!).pushReplacementNamed(Routes.discover);
    }
  }

  void navigateToDownloads() {
    if (context != null) {
      Navigator.of(context!).pushReplacementNamed(Routes.downloads);
    }
  }

  void navigateToHelpSupport() {
    if (context != null) {
      Navigator.of(context!).pushReplacementNamed(Routes.helpSupport);
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
}
