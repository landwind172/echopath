import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLocationEnabled = false;
  bool _hasPermission = false;
  Stream<Position>? _positionStream;

  Position? get currentPosition => _currentPosition;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get hasPermission => _hasPermission;

  Future<void> initialize() async {
    await _checkPermissions();
    await _checkLocationService();
    if (_hasPermission && _isLocationEnabled) {
      await getCurrentLocation();
      startLocationUpdates();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      final result = await Permission.location.request();
      _hasPermission = result.isGranted;
    } else {
      _hasPermission = status.isGranted;
    }
    notifyListeners();
  }

  Future<void> _checkLocationService() async {
    _isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();
  }

  Future<Position?> getCurrentLocation() async {
    if (!_hasPermission || !_isLocationEnabled) {
      return null;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      debugPrint('Get current location error: $e');
      return null;
    }
  }

  void startLocationUpdates() {
    if (!_hasPermission || !_isLocationEnabled) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );

    _positionStream?.listen(
      (Position position) {
        _currentPosition = position;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  void stopLocationUpdates() {
    _positionStream = null;
  }

  Future<double> getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<double> getBearingBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}