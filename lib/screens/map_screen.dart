import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/voice_navigation_provider.dart';
import '../providers/location_provider.dart';
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
  final TTSService _ttsService = getIt<TTSService>();
  GoogleMapController? _mapController;
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(0.3476, 32.5825), // Kampala, Uganda
    zoom: 12.0,
  );

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
      voiceProvider.updateCurrentScreen('map');
    });
  }

  Future<void> _initializeScreen() async {
    await _ttsService.speakWithPriority(
      'Interactive map loaded. Voice navigation active. Dynamic place discovery is ready. Say "where am I" for location or "find nearby" to explore. Global voice commands are available.',
    );
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
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Map controls
          Positioned(
            right: 16,
            top: 16,
            child: MapControlsWidget(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onCurrentLocation: _goToCurrentLocation,
            ),
          ),
          
          // Location info panel
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return Container(
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (locationProvider.currentPosition != null)
                        Text(
                          'Lat: ${locationProvider.currentPosition!.latitude.toStringAsFixed(4)}, '
                          'Lng: ${locationProvider.currentPosition!.longitude.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        Text(
                          'Location not available',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 1),
    );
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
    _ttsService.speakWithPriority('Zooming in on map');
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
    _ttsService.speakWithPriority('Zooming out on map');
  }

  void _goToCurrentLocation() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentPosition != null) {
      final position = locationProvider.currentPosition!;
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
      _ttsService.speakWithPriority('Showing your current location on the map');
    } else {
      _ttsService.speakWithPriority('Current location not available. Please enable location services.');
    }
  }
}