import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/tts_service.dart';
import '../services/download_service.dart';
import '../services/dependency_injection.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/voice_status_widget.dart';
import '../widgets/downloaded_tour_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final TTSService _ttsService = getIt<TTSService>();
  final DownloadService _downloadService = getIt<DownloadService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
      // Update voice navigation context
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.updateCurrentScreen('downloads');
    });
  }

  Future<void> _initializeScreen() async {
    await _ttsService.speakWithPriority(
      'Downloads screen loaded. Voice navigation active. Access your offline content and manage downloads. Global voice commands are available.',
    );
    
    await _downloadService.loadDownloadedTours();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downloads'),
        actions: const [VoiceStatusWidget()],
      ),
      body: Consumer<DownloadService>(
        builder: (context, downloadService, child) {
          if (downloadService.downloadedTours.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: downloadService.downloadedTours.length,
            itemBuilder: (context, index) {
              final tourId = downloadService.downloadedTours.elementAt(index);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DownloadedTourCard(
                  tourId: tourId,
                  onPlay: () => _playTour(tourId),
                  onDelete: () => _deleteTour(tourId),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 3),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Downloads Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Download tours from the Discover screen to access them offline',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/discover',
                (route) => false,
              );
            },
            child: const Text('Browse Tours'),
          ),
        ],
      ),
    );
  }

  void _playTour(String tourId) {
    _ttsService.speakWithPriority('Playing downloaded tour: $tourId');
  }

  void _deleteTour(String tourId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tour'),
        content: Text('Are you sure you want to delete this tour?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadService.deleteTour(tourId);
              _ttsService.speakWithPriority('Tour deleted successfully');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}