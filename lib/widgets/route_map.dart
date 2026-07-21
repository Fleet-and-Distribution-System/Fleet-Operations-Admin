import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Straight-line route between pickup and destination — not a real road
// route (that would need a routing API), but genuinely useful for seeing
// where a trip goes at a glance. OpenStreetMap tiles, no API key required.
class RouteMap extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final double height;

  const RouteMap({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(pickupLat, pickupLng);
    final destination = LatLng(destinationLat, destinationLng);
    final bounds = LatLngBounds.fromPoints([pickup, destination]);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(48),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fleetops.admin',
            ),
            PolylineLayer(
              polylines: [
                Polyline(points: [pickup, destination], strokeWidth: 3, color: const Color(0xFF496DDB)),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pickup,
                  width: 36,
                  height: 36,
                  child: const Icon(Icons.trip_origin, color: Color(0xFF1B8A5A), size: 28),
                ),
                Marker(
                  point: destination,
                  width: 36,
                  height: 36,
                  child: const Icon(Icons.location_on, color: Color(0xFFC0392B), size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
