import 'package:json_annotation/json_annotation.dart';

part 'user_preferences_model.g.dart';

@JsonSerializable()
class UserPreferencesModel {
  final double speechRate;
  final double pitch;
  final String language;
  final bool voiceNavigationEnabled;
  final bool locationServicesEnabled;
  final double volume;
  final bool vibrationEnabled;
  final String preferredMapType;
  final bool autoPlayEnabled;
  final DateTime lastUpdated;

  UserPreferencesModel({
    required this.speechRate,
    required this.pitch,
    required this.language,
    required this.voiceNavigationEnabled,
    required this.locationServicesEnabled,
    required this.volume,
    required this.vibrationEnabled,
    required this.preferredMapType,
    required this.autoPlayEnabled,
    required this.lastUpdated,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferencesModelToJson(this);

  factory UserPreferencesModel.fromMap(Map<String, dynamic> map) {
    return UserPreferencesModel(
      speechRate: (map['speechRate'] ?? 0.5).toDouble(),
      pitch: (map['pitch'] ?? 1.0).toDouble(),
      language: map['language'] ?? 'en-US',
      voiceNavigationEnabled: map['voiceNavigationEnabled'] ?? true,
      locationServicesEnabled: map['locationServicesEnabled'] ?? true,
      volume: (map['volume'] ?? 1.0).toDouble(),
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      preferredMapType: map['preferredMapType'] ?? 'normal',
      autoPlayEnabled: map['autoPlayEnabled'] ?? true,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'speechRate': speechRate,
      'pitch': pitch,
      'language': language,
      'voiceNavigationEnabled': voiceNavigationEnabled,
      'locationServicesEnabled': locationServicesEnabled,
      'volume': volume,
      'vibrationEnabled': vibrationEnabled,
      'preferredMapType': preferredMapType,
      'autoPlayEnabled': autoPlayEnabled,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  UserPreferencesModel copyWith({
    double? speechRate,
    double? pitch,
    String? language,
    bool? voiceNavigationEnabled,
    bool? locationServicesEnabled,
    double? volume,
    bool? vibrationEnabled,
    String? preferredMapType,
    bool? autoPlayEnabled,
    DateTime? lastUpdated,
  }) {
    return UserPreferencesModel(
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      language: language ?? this.language,
      voiceNavigationEnabled: voiceNavigationEnabled ?? this.voiceNavigationEnabled,
      locationServicesEnabled: locationServicesEnabled ?? this.locationServicesEnabled,
      volume: volume ?? this.volume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      preferredMapType: preferredMapType ?? this.preferredMapType,
      autoPlayEnabled: autoPlayEnabled ?? this.autoPlayEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static UserPreferencesModel get defaultPreferences {
    return UserPreferencesModel(
      speechRate: 0.5,
      pitch: 1.0,
      language: 'en-US',
      voiceNavigationEnabled: true,
      locationServicesEnabled: true,
      volume: 1.0,
      vibrationEnabled: true,
      preferredMapType: 'normal',
      autoPlayEnabled: true,
      lastUpdated: DateTime.now(),
    );
  }
}