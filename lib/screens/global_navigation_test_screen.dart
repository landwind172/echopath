import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/voice_service.dart';
import '../services/dependency_injection.dart';

class GlobalNavigationTestScreen extends StatefulWidget {
  const GlobalNavigationTestScreen({super.key});

  @override
  State<GlobalNavigationTestScreen> createState() =>
      _GlobalNavigationTestScreenState();
}

class _GlobalNavigationTestScreenState
    extends State<GlobalNavigationTestScreen> {
  final VoiceService _voiceService = getIt<VoiceService>();
  String _status = 'Ready to test global navigation';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Voice Navigation Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testGlobalCommands,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<VoiceNavigationProvider>(
                      builder: (context, provider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Navigation: ${provider.isVoiceNavigationEnabled ? "Enabled" : "Disabled"}',
                            ),
                            Text(
                              'Listening: ${provider.isListening ? "Yes" : "No"}',
                            ),
                            Text(
                              'Last Command: ${provider.lastCommand.isEmpty ? "None" : provider.lastCommand}',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Global Commands Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global Voice Commands:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Try saying these commands from any screen:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildCommandItem(
                      '"Go home" or "Home"',
                      'Navigate to home screen',
                    ),
                    _buildCommandItem(
                      '"Open map" or "Map"',
                      'Open interactive map',
                    ),
                    _buildCommandItem(
                      '"Show tours" or "Discover"',
                      'Open discover tours',
                    ),
                    _buildCommandItem(
                      '"Downloads" or "Offline"',
                      'Open offline library',
                    ),
                    _buildCommandItem(
                      '"Get help" or "Help"',
                      'Open help and support',
                    ),
                    _buildCommandItem(
                      '"Voice commands"',
                      'Hear available commands',
                    ),
                    _buildCommandItem('"Test voice"', 'Test voice recognition'),
                    _buildCommandItem('"Stop talking"', 'Stop current speech'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Global Navigation:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _testCommand('go home'),
                          child: const Text('Test: Go Home'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testCommand('open map'),
                          child: const Text('Test: Open Map'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testCommand('show tours'),
                          child: const Text('Test: Show Tours'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testCommand('downloads'),
                          child: const Text('Test: Downloads'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testCommand('get help'),
                          child: const Text('Test: Get Help'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testCommand('voice commands'),
                          child: const Text('Test: Voice Commands'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Make sure voice navigation is enabled\n'
                      '2. Speak any of the global commands clearly\n'
                      '3. The app should navigate to the requested screen\n'
                      '4. You can also use the test buttons to simulate commands\n'
                      '5. Global commands work from any screen in the app',
                    ),
                  ],
                ),
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

  Future<void> _testCommand(String command) async {
    setState(() {
      _status = 'Testing command: $command';
    });

    try {
      await _voiceService.handleGlobalVoiceCommand(command);
      setState(() {
        _status = 'Command executed: $command';
      });
    } catch (e) {
      setState(() {
        _status = 'Error executing command: $e';
      });
    }
  }

  Future<void> _testGlobalCommands() async {
    setState(() {
      _status = 'Testing global commands...';
    });

    final commands = [
      'go home',
      'open map',
      'show tours',
      'downloads',
      'get help',
    ];

    for (final command in commands) {
      await Future.delayed(const Duration(seconds: 2));
      await _testCommand(command);
    }

    setState(() {
      _status = 'Global command test completed';
    });
  }
}
