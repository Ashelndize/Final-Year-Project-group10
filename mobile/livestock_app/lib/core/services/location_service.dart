import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final bool consentGiven;
  final String? errorMessage;

  const LocationResult({
    this.latitude,
    this.longitude,
    required this.consentGiven,
    this.errorMessage,
  });

  bool get hasLocation => latitude != null && longitude != null;
}

class LocationService {
  /// Requests location permission and returns the current position if granted.
  /// Returns [LocationResult] with consentGiven=false if the user declines.
  static Future<LocationResult> requestAndGetLocation() async {
    final permStatus = await Permission.locationWhenInUse.request();

    if (permStatus.isDenied || permStatus.isPermanentlyDenied) {
      return const LocationResult(
        consentGiven: false,
        errorMessage: 'Location permission not granted.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        consentGiven: true,
      );
    } catch (e) {
      return LocationResult(
        consentGiven: true,
        errorMessage: 'Could not get location: ${e.toString()}',
      );
    }
  }

  /// Checks whether location services are enabled without requesting permission.
  static Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// Opens the app settings so the user can manually grant location permission.
  static Future<void> openSettings() => openAppSettings();
}
