import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showDriverDetailDialog(BuildContext context, Map<String, dynamic> driver) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _DriverDetailDialog(driver: driver),
  );
}

class _DriverDetailDialog extends StatefulWidget {
  final Map<String, dynamic> driver;
  const _DriverDetailDialog({required this.driver});

  @override
  State<_DriverDetailDialog> createState() => _DriverDetailDialogState();
}

class _DriverDetailDialogState extends State<_DriverDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _licenseController;
  final _api = ApiClient();

  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.driver['fullName'] ?? '');
    _phoneController = TextEditingController(text: widget.driver['phone'] ?? '');
    _licenseController = TextEditingController(text: widget.driver['licenseNumber'] ?? '');
    _isActive = widget.driver['isActive'] as bool? ?? true;
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.patch('/drivers/${widget.driver['id']}', {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
      });
      if (_isActive != (widget.driver['isActive'] as bool? ?? true)) {
        await _api.patch('/drivers/${widget.driver['id']}/active', {'isActive': _isActive});
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
      title: const Text('Edit Driver'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(labelText: 'License number'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: _isActive ? null : const Text('Login will be disabled', style: TextStyle(color: Colors.red)),
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
          onPressed: _saving ? null : _saveDetails,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
