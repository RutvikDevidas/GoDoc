import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await _determinePosition();
      setState(() {
        _userPosition = position;
      });
      await _moveCameraToBounds();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
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

  Future<void> _moveCameraToBounds() async {
    if (_userPosition == null) return;

    final clinic = LatLng(widget.clinicLatitude, widget.clinicLongitude);
    final user = LatLng(_userPosition!.latitude, _userPosition!.longitude);

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

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
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
          LatLng(widget.clinicLatitude, widget.clinicLongitude),
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
        ],
        color: Theme.of(context).colorScheme.primary,
        width: 5,
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
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
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
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
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
