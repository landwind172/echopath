import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_navigation_provider.dart';

class VoiceStatusWidget extends StatelessWidget {
  const VoiceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceNavigationProvider>(
      builder: (context, voiceProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show last command if available
            if (voiceProvider.lastCommand.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  voiceProvider.lastCommand,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            // Voice toggle button
            Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            onPressed: () => voiceProvider.toggleVoiceNavigation(),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                voiceProvider.isVoiceNavigationEnabled
                        ? (voiceProvider.isListening
                              ? Icons.mic
                              : Icons.mic_none)
                    : Icons.mic_off,
                key: ValueKey(voiceProvider.isVoiceNavigationEnabled),
                color: voiceProvider.isVoiceNavigationEnabled
                    ? (voiceProvider.isListening 
                        ? Colors.red 
                        : Theme.of(context).primaryColor)
                    : Colors.grey,
              ),
            ),
            tooltip: voiceProvider.isVoiceNavigationEnabled
                    ? 'Voice navigation enabled (${voiceProvider.isListening ? "Listening" : "Ready"})'
                : 'Voice navigation disabled',
          ),
            ),
          ],
        );
      },
    );
  }
}
