import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/voice_service.dart';
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
    extends State<GlobalVoiceNavigationWidget> {
  final VoiceService _voiceService = getIt<VoiceService>();

  @override
  void initState() {
    super.initState();
    // Ensure voice service is initialized
    _voiceService.addListener(_onVoiceServiceChanged);
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChanged);
    super.dispose();
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
            if (widget.showVoiceStatus &&
                voiceProvider.isVoiceNavigationEnabled)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: voiceProvider.isListening
                        ? Colors.green.withValues(alpha: 0.9)
                        : Colors.grey.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        voiceProvider.isListening ? Icons.mic : Icons.mic_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        voiceProvider.isListening ? 'Listening' : 'Voice Ready',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Global voice command help button
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'global_voice_help',
                onPressed: () => _showGlobalVoiceCommands(context),
                backgroundColor: Colors.blue,
                child: const Icon(Icons.help, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGlobalVoiceCommands(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Global Voice Commands',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'These commands work from any screen:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildCommandItem('"Go home" or "Home"', 'Navigate to home screen'),
            _buildCommandItem('"Open map" or "Map"', 'Open interactive map'),
            _buildCommandItem(
              '"Show tours" or "Discover"',
              'Open discover tours',
            ),
            _buildCommandItem(
              '"Downloads" or "Offline"',
              'Open offline library',
            ),
            _buildCommandItem('"Get help" or "Help"', 'Open help and support'),
            _buildCommandItem('"Voice commands"', 'Hear available commands'),
            _buildCommandItem('"Test voice"', 'Test voice recognition'),
            _buildCommandItem('"Stop talking"', 'Stop current speech'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandItem(String command, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Expanded(flex: 3, child: Text(description)),
        ],
      ),
    );
  }
}
