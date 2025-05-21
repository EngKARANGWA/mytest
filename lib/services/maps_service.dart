import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MapsService {
  static Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      return {
        'latitude': 0.0,
        'longitude': 0.0,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getNearbySellers(
    double latitude,
    double longitude,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final sellersJson = prefs.getString('sellers');
    if (sellersJson == null) return [];

    final sellers = (json.decode(sellersJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    // Calculate distance for each seller
    for (var seller in sellers) {
      if (seller['location'] != null) {
        final sellerLat = seller['location']['latitude'] as double;
        final sellerLng = seller['location']['longitude'] as double;
        seller['distance'] = Geolocator.distanceBetween(
              latitude,
              longitude,
              sellerLat,
              sellerLng,
            ) /
            1000; // Convert to kilometers
      }
    }

    // Sort by distance
    sellers.sort((a, b) => (a['distance'] ?? double.infinity)
        .compareTo(b['distance'] ?? double.infinity));

    return sellers;
  }

  static Future<String> getStaticMap(double latitude, double longitude) async {
    // Using Google Maps Static API
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with your API key
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$latitude,$longitude'
        '&zoom=15'
        '&size=600x300'
        '&markers=color:red%7C$latitude,$longitude'
        '&key=$apiKey';
  }

  static Future<void> openLocationInMaps(
      double latitude, double longitude, String label) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$label');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch maps';
    }
  }

  static Future<void> openAddressInMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch maps';
    }
  }
}
