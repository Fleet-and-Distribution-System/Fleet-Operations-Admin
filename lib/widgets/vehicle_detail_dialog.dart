import 'package:flutter/material.dart';
import '../api/api_client.dart';

const _statuses = [
  'AVAILABLE',
  'LOADING',
  'IN_TRANSIT',
  'DELIVERED',
  'MAINTENANCE',
  'ACCIDENT',
  'BREAKDOWN',
  'PARKED',
  'INACTIVE',
];

Future<bool?> showVehicleDetailDialog(BuildContext context, Map<String, dynamic> vehicle) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _VehicleDetailDialog(vehicle: vehicle),
  );
}

class _VehicleDetailDialog extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const _VehicleDetailDialog({required this.vehicle});

  @override
  State<_VehicleDetailDialog> createState() => _VehicleDetailDialogState();
}

class _VehicleDetailDialogState extends State<_VehicleDetailDialog> {
  final _api = ApiClient();
  late String _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.vehicle['status'] as String? ?? 'AVAILABLE';
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.patch('/vehicles/${widget.vehicle['id']}/status', {'status': _status});
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
    final v = widget.vehicle;
    return AlertDialog(
      title: Text(v['plateNumber'] ?? 'Vehicle'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${v['make'] ?? ''} ${v['model'] ?? ''} — ${v['vehicleType'] ?? ''}'),
            if (v['capacity'] != null) Text('Capacity: ${v['capacity']} kg'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
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
}
