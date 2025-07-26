import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/tts_service.dart';
import '../services/dependency_injection.dart';
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

    // Navigation commands
    if (lowerCommand.contains('map') ||
        lowerCommand.contains('show map') ||
        lowerCommand.contains('open map')) {
      Navigator.pushReplacementNamed(context, '/map');
      _ttsService.speak('Navigating to map screen');
    } else if (lowerCommand.contains('discover') ||
        lowerCommand.contains('tours') ||
        lowerCommand.contains('show tours')) {
      Navigator.pushReplacementNamed(context, '/discover');
      _ttsService.speak('Navigating to discover screen');
    } else if (lowerCommand.contains('downloads') ||
        lowerCommand.contains('offline') ||
        lowerCommand.contains('my downloads')) {
      Navigator.pushReplacementNamed(context, '/downloads');
      _ttsService.speak('Navigating to downloads screen');
    } else if (lowerCommand.contains('help') ||
        lowerCommand.contains('support') ||
        lowerCommand.contains('get help')) {
      Navigator.pushReplacementNamed(context, '/help-support');
      _ttsService.speak('Navigating to help and support screen');
    }
    // Quick action commands
    else if (lowerCommand.contains('quick actions') ||
        lowerCommand.contains('actions')) {
      _ttsService.speak(
        'Quick actions are available: Map, Discover Tours, Downloads, and Help & Support',
      );
    } else if (lowerCommand.contains('recent tours') ||
        lowerCommand.contains('history')) {
      _ttsService.speak(
        'Recent tours section shows your recently played tours',
      );
    } else if (lowerCommand.contains('voice commands') ||
        lowerCommand.contains('commands')) {
      _speakAvailableCommands();
    } else if (lowerCommand.contains('home') ||
        lowerCommand.contains('main screen')) {
      _ttsService.speak('You are already on the home screen');
    }
  }

  void _speakAvailableCommands() {
    if (!mounted) return;
    _ttsService.speak('''
Available voice commands on home screen:
Navigation: "Open map", "Show tours", "Downloads", "Get help"
Information: "Quick actions", "Recent tours", "Voice commands"
You can also use the quick action cards to navigate to different sections.
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
      }
    });
  }

  Future<void> _speakWelcomeMessage() async {
    if (!mounted) return;
    await _ttsService.speak(
      'Welcome to your Echo Guide home screen. Here you can access quick actions, view your recent tours, and navigate to different sections of the app using voice commands. Say "voice commands" to hear available options.',
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
                  onTap: () => Navigator.pushNamed(context, '/map'),
                  voiceCommand: '"Open map"',
                ),
                QuickActionCard(
                  title: 'Discover Tours',
                  subtitle: 'Browse available tours',
                  icon: Icons.explore,
                  onTap: () => Navigator.pushNamed(context, '/discover'),
                  voiceCommand: '"Show tours"',
                ),
                QuickActionCard(
                  title: 'My Downloads',
                  subtitle: 'Offline content',
                  icon: Icons.download,
                  onTap: () => Navigator.pushNamed(context, '/downloads'),
                  voiceCommand: '"Downloads"',
                ),
                QuickActionCard(
                  title: 'Help & Support',
                  subtitle: 'Get assistance',
                  icon: Icons.help,
                  onTap: () => Navigator.pushNamed(context, '/help-support'),
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
                  child: Row(
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
            'Information',
            '"Quick actions", "Recent tours", "Voice commands"',
          ),
          _buildVoiceCommandItem(
            'Help',
            '"Voice commands" to hear all options',
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
