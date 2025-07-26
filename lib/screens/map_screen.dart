import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/location_provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/tts_service.dart';
import '../services/dependency_injection.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/voice_status_widget.dart';
import '../widgets/map_controls_widget.dart';
import 'dart:async'; // Added for Timer
import 'dart:math'; // Added for Random

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TTSService _ttsService = getIt<TTSService>();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isNavigating = false;
  String _currentNarration = '';
  final bool _isVoiceModeEnabled = true;
  double _currentZoom = 15.0;
  LatLng? _lastTappedLocation;
  bool _isSearchingNearby = false;
  final List<String> _recentCommands = [];
  String _currentSearchType = '';
  String? _selectedPlace; // Track selected place for better UX
  bool _isMapReady = false; // Track if map is ready for interactions

  // Enhanced accessibility features for blind users
  bool _isTourGuideMode = false; // Tour guide narration mode
  int _tourStepIndex = 0;
  List<Map<String, dynamic>> _tourRoute = [];
  bool _isAutoNarrationEnabled = true; // Automatic location descriptions
  Timer? _autoNarrationTimer;
  bool _isDetailedMode = true; // Detailed descriptions for blind users

  // Dynamic place discovery
  final List<Map<String, dynamic>> _dynamicPlaces = [];
  Timer? _dynamicPlaceUpdateTimer;

  // Enhanced location data for Buganda, Uganda
  final List<Map<String, dynamic>> _bugandaPlaces = [
    {
      'name': 'Kasubi Tombs',
      'type': 'historical',
      'position': const LatLng(0.3476, 32.5825),
      'description':
          'UNESCO World Heritage site and royal burial grounds of Buganda kings',
      'category': 'Historical Site',
      'rating': 4.5,
      'features': [
        'UNESCO Heritage',
        'Royal Tombs',
        'Traditional Architecture',
        'Cultural Tours',
      ],
    },
    {
      'name': 'Namugongo Martyrs Shrine',
      'type': 'religious',
      'position': const LatLng(0.3751, 32.6532),
      'description': 'Major pilgrimage site commemorating Christian martyrs',
      'category': 'Religious Site',
      'rating': 4.7,
      'features': [
        'Pilgrimage Site',
        'Religious Tours',
        'Historical Significance',
        'Annual Celebrations',
      ],
    },
    {
      'name': 'Lubiri Palace',
      'type': 'historical',
      'position': const LatLng(0.3011, 32.5511),
      'description': 'Official residence of the Kabaka of Buganda',
      'category': 'Royal Palace',
      'rating': 4.3,
      'features': [
        'Royal Residence',
        'Traditional Architecture',
        'Cultural Heritage',
        'Guided Tours',
      ],
    },
    {
      'name': 'Serena Hotel Kampala',
      'type': 'hotel',
      'position': const LatLng(0.3136, 32.5811),
      'description': 'Luxury hotel in the heart of Kampala',
      'category': 'Luxury Hotel',
      'rating': 4.6,
      'features': [
        '5-Star Service',
        'Conference Facilities',
        'Fine Dining',
        'City Views',
      ],
    },
    {
      'name': 'Sheraton Kampala Hotel',
      'type': 'hotel',
      'position': const LatLng(0.3176, 32.5856),
      'description': 'International hotel with modern amenities',
      'category': 'Business Hotel',
      'rating': 4.4,
      'features': [
        'Business Center',
        'Pool',
        'Multiple Restaurants',
        'Event Spaces',
      ],
    },
    {
      'name': 'Owino Market',
      'type': 'market',
      'position': const LatLng(0.3136, 32.5736),
      'description': 'Largest market in East Africa with diverse goods',
      'category': 'Traditional Market',
      'rating': 4.0,
      'features': [
        'Local Goods',
        'Traditional Crafts',
        'Fresh Produce',
        'Cultural Experience',
      ],
    },
    {
      'name': 'Nakasero Market',
      'type': 'market',
      'position': const LatLng(0.3186, 32.5811),
      'description': 'Fresh produce market with local fruits and vegetables',
      'category': 'Fresh Market',
      'rating': 4.2,
      'features': [
        'Fresh Produce',
        'Local Fruits',
        'Organic Options',
        'Daily Fresh Items',
      ],
    },
    {
      'name': 'Fang Fang Restaurant',
      'type': 'restaurant',
      'position': const LatLng(0.3156, 32.5831),
      'description': 'Popular Chinese restaurant in Kampala',
      'category': 'Chinese Cuisine',
      'rating': 4.3,
      'features': [
        'Authentic Chinese',
        'Vegetarian Options',
        'Takeaway Available',
        'Family Friendly',
      ],
    },
    {
      'name': 'Cafe Javas',
      'type': 'restaurant',
      'position': const LatLng(0.3166, 32.5841),
      'description': 'Local coffee chain with Ugandan specialties',
      'category': 'Cafe & Restaurant',
      'rating': 4.1,
      'features': [
        'Local Coffee',
        'Ugandan Cuisine',
        'Free WiFi',
        'Multiple Locations',
      ],
    },
    {
      'name': 'Ndere Cultural Centre',
      'type': 'tour',
      'position': const LatLng(0.3456, 32.6123),
      'description': 'Cultural center showcasing traditional music and dance',
      'category': 'Cultural Tours',
      'rating': 4.5,
      'features': [
        'Traditional Performances',
        'Cultural Workshops',
        'Music Shows',
        'Dance Lessons',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });

    // Listen for voice commands
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.addListener(_onVoiceCommandReceived);
    });
  }

  void _onVoiceCommandReceived() async {
    if (!mounted) return;

    try {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      if (voiceProvider.lastCommand.isNotEmpty) {
        await _handleMapVoiceCommands(voiceProvider.lastCommand);
        voiceProvider.clearLastCommand();
      }
    } catch (e) {
      debugPrint('Voice command error: $e');
    }
  }

  Future<void> _initializeMap() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    await _ttsService.speakWithPriority('''
Welcome to the Interactive Map for blind users. 
Voice navigation is active and optimized for accessibility.
You can start a guided tour by saying "start tour", 
explore locations with "find nearby places", 
or get directions with "navigate to" followed by a place name.
Dynamic place discovery is enabled - the map will automatically find health facilities, institutions, and landmarks near your location.
Say "help" to hear all available commands.
Automatic location descriptions are enabled for seamless navigation.
''');

    if (!mounted) return;

    if (locationProvider.currentPosition == null) {
      await locationProvider.getCurrentLocation();
    }

    if (locationProvider.currentPosition != null) {
      _addCurrentLocationMarker(locationProvider.currentPosition!);
      _centerMapOnCurrentLocation(locationProvider.currentPosition!);
      _addBugandaPlaceMarkers();

      final position = locationProvider.currentPosition!;
      await _speakLocationDetails(position, 'Your current location');

      // Start dynamic place discovery
      await _discoverDynamicPlaces(position);

      // Start auto-narration for blind users
      if (_isAutoNarrationEnabled) {
        _startAutoNarration();
      }

      // Start periodic dynamic place updates
      _startDynamicPlaceUpdates();
    } else {
      await _ttsService.speakWithPriority(
        'Unable to get your current location. Please check location permissions and try again. You can still explore the map using voice commands.',
      );
    }
  }

  void _addBugandaPlaceMarkers() {
    if (!mounted) return;

    setState(() {
      for (final place in _bugandaPlaces) {
        _markers.add(
          Marker(
            markerId: MarkerId(place['name']),
            position: place['position'],
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: '${place['category']} - Rating: ${place['rating']}/5',
            ),
            icon: _getMarkerIcon(place['type']),
            onTap: () => _onPlaceMarkerTapped(place),
          ),
        );
      }
    });
  }

  // Dynamic place discovery methods
  Future<void> _discoverDynamicPlaces(Position position) async {
    if (!mounted) return;

    try {
      // Discover health facilities
      await _discoverPlacesByType(position, 'health', 'hospital');
      await _discoverPlacesByType(position, 'health', 'clinic');
      await _discoverPlacesByType(position, 'health', 'pharmacy');

      // Discover educational institutions
      await _discoverPlacesByType(position, 'education', 'university');
      await _discoverPlacesByType(position, 'education', 'school');
      await _discoverPlacesByType(position, 'education', 'college');

      // Discover government institutions
      await _discoverPlacesByType(position, 'government', 'police');
      await _discoverPlacesByType(position, 'government', 'post_office');
      await _discoverPlacesByType(position, 'government', 'bank');

      // Discover transportation
      await _discoverPlacesByType(position, 'transport', 'bus_station');
      await _discoverPlacesByType(position, 'transport', 'taxi_stand');

      // Discover additional landmarks
      await _discoverPlacesByType(position, 'landmark', 'monument');
      await _discoverPlacesByType(position, 'landmark', 'park');

      if (mounted) {
        setState(() {
          // _isLoadingDynamicPlaces = false;
        });

        if (_dynamicPlaces.isNotEmpty) {
          await _ttsService.speak(
            'Discovered ${_dynamicPlaces.length} additional places near your location including health facilities, institutions, and landmarks. Say "find nearby" to explore them.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error discovering dynamic places: $e');
      if (mounted) {
        setState(() {
          // _isLoadingDynamicPlaces = false;
        });
      }
    }
  }

  Future<void> _discoverPlacesByType(
    Position position,
    String category,
    String type,
  ) async {
    try {
      // Use Google Places API or similar to discover places
      // For now, we'll use a mock implementation that creates realistic place data
      final places = await _getMockPlacesByType(position, category, type);

      for (final place in places) {
        if (!_dynamicPlaces.any((p) => p['name'] == place['name'])) {
          _dynamicPlaces.add(place);
          _addDynamicPlaceMarker(place);
        }
      }
    } catch (e) {
      debugPrint('Error discovering $type places: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getMockPlacesByType(
    Position position,
    String category,
    String type,
  ) async {
    // Mock implementation - in a real app, this would call Google Places API
    final List<Map<String, dynamic>> places = [];

    // Generate realistic coordinates within the radius
    final random = Random();
    final placesCount = random.nextInt(3) + 1; // 1-3 places per type

    for (int i = 0; i < placesCount; i++) {
      final latOffset = (random.nextDouble() - 0.5) * 0.01; // ±0.005 degrees
      final lngOffset = (random.nextDouble() - 0.5) * 0.01;

      final place = _createMockPlace(
        position.latitude + latOffset,
        position.longitude + lngOffset,
        category,
        type,
        i + 1,
      );

      if (place != null) {
        places.add(place);
      }
    }

    return places;
  }

  Map<String, dynamic>? _createMockPlace(
    double lat,
    double lng,
    String category,
    String type,
    int index,
  ) {
    final placeNames = _getPlaceNamesByType(category, type);
    if (placeNames.isEmpty) return null;

    final name = placeNames[index % placeNames.length];
    final description = _getPlaceDescriptionByType(category, type, name);
    final features = _getPlaceFeaturesByType(category, type);

    return {
      'name': name,
      'type': type,
      'category': category,
      'position': LatLng(lat, lng),
      'description': description,
      'rating': 4.0 + (index * 0.1), // Vary ratings slightly
      'features': features,
      'isDynamic': true, // Mark as dynamically discovered
    };
  }

  List<String> _getPlaceNamesByType(String category, String type) {
    switch ('$category:$type') {
      case 'health:hospital':
        return [
          'Mulago National Referral Hospital',
          'Kampala International Hospital',
          'Nakasero Hospital',
          'Case Medical Centre',
          'Kampala Hospital',
        ];
      case 'health:clinic':
        return [
          'Kampala Medical Clinic',
          'Nakasero Health Centre',
          'Kibuli Medical Clinic',
          'Wandegeya Health Centre',
          'Makerere Health Clinic',
        ];
      case 'health:pharmacy':
        return [
          'Goodlife Pharmacy',
          'Kampala Pharmacy',
          'Nakasero Pharmacy',
          'Makerere Pharmacy',
          'Kibuli Pharmacy',
        ];
      case 'education:university':
        return [
          'Makerere University',
          'Kyambogo University',
          'Uganda Christian University',
          'Kampala International University',
          'Nkumba University',
        ];
      case 'education:school':
        return [
          'Kampala Parents School',
          'Nakasero Primary School',
          'Makerere College School',
          'Kibuli Secondary School',
          'St. Mary\'s College Kisubi',
        ];
      case 'education:college':
        return [
          'Makerere University College',
          'Kampala Technical College',
          'Uganda Technical College',
          'Nakasero Vocational Institute',
          'Kibuli Teacher Training College',
        ];
      case 'government:police':
        return [
          'Kampala Central Police Station',
          'Nakasero Police Post',
          'Makerere Police Station',
          'Kibuli Police Station',
          'Wandegeya Police Post',
        ];
      case 'government:post_office':
        return [
          'Kampala Post Office',
          'Nakasero Post Office',
          'Makerere Post Office',
          'Kibuli Post Office',
          'Wandegeya Post Office',
        ];
      case 'government:bank':
        return [
          'Bank of Uganda',
          'Stanbic Bank Kampala',
          'Centenary Bank',
          'DFCU Bank',
          'KCB Bank Uganda',
        ];
      case 'transport:bus_station':
        return [
          'Kampala Bus Terminal',
          'Nakasero Bus Park',
          'Makerere Bus Stop',
          'Kibuli Taxi Park',
          'Wandegeya Bus Station',
        ];
      case 'transport:taxi_stand':
        return [
          'Kampala Taxi Park',
          'Nakasero Taxi Stand',
          'Makerere Taxi Stop',
          'Kibuli Taxi Park',
          'Wandegeya Taxi Stand',
        ];
      case 'landmark:monument':
        return [
          'Independence Monument',
          'Freedom Square',
          'Constitution Square',
          'Unity Monument',
          'Peace Memorial',
        ];
      case 'landmark:park':
        return [
          'Independence Grounds',
          'Nakasero Hill Park',
          'Makerere Hill Park',
          'Kibuli Hill Park',
          'Wandegeya Park',
        ];
      default:
        return [];
    }
  }

  String _getPlaceDescriptionByType(String category, String type, String name) {
    switch ('$category:$type') {
      case 'health:hospital':
        return 'Medical facility providing comprehensive healthcare services and emergency care';
      case 'health:clinic':
        return 'Local health center offering primary healthcare and medical consultations';
      case 'health:pharmacy':
        return 'Pharmacy providing prescription medications and health products';
      case 'education:university':
        return 'Higher education institution offering degree programs and research opportunities';
      case 'education:school':
        return 'Educational institution providing primary and secondary education';
      case 'education:college':
        return 'Educational institution offering specialized training and certificate programs';
      case 'government:police':
        return 'Law enforcement facility providing public safety and security services';
      case 'government:post_office':
        return 'Government facility for mail services and postal operations';
      case 'government:bank':
        return 'Financial institution providing banking services and financial products';
      case 'transport:bus_station':
        return 'Public transportation hub for bus services and intercity travel';
      case 'transport:taxi_stand':
        return 'Public transportation hub for taxi services and local travel';
      case 'landmark:monument':
        return 'Historical monument commemorating significant events and cultural heritage';
      case 'landmark:park':
        return 'Public park offering recreational space and natural environment';
      default:
        return 'Local facility providing essential services to the community';
    }
  }

  List<String> _getPlaceFeaturesByType(String category, String type) {
    switch ('$category:$type') {
      case 'health:hospital':
        return [
          'Emergency Care',
          'Specialized Treatment',
          '24/7 Service',
          'Medical Staff',
        ];
      case 'health:clinic':
        return [
          'Primary Care',
          'Medical Consultations',
          'Health Screenings',
          'Vaccinations',
        ];
      case 'health:pharmacy':
        return [
          'Prescription Drugs',
          'Over-the-Counter Medicine',
          'Health Products',
          'Consultation',
        ];
      case 'education:university':
        return [
          'Degree Programs',
          'Research Facilities',
          'Library',
          'Student Services',
        ];
      case 'education:school':
        return [
          'Primary Education',
          'Secondary Education',
          'Extracurricular Activities',
          'Sports',
        ];
      case 'education:college':
        return [
          'Vocational Training',
          'Certificate Programs',
          'Skills Development',
          'Career Guidance',
        ];
      case 'government:police':
        return [
          'Law Enforcement',
          'Public Safety',
          'Emergency Response',
          'Community Service',
        ];
      case 'government:post_office':
        return [
          'Mail Services',
          'Package Delivery',
          'Postal Banking',
          'Government Services',
        ];
      case 'government:bank':
        return [
          'Banking Services',
          'Financial Products',
          'ATM Services',
          'Customer Support',
        ];
      case 'transport:bus_station':
        return [
          'Intercity Travel',
          'Local Routes',
          'Ticket Services',
          'Waiting Area',
        ];
      case 'transport:taxi_stand':
        return [
          'Local Transportation',
          'Shared Rides',
          'Quick Travel',
          'City Routes',
        ];
      case 'landmark:monument':
        return [
          'Historical Significance',
          'Cultural Heritage',
          'Tourist Attraction',
          'Photo Opportunities',
        ];
      case 'landmark:park':
        return [
          'Recreation Space',
          'Natural Environment',
          'Walking Paths',
          'Public Events',
        ];
      default:
        return [
          'Essential Services',
          'Community Access',
          'Public Facility',
          'Local Resource',
        ];
    }
  }

  void _addDynamicPlaceMarker(Map<String, dynamic> place) {
    if (!mounted) return;

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('dynamic_${place['name']}'),
          position: place['position'],
          infoWindow: InfoWindow(
            title: place['name'],
            snippet: '${place['category']} - ${place['type']}',
          ),
          icon: _getMarkerIcon(place['type']),
          onTap: () => _onPlaceMarkerTapped(place),
        ),
      );
    });
  }

  void _startDynamicPlaceUpdates() {
    _dynamicPlaceUpdateTimer?.cancel();
    _dynamicPlaceUpdateTimer = Timer.periodic(const Duration(minutes: 10), (
      timer,
    ) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      if (locationProvider.currentPosition != null) {
        _discoverDynamicPlaces(locationProvider.currentPosition!);
      }
    });
  }

  // Dynamic place search methods
  Future<void> _searchDynamicPlacesByType(String type) async {
    if (!mounted) return;

    setState(() {
      _isSearchingNearby = true;
      _currentSearchType = type;
    });

    final filteredPlaces = _dynamicPlaces
        .where((place) => place['type'] == type)
        .toList();

    if (filteredPlaces.isNotEmpty) {
      // Focus map on the first result
      final firstPlace = filteredPlaces.first;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(firstPlace['position'], 14.0),
      );

      // Speak results
      final placeNames = filteredPlaces.map((p) => p['name']).join(', ');
      await _ttsService.speak(
        'Found ${filteredPlaces.length} ${type}s: $placeNames. Tap on map markers for details.',
      );
    } else {
      await _ttsService.speak(
        'No ${type}s found in the current area. Try moving to a different location or say "refresh places" to discover new locations.',
      );
    }

    if (mounted) {
      setState(() {
        _isSearchingNearby = false;
      });
    }
  }

  BitmapDescriptor _getMarkerIcon(String type) {
    switch (type) {
      case 'hotel':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'market':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      case 'tour':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueMagenta,
        );
      case 'historical':
      case 'religious':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      // Dynamic place types
      case 'hospital':
      case 'clinic':
      case 'pharmacy':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'university':
      case 'school':
      case 'college':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'police':
      case 'post_office':
      case 'bank':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'bus_station':
      case 'taxi_stand':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'monument':
      case 'park':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _onPlaceMarkerTapped(Map<String, dynamic> place) {
    setState(() {
      _selectedPlace = place['name'];
    });

    _speakPlaceDetails(place);
  }

  Future<void> _speakPlaceDetails(Map<String, dynamic> place) async {
    final features = (place['features'] as List<dynamic>).join(', ');
    final rating = place['rating'].toString();
    final category = place['category'];

    String description =
        '''
${place['name']}, a $category. 
${place['description']}
Rating: $rating out of 5 stars.
Features: $features.
''';

    // Add enhanced information for blind users
    if (_isDetailedMode) {
      description += '''
Accessibility information: This location is accessible via public transportation and has audio guides available.
Cultural significance: This site represents the rich heritage of Buganda Kingdom.
''';

      // Add specific accessibility details based on place type
      switch (place['type']) {
        case 'historical':
          description +=
              'Historical sites include audio tours and tactile exhibits for enhanced accessibility. ';
          break;
        case 'religious':
          description +=
              'Religious sites offer guided tours with detailed audio descriptions of architectural features. ';
          break;
        case 'hotel':
          description +=
              'Hotels provide accessible accommodations and audio guidance for navigation. ';
          break;
        case 'market':
          description +=
              'Markets have audio guides describing local products and cultural significance. ';
          break;
      }
    }

    description +=
        '''
Say "navigate to ${place['name']}" for directions, 
"select place" to choose this location, 
or "describe place" for more information.
''';

    await _ttsService.speakWithPriority(description);
  }

  void _addCurrentLocationMarker(position) {
    if (!mounted) return;
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  void _centerMapOnCurrentLocation(Position position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
      _currentZoom = 15.0;
    }
  }

  Future<void> _speakLocationDetails(
    Position position,
    String locationName,
  ) async {
    if (!_isVoiceModeEnabled) return;

    String locationInfo =
        '$locationName is at coordinates ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

    // Find nearby places
    final nearbyPlaces = _findNearbyPlaces(position);
    if (nearbyPlaces.isNotEmpty) {
      locationInfo +=
          '. Nearby places include: ${nearbyPlaces.take(3).map((p) => p['name']).join(', ')}';
    }

    await _ttsService.speak(locationInfo);
  }

  List<Map<String, dynamic>> _findNearbyPlaces(
    Position position, {
    double radiusKm = 2.0,
  }) {
    final nearby = <Map<String, dynamic>>[];

    // Include static Buganda places
    for (final place in _bugandaPlaces) {
      final placePosition = place['position'] as LatLng;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        placePosition.latitude,
        placePosition.longitude,
      );

      if (distance <= radiusKm * 1000) {
        final placeWithDistance = Map<String, dynamic>.from(place);
        placeWithDistance['distance'] = distance;
        nearby.add(placeWithDistance);
      }
    }

    // Include dynamic places
    for (final place in _dynamicPlaces) {
      final placePosition = place['position'] as LatLng;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        placePosition.latitude,
        placePosition.longitude,
      );

      if (distance <= radiusKm * 1000) {
        final placeWithDistance = Map<String, dynamic>.from(place);
        placeWithDistance['distance'] = distance;
        nearby.add(placeWithDistance);
      }
    }

    // Sort by distance
    nearby.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );
    return nearby;
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentPosition != null) {
      _centerMapOnCurrentLocation(locationProvider.currentPosition!);
    }

    await _ttsService.speak(
      'Map is ready for interaction. Use voice commands to explore locations.',
    );
  }

  void _onMapTap(LatLng position) {
    _lastTappedLocation = position;
    _speakLocationInfo(position);

    // Clear any selected place when tapping elsewhere
    if (_selectedPlace != null) {
      setState(() {
        _selectedPlace = null;
      });
    }
  }

  Future<void> _speakLocationInfo(LatLng position) async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentPosition != null) {
      final distance = await locationProvider.getDistanceTo(
        position.latitude,
        position.longitude,
      );

      final bearing = await locationProvider.getBearingTo(
        position.latitude,
        position.longitude,
      );

      final distanceInKm = (distance / 1000).toStringAsFixed(1);
      final direction = _getDirectionFromBearing(bearing);

      // Check for nearby places at tapped location
      final nearbyPlaces = _findNearbyPlaces(
        Position(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
        radiusKm: 0.5,
      );

      String locationInfo =
          'Location selected. Distance: $distanceInKm kilometers $direction from your current position.';

      if (nearbyPlaces.isNotEmpty) {
        final closestPlace = nearbyPlaces.first;
        locationInfo +=
            ' Closest place: ${closestPlace['name']}, a ${closestPlace['category']}.';
      }

      await _ttsService.speak(locationInfo);
    }
  }

  String _getDirectionFromBearing(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'north';
    if (bearing >= 22.5 && bearing < 67.5) return 'northeast';
    if (bearing >= 67.5 && bearing < 112.5) return 'east';
    if (bearing >= 112.5 && bearing < 157.5) return 'southeast';
    if (bearing >= 157.5 && bearing < 202.5) return 'south';
    if (bearing >= 202.5 && bearing < 247.5) return 'southwest';
    if (bearing >= 247.5 && bearing < 292.5) return 'west';
    if (bearing >= 292.5 && bearing < 337.5) return 'northwest';
    return 'unknown direction';
  }

  Future<void> _searchPlacesByType(String type) async {
    if (!mounted) return;

    setState(() {
      _isSearchingNearby = true;
      _currentSearchType = type;
    });

    final filteredPlaces = _bugandaPlaces
        .where((place) => place['type'] == type)
        .toList();

    if (filteredPlaces.isNotEmpty) {
      // Focus map on the first result
      final firstPlace = filteredPlaces.first;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(firstPlace['position'], 14.0),
      );

      // Speak results
      final placeNames = filteredPlaces.map((p) => p['name']).join(', ');
      await _ttsService.speak(
        'Found ${filteredPlaces.length} ${type}s: $placeNames. Tap on map markers for details.',
      );
    } else {
      await _ttsService.speak('No ${type}s found in the current area.');
    }

    if (mounted) {
      setState(() {
        _isSearchingNearby = false;
      });
    }
  }

  Future<void> _handleMapVoiceCommands(String command) async {
    final lowerCommand = command.toLowerCase();
    _recentCommands.insert(0, command);
    if (_recentCommands.length > 5) {
      _recentCommands.removeLast();
    }

    // Tour Guide Commands for Blind Users
    if (lowerCommand.contains('start tour') ||
        lowerCommand.contains('begin tour') ||
        lowerCommand.contains('guided tour')) {
      _startGuidedTour();
    } else if (lowerCommand.contains('next stop') ||
        lowerCommand.contains('next location') ||
        lowerCommand.contains('continue tour')) {
      _nextTourStop();
    } else if (lowerCommand.contains('previous stop') ||
        lowerCommand.contains('go back') ||
        lowerCommand.contains('last location')) {
      _previousTourStop();
    } else if (lowerCommand.contains('stop tour') ||
        lowerCommand.contains('end tour') ||
        lowerCommand.contains('exit tour')) {
      _stopGuidedTour();
    } else if (lowerCommand.contains('repeat description') ||
        lowerCommand.contains('say again') ||
        lowerCommand.contains('describe again')) {
      _repeatCurrentDescription();
    } else if (lowerCommand.contains('detailed mode') ||
        lowerCommand.contains('detailed descriptions')) {
      _toggleDetailedMode();
    } else if (lowerCommand.contains('auto narration') ||
        lowerCommand.contains('automatic descriptions')) {
      _toggleAutoNarration();
    }
    // Enhanced Location Commands for Blind Users
    else if (lowerCommand.contains('where am i') ||
        lowerCommand.contains('my location') ||
        lowerCommand.contains('current location')) {
      _goToCurrentLocation();
    } else if (lowerCommand.contains('describe surroundings') ||
        lowerCommand.contains('what is around me') ||
        lowerCommand.contains('environment description')) {
      _describeSurroundings();
    } else if (lowerCommand.contains('find nearby') ||
        lowerCommand.contains('what is nearby') ||
        lowerCommand.contains('nearby places')) {
      _searchAllNearbyPlaces();
    }
    // Enhanced Search Commands for Static Places
    else if (lowerCommand.contains('find hotels') ||
        lowerCommand.contains('hotels')) {
      _searchPlacesByType('hotel');
    } else if (lowerCommand.contains('find restaurants') ||
        lowerCommand.contains('restaurants') ||
        lowerCommand.contains('food')) {
      _searchPlacesByType('restaurant');
    } else if (lowerCommand.contains('find markets') ||
        lowerCommand.contains('markets') ||
        lowerCommand.contains('shopping')) {
      _searchPlacesByType('market');
    } else if (lowerCommand.contains('find tours') ||
        lowerCommand.contains('tours') ||
        lowerCommand.contains('attractions')) {
      _searchPlacesByType('tour');
    } else if (lowerCommand.contains('find historical') ||
        lowerCommand.contains('historical sites')) {
      _searchPlacesByType('historical');
    } else if (lowerCommand.contains('find religious') ||
        lowerCommand.contains('religious sites')) {
      _searchPlacesByType('religious');
    }
    // Dynamic Place Search Commands
    else if (lowerCommand.contains('find hospitals') ||
        lowerCommand.contains('hospitals') ||
        lowerCommand.contains('medical facilities')) {
      _searchDynamicPlacesByType('hospital');
    } else if (lowerCommand.contains('find clinics') ||
        lowerCommand.contains('clinics') ||
        lowerCommand.contains('health centers')) {
      _searchDynamicPlacesByType('clinic');
    } else if (lowerCommand.contains('find pharmacies') ||
        lowerCommand.contains('pharmacies') ||
        lowerCommand.contains('drug stores')) {
      _searchDynamicPlacesByType('pharmacy');
    } else if (lowerCommand.contains('find universities') ||
        lowerCommand.contains('universities') ||
        lowerCommand.contains('colleges')) {
      _searchDynamicPlacesByType('university');
    } else if (lowerCommand.contains('find schools') ||
        lowerCommand.contains('schools') ||
        lowerCommand.contains('education')) {
      _searchDynamicPlacesByType('school');
    } else if (lowerCommand.contains('find police') ||
        lowerCommand.contains('police stations') ||
        lowerCommand.contains('law enforcement')) {
      _searchDynamicPlacesByType('police');
    } else if (lowerCommand.contains('find banks') ||
        lowerCommand.contains('banks') ||
        lowerCommand.contains('financial institutions')) {
      _searchDynamicPlacesByType('bank');
    } else if (lowerCommand.contains('find bus stations') ||
        lowerCommand.contains('bus stations') ||
        lowerCommand.contains('transportation')) {
      _searchDynamicPlacesByType('bus_station');
    } else if (lowerCommand.contains('find landmarks') ||
        lowerCommand.contains('landmarks') ||
        lowerCommand.contains('monuments')) {
      _searchDynamicPlacesByType('monument');
    } else if (lowerCommand.contains('find parks') ||
        lowerCommand.contains('parks') ||
        lowerCommand.contains('recreation')) {
      _searchDynamicPlacesByType('park');
    }
    // Enhanced Navigation Commands
    else if (lowerCommand.contains('navigate to') ||
        lowerCommand.contains('directions to')) {
      await _handleNavigationRequest(command);
    } else if (lowerCommand.contains('start navigation') ||
        lowerCommand.contains('navigate')) {
      _startNavigation();
    } else if (lowerCommand.contains('stop navigation') ||
        lowerCommand.contains('end navigation')) {
      _stopNavigation();
    } else if (lowerCommand.contains('give directions') ||
        lowerCommand.contains('how do i get there')) {
      _giveDetailedDirections();
    }
    // Enhanced Map Control Commands
    else if (lowerCommand.contains('zoom in') ||
        lowerCommand.contains('closer')) {
      _zoomIn();
    } else if (lowerCommand.contains('zoom out') ||
        lowerCommand.contains('farther')) {
      _zoomOut();
    } else if (lowerCommand.contains('center map') ||
        lowerCommand.contains('center view')) {
      _centerMapOnUserLocation();
    } else if (lowerCommand.contains('reset map') ||
        lowerCommand.contains('reset view')) {
      _resetMapView();
    }
    // Enhanced Place Interaction Commands
    else if (lowerCommand.contains('select place') ||
        lowerCommand.contains('choose place')) {
      _selectCurrentPlace();
    } else if (lowerCommand.contains('clear selection') ||
        lowerCommand.contains('deselect')) {
      _clearPlaceSelection();
    } else if (lowerCommand.contains('selected place') ||
        lowerCommand.contains('what is selected')) {
      _speakSelectedPlace();
    } else if (lowerCommand.contains('describe place') ||
        lowerCommand.contains('tell me about')) {
      _describeSelectedPlace();
    }
    // Enhanced Accessibility Commands
    else if (lowerCommand.contains('describe location') ||
        lowerCommand.contains('what is here')) {
      await _describeCurrentView();
    } else if (lowerCommand.contains('read markers') ||
        lowerCommand.contains('list places')) {
      await _readAllMarkers();
    } else if (lowerCommand.contains('read nearby') ||
        lowerCommand.contains('nearby info')) {
      _readNearbyPlaces();
    } else if (lowerCommand.contains('accessibility info') ||
        lowerCommand.contains('accessibility features')) {
      _speakAccessibilityInfo();
    }
    // Enhanced Information Commands
    else if (lowerCommand.contains('help') ||
        lowerCommand.contains('commands')) {
      _speakHelpCommands();
    } else if (lowerCommand.contains('map info')) {
      _speakMapInfo();
    } else if (lowerCommand.contains('tour status') ||
        lowerCommand.contains('tour progress')) {
      _speakTourStatus();
    } else if (lowerCommand.contains('map status') ||
        lowerCommand.contains('is map ready')) {
      _speakMapStatus();
    } else if (lowerCommand.contains('last tap') ||
        lowerCommand.contains('tapped location')) {
      _speakLastTappedLocation();
    } else if (lowerCommand.contains('refresh places') ||
        lowerCommand.contains('update places') ||
        lowerCommand.contains('discover places')) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      if (locationProvider.currentPosition != null) {
        await _discoverDynamicPlaces(locationProvider.currentPosition!);
        _ttsService.speakWithPriority(
          'Refreshed places near your location. New health facilities, institutions, and landmarks have been discovered.',
        );
      } else {
        _ttsService.speakWithPriority(
          'Location not available. Please enable location services to refresh places.',
        );
      }
    } else if (lowerCommand.contains('test voice') ||
        lowerCommand.contains('voice test')) {
      _ttsService.speakWithPriority(
        'Voice commands are working in map screen! You said: $command',
      );
    } else {
      // Provide helpful feedback for unrecognized commands
      _ttsService.speakWithPriority(
        'Command not recognized. You said: "$command". Say "help" to hear available commands for blind users.',
      );
    }
  }

  Future<void> _handleNavigationRequest(String command) async {
    // Extract destination from command
    final lowerCommand = command.toLowerCase();
    String? destination;

    for (final place in _bugandaPlaces) {
      final placeName = place['name'].toString().toLowerCase();
      if (lowerCommand.contains(placeName.split(' ').first)) {
        destination = place['name'];
        break;
      }
    }

    if (destination != null) {
      await _ttsService.speak(
        'Starting navigation to $destination. Follow voice guidance.',
      );
      _startNavigationToPlace(destination);
    } else {
      await _ttsService.speak(
        'Destination not found. Say "find places" to hear available locations.',
      );
    }
  }

  void _startNavigationToPlace(String placeName) {
    final place = _bugandaPlaces.firstWhere(
      (p) => p['name'] == placeName,
      orElse: () => _bugandaPlaces.first,
    );

    if (!mounted) return;
    setState(() {
      _isNavigating = true;
      _currentNarration = 'Navigating to $placeName. Distance calculating...';
    });

    // Center map on destination
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(place['position'], 16.0),
    );

    _speakPlaceDetails(place);
  }

  Future<void> _describeCurrentView() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    String description = 'Current map view: ';
    description += 'Zoom level ${_currentZoom.toStringAsFixed(1)}. ';

    if (locationProvider.currentPosition != null) {
      description += 'Your location is visible. ';
      final nearbyPlaces = _findNearbyPlaces(locationProvider.currentPosition!);
      if (nearbyPlaces.isNotEmpty) {
        description +=
            '${nearbyPlaces.length} nearby places visible including ';
        description += nearbyPlaces.take(3).map((p) => p['name']).join(', ');
      }
    } else {
      description += 'Location not available. ';
    }

    description += '. ${_markers.length} total markers on map.';
    await _ttsService.speak(description);
  }

  Future<void> _readAllMarkers() async {
    if (_markers.isEmpty) {
      await _ttsService.speak('No markers currently visible on the map.');
      return;
    }

    final markerNames = _bugandaPlaces.map((place) => place['name']).toList();
    final markerList = markerNames.take(10).join(', ');

    await _ttsService.speak(
      'Map markers: $markerList. Say "navigate to" followed by a place name to get directions.',
    );
  }

  Future<void> _searchAllNearbyPlaces() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentPosition != null) {
      final nearbyPlaces = _findNearbyPlaces(locationProvider.currentPosition!);

      if (nearbyPlaces.isNotEmpty) {
        final placesList = nearbyPlaces
            .take(8)
            .map((place) {
              final distance = ((place['distance'] as num) / 1000)
                  .toStringAsFixed(1);
              return '${place['name']}, $distance kilometers away, ${place['category']}';
            })
            .join('. ');

        await _ttsService.speak(
          'Found ${nearbyPlaces.length} nearby places: $placesList. Say "navigate to" followed by a place name for directions.',
        );
      } else {
        await _ttsService.speak('No places found nearby.');
      }
    } else {
      await _ttsService.speak(
        'Location not available. Please enable location services.',
      );
    }
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
    _currentZoom = (_currentZoom - 1).clamp(1.0, 20.0);
    if (_isVoiceModeEnabled) {
      _ttsService.speak(
        'Zooming out. Current zoom level: ${_currentZoom.toStringAsFixed(1)}',
      );
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
    _currentZoom = (_currentZoom + 1).clamp(1.0, 20.0);
    if (_isVoiceModeEnabled) {
      _ttsService.speak(
        'Zooming in. Current zoom level: ${_currentZoom.toStringAsFixed(1)}',
      );
    }
  }

  void _startNavigation() {
    if (!mounted) return;
    setState(() {
      _isNavigating = true;
      _currentNarration = 'Navigation started. Follow the route ahead.';
    });
    if (_isVoiceModeEnabled) {
      _ttsService.speak('Navigation started. Follow the route ahead.');
    }
  }

  void _stopNavigation() {
    if (!mounted) return;
    setState(() {
      _isNavigating = false;
      _currentNarration = '';
    });
    if (_isVoiceModeEnabled) {
      _ttsService.speak('Navigation stopped');
    }
  }

  void _selectCurrentPlace() {
    if (_selectedPlace == null) {
      _ttsService.speak(
        'No place currently selected. Tap on a marker to select it.',
      );
    } else {
      _ttsService.speak('Place "$_selectedPlace" selected.');
    }
  }

  void _clearPlaceSelection() {
    if (_selectedPlace != null) {
      _ttsService.speak('Place "$_selectedPlace" deselected.');
      setState(() {
        _selectedPlace = null;
      });
    } else {
      _ttsService.speak('No place currently selected to deselect.');
    }
  }

  void _speakSelectedPlace() {
    if (_selectedPlace == null) {
      _ttsService.speak('No place currently selected.');
    } else {
      _ttsService.speak('The currently selected place is "$_selectedPlace".');
    }
  }

  void _centerMapOnUserLocation() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          ),
          15.0,
        ),
      );
      _ttsService.speak('Centered map on your current location.');
    } else {
      _ttsService.speak(
        'Location not available. Please enable location services to center the map.',
      );
    }
  }

  void _resetMapView() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          ),
          15.0,
        ),
      );
      _ttsService.speak('Reset map view to your current location.');
    } else {
      _ttsService.speak(
        'Location not available. Please enable location services to reset the map view.',
      );
    }
  }

  Future<void> _readNearbyPlaces() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentPosition != null) {
      final nearbyPlaces = _findNearbyPlaces(locationProvider.currentPosition!);

      if (nearbyPlaces.isNotEmpty) {
        final placesList = nearbyPlaces
            .take(5)
            .map((place) {
              final distance = ((place['distance'] as num) / 1000)
                  .toStringAsFixed(1);
              return '${place['name']}, $distance kilometers away, ${place['category']}';
            })
            .join('. ');

        await _ttsService.speak(
          'Nearby places: $placesList. Say "navigate to" followed by a place name for directions.',
        );
      } else {
        await _ttsService.speak('No places found nearby.');
      }
    } else {
      await _ttsService.speak(
        'Location not available. Please enable location services.',
      );
    }
  }

  void _speakHelpCommands() {
    _ttsService.speakWithPriority('''
Available voice commands for blind users in map screen:

Tour Guide Commands:
"Start tour" - Begin guided tour of Buganda Kingdom
"Next stop" / "Continue tour" - Go to next tour location
"Previous stop" / "Go back" - Return to previous location
"Stop tour" / "End tour" - End guided tour
"Tour status" - Check tour progress

Location & Navigation:
"Where am I" - Get current location
"Describe surroundings" - Hear what's around you
"Navigate to [place name]" - Get directions to a place
"Give directions" - Get detailed directions to selected place
"Start navigation" / "Stop navigation" - Control navigation

Search & Discovery:
"Find hotels" / "Find restaurants" / "Find markets" / "Find tours"
"Find historical" / "Find religious" - Search by category
"Find nearby" - Discover nearby places

Place Interaction:
"Select place" / "Choose place" - Select current place
"Describe place" / "Tell me about" - Get detailed place information
"Clear selection" - Clear selected place

Accessibility Features:
"Repeat description" - Hear current description again
"Detailed mode" - Toggle detailed descriptions
"Auto narration" - Toggle automatic location announcements
"Accessibility info" - Hear about accessibility features

Map Control:
"Zoom in" / "Zoom out" - Control map zoom
"Center map" / "Reset map" - Map positioning

Information:
"Help" - Hear this list of commands
"Map info" - Get map status information
"Test voice" - Verify voice recognition is working

All commands are designed for hands-free operation. Speak clearly and naturally.
''');
  }

  void _speakMapInfo() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    String info =
        'Map information. Current zoom level: ${_currentZoom.toStringAsFixed(1)}. ';

    if (locationProvider.currentPosition != null) {
      info += 'Your location is available. ';
    } else {
      info += 'Location services are not available. ';
    }

    info += 'Voice mode is ${_isVoiceModeEnabled ? 'enabled' : 'disabled'}. ';
    info += 'Navigation is ${_isNavigating ? 'active' : 'inactive'}. ';
    info += '${_markers.length} places are marked on the map.';

    _ttsService.speak(info);
  }

  void _goToCurrentLocation() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentPosition != null) {
      _centerMapOnCurrentLocation(locationProvider.currentPosition!);
      _ttsService.speak('Centered on your current location');
    } else {
      _ttsService.speak(
        'Location not available. Please enable location services.',
      );
    }
  }

  void _speakMapStatus() {
    _ttsService.speakWithPriority(
      'Map is ready for interaction: ${_isMapReady ? 'Yes' : 'No'}.',
    );
  }

  void _speakLastTappedLocation() {
    if (_lastTappedLocation != null) {
      _ttsService.speakWithPriority(
        'Last tapped location: ${_lastTappedLocation!.latitude.toStringAsFixed(4)}, ${_lastTappedLocation!.longitude.toStringAsFixed(4)}.',
      );
    } else {
      _ttsService.speakWithPriority(
        'No location has been tapped on the map yet.',
      );
    }
  }

  // Tour Guide Methods for Blind Users
  void _startGuidedTour() {
    if (_tourRoute.isEmpty) {
      // Create a default tour route with key Buganda locations
      _tourRoute = [
        _bugandaPlaces.firstWhere((p) => p['name'] == 'Kasubi Tombs'),
        _bugandaPlaces.firstWhere(
          (p) => p['name'] == 'Namugongo Martyrs Shrine',
        ),
        _bugandaPlaces.firstWhere((p) => p['name'] == 'Lubiri Palace'),
        _bugandaPlaces.firstWhere((p) => p['name'] == 'Owino Market'),
      ];
    }

    setState(() {
      _isTourGuideMode = true;
      _tourStepIndex = 0;
    });

    _ttsService.speakWithPriority('''
Guided tour started! Welcome to the Buganda Kingdom tour.
This tour will take you through the most important cultural and historical sites.
Say "next stop" to continue, "previous stop" to go back, or "stop tour" to end.
''');

    _navigateToTourStop();
  }

  void _nextTourStop() {
    if (!_isTourGuideMode) {
      _ttsService.speak(
        'No tour is currently active. Say "start tour" to begin.',
      );
      return;
    }

    if (_tourStepIndex < _tourRoute.length - 1) {
      _tourStepIndex++;
      _navigateToTourStop();
    } else {
      _ttsService.speak(
        'You have reached the end of the tour. Say "previous stop" to go back or "stop tour" to end.',
      );
    }
  }

  void _previousTourStop() {
    if (!_isTourGuideMode) {
      _ttsService.speak(
        'No tour is currently active. Say "start tour" to begin.',
      );
      return;
    }

    if (_tourStepIndex > 0) {
      _tourStepIndex--;
      _navigateToTourStop();
    } else {
      _ttsService.speak(
        'You are at the beginning of the tour. Say "next stop" to continue.',
      );
    }
  }

  void _stopGuidedTour() {
    setState(() {
      _isTourGuideMode = false;
      _tourStepIndex = 0;
    });

    _ttsService.speakWithPriority(
      'Tour ended. You can explore freely or say "start tour" to begin again.',
    );
  }

  void _navigateToTourStop() {
    if (_tourRoute.isEmpty || _tourStepIndex >= _tourRoute.length) return;

    final currentStop = _tourRoute[_tourStepIndex];
    final position = currentStop['position'] as LatLng;

    // Center map on tour stop
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 16.0));

    // Provide detailed description
    _speakTourStopDescription(currentStop);
  }

  void _speakTourStopDescription(Map<String, dynamic> place) {
    final stepNumber = _tourStepIndex + 1;
    final totalSteps = _tourRoute.length;

    String description =
        '''
Stop $stepNumber of $totalSteps: ${place['name']}.
${place['description']}
Category: ${place['category']}. Rating: ${place['rating']} out of 5 stars.
''';

    if (_isDetailedMode) {
      final features = (place['features'] as List<dynamic>).join(', ');
      description += 'Features: $features. ';

      // Add historical context for cultural sites
      if (place['type'] == 'historical' || place['type'] == 'religious') {
        description +=
            'This location holds significant cultural and historical importance in Buganda Kingdom. ';
      }
    }

    description +=
        'Say "next stop" to continue, "previous stop" to go back, or "repeat description" to hear this again.';

    _ttsService.speakWithPriority(description);
  }

  void _repeatCurrentDescription() {
    if (_isTourGuideMode &&
        _tourRoute.isNotEmpty &&
        _tourStepIndex < _tourRoute.length) {
      _speakTourStopDescription(_tourRoute[_tourStepIndex]);
    } else if (_selectedPlace != null) {
      final place = _bugandaPlaces.firstWhere(
        (p) => p['name'] == _selectedPlace,
      );
      _speakPlaceDetails(place);
    } else {
      _ttsService.speak(
        'No current description to repeat. Select a place or start a tour.',
      );
    }
  }

  void _toggleDetailedMode() {
    setState(() {
      _isDetailedMode = !_isDetailedMode;
    });

    _ttsService.speakWithPriority(
      'Detailed mode ${_isDetailedMode ? 'enabled' : 'disabled'}. ${_isDetailedMode ? 'You will receive comprehensive descriptions.' : 'You will receive brief descriptions.'}',
    );
  }

  void _toggleAutoNarration() {
    setState(() {
      _isAutoNarrationEnabled = !_isAutoNarrationEnabled;
    });

    if (_isAutoNarrationEnabled) {
      _startAutoNarration();
      _ttsService.speakWithPriority(
        'Automatic narration enabled. You will receive automatic location descriptions.',
      );
    } else {
      _stopAutoNarration();
      _ttsService.speakWithPriority('Automatic narration disabled.');
    }
  }

  void _startAutoNarration() {
    _autoNarrationTimer?.cancel();
    _autoNarrationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isAutoNarrationEnabled && mounted) {
        _describeCurrentView();
      }
    });
  }

  void _stopAutoNarration() {
    _autoNarrationTimer?.cancel();
    _autoNarrationTimer = null;
  }

  // Enhanced Location Methods for Blind Users
  void _describeSurroundings() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentPosition != null) {
      final nearbyPlaces = _findNearbyPlaces(locationProvider.currentPosition!);

      if (nearbyPlaces.isNotEmpty) {
        String description = 'Your surroundings include: ';
        for (int i = 0; i < nearbyPlaces.length && i < 3; i++) {
          final place = nearbyPlaces[i];
          final distance = ((place['distance'] as num) / 1000).toStringAsFixed(
            1,
          );
          description += '${place['name']}, $distance kilometers away. ';
        }

        if (_isDetailedMode) {
          description +=
              'You are in the Buganda Kingdom region, known for its rich cultural heritage and historical significance. ';
        }

        _ttsService.speakWithPriority(description);
      } else {
        _ttsService.speakWithPriority(
          'No notable places found in your immediate surroundings.',
        );
      }
    } else {
      _ttsService.speakWithPriority(
        'Location not available. Please enable location services to describe your surroundings.',
      );
    }
  }

  void _giveDetailedDirections() {
    if (_selectedPlace == null) {
      _ttsService.speak(
        'No destination selected. Say "navigate to" followed by a place name first.',
      );
      return;
    }

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentPosition == null) {
      _ttsService.speak(
        'Your location is not available. Please enable location services.',
      );
      return;
    }

    final destination = _bugandaPlaces.firstWhere(
      (p) => p['name'] == _selectedPlace,
    );
    final destinationPos = destination['position'] as LatLng;

    // Calculate distance and bearing
    final distance = Geolocator.distanceBetween(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
      destinationPos.latitude,
      destinationPos.longitude,
    );

    final bearing = Geolocator.bearingBetween(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
      destinationPos.latitude,
      destinationPos.longitude,
    );

    final distanceKm = (distance / 1000).toStringAsFixed(1);
    final direction = _getDirectionFromBearing(bearing);

    String directions =
        '''
Directions to $_selectedPlace:
Distance: $distanceKm kilometers.
Direction: $direction.
${destination['description']}
''';

    if (_isDetailedMode) {
      directions +=
          'This location is a ${destination['category']} with a rating of ${destination['rating']} out of 5 stars. ';
    }

    directions += 'Say "start navigation" to begin turn-by-turn guidance.';

    _ttsService.speakWithPriority(directions);
  }

  void _describeSelectedPlace() {
    if (_selectedPlace == null) {
      _ttsService.speak(
        'No place currently selected. Tap on a marker or say "navigate to" followed by a place name.',
      );
      return;
    }

    final place = _bugandaPlaces.firstWhere((p) => p['name'] == _selectedPlace);
    _speakPlaceDetails(place);
  }

  void _speakAccessibilityInfo() {
    _ttsService.speakWithPriority('''
Accessibility features for blind users:
- Voice navigation with detailed audio descriptions
- Automatic location announcements
- Tour guide mode with step-by-step guidance
- Detailed mode for comprehensive information
- Repeat descriptions on demand
- Surroundings description
- Turn-by-turn navigation with voice guidance
All features are designed for hands-free operation using voice commands.
''');
  }

  void _speakTourStatus() {
    if (_isTourGuideMode) {
      final currentStop = _tourRoute[_tourStepIndex];
      final stepNumber = _tourStepIndex + 1;
      final totalSteps = _tourRoute.length;

      _ttsService.speakWithPriority('''
Tour status: Active
Current stop: $stepNumber of $totalSteps - ${currentStop['name']}
Progress: ${((stepNumber / totalSteps) * 100).toStringAsFixed(0)}% complete
Say "next stop" to continue or "stop tour" to end.
''');
    } else {
      _ttsService.speakWithPriority(
        'No tour is currently active. Say "start tour" to begin a guided tour.',
      );
    }
  }

  @override
  void dispose() {
    // Clean up auto-narration timer
    _autoNarrationTimer?.cancel();

    // Clean up dynamic place update timer
    _dynamicPlaceUpdateTimer?.cancel();

    // Clean up voice navigation listener
    try {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.removeListener(_onVoiceCommandReceived);
    } catch (e) {
      // Ignore errors during dispose
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Map'),
        actions: const [VoiceStatusWidget()],
      ),
      body: Stack(
        children: [
          Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return GoogleMap(
                onMapCreated: _onMapCreated,
                onTap: _onMapTap,
                initialCameraPosition: CameraPosition(
                  target: locationProvider.currentPosition != null
                      ? LatLng(
                          locationProvider.currentPosition!.latitude,
                          locationProvider.currentPosition!.longitude,
                        )
                      : const LatLng(0.3136, 32.5811), // Kampala, Uganda
                  zoom: 15.0,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
              );
            },
          ),

          // Enhanced voice command info panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.voice_chat,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Commands Active',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isVoiceModeEnabled
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isVoiceModeEnabled ? Icons.mic : Icons.mic_off,
                              size: 16,
                              color: _isVoiceModeEnabled
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isVoiceModeEnabled ? 'ON' : 'OFF',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isVoiceModeEnabled
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Say: "Find nearby places", "Navigate to Kasubi Tombs", "Where am I", "Describe location", "Help"',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_currentSearchType.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Currently showing: ${_currentSearchType}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (_recentCommands.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last command: "${_recentCommands.first}"',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Map controls
          Positioned(
            right: 16,
            bottom: 100,
            child: MapControlsWidget(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onCurrentLocation: _goToCurrentLocation,
            ),
          ),

          // Selected place indicator
          if (_selectedPlace != null)
            Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selected: $_selectedPlace',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedPlace = null;
                            });
                            _ttsService.speak('Place selection cleared');
                          },
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final place = _bugandaPlaces.firstWhere(
                                (p) => p['name'] == _selectedPlace,
                              );
                              _speakPlaceDetails(place);
                            },
                            icon: const Icon(Icons.info, size: 16),
                            label: const Text('Info'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _startNavigationToPlace(_selectedPlace!);
                            },
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Navigation panel
          if (_isNavigating)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.navigation, color: Colors.white, size: 24),
                    const SizedBox(height: 8),
                    const Text(
                      'Navigation Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentNarration.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _currentNarration,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Search indicator
          if (_isSearchingNearby)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Searching for ${_currentSearchType}s...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 1),
    );
  }
}
