import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressBar(context, audioProvider),
              const SizedBox(height: 16),
              _buildControls(context, audioProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioProvider audioProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(audioProvider.position),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _formatDuration(audioProvider.duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: audioProvider.duration.inMilliseconds > 0
              ? audioProvider.position.inMilliseconds / audioProvider.duration.inMilliseconds
              : 0.0,
          backgroundColor: Theme.of(context).dividerColor,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, AudioProvider audioProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: audioProvider.playlist.isNotEmpty
              ? audioProvider.playPrevious
              : null,
          icon: const Icon(Icons.skip_previous),
          iconSize: 32,
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else if (audioProvider.isPaused) {
                audioProvider.resume();
              }
            },
            icon: Icon(
              audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            iconSize: 32,
          ),
        ),
        IconButton(
          onPressed: audioProvider.playlist.isNotEmpty
              ? audioProvider.playNext
              : null,
          icon: const Icon(Icons.skip_next),
          iconSize: 32,
        ),
        IconButton(
          onPressed: audioProvider.stop,
          icon: const Icon(Icons.stop),
          iconSize: 32,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}