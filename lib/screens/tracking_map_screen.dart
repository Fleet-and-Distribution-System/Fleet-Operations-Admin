import 'package:flutter/material.dart';
import '../widgets/route_map.dart';

class TrackingMapScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  const TrackingMapScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final order = trip['transportOrder'] as Map<String, dynamic>?;
    final vehicle = trip['vehicle'] as Map<String, dynamic>?;
    final driver = trip['driver'] as Map<String, dynamic>?;

    final hasCoords = order?['pickupLat'] != null &&
        order?['pickupLng'] != null &&
        order?['destinationLat'] != null &&
        order?['destinationLng'] != null;

    return Scaffold(
      appBar: AppBar(title: Text(order?['orderNumber'] ?? 'Trip Tracking')),
      body: hasCoords
          ? Column(
              children: [
                Expanded(
                  child: RouteMap(
                    pickupLat: (order!['pickupLat'] as num).toDouble(),
                    pickupLng: (order['pickupLng'] as num).toDouble(),
                    destinationLat: (order['destinationLat'] as num).toDouble(),
                    destinationLng: (order['destinationLng'] as num).toDouble(),
                    height: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${order['pickupLocation']} → ${order['destinationLocation']}'),
                          Text('${vehicle?['plateNumber'] ?? ''} — ${driver?['fullName'] ?? ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                      Chip(label: Text(trip['status'] ?? '')),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This trip\'s order has no saved coordinates yet — set them on the pickup/destination Locations to see the route here.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
