import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tour_model.g.dart';

@JsonSerializable()
class TourModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> audioFiles;
  final List<TourPoint> points;
  final double duration; // in minutes
  final String difficulty;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for Buganda tours
  final String? distance;
  final String? accessibility;
  final String? highlights;
  final String? category;
  final String? audioDescription;
  final List<String>? voiceCommands;

  TourModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.audioFiles,
    required this.points,
    required this.duration,
    required this.difficulty,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.distance,
    this.accessibility,
    this.highlights,
    this.category,
    this.audioDescription,
    this.voiceCommands,
  });

  factory TourModel.fromJson(Map<String, dynamic> json) =>
      _$TourModelFromJson(json);

  Map<String, dynamic> toJson() => _$TourModelToJson(this);

  factory TourModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TourModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      audioFiles: List<String>.from(data['audioFiles'] ?? []),
      points:
          (data['points'] as List<dynamic>?)
              ?.map((point) => TourPoint.fromJson(point))
              .toList() ??
          [],
      duration: (data['duration'] ?? 0).toDouble(),
      difficulty: data['difficulty'] ?? 'Easy',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      distance: data['distance'],
      accessibility: data['accessibility'],
      highlights: data['highlights'],
      category: data['category'],
      audioDescription: data['audioDescription'],
      voiceCommands: data['voiceCommands'] != null
          ? List<String>.from(data['voiceCommands'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'audioFiles': audioFiles,
      'points': points.map((point) => point.toJson()).toList(),
      'duration': duration,
      'difficulty': difficulty,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'distance': distance,
      'accessibility': accessibility,
      'highlights': highlights,
      'category': category,
      'audioDescription': audioDescription,
      'voiceCommands': voiceCommands,
    };
  }
}

@JsonSerializable()
class TourPoint {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String audioFile;
  final int order;

  TourPoint({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.audioFile,
    required this.order,
  });

  factory TourPoint.fromJson(Map<String, dynamic> json) =>
      _$TourPointFromJson(json);

  Map<String, dynamic> toJson() => _$TourPointToJson(this);
}
