import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClinicMapPreview extends StatelessWidget {
  final double lat;
  final double lng;

  const ClinicMapPreview({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final target = LatLng(lat, lng);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 15),
          markers: {
            Marker(
              markerId: const MarkerId("clinic"),
              position: target,
              infoWindow: const InfoWindow(title: "Clinic Location"),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }
}
