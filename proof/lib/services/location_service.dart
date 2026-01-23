import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get location as map
  Future<Map<String, double>?> getLocationAsMap() async {
    final position = await getCurrentLocation();
    if (position == null) return null;
    
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  // Format location as string
  String formatLocation(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return 'Location not available';
    }
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Get city name from coordinates (reverse geocoding)
  Future<String> getCityName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        // Try to get city, locality, or subAdministrativeArea
        String cityName = place.locality ?? 
                         place.subAdministrativeArea ?? 
                         place.administrativeArea ?? 
                         'Unknown Location';
        
        // Add country if available
        if (place.country != null && place.country!.isNotEmpty) {
          return '$cityName, ${place.country}';
        }
        return cityName;
      }
      return formatLocation(latitude, longitude);
    } catch (e) {
      print('Error getting city name: $e');
      return formatLocation(latitude, longitude);
    }
  }
}