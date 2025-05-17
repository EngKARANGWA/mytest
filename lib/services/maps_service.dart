import 'package:url_launcher/url_launcher.dart';

class MapsService {
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
