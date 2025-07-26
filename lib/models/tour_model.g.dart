// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tour_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TourModel _$TourModelFromJson(Map<String, dynamic> json) => TourModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  imageUrl: json['imageUrl'] as String,
  audioFiles: (json['audioFiles'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  points: (json['points'] as List<dynamic>)
      .map((e) => TourPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  duration: (json['duration'] as num).toDouble(),
  difficulty: json['difficulty'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TourModelToJson(TourModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'imageUrl': instance.imageUrl,
  'audioFiles': instance.audioFiles,
  'points': instance.points,
  'duration': instance.duration,
  'difficulty': instance.difficulty,
  'tags': instance.tags,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

TourPoint _$TourPointFromJson(Map<String, dynamic> json) => TourPoint(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  audioFile: json['audioFile'] as String,
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$TourPointToJson(TourPoint instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'audioFile': instance.audioFile,
  'order': instance.order,
};
