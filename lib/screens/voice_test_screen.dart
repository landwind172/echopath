import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../services/dependency_injection.dart';

class VoiceTestScreen extends StatefulWidget {
  const VoiceTestScreen({super.key});

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final TTSService _ttsService = getIt<TTSService>();
  final VoiceService _voiceService = getIt<VoiceService>();

  String _status = 'Ready';
  String _lastCommand = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _checkVoiceStatus();
  }

  Future<void> _checkVoiceStatus() async {
    setState(() {
      _status = 'Checking voice service...';
    });

    try {
      final isInitialized = _voiceService.isInitialized;
      final isListening = _voiceService.isListening;

      setState(() {
        _status = isInitialized
            ? 'Voice service ready'
            : 'Voice service not initialized';
        _isListening = isListening;
      });

      if (isInitialized) {
        await _ttsService.speak(
          'Voice test screen loaded. Say "test voice" to verify recognition.',
        );
      } else {
        await _ttsService.speak(
          'Voice service is not initialized. Please check permissions.',
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _testVoiceCommand(String command) async {
    setState(() {
      _lastCommand = command;
      _status = 'Testing: $command';
    });

    try {
      // Prepare all the speech texts that need to be spoken
      List<String> speechTexts = ['Testing command: $command'];

      // Simulate command processing
      await Future.delayed(Duration(milliseconds: 1000));

      if (command.toLowerCase().contains('map')) {
        speechTexts.add('Would navigate to map screen');
      } else if (command.toLowerCase().contains('discover')) {
        speechTexts.add('Would navigate to discover screen');
      } else if (command.toLowerCase().contains('downloads')) {
        speechTexts.add('Would navigate to downloads screen');
      } else if (command.toLowerCase().contains('help')) {
        speechTexts.add('Would navigate to help screen');
      } else if (command.toLowerCase().contains('home')) {
        speechTexts.add('Would navigate to home screen');
      } else if (command.toLowerCase().contains('test')) {
        speechTexts.add('Voice recognition test successful!');
      } else {
        speechTexts.add('Command not recognized: $command');
      }

      // Use sequential speech to prevent interruptions
      await _ttsService.speakSequential(speechTexts);

      setState(() {
        _status = 'Command processed: $command';
      });
    } catch (e) {
      setState(() {
        _status = 'Error processing command: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Navigation Test'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _checkVoiceStatus),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Listening: ${_isListening ? "Yes" : "No"}'),
                    Text(
                      'Initialized: ${_voiceService.isInitialized ? "Yes" : "No"}',
                    ),
                    Text('Language: ${_voiceService.currentLanguage}'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Last Command Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Command:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_lastCommand.isEmpty ? 'None' : _lastCommand),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Test Commands
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Commands:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                                'test voice',
                                'open map',
                                'go to discover',
                                'show downloads',
                                'help',
                                'home',
                              ]
                              .map(
                                (command) => ElevatedButton(
                                  onPressed: () => _testVoiceCommand(command),
                                  child: Text(command),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Voice Navigation Provider Status
            Consumer<VoiceNavigationProvider>(
              builder: (context, provider, child) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Navigation Provider:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Enabled: ${provider.isVoiceNavigationEnabled}'),
                        Text('Listening: ${provider.isListening}'),
                        Text('Initializing: ${provider.isInitializing}'),
                        Text('Last Command: ${provider.lastCommand}'),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => provider.toggleVoiceNavigation(),
                              child: Text(
                                provider.isVoiceNavigationEnabled
                                    ? 'Disable'
                                    : 'Enable',
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  provider.restartVoiceNavigation(),
                              child: Text('Restart'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 16),

            // Instructions
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Ensure microphone permissions are granted'),
                    Text('2. Click "Enable" to start voice navigation'),
                    Text('3. Try saying: "open map", "go to discover", etc.'),
                    Text('4. Use test buttons to simulate commands'),
                    Text('5. Check the diagnostic screen for detailed info'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
