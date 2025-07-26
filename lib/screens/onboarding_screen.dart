import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

import '../services/tts_service.dart';
import '../services/dependency_injection.dart';
import '../core/routes.dart';
import '../widgets/voice_command_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TTSService _ttsService = getIt<TTSService>();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Echo Guide',
      description:
          'Your voice-powered tour companion that makes exploring accessible and engaging for everyone.',
      icon: Icons.mic,
      voiceText:
          'Welcome to Echo Guide. I am your voice-powered tour companion, designed to make exploring the world accessible and engaging for everyone.',
    ),
    OnboardingPage(
      title: 'Voice Navigation',
      description:
          'Navigate through the app using simple voice commands. Say "go home", "open map", or "show tours" to move between screens.',
      icon: Icons.record_voice_over,
      voiceText:
          'Voice navigation is your key to seamless app control. Simply say commands like go home, open map, or show tours to navigate between screens effortlessly.',
    ),
    OnboardingPage(
      title: 'Interactive Maps',
      description:
          'Explore locations with real-time audio narration. Get detailed descriptions of nearby points of interest.',
      icon: Icons.map,
      voiceText:
          'Our interactive maps provide real-time audio narration as you explore. You will receive detailed descriptions of nearby points of interest and can navigate with confidence.',
    ),
    OnboardingPage(
      title: 'Offline Content',
      description:
          'Download tours for offline use. Enjoy guided experiences even without an internet connection.',
      icon: Icons.download,
      voiceText:
          'Download tours for offline use and enjoy guided experiences even without an internet connection. Your adventures are not limited by connectivity.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _speakCurrentPage();
  }

  Future<void> _speakCurrentPage() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _ttsService.speak(_pages[_currentPage].voiceText);

    // Automatically advance to next page after 7 seconds
    if (mounted) {
      await Future.delayed(const Duration(seconds: 7));
      if (mounted) {
        final appStateProvider = Provider.of<AppStateProvider>(
          context,
          listen: false,
        );
        if (appStateProvider.autoTransitionEnabled) {
          if (_currentPage < _pages.length - 1) {
            _nextPage();
          } else {
            _completeOnboarding();
          }
        }
      }
    }
  }

  Future<void> _speakCurrentPageWithoutAutoAdvance() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _ttsService.speak(_pages[_currentPage].voiceText);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _currentPage++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _speakCurrentPage();
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _speakCurrentPageWithoutAutoAdvance();
    }
  }

  void _completeOnboarding() {
    final appStateProvider = Provider.of<AppStateProvider>(
      context,
      listen: false,
    );
    appStateProvider.setFirstLaunchComplete();

    _ttsService.speak(
      'Onboarding complete. Welcome to Echo Guide. You can now explore all the features using voice commands or the navigation buttons.',
    );

    // Automatically transition to home screen after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _speakCurrentPage();
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          VoiceCommandButton(
            onPressed: () => _ttsService.speak(page.voiceText),
            tooltip: 'Repeat information',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _previousPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final String voiceText;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.voiceText,
  });
}
