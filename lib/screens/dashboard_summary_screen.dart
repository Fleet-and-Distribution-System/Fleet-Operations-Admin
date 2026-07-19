import 'package:flutter/material.dart';
import '../api/api_client.dart';

class DashboardSummaryScreen extends StatefulWidget {
  const DashboardSummaryScreen({super.key});

  @override
  State<DashboardSummaryScreen> createState() => _DashboardSummaryScreenState();
}

class _DashboardSummaryScreenState extends State<DashboardSummaryScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        _api.get('/vehicles'),
        _api.get('/drivers'),
        _api.get('/orders'),
        _api.get('/trips'),
      ]);

      final vehicles = results[0] as List<dynamic>;
      final drivers = results[1] as List<dynamic>;
      final orders = results[2] as List<dynamic>;
      final trips = results[3] as List<dynamic>;

      final vehiclesByStatus = <String, int>{};
      for (final v in vehicles) {
        final s = v['status'] as String? ?? 'UNKNOWN';
        vehiclesByStatus[s] = (vehiclesByStatus[s] ?? 0) + 1;
      }

      final tripsByStatus = <String, int>{};
      for (final t in trips) {
        final s = t['status'] as String? ?? 'UNKNOWN';
        tripsByStatus[s] = (tripsByStatus[s] ?? 0) + 1;
      }

      final ordersByStatus = <String, int>{};
      for (final o in orders) {
        final s = o['status'] as String? ?? 'UNKNOWN';
        ordersByStatus[s] = (ordersByStatus[s] ?? 0) + 1;
      }

      double totalCost = 0;
      for (final t in trips) {
        if (t['status'] == 'DELIVERED' && t['tripCost'] != null) {
          totalCost += (t['tripCost'] as num).toDouble();
        }
      }

      if (!mounted) return;
      setState(() {
        _summary = {
          'totalVehicles': vehicles.length,
          'totalDrivers': drivers.length,
          'activeDrivers': drivers.where((d) => d['isActive'] == true).length,
          'totalOrders': orders.length,
          'totalTrips': trips.length,
          'totalCost': totalCost,
          'vehiclesByStatus': vehiclesByStatus,
          'tripsByStatus': tripsByStatus,
          'ordersByStatus': ordersByStatus,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load dashboard data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _load, child: _buildBody());
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          Center(child: FilledButton(onPressed: _load, child: const Text('Retry'))),
        ],
      );
    }
    if (_summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final s = _summary!;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard('Vehicles', s['totalVehicles'].toString(), Icons.local_shipping, Colors.indigo),
            _statCard('Drivers', '${s['activeDrivers']} / ${s['totalDrivers']} active', Icons.person, Colors.teal),
            _statCard('Orders', s['totalOrders'].toString(), Icons.receipt_long, Colors.orange),
            _statCard('Trips', s['totalTrips'].toString(), Icons.route, Colors.purple),
            _statCard('Total Cost (Delivered)', '₦${(s['totalCost'] as double).toStringAsFixed(2)}', Icons.attach_money, Colors.green),
          ],
        ),
        const SizedBox(height: 32),
        _breakdownSection('Vehicles by status', s['vehiclesByStatus'] as Map<String, int>),
        const SizedBox(height: 24),
        _breakdownSection('Orders by status', s['ordersByStatus'] as Map<String, int>),
        const SizedBox(height: 24),
        _breakdownSection('Trips by status', s['tripsByStatus'] as Map<String, int>),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _breakdownSection(String title, Map<String, int> counts) {
    if (counts.isEmpty) {
      return Text('$title — no data yet', style: TextStyle(color: Colors.grey.shade600));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: counts.entries
              .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
              .toList(),
        ),
      ],
    );
  }
}
