import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClinicRouteScreen extends StatefulWidget {
  final double clinicLatitude;
  final double clinicLongitude;
  final String clinicName;
  final String clinicAddress;

  const ClinicRouteScreen({
    super.key,
    required this.clinicLatitude,
    required this.clinicLongitude,
    required this.clinicName,
    required this.clinicAddress,
  });

  @override
  State<ClinicRouteScreen> createState() => _ClinicRouteScreenState();
}

class _ClinicRouteScreenState extends State<ClinicRouteScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _userPosition;
  String? _error;
  bool _loading = true;
  bool _locationPermissionGranted = false;
  bool _permissionPermanentlyDenied = false;

  bool _hasLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    setState(() {
      _loading = true;
      _error = null;
      _permissionPermanentlyDenied = false;
    });

    try {
      final position = await _determinePosition();
      setState(() {
        _userPosition = position;
        _locationPermissionGranted = true;
      });
      await _moveCameraToBounds();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _locationPermissionGranted = false;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    if (kIsWeb) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 12));
      _locationPermissionGranted = true;
      return position;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationPermissionGranted = false;
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _permissionPermanentlyDenied = true;
      _locationPermissionGranted = false;
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    _locationPermissionGranted = _hasLocationPermission(permission);

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      rethrow;
    }
  }

  Future<void> _moveCameraToBounds() async {
    if (_userPosition == null) return;

    final clinic = LatLng(widget.clinicLatitude, widget.clinicLongitude);
    final user = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    final latitudeDelta = (clinic.latitude - user.latitude).abs();
    final longitudeDelta = (clinic.longitude - user.longitude).abs();

    final controller = await _controller.future;

    if (latitudeDelta < 0.0005 && longitudeDelta < 0.0005) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(clinic, 17),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        (clinic.latitude < user.latitude) ? clinic.latitude : user.latitude,
        (clinic.longitude < user.longitude) ? clinic.longitude : user.longitude,
      ),
      northeast: LatLng(
        (clinic.latitude > user.latitude) ? clinic.latitude : user.latitude,
        (clinic.longitude > user.longitude) ? clinic.longitude : user.longitude,
      ),
    );

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
    } catch (_) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(clinic, 14));
    }
  }

  Future<void> _openLocationAccess() async {
    if (_permissionPermanentlyDenied) {
      await Geolocator.openAppSettings();
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }

    await _loadUserLocation();
  }

  double get _distanceMeters {
    if (_userPosition == null) return 0;
    return Geolocator.distanceBetween(
      widget.clinicLatitude,
      widget.clinicLongitude,
      _userPosition!.latitude,
      _userPosition!.longitude,
    );
  }

  Set<Marker> get _markers {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('clinic'),
        position: LatLng(widget.clinicLatitude, widget.clinicLongitude),
        infoWindow: InfoWindow(
          title: widget.clinicName,
          snippet: widget.clinicAddress,
        ),
      ),
    };

    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('you'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: 'You'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    if (_userPosition == null) return const {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          LatLng(widget.clinicLatitude, widget.clinicLongitude),
        ],
        color: Theme.of(context).colorScheme.primary,
        width: 7,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        visible: true,
        zIndex: 1,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh location',
            onPressed: _loadUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.clinicLatitude, widget.clinicLongitude),
                zoom: 14,
              ),
              mapType: MapType.normal,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: _locationPermissionGranted,
              onMapCreated: (controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
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
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: _openLocationAccess,
                            child: Text(
                              _permissionPermanentlyDenied
                                  ? 'Open app settings'
                                  : 'Open location settings',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _loadUserLocation,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinic: ${widget.clinicName}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.clinicAddress,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Text(
              _userPosition == null
                  ? 'Tap refresh to find your location'
                  : 'Distance: ${(_distanceMeters / 1000).toStringAsFixed(2)} km',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
