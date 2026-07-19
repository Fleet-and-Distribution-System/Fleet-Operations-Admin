import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../widgets/create_waybill_dialog.dart';
import '../widgets/record_pod_dialog.dart';
import '../web_download.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _trip;
  String? _error;
  bool _actionInProgress = false;
  bool _downloadingPdf = false;
  bool _settingCost = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await _api.get('/trips/${widget.tripId}');
      if (!mounted) return;
      setState(() => _trip = result as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not reach the server.');
    }
  }

  Future<void> _runAction(String action) async {
    setState(() => _actionInProgress = true);
    try {
      await _api.patch('/trips/${widget.tripId}/$action', {});
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not reach the server.')));
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Detail')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_trip == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final t = _trip!;
    final order = t['transportOrder'] as Map<String, dynamic>?;
    final vehicle = t['vehicle'] as Map<String, dynamic>?;
    final driver = t['driver'] as Map<String, dynamic>?;
    final waybill = t['waybill'] as Map<String, dynamic>?;
    final status = t['status'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Text(order?['orderNumber'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(width: 12),
            Chip(label: Text(status)),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('Route'),
        _kv('Pickup', order?['pickupLocation']),
        _kv('Destination', order?['destinationLocation']),
        _kv('Cargo', order?['cargoDescription']),
        const SizedBox(height: 16),
        _sectionTitle('Assignment'),
        _kv('Vehicle', vehicle != null ? '${vehicle['plateNumber']} — ${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}' : null),
        _kv('Driver', driver?['fullName']),
        const SizedBox(height: 16),
        _sectionTitle('Timeline'),
        _kv('Planned departure', t['plannedDeparture']),
        _kv('Actual departure', t['actualDeparture']),
        _kv('Actual arrival', t['actualArrival']),
        const SizedBox(height: 16),
        _sectionTitle('Cost'),
        _kv('Trip cost', t['tripCost'] != null ? '₦${t['tripCost']}' : null),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _settingCost ? null : () => _showSetCostDialog(t['tripCost'] as num?),
          icon: _settingCost
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.attach_money),
          label: Text(t['tripCost'] != null ? 'Update Cost' : 'Set Cost'),
        ),
        if (waybill != null) ...[
          const SizedBox(height: 16),
          _sectionTitle('Waybill'),
          _kv('Waybill number', waybill['waybillNumber']),
          _kv('Signed by', waybill['signedByName']),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _downloadingPdf ? null : () => _downloadPdf(waybill['id'] as String, waybill['waybillNumber'] as String),
            icon: _downloadingPdf
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            label: Text(_downloadingPdf ? 'Downloading…' : 'Download PDF'),
          ),
        ],
        const SizedBox(height: 32),
        _buildActions(status),
      ],
    );
  }

  Widget _buildActions(String status) {
    final buttons = <Widget>[];

    if (status == 'ASSIGNED') {
      buttons.add(FilledButton.icon(
        onPressed: _actionInProgress ? null : () => _runAction('start'),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Trip'),
      ));
    }
    if (status == 'IN_TRANSIT') {
      buttons.add(FilledButton.icon(
        onPressed: _actionInProgress ? null : () => _runAction('complete'),
        icon: const Icon(Icons.check),
        label: const Text('Complete Trip'),
      ));
    }
    if (status == 'ASSIGNED' || status == 'IN_TRANSIT') {
      buttons.add(OutlinedButton.icon(
        onPressed: _actionInProgress ? null : () => _runAction('cancel'),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Cancel Trip'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
      ));
    }

    if (status == 'DELIVERED') {
      final waybill = _trip?['waybill'] as Map<String, dynamic>?;
      if (waybill == null) {
        buttons.add(FilledButton.icon(
          onPressed: _actionInProgress ? null : _createWaybill,
          icon: const Icon(Icons.receipt_long),
          label: const Text('Create Waybill'),
        ));
      } else if (waybill['signedAt'] == null) {
        buttons.add(FilledButton.icon(
          onPressed: _actionInProgress ? null : _recordPod,
          icon: const Icon(Icons.edit_note),
          label: const Text('Record Proof of Delivery'),
        ));
      }
    }

    if (buttons.isEmpty) {
      return Text(
        'No further actions — trip is $status.',
        style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
      );
    }

    return Wrap(spacing: 12, children: buttons);
  }

  Future<void> _createWaybill() async {
    final created = await showCreateWaybillDialog(context, widget.tripId);
    if (created == true) await _load();
  }

  Future<void> _recordPod() async {
    final waybill = _trip?['waybill'] as Map<String, dynamic>?;
    if (waybill == null) return;
    final saved = await showRecordPodDialog(context, waybill['id'] as String);
    if (saved == true) await _load();
  }

  Future<void> _showSetCostDialog(num? currentCost) async {
    final controller = TextEditingController(text: currentCost?.toString() ?? '');
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Trip Cost'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Cost (₦)', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;

    setState(() => _settingCost = true);
    try {
      await _api.patch('/trips/${widget.tripId}/cost', {'tripCost': result});
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not reach the server.')));
    } finally {
      if (mounted) setState(() => _settingCost = false);
    }
  }

  Future<void> _downloadPdf(String waybillId, String waybillNumber) async {
    setState(() => _downloadingPdf = true);
    try {
      final bytes = await _api.getBytes('/waybills/$waybillId/pdf');
      downloadBytesAsFile(bytes, '$waybillNumber.pdf');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not download the PDF.')));
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _kv(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
