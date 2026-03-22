import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result returned when a clinic location is picked on the map.
class ClinicLocationResult {
  final double latitude;
  final double longitude;
  final String address;

  ClinicLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class ClinicLocationPickerScreen extends StatefulWidget {
  /// Optional starting location.
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
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  LatLng? _pickedLocation;
  String? _pickedAddress;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pickedAddress = widget.initialAddress;
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _pickedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _latitudeController.text = widget.initialLatitude!.toString();
      _longitudeController.text = widget.initialLongitude!.toString();
    }
    if (_supportsEmbeddedMap) {
      _initMap();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _initMap() async {
    try {
      final cameraPosition = await _getInitialCameraPosition();
      final controller = await _controller.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Google Maps did not initialize. Check your Maps API key and platform support.',
          );
        },
      );
      controller.moveCamera(CameraUpdate.newCameraPosition(cameraPosition));
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<CameraPosition> _getInitialCameraPosition() async {
    if (_pickedLocation != null) {
      return CameraPosition(target: _pickedLocation!, zoom: 15);
    }

    final position = await _determinePosition();
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 15,
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.name != null && place.name!.isNotEmpty) {
          parts.add(place.name!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }

        setState(() {
          _pickedAddress = parts.join(', ');
        });
      }
    } catch (_) {
      // ignore errors - address is optional
    }
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      _pickedLocation = position;
      _pickedAddress = null;
      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();
    });

    await _reverseGeocode(position);

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _confirmSelection() {
    if (!_supportsEmbeddedMap) {
      final latitude = double.tryParse(_latitudeController.text.trim());
      final longitude = double.tryParse(_longitudeController.text.trim());

      if (latitude == null || longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter valid latitude and longitude values.'),
          ),
        );
        return;
      }

      _pickedLocation = LatLng(latitude, longitude);
    }

    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map.')),
      );
      return;
    }

    Navigator.of(context).pop(
      ClinicLocationResult(
        latitude: _pickedLocation!.latitude,
        longitude: _pickedLocation!.longitude,
        address:
            _pickedAddress ??
            '${_pickedLocation!.latitude.toStringAsFixed(6)}, ${_pickedLocation!.longitude.toStringAsFixed(6)}',
        ),
    );
  }

  bool get _supportsEmbeddedMap {
    if (kIsWeb) return true;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  Future<void> _openInGoogleMaps() async {
    final query = widget.initialAddress?.trim().isNotEmpty == true
        ? widget.initialAddress!.trim()
        : _pickedAddress?.trim();
    final latitude = _latitudeController.text.trim();
    final longitude = _longitudeController.text.trim();

    Uri uri;
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else if (query != null && query.isNotEmpty) {
      uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': query,
      });
    } else {
      uri = Uri.parse('https://www.google.com/maps');
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
  }

  Widget _buildDesktopFallback() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.map_outlined, size: 36),
          const SizedBox(height: 16),
          const Text(
            'Embedded Google Maps is available on Android, iOS, and web in this app.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'On desktop, open Google Maps in your browser, copy the clinic coordinates, then paste them here.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _openInGoogleMaps,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open Google Maps'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _latitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Latitude'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _longitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Longitude'),
          ),
          const SizedBox(height: 12),
          if (_pickedAddress != null)
            Text(
              _pickedAddress!,
              style: const TextStyle(color: Colors.black54),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick clinic location')),
      body: Column(
        children: [
          Expanded(
            child: _supportsEmbeddedMap
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(0, 0),
                            zoom: 2,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          onMapCreated: (controller) {
                            if (!_controller.isCompleted) {
                              _controller.complete(controller);
                            }
                          },
                          markers: _pickedLocation == null
                              ? const {}
                              : {
                                  Marker(
                                    markerId: const MarkerId('clinic'),
                                    position: _pickedLocation!,
                                  ),
                                },
                          onTap: _onMapTap,
                        ),
                      ),
                      if (_loading)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black26,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      if (_error != null)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Check the Maps API key in AndroidManifest.xml or Info.plist if the map stays blank.',
                                      style: TextStyle(
                                        color: Colors.yellow,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : _buildDesktopFallback(),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pickedAddress ??
                      'Tap on the map to pick your clinic location',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmSelection,
                        child: const Text('Confirm location'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
