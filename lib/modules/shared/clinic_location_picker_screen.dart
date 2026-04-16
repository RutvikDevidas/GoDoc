import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlng;

class ClinicLocationResult {
  final double latitude;
  final double longitude;
  final String address;

  const ClinicLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class ClinicLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const ClinicLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<ClinicLocationPickerScreen> createState() =>
      _ClinicLocationPickerScreenState();
}

class _ClinicLocationPickerScreenState
    extends State<ClinicLocationPickerScreen> {
  static const gmaps.LatLng _defaultCenter = gmaps.LatLng(28.6139, 77.2090);

  final Completer<gmaps.GoogleMapController> _googleMapController =
      Completer();
  final MapController _webMapController = MapController();

  gmaps.LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _saving = false;
  bool _loadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = gmaps.LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    }
    _selectedAddress = widget.initialAddress?.trim();
  }

  gmaps.LatLng get _initialCameraTarget => _selectedLocation ?? _defaultCenter;

  Future<void> _setSelectedLocation(gmaps.LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _saving = true;
    });

    final fallbackAddress = _formatCoordinates(
      location.latitude,
      location.longitude,
    );

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final address = _placemarkToAddress(placemark);

      if (!mounted) return;
      setState(() {
        _selectedAddress = address.isEmpty ? fallbackAddress : address;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedAddress = fallbackAddress;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  String _placemarkToAddress(Placemark? placemark) {
    if (placemark == null) {
      return '';
    }

    final parts = <String?>[
      placemark.name,
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ];

    final deduped = <String>[];
    for (final part in parts) {
      final trimmed = part?.trim() ?? '';
      if (trimmed.isEmpty) continue;
      if (deduped.contains(trimmed)) continue;
      deduped.add(trimmed);
    }

    return deduped.join(', ');
  }

  String _formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loadingCurrentLocation = true;
    });

    try {
      final position = await _determinePosition();
      final location = gmaps.LatLng(position.latitude, position.longitude);

      await _setSelectedLocation(location);

      if (kIsWeb) {
        _webMapController.move(
          latlng.LatLng(location.latitude, location.longitude),
          16,
        );
      } else {
        final controller = await _googleMapController.future;
        await controller.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(location, 16),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingCurrentLocation = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    if (kIsWeb) {
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 12));
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Open device settings and try again.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(const Duration(seconds: 12));
  }

  void _confirmSelection() {
    final selectedLocation = _selectedLocation;
    final trimmedAddress = _selectedAddress?.trim();
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap the map to choose a clinic location.')),
      );
      return;
    }

    Navigator.pop(
      context,
      ClinicLocationResult(
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
        address:
            (trimmedAddress != null && trimmedAddress.isNotEmpty)
                ? trimmedAddress
                : _formatCoordinates(
                    selectedLocation.latitude,
                    selectedLocation.longitude,
                  ),
      ),
    );
  }

  Widget _buildMap(gmaps.LatLng? selectedLocation) {
    if (kIsWeb) {
      return FlutterMap(
        mapController: _webMapController,
        options: MapOptions(
          initialCenter: latlng.LatLng(
            _initialCameraTarget.latitude,
            _initialCameraTarget.longitude,
          ),
          initialZoom: selectedLocation == null ? 11 : 16,
          onTap: (_, point) {
            _setSelectedLocation(
              gmaps.LatLng(point.latitude, point.longitude),
            );
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.godoc',
          ),
          if (selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: latlng.LatLng(
                    selectedLocation.latitude,
                    selectedLocation.longitude,
                  ),
                  width: 56,
                  height: 56,
                  child: const Icon(
                    Icons.location_pin,
                    size: 42,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
        ],
      );
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _initialCameraTarget,
        zoom: selectedLocation == null ? 11 : 16,
      ),
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      onTap: _setSelectedLocation,
      onMapCreated: (controller) {
        if (!_googleMapController.isCompleted) {
          _googleMapController.complete(controller);
        }
      },
      markers: selectedLocation == null
          ? const <gmaps.Marker>{}
          : <gmaps.Marker>{
              gmaps.Marker(
                markerId: const gmaps.MarkerId('clinic-location'),
                position: selectedLocation,
                infoWindow: gmaps.InfoWindow(
                  title: 'Selected clinic',
                  snippet:
                      _selectedAddress ??
                      _formatCoordinates(
                        selectedLocation.latitude,
                        selectedLocation.longitude,
                      ),
                ),
              ),
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = _selectedLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic location'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _confirmSelection,
            child: const Text('Use this'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMap(selectedLocation),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tap anywhere on the map to pin the clinic.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedLocation == null
                        ? 'No location selected yet.'
                        : _selectedAddress ??
                            _formatCoordinates(
                              selectedLocation.latitude,
                              selectedLocation.longitude,
                            ),
                  ),
                  if (selectedLocation != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatCoordinates(
                        selectedLocation.latitude,
                        selectedLocation.longitude,
                      ),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadingCurrentLocation || _saving
                              ? null
                              : _useCurrentLocation,
                          icon: _loadingCurrentLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_outlined),
                          label: const Text('Current location'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _confirmSelection,
                          child: Text(_saving ? 'Saving...' : 'Confirm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
