import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;

import '../../core/constants/app_colors.dart';

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
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _userPosition;
  List<latlng.LatLng> _routePoints = const [];
  String? _currentLocationAddress;
  String? _error;
  bool _loading = true;
  bool _routeLoading = false;
  bool _usingFallbackRoute = false;
  bool _locationPermissionGranted = false;
  bool _permissionPermanentlyDenied = false;
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;

  bool _hasLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
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
      await _loadCurrentLocationAddress(position);
      await _loadBestRoute();
      await _moveCameraToBounds();
      _startLocationTracking();
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

  void _startLocationTracking() {
    _positionStreamSubscription?.cancel();

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      final currentUserPosition = _userPosition;
      final hasMeaningfulChange =
          currentUserPosition == null ||
          Geolocator.distanceBetween(
                currentUserPosition.latitude,
                currentUserPosition.longitude,
                position.latitude,
                position.longitude,
              ) >
              20;

      if (!hasMeaningfulChange || !mounted) {
        return;
      }

      setState(() {
        _userPosition = position;
      });

      await _loadCurrentLocationAddress(position);
      await _loadBestRoute();
      await _moveCameraToBounds();
    });
  }

  Future<void> _loadCurrentLocationAddress(Position position) async {
    final fallback =
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final address = _placemarkToAddress(placemark);

      if (!mounted) return;
      setState(() {
        _currentLocationAddress = address.isEmpty ? fallback : address;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentLocationAddress = fallback;
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

  Future<void> _loadBestRoute() async {
    final userPosition = _userPosition;
    if (userPosition == null) return;

    final originLat = userPosition.latitude;
    final originLon = userPosition.longitude;
    final destinationLat = widget.clinicLatitude;
    final destinationLon = widget.clinicLongitude;

    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$originLon,$originLat;$destinationLon,$destinationLat'
      '?overview=full&geometries=geojson&alternatives=true&steps=false',
    );

    if (mounted) {
      setState(() {
        _routeLoading = true;
      });
    }

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Route service returned ${response.statusCode}.');
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = payload['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) {
        throw Exception('No road route found.');
      }

      final bestRoute = routes.first as Map<String, dynamic>;
      final geometry = bestRoute['geometry'] as Map<String, dynamic>? ?? const {};
      final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];

      final points = coordinates
          .whereType<List<dynamic>>()
          .where((point) => point.length >= 2)
          .map(
            (point) => latlng.LatLng(
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            ),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _routePoints = points.isEmpty
            ? [
                latlng.LatLng(originLat, originLon),
                latlng.LatLng(destinationLat, destinationLon),
              ]
            : points;
        _routeDistanceMeters = (bestRoute['distance'] as num?)?.toDouble();
        _routeDurationSeconds = (bestRoute['duration'] as num?)?.toDouble();
        _usingFallbackRoute = points.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routePoints = [
          latlng.LatLng(originLat, originLon),
          latlng.LatLng(destinationLat, destinationLon),
        ];
        _routeDistanceMeters = _distanceMeters;
        _routeDurationSeconds = null;
        _usingFallbackRoute = true;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _routeLoading = false;
      });
    }
  }

  Future<void> _moveCameraToBounds() async {
    if (_userPosition == null) return;

    final clinic = latlng.LatLng(widget.clinicLatitude, widget.clinicLongitude);
    final user = latlng.LatLng(_userPosition!.latitude, _userPosition!.longitude);
    final latitudeDelta = (clinic.latitude - user.latitude).abs();
    final longitudeDelta = (clinic.longitude - user.longitude).abs();

    if (latitudeDelta < 0.0005 && longitudeDelta < 0.0005) {
      _mapController.move(
        latlng.LatLng(clinic.latitude, clinic.longitude),
        17,
      );
      return;
    }

    final bounds = LatLngBounds(
      latlng.LatLng(
        (clinic.latitude < user.latitude) ? clinic.latitude : user.latitude,
        (clinic.longitude < user.longitude) ? clinic.longitude : user.longitude,
      ),
      latlng.LatLng(
        (clinic.latitude > user.latitude) ? clinic.latitude : user.latitude,
        (clinic.longitude > user.longitude) ? clinic.longitude : user.longitude,
      ),
    );

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
        ),
      );
    } catch (_) {
      _mapController.move(
        latlng.LatLng(clinic.latitude, clinic.longitude),
        14,
      );
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

  String get _distanceLabel {
    final distanceMeters = _routeDistanceMeters ?? _distanceMeters;
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String? get _durationLabel {
    final durationSeconds = _routeDurationSeconds;
    if (durationSeconds == null) return null;

    final totalMinutes = (durationSeconds / 60).round();
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  String get _currentLocationLabel {
    return _currentLocationAddress ?? 'Detecting your current location...';
  }

  String get _currentLocationCoordinates {
    final userPosition = _userPosition;
    if (userPosition == null) {
      return '';
    }

    return '${userPosition.latitude.toStringAsFixed(5)}, ${userPosition.longitude.toStringAsFixed(5)}';
  }

  bool get _showCurrentLocationCoordinates {
    final coordinates = _currentLocationCoordinates;
    if (coordinates.isEmpty) {
      return false;
    }

    return _currentLocationAddress != coordinates;
  }

  Future<void> _recenterMap() async {
    await _moveCameraToBounds();
  }

  Widget _buildFloatingActions() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.small(
        heroTag: 'recenter-route',
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        onPressed: _recenterMap,
        child: const Icon(Icons.my_location_rounded),
      ),
    );
  }

  Widget _buildRouteStatusCard() {
    final theme = Theme.of(context);

    return Positioned(
      left: 16,
      right: 16,
      top: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.route_rounded,
                    label: _routeLoading
                        ? 'Refreshing route'
                        : _usingFallbackRoute
                            ? 'Approx route'
                            : 'OSRM route',
                    color: _usingFallbackRoute
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                  if (_userPosition != null)
                    _InfoChip(
                      icon: Icons.near_me_rounded,
                      label: _durationLabel == null
                          ? _distanceLabel
                          : '$_distanceLabel / $_durationLabel',
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _usingFallbackRoute
                    ? 'Using a direct fallback line until the road route is available.'
                    : 'Using your current live location as the route start and the clinic location as the destination.',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: latlng.LatLng(
          widget.clinicLatitude,
          widget.clinicLongitude,
        ),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.godoc',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: latlng.LatLng(
                widget.clinicLatitude,
                widget.clinicLongitude,
              ),
              width: 52,
              height: 52,
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 36,
                color: Colors.red,
              ),
            ),
            if (_userPosition != null)
              Marker(
                point: latlng.LatLng(
                  _userPosition!.latitude,
                  _userPosition!.longitude,
                ),
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 28,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      ],
    );
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
            child: _buildMap(),
          ),
          _buildRouteStatusCard(),
          _buildFloatingActions(),
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
              widget.clinicName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.clinicAddress,
              style: const TextStyle(color: AppColors.mutedText, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.trip_origin_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From your current live location',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentLocationLabel,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      if (_showCurrentLocationCoordinates) ...[
                        const SizedBox(height: 4),
                        Text(
                          _currentLocationCoordinates,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To clinic location',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.clinicAddress,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.clinicLatitude.toStringAsFixed(5)}, ${widget.clinicLongitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _userPosition == null
                  ? 'Tap refresh to find your location'
                  : _durationLabel == null
                      ? 'Distance: $_distanceLabel'
                      : 'Best route: $_distanceLabel / $_durationLabel',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
