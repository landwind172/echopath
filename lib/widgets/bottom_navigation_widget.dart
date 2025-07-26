import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/dependency_injection.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final TTSService ttsService = getIt<TTSService>();

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index, ttsService),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Discover',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.download),
          label: 'Downloads',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.help),
          label: 'Help',
        ),
      ],
    );
  }

  void _onItemTapped(BuildContext context, int index, TTSService ttsService) {
    if (index == currentIndex) return;

    String route;
    String screenName;

    switch (index) {
      case 0:
        route = '/home';
        screenName = 'Home';
        break;
      case 1:
        route = '/map';
        screenName = 'Map';
        break;
      case 2:
        route = '/discover';
        screenName = 'Discover';
        break;
      case 3:
        route = '/downloads';
        screenName = 'Downloads';
        break;
      case 4:
        route = '/help-support';
        screenName = 'Help and Support';
        break;
      default:
        return;
    }

    ttsService.speakWithPriority('Navigating to $screenName screen');
    
    // Always use pushNamedAndRemoveUntil for seamless navigation
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }
}