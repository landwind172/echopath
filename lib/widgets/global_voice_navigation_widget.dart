import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../services/dependency_injection.dart';

class GlobalVoiceNavigationWidget extends StatefulWidget {
  final Widget child;
  final bool showVoiceStatus;

  const GlobalVoiceNavigationWidget({
    super.key,
    required this.child,
    this.showVoiceStatus = true,
  });

  @override
  State<GlobalVoiceNavigationWidget> createState() =>
      _GlobalVoiceNavigationWidgetState();
}

class _GlobalVoiceNavigationWidgetState
    extends State<GlobalVoiceNavigationWidget> with WidgetsBindingObserver {
  final VoiceService _voiceService = getIt<VoiceService>();
  final TTSService _ttsService = getIt<TTSService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voiceService.addListener(_onVoiceServiceChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceService.removeListener(_onVoiceServiceChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pause voice listening when app goes to background
        _voiceService.stopContinuousListening();
        break;
      case AppLifecycleState.resumed:
        // Resume voice listening when app comes back to foreground
        if (mounted) {
          final voiceProvider = Provider.of<VoiceNavigationProvider>(
            context,
            listen: false,
          );
          if (voiceProvider.isVoiceNavigationEnabled) {
            _voiceService.startContinuousListening();
          }
        }
        break;
      default:
        break;
    }
  }

  void _onVoiceServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceNavigationProvider>(
      builder: (context, voiceProvider, child) {
        return Stack(
          children: [
            widget.child,
            
            // Enhanced voice status indicator
            if (widget.showVoiceStatus)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => _showVoiceStatus(context, voiceProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(voiceProvider),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(voiceProvider),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(voiceProvider),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Global voice help button
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'global_voice_help',
                onPressed: () => _showGlobalVoiceCommands(context),
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.help_outline, color: Colors.white),
              ),
            ),

            // Quick voice test button
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'voice_test',
                mini: true,
                onPressed: () => _testVoiceCommand(),
                backgroundColor: Colors.green,
                child: const Icon(Icons.mic, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(VoiceNavigationProvider provider) {
    if (!provider.isVoiceNavigationEnabled) return Colors.red;
    if (provider.isInitializing) return Colors.orange;
    if (provider.isListening) return Colors.green;
    return Colors.blue;
  }

  IconData _getStatusIcon(VoiceNavigationProvider provider) {
    if (!provider.isVoiceNavigationEnabled) return Icons.mic_off;
    if (provider.isInitializing) return Icons.hourglass_empty;
    if (provider.isListening) return Icons.mic;
    return Icons.mic_none;
  }

  String _getStatusText(VoiceNavigationProvider provider) {
    if (!provider.isVoiceNavigationEnabled) return 'VOICE OFF';
    if (provider.isInitializing) return 'STARTING';
    if (provider.isListening) return 'LISTENING';
    return 'READY';
  }

  void _showVoiceStatus(BuildContext context, VoiceNavigationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Navigation Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Enabled', provider.isVoiceNavigationEnabled ? 'Yes' : 'No'),
            _buildStatusRow('Listening', provider.isListening ? 'Yes' : 'No'),
            _buildStatusRow('Initializing', provider.isInitializing ? 'Yes' : 'No'),
            _buildStatusRow('Language', provider.currentLanguage),
            if (provider.lastCommand.isNotEmpty)
              _buildStatusRow('Last Command', provider.lastCommand),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!provider.isVoiceNavigationEnabled)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                provider.forceRestartVoiceNavigation();
              },
              child: const Text('Restart Voice'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label:')),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showGlobalVoiceCommands(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Global Voice Commands',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'These commands work from any screen in the app:',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCommandSection('Navigation Commands', [
                      _buildCommandItem('"Go home" or "Home"', 'Navigate to home screen'),
                      _buildCommandItem('"Open map" or "Map"', 'Open interactive map'),
                      _buildCommandItem('"Show tours" or "Discover"', 'Browse available tours'),
                      _buildCommandItem('"Downloads" or "Offline"', 'Access offline content'),
                      _buildCommandItem('"Get help" or "Help"', 'Open help and support'),
                    ]),
                    const SizedBox(height: 20),
                    _buildCommandSection('Utility Commands', [
                      _buildCommandItem('"Voice commands"', 'Hear all available commands'),
                      _buildCommandItem('"Test voice"', 'Test voice recognition'),
                      _buildCommandItem('"Stop talking"', 'Stop current speech'),
                      _buildCommandItem('"Repeat"', 'Repeat last information'),
                    ]),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips for Better Recognition:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('• Speak clearly and at normal pace'),
                          Text('• Use natural language variations'),
                          Text('• Wait for confirmation before next command'),
                          Text('• Commands work from any screen'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _testVoiceCommand(),
                    child: const Text('Test Voice'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandSection(String title, List<Widget> commands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...commands,
      ],
    );
  }

  Widget _buildCommandItem(String command, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              command,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(description),
          ),
        ],
      ),
    );
  }

  Future<void> _testVoiceCommand() async {
    await _ttsService.speakWithPriority(
      'Voice navigation test: Global commands are active and working. Try saying "go home", "open map", or "show tours".'
    );
  }
}