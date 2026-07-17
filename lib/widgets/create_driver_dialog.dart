import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showCreateDriverDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const _CreateDriverDialog(),
  );
}

class _CreateDriverDialog extends StatefulWidget {
  const _CreateDriverDialog();

  @override
  State<_CreateDriverDialog> createState() => _CreateDriverDialogState();
}

class _CreateDriverDialogState extends State<_CreateDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiClient();

  bool _createLogin = true;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.post('/drivers', {
        'fullName': _fullNameController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
        if (_licenseController.text.trim().isNotEmpty) 'licenseNumber': _licenseController.text.trim(),
        if (_createLogin && _phoneController.text.trim().isNotEmpty) ...{
          'loginPhone': _phoneController.text.trim(),
          'loginPassword': _passwordController.text,
        },
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
      title: const Text('Add Driver'),
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
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(labelText: 'License number'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Create login for this driver'),
                value: _createLogin,
                onChanged: (v) => setState(() => _createLogin = v ?? true),
              ),
              if (_createLogin)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Login password'),
                  obscureText: true,
                  validator: (v) {
                    if (!_createLogin) return null;
                    if (_phoneController.text.trim().isEmpty) return null;
                    if (v == null || v.length < 6) return 'At least 6 characters';
                    return null;
                  },
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
