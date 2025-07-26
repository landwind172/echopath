import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/dependency_injection.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = getIt<LocationService>();

  Position? _currentPosition;
  bool _isLocationEnabled = false;
  bool _hasPermission = false;
  bool _isTracking = false;
  final List<Position> _locationHistory = [];

  Position? get currentPosition => _currentPosition;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get hasPermission => _hasPermission;
  bool get isTracking => _isTracking;
  List<Position> get locationHistory => _locationHistory;

  LocationProvider() {
    _locationService.addListener(_onLocationServiceChanged);
    // Initialize location service
    _locationService.initialize();
  }

  void _onLocationServiceChanged() {
    _currentPosition = _locationService.currentPosition;
    _isLocationEnabled = _locationService.isLocationEnabled;
    _hasPermission = _locationService.hasPermission;
    
    if (_currentPosition != null && _isTracking) {
      _locationHistory.add(_currentPosition!);
      if (_locationHistory.length > 100) {
        _locationHistory.removeAt(0);
      }
    }
    
    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = position;
      notifyListeners();
    }
  }

  void startTracking() {
    _isTracking = true;
    _locationService.startLocationUpdates();
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    _locationService.stopLocationUpdates();
    notifyListeners();
  }

  void clearLocationHistory() {
    _locationHistory.clear();
    notifyListeners();
  }

  Future<double> getDistanceTo(double latitude, double longitude) async {
    if (_currentPosition == null) return 0.0;
    
    return await _locationService.getDistanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  Future<double> getBearingTo(double latitude, double longitude) async {
    if (_currentPosition == null) return 0.0;
    
    return await _locationService.getBearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationServiceChanged);
    super.dispose();
  }
}
