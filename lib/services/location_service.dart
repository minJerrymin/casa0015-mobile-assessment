import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    required this.message,
  });

  final bool success;
  final double? latitude;
  final double? longitude;
  final String message;
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return const LocationResult(
        success: false,
        message: 'Location services are switched off. Choose a London area or turn on GPS to use your current position.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult(
        success: false,
        message: 'Location permission was denied. You can still choose a London area manually.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        success: false,
        message: 'Location permission is disabled for MatchPint. Re-enable it in Android settings or choose an area manually.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LocationResult(
        success: true,
        latitude: position.latitude,
        longitude: position.longitude,
        message: 'Showing pubs near your current location.',
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult(
          success: true,
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          message: 'Showing pubs near your last known location.',
        );
      }
      return const LocationResult(
        success: false,
        message: 'Could not get a GPS fix. Choose a London area to continue.',
      );
    }
  }

  double distanceKm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final metres = Geolocator.distanceBetween(fromLatitude, fromLongitude, toLatitude, toLongitude);
    return metres / 1000.0;
  }
}
