import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showCustomerDetailDialog(BuildContext context, Map<String, dynamic> customer) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _CustomerDetailDialog(customer: customer),
  );
}

class _CustomerDetailDialog extends StatefulWidget {
  final Map<String, dynamic> customer;
  const _CustomerDetailDialog({required this.customer});

  @override
  State<_CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<_CustomerDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _contactEmailController;
  final _api = ApiClient();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer['name'] ?? '');
    _contactNameController = TextEditingController(text: widget.customer['contactName'] ?? '');
    _contactPhoneController = TextEditingController(text: widget.customer['contactPhone'] ?? '');
    _contactEmailController = TextEditingController(text: widget.customer['contactEmail'] ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.patch('/customers/${widget.customer['id']}', {
        'name': _nameController.text.trim(),
        'contactName': _contactNameController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
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
      title: const Text('Edit Customer'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _contactNameController,
                decoration: const InputDecoration(labelText: 'Contact name'),
              ),
              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(labelText: 'Contact phone'),
              ),
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(labelText: 'Contact email'),
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
