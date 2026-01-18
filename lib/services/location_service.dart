import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String? address;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.name?.isNotEmpty == true) parts.add(place.name!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (place.administrativeArea?.isNotEmpty == true) {
          parts.add(place.administrativeArea!);
        }
        if (place.country?.isNotEmpty == true) parts.add(place.country!);
        if (parts.isNotEmpty) {
          address = parts.join(', ');
        }
      }
    } catch (_) {
      address = null;
    }

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  Future<List<PlaceResult>> searchPlaces(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final locations = await locationFromAddress(query);
      return locations.map((location) {
        return PlaceResult(
          latitude: location.latitude,
          longitude: location.longitude,
          address: location.toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

class LocationData {
  LocationData({required this.latitude, required this.longitude, this.address});

  final double latitude;
  final double longitude;
  final String? address;
}

class PlaceResult {
  PlaceResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}
