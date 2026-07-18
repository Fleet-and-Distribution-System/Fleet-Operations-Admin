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
  List<String> _locationNames = [];
  String? _selectedCustomerId;
  String _priority = 'normal';
  bool _saving = false;
  String? _error;

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
        _locationNames = (result as List<dynamic>)
            .where((l) => l['isActive'] == true)
            .map((l) => l['name'] as String)
            .toList();
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
        'destinationLocation': _destinationController.text.trim(),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          validator: validator,
          onChanged: (_) => setState(() {}),
        ),
        if (_locationNames.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: -8,
            children: _locationNames.map((name) {
              return ActionChip(
                label: Text(name, style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => controller.text = name),
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
                          ),
                          _locationField(
                            controller: _destinationController,
                            label: 'Destination *',
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
