import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/dependency_injection.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/voice_status_widget.dart';
import '../widgets/help_section_widget.dart';
import '../widgets/faq_item_widget.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TTSService _ttsService = getIt<TTSService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    await _ttsService.speak(
      'Help and Support screen loaded. Find answers to common questions, learn about voice commands, and get assistance with using Echo Guide.',
    );

    // No automatic transition for main screens - user can navigate manually
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: const [VoiceStatusWidget()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildQuickHelpSection(),
            const SizedBox(height: 24),
            _buildVoiceCommandsSection(),
            const SizedBox(height: 24),
            _buildFAQSection(),
            const SizedBox(height: 24),
            _buildContactSection(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 4),
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
          const Icon(Icons.help_outline, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            'How can we help?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find answers, learn voice commands, and get support for Echo Guide.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpSection() {
    return HelpSectionWidget(
      title: 'Quick Help',
      children: [
        _buildQuickHelpCard(
          'Voice Commands',
          'Learn all available voice commands',
          Icons.mic,
          () => _speakVoiceCommands(),
        ),
        _buildQuickHelpCard(
          'Getting Started',
          'Basic guide to using Echo Guide',
          Icons.play_circle_outline,
          () => _speakGettingStarted(),
        ),
        _buildQuickHelpCard(
          'Accessibility Features',
          'Learn about accessibility options',
          Icons.accessibility,
          () => _speakAccessibilityFeatures(),
        ),
      ],
    );
  }

  Widget _buildQuickHelpCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildVoiceCommandsSection() {
    return HelpSectionWidget(
      title: 'Voice Commands Reference',
      children: [
        _buildCommandCategory('Navigation', [
          '"Go home" - Return to home screen',
          '"Open map" - View map screen',
          '"Show tours" - Browse available tours',
          '"Open downloads" - Access offline content',
          '"Get help" - Open this help screen',
        ]),
        _buildCommandCategory('Playback Control', [
          '"Play" - Start audio playback',
          '"Pause" - Pause current audio',
          '"Stop" - Stop audio playback',
          '"Next" - Play next audio track',
          '"Previous" - Play previous track',
          '"Volume up/down" - Adjust volume',
        ]),
        _buildCommandCategory('Map Commands', [
          '"Where am I?" - Get current location',
          '"Zoom in/out" - Adjust map zoom',
          '"Find nearby places" - Discover POIs',
          '"Start navigation" - Begin turn-by-turn',
        ]),
      ],
    );
  }

  Widget _buildCommandCategory(String category, List<String> commands) {
    return ExpansionTile(
      title: Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: commands
          .map(
            (command) => ListTile(
              dense: true,
              leading: const Icon(Icons.keyboard_voice, size: 16),
              title: Text(command),
              onTap: () => _ttsService.speak(command),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFAQSection() {
    return HelpSectionWidget(
      title: 'Frequently Asked Questions',
      children: [
        FAQItemWidget(
          question: 'How do I enable voice navigation?',
          answer:
              'Voice navigation is enabled by default. You can toggle it on/off from the settings or by saying "enable voice navigation" or "disable voice navigation".',
        ),
        FAQItemWidget(
          question: 'Can I use the app offline?',
          answer:
              'Yes! Download tours from the Discover screen to access them offline. Downloaded content is available in the Downloads screen.',
        ),
        FAQItemWidget(
          question: 'How do I adjust speech settings?',
          answer:
              'Speech rate and pitch can be adjusted in the app settings. You can also say "speak faster", "speak slower", "higher pitch", or "lower pitch".',
        ),
        FAQItemWidget(
          question: 'What if voice commands are not working?',
          answer:
              'Ensure microphone permissions are granted, speak clearly, and check that voice navigation is enabled. Try restarting the app if issues persist.',
        ),
        FAQItemWidget(
          question: 'How do I download tours for offline use?',
          answer:
              'Browse tours in the Discover screen and tap the download button on any tour. Downloaded tours will appear in the Downloads screen.',
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return HelpSectionWidget(
      title: 'Contact Support',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need more help?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact our support team for personalized assistance.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _contactSupport(),
                        icon: const Icon(Icons.email),
                        label: const Text('Email Support'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _provideFeedback(),
                        icon: const Icon(Icons.feedback),
                        label: const Text('Feedback'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _speakVoiceCommands() async {
    await _ttsService.speak(
      'Voice commands are organized into categories: Navigation commands like go home, open map, show tours. Playback commands like play, pause, stop, next, previous. Map commands like where am I, zoom in, zoom out, find nearby places. You can use these commands from any screen.',
    );
  }

  Future<void> _speakGettingStarted() async {
    await _ttsService.speak(
      'Getting started with Echo Guide: First, ensure location and microphone permissions are granted. Use voice commands or tap to navigate between screens. Download tours for offline use from the Discover screen. Use the map to explore locations with audio narration. Access your downloaded content from the Downloads screen.',
    );
  }

  Future<void> _speakAccessibilityFeatures() async {
    await _ttsService.speak(
      'Echo Guide is designed with accessibility in mind. Features include: Full voice navigation between all screens, Text-to-speech for all content, Voice commands for all major functions, High contrast themes, Large text support, Screen reader compatibility, Offline content access, and Real-time audio narration for maps.',
    );
  }

  void _contactSupport() {
    _ttsService.speak(
      'Opening email support. You can send us your questions or issues.',
    );
    // Implement email support functionality
  }

  void _provideFeedback() {
    _ttsService.speak(
      'Opening feedback form. We value your input to improve Echo Guide.',
    );
    // Implement feedback functionality
  }
}
