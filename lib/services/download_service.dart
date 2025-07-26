import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/tour_model.dart';

class DownloadService extends ChangeNotifier {
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadingTours = {};
  final Set<String> _downloadedTours = {};

  Map<String, double> get downloadProgress => _downloadProgress;
  Set<String> get downloadingTours => _downloadingTours;
  Set<String> get downloadedTours => _downloadedTours;

  Future<void> downloadTour(TourModel tour) async {
    if (_downloadingTours.contains(tour.id)) return;

    _downloadingTours.add(tour.id);
    _downloadProgress[tour.id] = 0.0;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final tourDirectory = Directory('${directory.path}/tours/${tour.id}');
      
      if (!await tourDirectory.exists()) {
        await tourDirectory.create(recursive: true);
      }

      // Download audio files
      double totalFiles = tour.audioFiles.length.toDouble();
      double downloadedFiles = 0;

      for (String audioUrl in tour.audioFiles) {
        await _downloadFile(audioUrl, tourDirectory.path);
        downloadedFiles++;
        _downloadProgress[tour.id] = downloadedFiles / totalFiles;
        notifyListeners();
      }

      // Save tour metadata
      final metadataFile = File('${tourDirectory.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode(tour.toJson()));

      _downloadedTours.add(tour.id);
      _downloadingTours.remove(tour.id);
      _downloadProgress.remove(tour.id);
      notifyListeners();

    } catch (e) {
      debugPrint('Download tour error: $e');
      _downloadingTours.remove(tour.id);
      _downloadProgress.remove(tour.id);
      notifyListeners();
    }
  }

  Future<void> _downloadFile(String url, String directoryPath) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final fileName = url.split('/').last;
        final file = File('$directoryPath/$fileName');
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Download file error: $e');
    }
  }

  Future<void> deleteTour(String tourId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tourDirectory = Directory('${directory.path}/tours/$tourId');
      
      if (await tourDirectory.exists()) {
        await tourDirectory.delete(recursive: true);
      }

      _downloadedTours.remove(tourId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete tour error: $e');
    }
  }

  Future<bool> isTourDownloaded(String tourId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tourDirectory = Directory('${directory.path}/tours/$tourId');
      return await tourDirectory.exists();
    } catch (e) {
      debugPrint('Check tour downloaded error: $e');
      return false;
    }
  }

  Future<List<String>> getDownloadedAudioFiles(String tourId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tourDirectory = Directory('${directory.path}/tours/$tourId');
      
      if (!await tourDirectory.exists()) return [];

      final files = await tourDirectory.list().toList();
      return files
          .where((file) => file.path.endsWith('.mp3') || file.path.endsWith('.wav'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      debugPrint('Get downloaded audio files error: $e');
      return [];
    }
  }

  Future<void> loadDownloadedTours() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final toursDirectory = Directory('${directory.path}/tours');
      
      if (!await toursDirectory.exists()) return;

      final tourDirectories = await toursDirectory.list().toList();
      for (var tourDir in tourDirectories) {
        if (tourDir is Directory) {
          final tourId = tourDir.path.split('/').last;
          _downloadedTours.add(tourId);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load downloaded tours error: $e');
    }
  }
}