import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showCreateMaintenanceDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const _CreateMaintenanceDialog(),
  );
}

class _CreateMaintenanceDialog extends StatefulWidget {
  const _CreateMaintenanceDialog();

  @override
  State<_CreateMaintenanceDialog> createState() => _CreateMaintenanceDialogState();
}

class _CreateMaintenanceDialogState extends State<_CreateMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _odometerController = TextEditingController();
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
      await _api.post('/maintenance', {
        'vehicleId': _selectedVehicleId,
        'serviceType': _serviceTypeController.text.trim(),
        if (_descriptionController.text.trim().isNotEmpty) 'description': _descriptionController.text.trim(),
        if (_costController.text.trim().isNotEmpty) 'cost': double.tryParse(_costController.text.trim()),
        if (_odometerController.text.trim().isNotEmpty)
          'odometerAtService': double.tryParse(_odometerController.text.trim()),
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
      title: const Text('Log Maintenance'),
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
                                child: Text(v['plateNumber'] ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedVehicleId = v),
                    ),
                    TextFormField(
                      controller: _serviceTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Service type *',
                        hintText: 'e.g. Oil Change, Tire Rotation, Brake Service',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(labelText: 'Cost (₦)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _odometerController,
                      decoration: const InputDecoration(labelText: 'Odometer at service'),
                      keyboardType: TextInputType.number,
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
