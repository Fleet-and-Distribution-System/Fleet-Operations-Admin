import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showCreateFuelLogDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const _CreateFuelLogDialog(),
  );
}

class _CreateFuelLogDialog extends StatefulWidget {
  const _CreateFuelLogDialog();

  @override
  State<_CreateFuelLogDialog> createState() => _CreateFuelLogDialogState();
}

class _CreateFuelLogDialogState extends State<_CreateFuelLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _odometerController = TextEditingController();
  final _stationController = TextEditingController();
  final _api = ApiClient();

  List<dynamic>? _vehicles;
  String? _selectedVehicleId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final result = await _api.get('/vehicles');
      if (!mounted) return;
      setState(() => _vehicles = result as List<dynamic>);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load vehicles.');
    }
  }

  String? get _unitHint {
    if (_selectedVehicleId == null || _vehicles == null) return null;
    final vehicle = _vehicles!.firstWhere(
      (v) => v['id'] == _selectedVehicleId,
      orElse: () => null,
    );
    final fuelType = (vehicle?['fuelType'] as String?)?.toUpperCase();
    if (fuelType == 'CNG') return 'Kg';
    if (fuelType == 'DIESEL' || fuelType == 'PETROL') return 'Litres';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      setState(() => _error = 'Select a vehicle.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.post('/fuel', {
        'vehicleId': _selectedVehicleId,
        'quantity': double.tryParse(_quantityController.text.trim()),
        if (_costController.text.trim().isNotEmpty) 'cost': double.tryParse(_costController.text.trim()),
        if (_odometerController.text.trim().isNotEmpty)
          'odometerAtFueling': double.tryParse(_odometerController.text.trim()),
        if (_stationController.text.trim().isNotEmpty) 'station': _stationController.text.trim(),
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
    final unitHint = _unitHint;
    return AlertDialog(
      title: const Text('Log Fuel'),
      content: SizedBox(
        width: 400,
        child: _vehicles == null
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleId,
                      decoration: const InputDecoration(labelText: 'Vehicle *'),
                      items: _vehicles!
                          .map((v) => DropdownMenuItem<String>(
                                value: v['id'] as String,
                                child: Text('${v['plateNumber'] ?? ''}${v['fuelType'] != null ? ' (${v['fuelType']})' : ''}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedVehicleId = v),
                    ),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        suffixText: unitHint,
                        helperText: unitHint == null ? 'Select a vehicle to see the correct unit' : null,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Enter a valid number' : null,
                    ),
                    TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(labelText: 'Cost (₦)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _odometerController,
                      decoration: const InputDecoration(labelText: 'Odometer at fueling'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _stationController,
                      decoration: const InputDecoration(labelText: 'Station'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        if (_vehicles != null)
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
      ],
    );
  }
}
