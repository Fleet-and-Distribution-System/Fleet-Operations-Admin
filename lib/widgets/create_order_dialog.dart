import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showCreateOrderDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const _CreateOrderDialog(),
  );
}

class _CreateOrderDialog extends StatefulWidget {
  const _CreateOrderDialog();

  @override
  State<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<_CreateOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _cargoController = TextEditingController();
  final _weightController = TextEditingController();
  final _api = ApiClient();

  List<dynamic>? _customers;
  List<dynamic> _locations = [];
  String? _selectedCustomerId;
  String _priority = 'normal';
  bool _saving = false;
  String? _error;

  // Coordinates captured when a saved Location chip is tapped — cleared if
  // the person then hand-edits the text field, since free-typed text has no
  // known coordinates to attach.
  double? _pickupLat;
  double? _pickupLng;
  double? _destinationLat;
  double? _destinationLng;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadLocations();
  }

  Future<void> _loadCustomers() async {
    try {
      final result = await _api.get('/customers');
      if (!mounted) return;
      setState(() => _customers = result as List<dynamic>);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load customers.');
    }
  }

  Future<void> _loadLocations() async {
    try {
      final result = await _api.get('/locations');
      if (!mounted) return;
      setState(() {
        _locations = (result as List<dynamic>).where((l) => l['isActive'] == true).toList();
      });
    } catch (e) {
      // Non-fatal
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      setState(() => _error = 'Select a customer.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.post('/orders', {
        'customerId': _selectedCustomerId,
        'pickupLocation': _pickupController.text.trim(),
        if (_pickupLat != null) 'pickupLat': _pickupLat,
        if (_pickupLng != null) 'pickupLng': _pickupLng,
        'destinationLocation': _destinationController.text.trim(),
        if (_destinationLat != null) 'destinationLat': _destinationLat,
        if (_destinationLng != null) 'destinationLng': _destinationLng,
        if (_cargoController.text.trim().isNotEmpty) 'cargoDescription': _cargoController.text.trim(),
        if (_weightController.text.trim().isNotEmpty)
          'quantityLitres': double.tryParse(_weightController.text.trim()),
        'priority': _priority,
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

  Widget _locationField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required bool isPickup,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          validator: validator,
          onChanged: (_) => setState(() {
            // Free-typed text has no known coordinates — clear whatever was
            // captured from a chip tap so we don't silently attach stale/wrong coords.
            if (isPickup) {
              _pickupLat = null;
              _pickupLng = null;
            } else {
              _destinationLat = null;
              _destinationLng = null;
            }
          }),
        ),
        if (_locations.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: -8,
            children: _locations.map((loc) {
              final hasCoords = loc['lat'] != null && loc['lng'] != null;
              return ActionChip(
                label: Text(
                  '${loc['name']}${hasCoords ? '' : ' (no coords)'}',
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  controller.text = loc['name'] as String;
                  final lat = (loc['lat'] as num?)?.toDouble();
                  final lng = (loc['lng'] as num?)?.toDouble();
                  if (isPickup) {
                    _pickupLat = lat;
                    _pickupLng = lng;
                  } else {
                    _destinationLat = lat;
                    _destinationLng = lng;
                  }
                }),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Transport Order'),
      content: SizedBox(
        width: 420,
        child: _customers == null
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : _customers!.isEmpty
                ? const Text('No customers yet — add a customer first before creating an order.')
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: const InputDecoration(labelText: 'Customer *'),
                            items: _customers!
                                .map((c) => DropdownMenuItem<String>(
                                      value: c['id'] as String,
                                      child: Text(c['name'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCustomerId = v),
                          ),
                          const SizedBox(height: 8),
                          _locationField(
                            controller: _pickupController,
                            label: 'Pickup location *',
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            isPickup: true,
                          ),
                          _locationField(
                            controller: _destinationController,
                            label: 'Destination *',
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            isPickup: false,
                          ),
                          TextFormField(
                            controller: _cargoController,
                            decoration: const InputDecoration(labelText: 'Cargo description'),
                          ),
                          TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(labelText: 'Quantity (Litres)'),
                            keyboardType: TextInputType.number,
                          ),
                          DropdownButtonFormField<String>(
                            value: _priority,
                            decoration: const InputDecoration(labelText: 'Priority'),
                            items: const [
                              DropdownMenuItem(value: 'normal', child: Text('Normal')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                              DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                            ],
                            onChanged: (v) => setState(() => _priority = v ?? 'normal'),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        if (_customers != null && _customers!.isNotEmpty)
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
