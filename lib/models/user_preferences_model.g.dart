// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreferencesModel _$UserPreferencesModelFromJson(
  Map<String, dynamic> json,
) => UserPreferencesModel(
  speechRate: (json['speechRate'] as num).toDouble(),
  pitch: (json['pitch'] as num).toDouble(),
  language: json['language'] as String,
  voiceNavigationEnabled: json['voiceNavigationEnabled'] as bool,
  locationServicesEnabled: json['locationServicesEnabled'] as bool,
  volume: (json['volume'] as num).toDouble(),
  vibrationEnabled: json['vibrationEnabled'] as bool,
  preferredMapType: json['preferredMapType'] as String,
  autoPlayEnabled: json['autoPlayEnabled'] as bool,
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$UserPreferencesModelToJson(
  UserPreferencesModel instance,
) => <String, dynamic>{
  'speechRate': instance.speechRate,
  'pitch': instance.pitch,
  'language': instance.language,
  'voiceNavigationEnabled': instance.voiceNavigationEnabled,
  'locationServicesEnabled': instance.locationServicesEnabled,
  'volume': instance.volume,
  'vibrationEnabled': instance.vibrationEnabled,
  'preferredMapType': instance.preferredMapType,
  'autoPlayEnabled': instance.autoPlayEnabled,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
};
