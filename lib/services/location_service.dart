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
        message: 'Location services are switched off. Turn on GPS to rank pubs from your current position.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult(
        success: false,
        message: 'Location permission was denied. MatchPint is still using prototype Central London distances.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        success: false,
        message: 'Location permission is permanently denied. Re-enable it in Android app settings to use live distance ranking.',
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
        message: 'Using phone GPS to update pub distances and ranking.',
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult(
          success: true,
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          message: 'Using last known phone location to update pub distances and ranking.',
        );
      }
      return const LocationResult(
        success: false,
        message: 'Could not get a GPS fix. MatchPint is still using prototype Central London distances.',
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
