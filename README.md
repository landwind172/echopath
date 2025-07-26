# Echo Guide - Voice-Powered Tour Guide App

A comprehensive Flutter application designed specifically for blind and visually impaired users, providing seamless voice navigation and immersive audio tour experiences.

## Features

### 🎤 Voice Navigation
- Complete voice control across all screens
- Natural language commands for navigation
- Continuous voice listening with smart activation
- Real-time voice feedback and confirmations

### 🗺️ Interactive Maps
- Google Maps integration with audio narration
- Real-time location descriptions
- Voice-controlled map navigation
- Distance and direction announcements

### 🎧 Audio Tours
- Downloadable tours for offline use
- High-quality audio narration
- Playlist management with voice controls
- Background audio with seamless transitions

### 📱 Accessibility-First Design
- Screen reader compatibility
- High contrast themes
- Large text support
- Haptic feedback integration
- Voice-first user interface

### 🔄 Offline Capability
- Download tours for offline access
- Local audio file management
- Offline map caching
- Sync when connection available

## Architecture

### Clean Architecture Structure
```
lib/
├── core/                 # App configuration and constants
├── models/              # Data models and entities
├── services/            # Business logic and external APIs
├── providers/           # State management
├── screens/             # UI screens
├── widgets/             # Reusable UI components
└── main.dart           # App entry point
```

### Key Services
- **VoiceService**: Speech-to-text and command processing
- **TTSService**: Text-to-speech with customizable settings
- **AudioService**: Audio playback and playlist management
- **LocationService**: GPS and location-based features
- **FirebaseService**: Cloud data synchronization
- **DownloadService**: Offline content management

## Voice Commands

### Navigation Commands
- "Go home" - Navigate to home screen
- "Open map" - Access map screen
- "Show tours" - Browse available tours
- "Open downloads" - View offline content
- "Get help" - Access help and support

### Playback Controls
- "Play" / "Pause" / "Stop" - Audio control
- "Next" / "Previous" - Track navigation
- "Volume up" / "Volume down" - Audio adjustment

### Map Commands
- "Where am I?" - Current location announcement
- "Zoom in" / "Zoom out" - Map zoom control
- "Find nearby places" - Discover points of interest

## Setup Instructions

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Firebase project setup
- Google Maps API key
- Android Studio / VS Code

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase (see Firebase Setup section)
4. Add Google Maps API key to platform-specific files
5. Run `flutter run` to start the app

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication, Firestore, and Storage
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place configuration files in appropriate directories
5. Run `flutterfire configure` to generate Firebase options

### Google Maps Setup
1. Enable Google Maps SDK in Google Cloud Console
2. Create API key with appropriate restrictions
3. Add API key to `android/app/src/main/AndroidManifest.xml`
4. Add API key to `ios/Runner/AppDelegate.swift`

## Permissions Required

### Android
- `INTERNET` - Network access
- `ACCESS_FINE_LOCATION` - GPS location
- `ACCESS_COARSE_LOCATION` - Network location
- `RECORD_AUDIO` - Voice commands
- `WRITE_EXTERNAL_STORAGE` - File downloads
- `VIBRATE` - Haptic feedback

### iOS
- `NSLocationWhenInUseUsageDescription` - Location access
- `NSMicrophoneUsageDescription` - Microphone access
- `NSLocationAlwaysAndWhenInUseUsageDescription` - Background location

## State Management

The app uses Provider pattern for state management with the following providers:

- **AppStateProvider**: Global app state and user preferences
- **VoiceNavigationProvider**: Voice command handling and status
- **AudioProvider**: Audio playback state and controls
- **LocationProvider**: GPS location and tracking

## Accessibility Features

### Voice-First Design
- All functionality accessible via voice commands
- Audio feedback for all user interactions
- Spoken descriptions of visual elements
- Voice-guided navigation flows

### Screen Reader Support
- Semantic labels for all UI elements
- Proper focus management
- Accessible navigation patterns
- Screen reader announcements

### Customization Options
- Adjustable speech rate and pitch
- Volume controls
- Language selection
- Voice command sensitivity

## Testing

### Unit Tests
Run unit tests with:
```bash
flutter test
```

### Integration Tests
Run integration tests with:
```bash
flutter drive --target=test_driver/app.dart
```

### Accessibility Testing
- Use TalkBack (Android) or VoiceOver (iOS) for testing
- Test all voice commands in different scenarios
- Verify audio feedback and announcements

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the established code style and architecture
4. Add tests for new functionality
5. Ensure accessibility compliance
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the in-app help section

## Acknowledgments

- Flutter team for the excellent framework
- Firebase for backend services
- Google Maps for location services
- The accessibility community for guidance and feedback# echopath
