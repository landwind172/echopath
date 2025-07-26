import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';
import '../services/dependency_injection.dart';
import '../core/routes.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/voice_status_widget.dart';
import '../widgets/quick_action_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TTSService _ttsService = getIt<TTSService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWelcomeMessage();
      _setCurrentScreen();
      _setupVoiceNavigation();
    });
  }

  void _setupVoiceNavigation() {
    // Use post-frame callback to avoid build-time provider access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final voiceProvider = Provider.of<VoiceNavigationProvider>(
          context,
          listen: false,
        );
        voiceProvider.addListener(_onVoiceCommandReceived);
      }
    });
  }

  void _onVoiceCommandReceived() {
    // Check if widget is still mounted before accessing context
    if (!mounted) return;

    try {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      if (voiceProvider.lastCommand.isNotEmpty) {
        _handleHomeVoiceCommands(voiceProvider.lastCommand);
        voiceProvider.clearLastCommand();
      }
    } catch (e) {
      // Ignore errors if context is no longer available
      debugPrint('Voice command error: $e');
    }
  }

  void _handleHomeVoiceCommands(String command) {
    if (!mounted) return;

    final lowerCommand = command.toLowerCase();

    // Debug command to test voice recognition
    if (lowerCommand.contains('test voice') ||
        lowerCommand.contains('voice test') ||
        lowerCommand.contains('test microphone')) {
      _ttsService.speakWithPriority(
        'Voice recognition is working! You said: $command',
      );
      return;
    }

    // Enhanced navigation commands with multiple variations
    if (lowerCommand.contains('map') ||
        lowerCommand.contains('show map') ||
        lowerCommand.contains('open map') ||
        lowerCommand.contains('view map') ||
        lowerCommand.contains('go to map')) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.map, (route) => false);
      _ttsService.speakWithPriority(
        'Opening interactive map with voice navigation',
      );
    } else if (lowerCommand.contains('discover') ||
        lowerCommand.contains('tours') ||
        lowerCommand.contains('show tours') ||
        lowerCommand.contains('browse tours') ||
        lowerCommand.contains('find tours') ||
        lowerCommand.contains('explore')) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.discover,
        (route) => false,
      );
      _ttsService.speakWithPriority(
        'Opening discover tours with Buganda destinations',
      );
    } else if (lowerCommand.contains('downloads') ||
        lowerCommand.contains('offline') ||
        lowerCommand.contains('my downloads') ||
        lowerCommand.contains('saved content') ||
        lowerCommand.contains('offline content')) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.downloads,
        (route) => false,
      );
      _ttsService.speakWithPriority(
        'Opening offline library with saved content',
      );
    } else if (lowerCommand.contains('help') ||
        lowerCommand.contains('support') ||
        lowerCommand.contains('get help') ||
        lowerCommand.contains('assistance') ||
        lowerCommand.contains('help me')) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.helpSupport,
        (route) => false,
      );
      _ttsService.speakWithPriority(
        'Opening help and support with voice commands guide',
      );
    }
    // Voice navigation control commands
    else if (lowerCommand.contains('restart voice') ||
        lowerCommand.contains('reset voice') ||
        lowerCommand.contains('restart navigation') ||
        lowerCommand.contains('reset navigation')) {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.forceRestartVoiceNavigation();
    } else if (lowerCommand.contains('enable voice') ||
        lowerCommand.contains('turn on voice') ||
        lowerCommand.contains('activate voice')) {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      if (!voiceProvider.isVoiceNavigationEnabled) {
        voiceProvider.toggleVoiceNavigation();
      } else {
        _ttsService.speakWithPriority('Voice navigation is already enabled');
      }
    } else if (lowerCommand.contains('disable voice') ||
        lowerCommand.contains('turn off voice') ||
        lowerCommand.contains('deactivate voice')) {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      if (voiceProvider.isVoiceNavigationEnabled) {
        voiceProvider.toggleVoiceNavigation();
      } else {
        _ttsService.speakWithPriority('Voice navigation is already disabled');
      }
    }
    // Quick action commands
    else if (lowerCommand.contains('quick actions') ||
        lowerCommand.contains('actions')) {
      _ttsService.speakWithPriority(
        'Quick actions are available: Map, Discover Tours, Downloads, and Help & Support',
      );
    } else if (lowerCommand.contains('recent tours') ||
        lowerCommand.contains('history')) {
      _ttsService.speakWithPriority(
        'Recent tours section shows your recently played tours',
      );
    } else if (lowerCommand.contains('voice commands') ||
        lowerCommand.contains('commands')) {
      _speakAvailableCommands();
    } else if (lowerCommand.contains('home') ||
        lowerCommand.contains('main screen')) {
      _ttsService.speakWithPriority('You are already on the home screen');
    } else if (lowerCommand.contains('what can i do') ||
        lowerCommand.contains('options') ||
        lowerCommand.contains('features')) {
      _speakHomeFeatures();
    } else {
      // Provide helpful feedback for unrecognized commands
      _ttsService.speakWithPriority(
        'Command not recognized. You said: "$command". Say "voice commands" to hear available options or use navigation commands like "open map" or "show tours".',
      );
    }
  }

  void _speakAvailableCommands() {
    if (!mounted) return;
    _ttsService.speakWithPriority('''
Available voice commands on home screen:
Navigation: "Open map", "Show tours", "Downloads", "Get help"
Voice Control: "Enable voice", "Disable voice", "Restart voice navigation"
Testing: "Test voice" to verify microphone is working
Information: "Quick actions", "Recent tours", "What can I do"
Features: All screens support voice navigation for seamless accessibility.
You can speak naturally - the app understands multiple ways to say the same command.
''');
  }

  void _speakHomeFeatures() {
    if (!mounted) return;
    _ttsService.speakWithPriority('''
Echo Guide features:
Interactive Map: Find hotels, restaurants, markets, and tours with voice commands.
Discover Tours: Explore Buganda destinations with detailed audio descriptions.
Offline Library: Access downloaded content without internet connection.
Voice Navigation: Complete hands-free control across all screens.
All features are designed for accessibility and ease of use.
''');
  }

  void _setCurrentScreen() {
    // Use post-frame callback to avoid build-time provider access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final appStateProvider = Provider.of<AppStateProvider>(
          context,
          listen: false,
        );
        appStateProvider.setCurrentScreen('home');

        // Update voice navigation provider with current screen context
        final voiceProvider = Provider.of<VoiceNavigationProvider>(
          context,
          listen: false,
        );
        voiceProvider.updateCurrentScreen('home');
      }
    });
  }

  Future<void> _speakWelcomeMessage() async {
    if (!mounted) return;
    await _ttsService.speakWithPriority(
      'Welcome to Echo Guide home screen. Voice navigation is active and ready. You can say "open map" for interactive locations, "show tours" for Buganda destinations, "downloads" for offline content, or "get help" for assistance. Say "what can I do" to hear all features.',
    );

    // No automatic transition for main screens - user can navigate manually
  }

  @override
  void dispose() {
    // Clean up voice navigation listener
    try {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.removeListener(_onVoiceCommandReceived);
    } catch (e) {
      // Ignore errors during dispose
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Echo Guide'),
        actions: const [VoiceStatusWidget()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            _buildRecentToursSection(),
            const SizedBox(height: 24),
            _buildVoiceCommandsSection(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waving_hand, color: Colors.white, size: 32),
              const Spacer(),
              Consumer<VoiceNavigationProvider>(
                builder: (context, voiceProvider, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: voiceProvider.isVoiceNavigationEnabled
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          voiceProvider.isVoiceNavigationEnabled
                              ? Icons.mic
                              : Icons.mic_off,
                          size: 16,
                          color: voiceProvider.isVoiceNavigationEnabled
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          voiceProvider.isVoiceNavigationEnabled
                              ? 'VOICE ON'
                              : 'VOICE OFF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: voiceProvider.isVoiceNavigationEnabled
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome Back!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ready to explore? Use voice commands or tap to navigate.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                QuickActionCard(
                  title: 'Explore Map',
                  subtitle: 'Find nearby tours',
                  icon: Icons.map,
                  onTap: () => Navigator.pushNamed(context, Routes.map),
                  voiceCommand: '"Open map"',
                ),
                QuickActionCard(
                  title: 'Discover Tours',
                  subtitle: 'Browse available tours',
                  icon: Icons.explore,
                  onTap: () => Navigator.pushNamed(context, Routes.discover),
                  voiceCommand: '"Show tours"',
                ),
                QuickActionCard(
                  title: 'My Downloads',
                  subtitle: 'Offline content',
                  icon: Icons.download,
                  onTap: () => Navigator.pushNamed(context, Routes.downloads),
                  voiceCommand: '"Downloads"',
                ),
                QuickActionCard(
                  title: 'Help & Support',
                  subtitle: 'Get assistance',
                  icon: Icons.help,
                  onTap: () => Navigator.pushNamed(context, Routes.helpSupport),
                  voiceCommand: '"Get help"',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<VoiceNavigationProvider>(
              builder: (context, voiceProvider, child) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            voiceProvider.isVoiceNavigationEnabled
                                ? Icons.mic
                                : Icons.mic_off,
                            color: voiceProvider.isVoiceNavigationEnabled
                                ? Colors.green
                                : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voice Navigation',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  voiceProvider.isVoiceNavigationEnabled
                                      ? 'Voice commands are active'
                                      : 'Voice commands are disabled',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: voiceProvider.isVoiceNavigationEnabled,
                            onChanged: (value) {
                              voiceProvider.toggleVoiceNavigation();
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                      if (!voiceProvider.isVoiceNavigationEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: voiceProvider.isInitializing
                                    ? null
                                    : () => voiceProvider
                                          .forceRestartVoiceNavigation(),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: Text(
                                  voiceProvider.isInitializing
                                      ? 'Initializing...'
                                      : 'Restart Voice Navigation',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentToursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Tours',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // Placeholder count
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sample Tour ${index + 1}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last played 2 days ago',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCommandsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Voice Commands',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVoiceCommandItem(
            'Navigation',
            '"Open map", "Show tours", "Downloads", "Get help"',
          ),
          _buildVoiceCommandItem(
            'Voice Control',
            '"Enable voice", "Disable voice", "Restart voice navigation"',
          ),
          _buildVoiceCommandItem(
            'Testing',
            '"Test voice" to verify microphone is working',
          ),
          _buildVoiceCommandItem(
            'Information',
            '"Quick actions", "Recent tours", "Voice commands"',
          ),
          _buildVoiceCommandItem(
            'Help',
            '"Voice commands" to hear all options',
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/voice-diagnostic');
            },
            icon: Icon(Icons.bug_report),
            label: Text('Voice Navigation Diagnostics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/voice-test');
            },
            icon: Icon(Icons.mic),
            label: Text('Voice Navigation Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final voiceService = getIt<VoiceService>();
              await voiceService.testVoiceNavigation();
            },
            icon: Icon(Icons.bug_report),
            label: Text('Test Voice Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCommandItem(String category, String commands) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(commands, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
