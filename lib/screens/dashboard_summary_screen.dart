import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

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
      double totalRevenue = 0;
      for (final t in trips) {
        if (t['status'] == 'DELIVERED') {
          if (t['tripCost'] != null) totalCost += (t['tripCost'] as num).toDouble();
          if (t['revenue'] != null) totalRevenue += (t['revenue'] as num).toDouble();
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
          'totalRevenue': totalRevenue,
          'totalProfit': totalRevenue - totalCost,
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
            _statCard(0, 'Vehicles', s['totalVehicles'].toString(), Icons.local_shipping),
            _statCard(1, 'Drivers', '${s['activeDrivers']} / ${s['totalDrivers']} active', Icons.person),
            _statCard(2, 'Orders', s['totalOrders'].toString(), Icons.receipt_long),
            _statCard(3, 'Trips', s['totalTrips'].toString(), Icons.route),
            _statCard(4, 'Total Cost (Delivered)', '\u20a6${(s['totalCost'] as double).toStringAsFixed(2)}', Icons.attach_money),
            _statCard(5, 'Total Revenue (Delivered)', '\u20a6${(s['totalRevenue'] as double).toStringAsFixed(2)}', Icons.trending_up),
            _statCard(0, 'Profit (Delivered)', '\u20a6${(s['totalProfit'] as double).toStringAsFixed(2)}', Icons.savings),
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

  Widget _statCard(int gradientIndex, String label, String value, IconData icon) {
    final gradient = AppTheme.gradients[gradientIndex % AppTheme.gradients.length];
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: gradient[0].withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _breakdownSection(String title, Map<String, int> counts) {
    if (counts.isEmpty) {
      return Text('$title \u2014 no data yet', style: TextStyle(color: Colors.grey.shade600));
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
