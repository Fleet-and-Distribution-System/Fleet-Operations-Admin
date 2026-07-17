import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showRecordPodDialog(BuildContext context, String waybillId) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _RecordPodDialog(waybillId: waybillId),
  );
}

class _RecordPodDialog extends StatefulWidget {
  final String waybillId;
  const _RecordPodDialog({required this.waybillId});

  @override
  State<_RecordPodDialog> createState() => _RecordPodDialogState();
}

class _RecordPodDialogState extends State<_RecordPodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _signedByController = TextEditingController();
  final _api = ApiClient();

  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.patch('/waybills/${widget.waybillId}/proof-of-delivery', {
        'receiverName': _receiverNameController.text.trim(),
        if (_receiverPhoneController.text.trim().isNotEmpty)
          'receiverPhone': _receiverPhoneController.text.trim(),
        if (_signedByController.text.trim().isNotEmpty) 'signedByName': _signedByController.text.trim(),
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
      title: const Text('Record Proof of Delivery'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _receiverNameController,
                decoration: const InputDecoration(labelText: 'Receiver name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _receiverPhoneController,
                decoration: const InputDecoration(labelText: 'Receiver phone'),
              ),
              TextFormField(
                controller: _signedByController,
                decoration: const InputDecoration(labelText: 'Signed by'),
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
