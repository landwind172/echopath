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
    // Check if widget is still mounted before accessing context
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
      // Ignore errors if context is no longer available
      debugPrint('Voice command error: $e');
    }
  }

  Future<void> _initializeMap() async {
    // Get the provider before any async operations
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    await _ttsService.speak(
      'Interactive map screen loaded. Voice navigation is enabled. You can say "help" for available commands, "where am I" for your location, "zoom in" or "zoom out" to control the map, "find nearby places" to search, or "toggle voice mode" to enable or disable voice feedback.',
    );

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Get current location if not available
    if (locationProvider.currentPosition == null) {
      await locationProvider.getCurrentLocation();
    }

    // Add current location marker and center map
    if (locationProvider.currentPosition != null) {
      _addCurrentLocationMarker(locationProvider.currentPosition!);
      _centerMapOnCurrentLocation(locationProvider.currentPosition!);

      // Speak current location info
      final position = locationProvider.currentPosition!;
      await _speakLocationDetails(position, 'Your current location');
    } else {
      await _ttsService.speak(
        'Unable to get your current location. Please check location permissions and try again.',
      );
    }

    // No automatic transition for main screens - user can navigate manually
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
    final address = await _getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String locationInfo =
        '$locationName is at coordinates ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

    if (address.isNotEmpty) {
      locationInfo += '. Address: $address';
    }

    if (locationProvider.currentPosition != null) {
      final distance = await locationProvider.getDistanceTo(
        position.latitude,
        position.longitude,
      );
      final bearing = await locationProvider.getBearingTo(
        position.latitude,
        position.longitude,
      );
      final direction = _getDirectionFromBearing(bearing);

      if (distance > 0) {
        final distanceText = distance < 1000
            ? '${distance.toStringAsFixed(0)} meters'
            : '${(distance / 1000).toStringAsFixed(1)} kilometers';
        locationInfo +=
            '. Distance: $distanceText $direction from your current position';
      }
    }

    await _ttsService.speak(locationInfo);
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    // Placeholder for geocoding - in a real app, you'd use a geocoding service
    // For now, return a simple description based on coordinates
    if (lat > 0) {
      return 'Northern Hemisphere';
    } else {
      return 'Southern Hemisphere';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move camera to current location if available
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

      await _ttsService.speak(
        'Location selected. Distance: $distanceInKm kilometers $direction from your current position. Coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      );
    } else {
      await _ttsService.speak(
        'Location selected. Coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}. Enable location services to get distance information.',
      );
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

  void _zoomToLevel(double zoomLevel) {
    _mapController?.animateCamera(CameraUpdate.zoomTo(zoomLevel));
    _currentZoom = zoomLevel;
    if (_isVoiceModeEnabled) {
      _ttsService.speak('Zoomed to level ${zoomLevel.toStringAsFixed(1)}');
    }
  }

  void _goToLastTappedLocation() {
    if (_lastTappedLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_lastTappedLocation!),
      );
      if (_isVoiceModeEnabled) {
        _ttsService.speak('Moving to last tapped location');
      }
    } else {
      if (_isVoiceModeEnabled) {
        _ttsService.speak('No previous location to go to');
      }
    }
  }

  void _searchNearbyPlaces() {
    if (!mounted) return;
    setState(() {
      _isSearchingNearby = true;
    });
    if (_isVoiceModeEnabled) {
      _ttsService.speak(
        'Searching for nearby places. This feature is coming soon.',
      );
    }
    // Simulate search completion
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isSearchingNearby = false;
      });
    });
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

  void _toggleVoiceMode() {
    if (!mounted) return;
    setState(() {
      _isVoiceModeEnabled = !_isVoiceModeEnabled;
    });
    _ttsService.speak(
      _isVoiceModeEnabled ? 'Voice mode enabled' : 'Voice mode disabled',
    );
  }

  void _speakHelpCommands() {
    final helpText = '''
Available voice commands:
Location: "Where am I", "Last location"
Zoom: "Zoom in", "Zoom out", "Zoom to street level", "Zoom to city level"
Navigation: "Find nearby places", "Start navigation", "Stop navigation"
Map control: "Toggle voice mode", "Clear markers", "Map info"
Directions: "Move north", "Move south", "Move east", "Move west"
Recent: "Repeat command", "Command history"
''';
    _ttsService.speak(helpText);
  }

  void _clearMarkers() {
    if (!mounted) return;
    setState(() {
      _markers.clear();
    });
    if (_isVoiceModeEnabled) {
      _ttsService.speak('All markers cleared');
    }
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
    info += 'Navigation is ${_isNavigating ? 'active' : 'inactive'}.';

    _ttsService.speak(info);
  }

  void _moveMapDirection(String direction) {
    if (_mapController == null) return;

    // Use a simple offset approach instead of getting visible region
    double latOffset = 0.01;
    double lngOffset = 0.01;

    switch (direction.toLowerCase()) {
      case 'north':
        latOffset = 0.01;
        lngOffset = 0.0;
        break;
      case 'south':
        latOffset = -0.01;
        lngOffset = 0.0;
        break;
      case 'east':
        latOffset = 0.0;
        lngOffset = 0.01;
        break;
      case 'west':
        latOffset = 0.0;
        lngOffset = -0.01;
        break;
    }

    // Get current camera position and move in the specified direction
    _mapController!.getVisibleRegion().then((bounds) {
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );

      final newPosition = LatLng(
        center.latitude + latOffset,
        center.longitude + lngOffset,
      );
      _mapController!.animateCamera(CameraUpdate.newLatLng(newPosition));

      if (_isVoiceModeEnabled) {
        _ttsService.speak('Moving map $direction');
      }
    });
  }

  void _repeatLastCommand() {
    if (_recentCommands.isNotEmpty) {
      _ttsService.speak('Last command was: ${_recentCommands.first}');
    } else {
      _ttsService.speak('No recent commands to repeat');
    }
  }

  void _speakCommandHistory() {
    if (_recentCommands.isEmpty) {
      _ttsService.speak('No command history available');
      return;
    }

    String history = 'Recent commands: ';
    for (int i = 0; i < _recentCommands.length && i < 3; i++) {
      history += '${i + 1}. ${_recentCommands[i]}. ';
    }
    _ttsService.speak(history);
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
    } else if (lowerCommand.contains('last location') ||
        lowerCommand.contains('previous location')) {
      _goToLastTappedLocation();
    }
    // Zoom commands
    else if (lowerCommand.contains('zoom in') ||
        lowerCommand.contains('closer')) {
      _zoomIn();
    } else if (lowerCommand.contains('zoom out') ||
        lowerCommand.contains('farther')) {
      _zoomOut();
    } else if (lowerCommand.contains('zoom to street') ||
        lowerCommand.contains('street level')) {
      _zoomToLevel(18.0);
    } else if (lowerCommand.contains('zoom to city') ||
        lowerCommand.contains('city level')) {
      _zoomToLevel(12.0);
    } else if (lowerCommand.contains('zoom to country') ||
        lowerCommand.contains('country level')) {
      _zoomToLevel(6.0);
    }
    // Navigation commands
    else if (lowerCommand.contains('find nearby') ||
        lowerCommand.contains('nearby places')) {
      _searchNearbyPlaces();
    } else if (lowerCommand.contains('start navigation') ||
        lowerCommand.contains('navigate')) {
      _startNavigation();
    } else if (lowerCommand.contains('stop navigation') ||
        lowerCommand.contains('end navigation')) {
      _stopNavigation();
    }
    // Map control commands
    else if (lowerCommand.contains('toggle voice') ||
        lowerCommand.contains('voice mode')) {
      _toggleVoiceMode();
    } else if (lowerCommand.contains('help') ||
        lowerCommand.contains('commands')) {
      _speakHelpCommands();
    } else if (lowerCommand.contains('clear markers') ||
        lowerCommand.contains('remove markers')) {
      _clearMarkers();
    } else if (lowerCommand.contains('map info') ||
        lowerCommand.contains('map details')) {
      _speakMapInfo();
    }
    // Direction commands
    else if (lowerCommand.contains('move north') ||
        lowerCommand.contains('go north')) {
      _moveMapDirection('north');
    } else if (lowerCommand.contains('move south') ||
        lowerCommand.contains('go south')) {
      _moveMapDirection('south');
    } else if (lowerCommand.contains('move east') ||
        lowerCommand.contains('go east')) {
      _moveMapDirection('east');
    } else if (lowerCommand.contains('move west') ||
        lowerCommand.contains('go west')) {
      _moveMapDirection('west');
    }
    // Recent commands
    else if (lowerCommand.contains('repeat command') ||
        lowerCommand.contains('last command')) {
      _repeatLastCommand();
    } else if (lowerCommand.contains('command history')) {
      _speakCommandHistory();
    }
  }

  @override
  void dispose() {
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
        title: const Text('Map'),
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
                      : const LatLng(
                          37.7749,
                          -122.4194,
                        ), // Default to San Francisco
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
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Commands',
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
                    'Say: "Help" for all commands, "Where am I", "Zoom in/out", "Find nearby places", "Toggle voice mode"',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: MapControlsWidget(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onCurrentLocation: _goToCurrentLocation,
            ),
          ),
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
                      'Searching nearby places...',
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
