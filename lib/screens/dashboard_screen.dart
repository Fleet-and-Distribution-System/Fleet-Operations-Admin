import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiClient();
  List<dynamic>? _vehicles;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _error = null);
    try {
      final result = await _api.get('/vehicles');
      setState(() => _vehicles = result as List<dynamic>);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not reach the server.');
    }
  }

  Future<void> _logout() async {
    await _api.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Ops — Vehicles'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVehicles,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          Center(child: FilledButton(onPressed: _loadVehicles, child: const Text('Retry'))),
        ],
      );
    }

    if (_vehicles == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicles!.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No vehicles yet.')),
        ],
      );
    }

    return ListView.builder(
      itemCount: _vehicles!.length,
      itemBuilder: (context, index) {
        final v = _vehicles![index];
        return ListTile(
          leading: const Icon(Icons.local_shipping),
          title: Text(v['plateNumber'] ?? ''),
          subtitle: Text('${v['make'] ?? ''} ${v['model'] ?? ''} — ${v['vehicleType'] ?? ''}'),
          trailing: Chip(label: Text(v['status'] ?? '')),
        );
      },
    );
  }
}
