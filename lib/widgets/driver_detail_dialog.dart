import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();

  late bool _isActive;
  String? _photoUrl;
  bool _saving = false;
  bool _resettingPassword = false;
  bool _uploadingPhoto = false;
  String? _error;
  String? _resetMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.driver['fullName'] ?? '');
    _phoneController = TextEditingController(text: widget.driver['phone'] ?? '');
    _licenseController = TextEditingController(text: widget.driver['licenseNumber'] ?? '');
    _isActive = widget.driver['isActive'] as bool? ?? true;
    _photoUrl = widget.driver['photoUrl'] as String?;
  }

  Future<void> _pickAndUploadPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final result = await _api.uploadFile('/drivers/${widget.driver['id']}/photo', 'photo', picked);
      if (!mounted) return;
      setState(() => _photoUrl = result['photoUrl'] as String?);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not upload photo.')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
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

  bool get _hasLogin => widget.driver['userId'] != null || widget.driver['phone'] != null;

  Future<void> _showResetPasswordDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Driver Password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder()),
            obscureText: true,
            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (newPassword == null) return;

    setState(() {
      _resettingPassword = true;
      _resetMessage = null;
    });
    try {
      await _api.patch('/drivers/${widget.driver['id']}/reset-password', {'newPassword': newPassword});
      if (!mounted) return;
      setState(() => _resetMessage = 'Password reset successfully.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _resetMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _resetMessage = 'Could not reach the server.');
    } finally {
      if (mounted) setState(() => _resettingPassword = false);
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
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                      child: _photoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: _uploadingPhoto
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
              if (_hasLogin) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _resettingPassword ? null : _showResetPasswordDialog,
                    icon: _resettingPassword
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.lock_reset),
                    label: const Text('Reset Password'),
                  ),
                ),
                if (_resetMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _resetMessage!,
                    style: TextStyle(color: _resetMessage!.contains('success') ? Colors.green : Colors.red, fontSize: 12),
                  ),
                ],
              ],
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
