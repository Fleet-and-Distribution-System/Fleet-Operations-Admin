import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'tracking_map_screen.dart';

class TrackingListScreen extends StatefulWidget {
  const TrackingListScreen({super.key});

  @override
  State<TrackingListScreen> createState() => _TrackingListScreenState();
}

class _TrackingListScreenState extends State<TrackingListScreen> {
  final _api = ApiClient();
  List<dynamic>? _trips;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await _api.get('/trips');
      if (!mounted) return;
      setState(() {
        // Delivery Movement Tracking is about trips actually in motion or
        // about to be — DELIVERED/CANCELLED trips have nowhere left to track.
        _trips = (result as List<dynamic>)
            .where((t) => t['status'] == 'ASSIGNED' || t['status'] == 'IN_TRANSIT')
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load trips.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _error != null
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
              ],
            )
          : _trips == null
              ? const Center(child: CircularProgressIndicator())
              : _trips!.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No active deliveries to track right now.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _trips!.length,
                      itemBuilder: (context, i) {
                        final t = _trips![i];
                        final order = t['transportOrder'] as Map<String, dynamic>?;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.map_outlined),
                            title: Text(order?['orderNumber'] ?? ''),
                            subtitle: Text('${order?['pickupLocation'] ?? ''} → ${order?['destinationLocation'] ?? ''}'),
                            trailing: Chip(label: Text(t['status'] ?? '')),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TrackingMapScreen(trip: t)),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
