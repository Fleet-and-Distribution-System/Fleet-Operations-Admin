import 'package:flutter/material.dart';
import '../api/api_client.dart';

const _orderStatuses = ['PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];

Future<bool?> showOrderDetailDialog(BuildContext context, Map<String, dynamic> order) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _OrderDetailDialog(order: order),
  );
}

class _OrderDetailDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  const _OrderDetailDialog({required this.order});

  @override
  State<_OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<_OrderDetailDialog> {
  final _api = ApiClient();
  late String _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'] as String? ?? 'PENDING';
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.patch('/orders/${widget.order['id']}/status', {'status': _status});
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
    final o = widget.order;
    return AlertDialog(
      title: Text(o['orderNumber'] ?? 'Order'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Customer', o['customer']?['name']),
            _kv('Pickup', o['pickupLocation']),
            _kv('Destination', o['destinationLocation']),
            _kv('Cargo', o['cargoDescription']),
            if (o['quantityLitres'] != null) _kv('Quantity', '${o['quantityLitres']} litres'),
            _kv('Priority', o['priority']),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _orderStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: changing status here does not affect any linked trip or vehicle assignment.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Close')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Status'),
        ),
      ],
    );
  }

  Widget _kv(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
