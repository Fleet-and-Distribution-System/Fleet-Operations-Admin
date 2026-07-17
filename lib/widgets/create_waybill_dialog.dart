import 'package:flutter/material.dart';
import '../api/api_client.dart';

Future<bool?> showCreateWaybillDialog(BuildContext context, String tripId) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _CreateWaybillDialog(tripId: tripId),
  );
}

class _CreateWaybillDialog extends StatefulWidget {
  final String tripId;
  const _CreateWaybillDialog({required this.tripId});

  @override
  State<_CreateWaybillDialog> createState() => _CreateWaybillDialogState();
}

class _CreateWaybillDialogState extends State<_CreateWaybillDialog> {
  final _sealController = TextEditingController();
  final _productsController = TextEditingController();
  final _api = ApiClient();

  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.post('/waybills', {
        'tripId': widget.tripId,
        if (_sealController.text.trim().isNotEmpty) 'sealNumber': _sealController.text.trim(),
        if (_productsController.text.trim().isNotEmpty) 'productsSummary': _productsController.text.trim(),
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
      title: const Text('Create Waybill'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _sealController, decoration: const InputDecoration(labelText: 'Seal number')),
            TextField(
              controller: _productsController,
              decoration: const InputDecoration(labelText: 'Products summary'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
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
