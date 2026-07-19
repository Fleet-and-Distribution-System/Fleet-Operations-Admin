import 'package:flutter/material.dart';
import '../api/api_client.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _api = ApiClient();

  Map<String, dynamic>? _company;
  bool _saving = false;
  String? _error;
  String? _success;

  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _changingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await _api.get('/company');
      if (!mounted) return;
      setState(() {
        _company = result as Map<String, dynamic>;
        _nameController.text = _company!['name'] ?? '';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not reach the server.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await _api.patch('/company', {'name': _nameController.text.trim()});
      if (!mounted) return;
      setState(() => _success = 'Saved.');
      await _load();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not reach the server.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _changingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });
    try {
      await _api.post('/auth/change-password', {
        'currentPassword': _currentPasswordController.text,
        'newPassword': _newPasswordController.text,
      });
      if (!mounted) return;
      setState(() => _passwordSuccess = 'Password changed.');
      _currentPasswordController.clear();
      _newPasswordController.clear();
    } on ApiException catch (e) {
      setState(() => _passwordError = e.message);
    } catch (e) {
      setState(() => _passwordError = 'Could not reach the server.');
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Settings')),
      body: _company == null
          ? (_error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : const Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Company Name', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a valid company name' : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Slug (used for login, cannot be changed here): ${_company!['slug']}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 24),
                          if (_error != null) ...[
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                          ],
                          if (_success != null) ...[
                            Text(_success!, style: const TextStyle(color: Colors.green)),
                            const SizedBox(height: 12),
                          ],
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 24),
                    Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Change Password', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: const InputDecoration(labelText: 'Current password', border: OutlineInputBorder()),
                            obscureText: true,
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder()),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          if (_passwordError != null) ...[
                            Text(_passwordError!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                          ],
                          if (_passwordSuccess != null) ...[
                            Text(_passwordSuccess!, style: const TextStyle(color: Colors.green)),
                            const SizedBox(height: 12),
                          ],
                          FilledButton(
                            onPressed: _changingPassword ? null : _changePassword,
                            child: _changingPassword
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Change Password'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
