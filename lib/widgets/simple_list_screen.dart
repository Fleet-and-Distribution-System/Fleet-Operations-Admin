import 'package:flutter/material.dart';
import '../api/api_client.dart';

class SimpleListScreen extends StatefulWidget {
  final String title;
  final String endpoint;
  final Widget Function(BuildContext context, dynamic item) itemBuilder;
  final VoidCallback? onLogout;

  const SimpleListScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.itemBuilder,
    this.onLogout,
  });

  @override
  State<SimpleListScreen> createState() => _SimpleListScreenState();
}

class _SimpleListScreenState extends State<SimpleListScreen> {
  final _api = ApiClient();
  List<dynamic>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SimpleListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endpoint != widget.endpoint) _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _items = null;
    });
    try {
      final result = await _api.get(widget.endpoint);
      final list = result is Map && result.containsKey('data') ? result['data'] : result;
      if (!mounted) return;
      setState(() => _items = list as List<dynamic>);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not reach the server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          Center(child: FilledButton(onPressed: _load, child: const Text('Retry'))),
        ],
      );
    }

    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items!.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text('No ${widget.title.toLowerCase()} yet.')),
        ],
      );
    }

    return ListView.builder(
      itemCount: _items!.length,
      itemBuilder: (context, index) => widget.itemBuilder(context, _items![index]),
    );
  }
}
