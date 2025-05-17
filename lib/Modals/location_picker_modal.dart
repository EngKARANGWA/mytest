import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerModal extends StatefulWidget {
  final Function(String, double, double) onLocationSelected;

  const LocationPickerModal({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  LatLng _selectedLocation = const LatLng(0, 0);
  String _address = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Get address from coordinates
      await _getAddressFromLatLng(_selectedLocation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address =
              '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting address: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Product Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 15,
                    ),
                    onTap: (position) async {
                      setState(() {
                        _selectedLocation = position;
                      });
                      await _getAddressFromLatLng(position);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: _selectedLocation,
                        draggable: true,
                        onDragEnd: (position) async {
                          setState(() {
                            _selectedLocation = position;
                          });
                          await _getAddressFromLatLng(position);
                        },
                      ),
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_address.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _address,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onLocationSelected(
                        _address,
                        _selectedLocation.latitude,
                        _selectedLocation.longitude,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Select Location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
