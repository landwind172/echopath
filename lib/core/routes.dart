import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/downloads_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/voice_diagnostic_screen.dart';
import '../screens/voice_test_screen.dart';
import '../screens/global_navigation_test_screen.dart';

class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String map = '/map';
  static const String discover = '/discover';
  static const String downloads = '/downloads';
  static const String helpSupport = '/help-support';
  static const String voiceDiagnostic = '/voice-diagnostic';
  static const String voiceTest = '/voice-test';
  static const String globalNavigationTest = '/global-navigation-test';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      home: (context) => const HomeScreen(),
      map: (context) => const MapScreen(),
      discover: (context) => const DiscoverScreen(),
      downloads: (context) => const DownloadsScreen(),
      helpSupport: (context) => const HelpSupportScreen(),
      voiceDiagnostic: (context) => const VoiceDiagnosticScreen(),
      voiceTest: (context) => const VoiceTestScreen(),
      globalNavigationTest: (context) => const GlobalNavigationTestScreen(),
    };
  }
}
