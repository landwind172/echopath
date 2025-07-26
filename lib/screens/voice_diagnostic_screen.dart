import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../services/dependency_injection.dart';

class VoiceDiagnosticScreen extends StatefulWidget {
  const VoiceDiagnosticScreen({super.key});

  @override
  State<VoiceDiagnosticScreen> createState() => _VoiceDiagnosticScreenState();
}

class _VoiceDiagnosticScreenState extends State<VoiceDiagnosticScreen>
    with WidgetsBindingObserver {
  final TTSService _ttsService = getIt<TTSService>();
  final VoiceService _voiceService = getIt<VoiceService>();

  String _status = 'Initializing...';
  String _lastCommand = '';
  bool _isListening = false;
  bool _isInitialized = false;
  String _permissionStatus = 'Checking...';
  String _languageStatus = 'Checking...';
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runDiagnostics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAllVoiceServices();
    super.dispose();
  }

  void _stopAllVoiceServices() {
    try {
      // Stop any ongoing voice listening when disposing
      if (_isListening) {
        _voiceService.stopListening();
      }
      // Stop any ongoing TTS
      _ttsService.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping voice services during dispose: $e');
      }
    }
  }

  Future<void> _testGlobalVoiceCommands() async {
    setState(() {
      _status = 'Testing global voice commands...';
    });

    try {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );

      // Test basic global commands
      final testCommands = [
        'go home',
        'open map',
        'show tours',
        'downloads',
        'get help',
        'voice commands',
        'test voice',
      ];

      for (final command in testCommands) {
        setState(() {
          _lastCommand = command;
          _status = 'Testing global command: $command';
        });

        await Future.delayed(Duration(milliseconds: 500));

        // Simulate the command being processed
        if (kDebugMode) {
          print('Testing global command: $command');
        }
        _addTestResult('Global: $command', 'TESTED');
      }

      setState(() {
        _status = 'Global command tests completed!';
      });
    } catch (e) {
      if (kDebugMode) {
        print('Global command test error: $e');
      }
      _addTestResult('Global Commands', 'ERROR: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Stop voice listening when app goes to background
        if (_isListening) {
          _voiceService.stopListening();
          setState(() {
            _isListening = false;
          });
        }
        break;
      case AppLifecycleState.resumed:
        // Optionally restart diagnostics when app comes back to foreground
        break;
      default:
        break;
    }
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _status = 'Running diagnostics...';
      _testResults.clear();
    });

    // Test 1: Check permissions
    await _testPermissions();

    // Test 2: Check voice service initialization
    await _testVoiceService();

    // Test 3: Check TTS service
    await _testTTSService();

    // Test 4: Test navigation commands
    await _testNavigationCommands();

    // Test 5: Test voice recognition
    await _testVoiceRecognition();

    setState(() {
      _status = 'Diagnostics completed!';
    });
  }

  Future<void> _testPermissions() async {
    setState(() {
      _status = 'Testing microphone permissions...';
    });

    try {
      final status = await Permission.microphone.status;
      if (kDebugMode) {
        print('Microphone permission: $status');
      }

      if (status.isDenied) {
        final result = await Permission.microphone.request();
        if (kDebugMode) {
          print('Permission request result: $result');
        }
        setState(() {
          _permissionStatus = 'Requested: $result';
        });
      } else {
        setState(() {
          _permissionStatus = 'Status: $status';
        });
      }

      _addTestResult('Permissions', status.isGranted ? 'PASS' : 'FAIL');
    } catch (e) {
      if (kDebugMode) {
        print('Permission test error: $e');
      }
      setState(() {
        _permissionStatus = 'Error: $e';
      });
      _addTestResult('Permissions', 'ERROR: $e');
    }
  }

  Future<void> _testVoiceService() async {
    setState(() {
      _status = 'Testing voice service...';
    });

    try {
      final isInitialized = _voiceService.isInitialized;
      final currentLanguage = _voiceService.currentLanguage;

      if (kDebugMode) {
        print('Voice service initialized: $isInitialized');
      }
      if (kDebugMode) {
        print('Current language: $currentLanguage');
      }

      setState(() {
        _isInitialized = isInitialized;
        _languageStatus = 'Language: $currentLanguage';
      });

      _addTestResult('Voice Service', isInitialized ? 'PASS' : 'FAIL');
    } catch (e) {
      if (kDebugMode) {
        print('Voice service test error: $e');
      }
      _addTestResult('Voice Service', 'ERROR: $e');
    }
  }

  Future<void> _testTTSService() async {
    setState(() {
      _status = 'Testing TTS service...';
    });

    try {
      await _ttsService.speak('Testing text to speech service');
      _addTestResult('TTS Service', 'PASS');
    } catch (e) {
      if (kDebugMode) {
        print('TTS test error: $e');
      }
      _addTestResult('TTS Service', 'ERROR: $e');
    }
  }

  Future<void> _testNavigationCommands() async {
    setState(() {
      _status = 'Testing navigation commands...';
    });

    final testCommands = [
      'open map',
      'go to discover',
      'show downloads',
      'help',
      'home',
    ];

    for (final command in testCommands) {
      setState(() {
        _lastCommand = command;
        _status = 'Testing command: $command';
      });

      await Future.delayed(Duration(milliseconds: 1000));

      // Simulate command processing
      if (kDebugMode) {
        print('Testing command: $command');
      }
      _addTestResult('Command: $command', 'TESTED');
    }
  }

  Future<void> _testVoiceRecognition() async {
    setState(() {
      _status = 'Testing voice recognition...';
    });

    try {
      // Test if voice service can start listening
      if (_voiceService.isInitialized) {
        await _voiceService.startListening();
        setState(() {
          _isListening = _voiceService.isListening;
        });

        await Future.delayed(Duration(seconds: 3));

        // Ensure we stop listening even if there's an error
        try {
          await _voiceService.stopListening();
        } catch (stopError) {
          if (kDebugMode) {
            print('Error stopping voice listening: $stopError');
          }
        }

        setState(() {
          _isListening = _voiceService.isListening;
        });

        _addTestResult('Voice Recognition', 'PASS');
      } else {
        _addTestResult('Voice Recognition', 'FAIL: Service not initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Voice recognition test error: $e');
      }
      // Ensure we try to stop listening even if there was an error
      try {
        if (_isListening) {
          await _voiceService.stopListening();
          setState(() {
            _isListening = false;
          });
        }
      } catch (stopError) {
        if (kDebugMode) {
          print('Error stopping voice listening after test error: $stopError');
        }
      }
      _addTestResult('Voice Recognition', 'ERROR: $e');
    }
  }

  void _addTestResult(String test, String result) {
    setState(() {
      _testResults.add('$test: $result');
    });
  }

  Future<void> _testManualCommand(String command) async {
    setState(() {
      _lastCommand = command;
      _status = 'Testing manual command: $command';
    });

    try {
      // Prepare all the speech texts that need to be spoken
      List<String> speechTexts = ['Testing command: $command'];

      // Add navigation response based on command
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
      } else {
        speechTexts.add('Command not recognized: $command');
      }

      // Use sequential speech to prevent interruptions
      await _ttsService.speakSequential(speechTexts);

      _addTestResult('Manual: $command', 'PROCESSED');
    } catch (e) {
      if (kDebugMode) {
        print('Manual command test error: $e');
      }
      _addTestResult('Manual: $command', 'ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Navigation Diagnostics'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _runDiagnostics),
        ],
      ),
      body: SingleChildScrollView(
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
                    Text('Initialized: ${_isInitialized ? "Yes" : "No"}'),
                    Text('Permission: $_permissionStatus'),
                    Text('Language: $_languageStatus'),
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

            // Test Results Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._testResults.map(
                      (result) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(result),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Manual Test Commands
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Test Commands:',
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
                                'open map',
                                'go to discover',
                                'show downloads',
                                'help',
                                'home',
                              ]
                              .map(
                                (command) => ElevatedButton(
                                  onPressed: () => _testManualCommand(command),
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
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    provider.toggleVoiceNavigation(),
                                child: Text(
                                  provider.isVoiceNavigationEnabled
                                      ? 'Disable Voice Navigation'
                                      : 'Enable Voice Navigation',
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    provider.forceRestartVoiceNavigation(),
                                child: Text('Force Restart'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _testGlobalVoiceCommands(),
                                child: Text('Test Global Commands'),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _voiceService.testGlobalVoiceNavigation(),
                                child: Text('Test Voice System'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
