import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showDispatchTripDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const _DispatchTripDialog(),
  );
}

class _DispatchTripDialog extends StatefulWidget {
  const _DispatchTripDialog();

  @override
  State<_DispatchTripDialog> createState() => _DispatchTripDialogState();
}

class _DispatchTripDialogState extends State<_DispatchTripDialog> {
  final _api = ApiClient();

  List<dynamic>? _pendingOrders;
  List<dynamic>? _availableVehicles;
  List<dynamic>? _activeDrivers;

  String? _selectedOrderId;
  String? _selectedVehicleId;
  String? _selectedDriverId;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.get('/orders?status=PENDING'),
        _api.get('/vehicles'),
        _api.get('/drivers'),
      ]);

      final orders = results[0] as List<dynamic>;
      final vehicles = (results[1] as List<dynamic>).where((v) => v['status'] == 'AVAILABLE').toList();
      final drivers = (results[2] as List<dynamic>).where((d) => d['isActive'] == true).toList();

      if (!mounted) return;
      setState(() {
        _pendingOrders = orders;
        _availableVehicles = vehicles;
        _activeDrivers = drivers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load orders/vehicles/drivers.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedOrderId == null || _selectedVehicleId == null || _selectedDriverId == null) {
      setState(() => _error = 'Select an order, vehicle, and driver.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.post('/trips', {
        'transportOrderId': _selectedOrderId,
        'vehicleId': _selectedVehicleId,
        'driverId': _selectedDriverId,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not reach the server.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dispatch Trip'),
      content: SizedBox(
        width: 440,
        child: _loading
            ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))
            : _buildForm(),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        if (!_loading)
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Dispatch'),
          ),
      ],
    );
  }

  Widget _buildForm() {
    if (_pendingOrders != null && _pendingOrders!.isEmpty) {
      return const Text('No pending orders to dispatch — create a transport order first.');
    }
    if (_availableVehicles != null && _availableVehicles!.isEmpty) {
      return const Text('No available vehicles — every vehicle is currently loading, in transit, or unavailable.');
    }
    if (_activeDrivers != null && _activeDrivers!.isEmpty) {
      return const Text('No active drivers available.');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedOrderId,
          decoration: const InputDecoration(labelText: 'Pending order *'),
          items: _pendingOrders!
              .map((o) => DropdownMenuItem<String>(
                    value: o['id'] as String,
                    child: Text('${o['orderNumber']} — ${o['pickupLocation']} → ${o['destinationLocation']}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedOrderId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedVehicleId,
          decoration: const InputDecoration(labelText: 'Available vehicle *'),
          items: _availableVehicles!
              .map((v) => DropdownMenuItem<String>(
                    value: v['id'] as String,
                    child: Text('${v['plateNumber']} — ${v['make'] ?? ''} ${v['model'] ?? ''}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedVehicleId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedDriverId,
          decoration: const InputDecoration(labelText: 'Active driver *'),
          items: _activeDrivers!
              .map((d) => DropdownMenuItem<String>(
                    value: d['id'] as String,
                    child: Text(d['fullName'] ?? ''),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedDriverId = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}
