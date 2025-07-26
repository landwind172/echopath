import 'package:get_it/get_it.dart';
import 'voice_service.dart';
import 'tts_service.dart';
import 'audio_service.dart';
import 'location_service.dart';
import 'firebase_service.dart';
import 'navigation_service.dart';
import 'navigation_coordinator.dart';
import 'download_service.dart';
import 'notification_service.dart';

final GetIt getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> initialize() async {
    // Register services as singletons
    getIt.registerSingleton<VoiceService>(VoiceService());
    getIt.registerSingleton<TTSService>(TTSService());
    getIt.registerSingleton<AudioService>(AudioService());
    getIt.registerSingleton<LocationService>(LocationService());
    getIt.registerSingleton<FirebaseService>(FirebaseService());
    getIt.registerSingleton<NavigationService>(NavigationService());
    getIt.registerSingleton<NavigationCoordinator>(NavigationCoordinator());
    getIt.registerSingleton<DownloadService>(DownloadService());
    getIt.registerSingleton<NotificationService>(NotificationService());

    // Initialize services
    await getIt<VoiceService>().initialize();
    await getIt<TTSService>().initialize();
    await getIt<AudioService>().initialize();
    await getIt<LocationService>().initialize();
    await getIt<NotificationService>().initialize();
  }
}
