import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showLocationDetailDialog(BuildContext context, Map<String, dynamic> location) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _LocationDetailDialog(location: location),
  );
}

class _LocationDetailDialog extends StatefulWidget {
  final Map<String, dynamic> location;
  const _LocationDetailDialog({required this.location});

  @override
  State<_LocationDetailDialog> createState() => _LocationDetailDialogState();
}

class _LocationDetailDialogState extends State<_LocationDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _addressController;
  final _api = ApiClient();

  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location['name'] ?? '');
    _typeController = TextEditingController(text: widget.location['type'] ?? '');
    _addressController = TextEditingController(text: widget.location['address'] ?? '');
    _isActive = widget.location['isActive'] as bool? ?? true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.patch('/locations/${widget.location['id']}', {
        'name': _nameController.text.trim(),
        'type': _typeController.text.trim(),
        'address': _addressController.text.trim(),
      });
      if (_isActive != (widget.location['isActive'] as bool? ?? true)) {
        await _api.patch('/locations/${widget.location['id']}/active', {'isActive': _isActive});
      }
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
      title: const Text('Edit Location'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  hintText: 'e.g. Loading Terminal, Filling Station, Tank Farm',
                ),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
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
