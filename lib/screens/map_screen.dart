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
  bool _isVoiceModeEnabled = true;
  double _currentZoom = 15.0;
  LatLng? _lastTappedLocation;
  bool _isSearchingNearby = false;
  final List<String> _recentCommands = [];
  String _currentSearchType = '';

  // Enhanced location data for Buganda, Uganda
  final List<Map<String, dynamic>> _bugandaPlaces = [
    {
      'name': 'Kasubi Tombs',
      'type': 'historical',
      'position': const LatLng(0.3476, 32.5825),
      'description': 'UNESCO World Heritage site and royal burial grounds of Buganda kings',
      'category': 'Historical Site',
      'rating': 4.5,
      'features': ['UNESCO Heritage', 'Royal Tombs', 'Traditional Architecture', 'Cultural Tours']
    },
    {
      'name': 'Namugongo Martyrs Shrine',
      'type': 'religious',
      'position': const LatLng(0.3751, 32.6532),
      'description': 'Major pilgrimage site commemorating Christian martyrs',
      'category': 'Religious Site',
      'rating': 4.7,
      'features': ['Pilgrimage Site', 'Religious Tours', 'Historical Significance', 'Annual Celebrations']
    },
    {
      'name': 'Lubiri Palace',
      'type': 'historical',
      'position': const LatLng(0.3011, 32.5511),
      'description': 'Official residence of the Kabaka of Buganda',
      'category': 'Royal Palace',
      'rating': 4.3,
      'features': ['Royal Residence', 'Traditional Architecture', 'Cultural Heritage', 'Guided Tours']
    },
    {
      'name': 'Serena Hotel Kampala',
      'type': 'hotel',
      'position': const LatLng(0.3136, 32.5811),
      'description': 'Luxury hotel in the heart of Kampala',
      'category': 'Luxury Hotel',
      'rating': 4.6,
      'features': ['5-Star Service', 'Conference Facilities', 'Fine Dining', 'City Views']
    },
    {
      'name': 'Sheraton Kampala Hotel',
      'type': 'hotel',
      'position': const LatLng(0.3176, 32.5856),
      'description': 'International hotel with modern amenities',
      'category': 'Business Hotel',
      'rating': 4.4,
      'features': ['Business Center', 'Pool', 'Multiple Restaurants', 'Event Spaces']
    },
    {
      'name': 'Owino Market',
      'type': 'market',
      'position': const LatLng(0.3136, 32.5736),
      'description': 'Largest market in East Africa with diverse goods',
      'category': 'Traditional Market',
      'rating': 4.0,
      'features': ['Local Goods', 'Traditional Crafts', 'Fresh Produce', 'Cultural Experience']
    },
    {
      'name': 'Nakasero Market',
      'type': 'market',
      'position': const LatLng(0.3186, 32.5811),
      'description': 'Fresh produce market with local fruits and vegetables',
      'category': 'Fresh Market',
      'rating': 4.2,
      'features': ['Fresh Produce', 'Local Fruits', 'Organic Options', 'Daily Fresh Items']
    },
    {
      'name': 'Fang Fang Restaurant',
      'type': 'restaurant',
      'position': const LatLng(0.3156, 32.5831),
      'description': 'Popular Chinese restaurant in Kampala',
      'category': 'Chinese Cuisine',
      'rating': 4.3,
      'features': ['Authentic Chinese', 'Vegetarian Options', 'Takeaway Available', 'Family Friendly']
    },
    {
      'name': 'Cafe Javas',
      'type': 'restaurant',
      'position': const LatLng(0.3166, 32.5841),
      'description': 'Local coffee chain with Ugandan specialties',
      'category': 'Cafe & Restaurant',
      'rating': 4.1,
      'features': ['Local Coffee', 'Ugandan Cuisine', 'Free WiFi', 'Multiple Locations']
    },
    {
      'name': 'Ndere Cultural Centre',
      'type': 'tour',
      'position': const LatLng(0.3456, 32.6123),
      'description': 'Cultural center showcasing traditional music and dance',
      'category': 'Cultural Tours',
      'rating': 4.5,
      'features': ['Traditional Performances', 'Cultural Workshops', 'Music Shows', 'Dance Lessons']
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

  void _onVoiceCommandReceived() {
    if (!mounted) return;

    try {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      if (voiceProvider.lastCommand.isNotEmpty) {
        _handleMapVoiceCommands(voiceProvider.lastCommand);
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

    await _ttsService.speak(
      'Interactive map screen loaded. Voice navigation is active. You can say "find hotels", "find restaurants", "find markets", "find tours", or "where am I" for location services. Say "help" for all available commands.',
    );

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
    } else {
      await _ttsService.speak(
        'Unable to get your current location. Please check location permissions and try again.',
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

  BitmapDescriptor _getMarkerIcon(String type) {
    switch (type) {
      case 'hotel':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'market':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'tour':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'historical':
      case 'religious':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _onPlaceMarkerTapped(Map<String, dynamic> place) {
    _speakPlaceDetails(place);
  }

  Future<void> _speakPlaceDetails(Map<String, dynamic> place) async {
    final features = (place['features'] as List<String>).join(', ');
    
    await _ttsService.speak('''
${place['name']}. 
${place['description']}
Category: ${place['category']}. 
Rating: ${place['rating']} out of 5 stars.
Features: $features.
Say "navigate to ${place['name']}" to get directions.
''');
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

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    String locationInfo =
        '$locationName is at coordinates ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

    // Find nearby places
    final nearbyPlaces = _findNearbyPlaces(position);
    if (nearbyPlaces.isNotEmpty) {
      locationInfo += '. Nearby places include: ${nearbyPlaces.take(3).map((p) => p['name']).join(', ')}';
    }

    await _ttsService.speak(locationInfo);
  }

  List<Map<String, dynamic>> _findNearbyPlaces(Position position, {double radiusKm = 2.0}) {
    final nearby = <Map<String, dynamic>>[];
    
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
    
    // Sort by distance
    nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    return nearby;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentPosition != null) {
      _centerMapOnCurrentLocation(locationProvider.currentPosition!);
    }
  }

  void _onMapTap(LatLng position) {
    _lastTappedLocation = position;
    _speakLocationInfo(position);
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

      String locationInfo = 'Location selected. Distance: $distanceInKm kilometers $direction from your current position.';
      
      if (nearbyPlaces.isNotEmpty) {
        final closestPlace = nearbyPlaces.first;
        locationInfo += ' Closest place: ${closestPlace['name']}, a ${closestPlace['category']}.';
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

    final filteredPlaces = _bugandaPlaces.where((place) => place['type'] == type).toList();
    
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

  void _handleMapVoiceCommands(String command) {
    final lowerCommand = command.toLowerCase();
    _recentCommands.insert(0, command);
    if (_recentCommands.length > 5) {
      _recentCommands.removeLast();
    }

    // Location commands
    if (lowerCommand.contains('where am i') ||
        lowerCommand.contains('my location') ||
        lowerCommand.contains('current location')) {
      _goToCurrentLocation();
    }
    // Enhanced search commands with better feedback
    else if (lowerCommand.contains('find nearby') ||
        lowerCommand.contains('what is nearby') ||
        lowerCommand.contains('nearby places')) {
      _searchAllNearbyPlaces();
    }
    // Search commands
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
    // Zoom commands
    else if (lowerCommand.contains('zoom in') ||
        lowerCommand.contains('closer')) {
      _zoomIn();
    } else if (lowerCommand.contains('zoom out') ||
        lowerCommand.contains('farther')) {
      _zoomOut();
    }
    // Enhanced navigation commands
    else if (lowerCommand.contains('navigate to') ||
        lowerCommand.contains('directions to')) {
      _handleNavigationRequest(command);
    }
    // Navigation commands
    else if (lowerCommand.contains('start navigation') ||
        lowerCommand.contains('navigate')) {
      _startNavigation();
    } else if (lowerCommand.contains('stop navigation') ||
        lowerCommand.contains('end navigation')) {
      _stopNavigation();
    }
    // Accessibility commands
    else if (lowerCommand.contains('describe location') ||
        lowerCommand.contains('what is here')) {
      _describeCurrentView();
    } else if (lowerCommand.contains('read markers') ||
        lowerCommand.contains('list places')) {
      _readAllMarkers();
    }
    // Help and info commands
    else if (lowerCommand.contains('help') ||
        lowerCommand.contains('commands')) {
      _speakHelpCommands();
    } else if (lowerCommand.contains('map info')) {
      _speakMapInfo();
    } else {
      // Provide helpful feedback for unrecognized commands
      _ttsService.speak('Map command not recognized. Say "help" to hear available map commands.');
    }
  }

  void _handleNavigationRequest(String command) {
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
      _ttsService.speak('Starting navigation to $destination. Follow voice guidance.');
      _startNavigationToPlace(destination);
    } else {
      _ttsService.speak('Destination not found. Say "find places" to hear available locations.');
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

  void _describeCurrentView() {
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
        description += '${nearbyPlaces.length} nearby places visible including ';
        description += nearbyPlaces.take(3).map((p) => p['name']).join(', ');
      }
    } else {
      description += 'Location not available. ';
    }
    
    description += '. ${_markers.length} total markers on map.';
    _ttsService.speak(description);
  }

  void _readAllMarkers() {
    if (_markers.isEmpty) {
      _ttsService.speak('No markers currently visible on the map.');
      return;
    }
    
    final markerNames = _bugandaPlaces.map((place) => place['name']).toList();
    final markerList = markerNames.take(10).join(', ');
    
    _ttsService.speak(
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
        final placesList = nearbyPlaces.take(8).map((place) {
          final distance = (place['distance'] as double / 1000).toStringAsFixed(1);
          return '${place['name']}, ${distance} kilometers away, ${place['category']}';
        }).join('. ');
        
        await _ttsService.speak(
          'Found ${nearbyPlaces.length} nearby places: $placesList. Say "navigate to" followed by a place name for directions.',
        );
      } else {
        await _ttsService.speak('No places found nearby.');
      }
    } else {
      await _ttsService.speak('Location not available. Please enable location services.');
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

  void _speakHelpCommands() {
    final helpText = '''
Available map voice commands:
Location: "Where am I"
Search: "Find hotels", "Find restaurants", "Find markets", "Find tours", "Find nearby places"
Navigation: "Navigate to [place name]", "Start navigation", "Stop navigation"
Zoom: "Zoom in", "Zoom out"
Information: "Describe location", "Read markers", "Map info"
Accessibility: All places include detailed audio descriptions and accessibility information.
Say place names like "Kasubi Tombs", "Namugongo Shrine", or "Lubiri Palace" for specific locations.
''';
    _ttsService.speak(helpText);
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

  @override
  void dispose() {
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