import 'package:flutter/foundation.dart';
import '../models/user_preferences_model.dart';
import '../services/firebase_service.dart';
import '../services/dependency_injection.dart';

class AppStateProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = getIt<FirebaseService>();

  UserPreferencesModel _userPreferences =
      UserPreferencesModel.defaultPreferences;
  bool _isFirstLaunch = true;
  bool _isLoading = false;
  String? _currentScreen;
  bool _autoTransitionEnabled =
      true; // Only affects splash screen and onboarding screens with next/previous buttons

  UserPreferencesModel get userPreferences => _userPreferences;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoading => _isLoading;
  String? get currentScreen => _currentScreen;
  bool get autoTransitionEnabled => _autoTransitionEnabled;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load user preferences from Firebase
      final preferences = await _firebaseService.getUserPreferences();
      if (preferences != null) {
        _userPreferences = preferences;
        _isFirstLaunch = false;
      }
    } catch (e) {
      debugPrint('Initialize app state error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserPreferences(UserPreferencesModel preferences) async {
    _userPreferences = preferences;
    notifyListeners();

    try {
      await _firebaseService.saveUserPreferences(preferences);
    } catch (e) {
      debugPrint('Update user preferences error: $e');
    }
  }

  void setCurrentScreen(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void setFirstLaunchComplete() {
    _isFirstLaunch = false;
    notifyListeners();
  }

  void toggleAutoTransition() {
    _autoTransitionEnabled = !_autoTransitionEnabled;
    notifyListeners();
  }

  void setAutoTransition(bool enabled) {
    _autoTransitionEnabled = enabled;
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _userPreferences = UserPreferencesModel.defaultPreferences;
    notifyListeners();

    try {
      await _firebaseService.saveUserPreferences(_userPreferences);
    } catch (e) {
      debugPrint('Reset to defaults error: $e');
    }
  }
}
