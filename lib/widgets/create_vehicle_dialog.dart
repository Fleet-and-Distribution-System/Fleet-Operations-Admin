import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showCreateVehicleDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const _CreateVehicleDialog(),
  );
}

class _CreateVehicleDialog extends StatefulWidget {
  const _CreateVehicleDialog();

  @override
  State<_CreateVehicleDialog> createState() => _CreateVehicleDialogState();
}

class _CreateVehicleDialogState extends State<_CreateVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _typeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _api = ApiClient();

  String? _fuelType;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.post('/vehicles', {
        'plateNumber': _plateController.text.trim(),
        if (_makeController.text.trim().isNotEmpty) 'make': _makeController.text.trim(),
        if (_modelController.text.trim().isNotEmpty) 'model': _modelController.text.trim(),
        if (_typeController.text.trim().isNotEmpty) 'vehicleType': _typeController.text.trim(),
        if (_capacityController.text.trim().isNotEmpty)
          'capacity': double.tryParse(_capacityController.text.trim()),
        if (_fuelType != null) 'fuelType': _fuelType,
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
      title: const Text('Add Vehicle'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Plate number *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(controller: _makeController, decoration: const InputDecoration(labelText: 'Make')),
              TextFormField(controller: _modelController, decoration: const InputDecoration(labelText: 'Model')),
              TextFormField(controller: _typeController, decoration: const InputDecoration(labelText: 'Vehicle type')),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity (kg)'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: _fuelType,
                decoration: const InputDecoration(labelText: 'Fuel / Engine type'),
                items: const [
                  DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                  DropdownMenuItem(value: 'PETROL', child: Text('Petrol')),
                  DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                ],
                onChanged: (v) => setState(() => _fuelType = v),
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
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }
}
