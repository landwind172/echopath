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
            // Show last command if available (shortened for better UI)
            if (voiceProvider.lastCommand.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  voiceProvider.lastCommand.length > 15 
                      ? '${voiceProvider.lastCommand.substring(0, 15)}...'
                      : voiceProvider.lastCommand,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Enhanced voice toggle button with status indicator
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                children: [
                  IconButton(
                    onPressed: () => voiceProvider.toggleVoiceNavigation(),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        voiceProvider.isVoiceNavigationEnabled
                            ? (voiceProvider.isListening
                                ? Icons.mic
                                : Icons.mic_none)
                            : Icons.mic_off,
                        key: ValueKey('${voiceProvider.isVoiceNavigationEnabled}_${voiceProvider.isListening}'),
                        color: voiceProvider.isVoiceNavigationEnabled
                            ? (voiceProvider.isListening 
                                ? Colors.green 
                                : Theme.of(context).primaryColor)
                            : Colors.grey,
                        size: 24,
                      ),
                    ),
                    tooltip: voiceProvider.isVoiceNavigationEnabled
                        ? (voiceProvider.isListening 
                            ? 'Voice navigation active - Listening'
                            : 'Voice navigation enabled - Ready')
                        : 'Voice navigation disabled - Tap to enable',
                  ),
                  
                  // Listening indicator
                  if (voiceProvider.isListening)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Initializing indicator
                  if (voiceProvider.isInitializing)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}