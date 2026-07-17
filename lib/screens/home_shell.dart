import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../widgets/simple_list_screen.dart';
import 'login_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _api = ApiClient();

  static const _destinations = [
    (icon: Icons.local_shipping, label: 'Vehicles'),
    (icon: Icons.person, label: 'Drivers'),
    (icon: Icons.store, label: 'Customers'),
    (icon: Icons.receipt_long, label: 'Orders'),
    (icon: Icons.route, label: 'Trips'),
  ];

  Future<void> _logout() async {
    await _api.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return SimpleListScreen(
          title: 'Vehicles',
          endpoint: '/vehicles',
          itemBuilder: (context, v) => ListTile(
            leading: const Icon(Icons.local_shipping),
            title: Text(v['plateNumber'] ?? ''),
            subtitle: Text('${v['make'] ?? ''} ${v['model'] ?? ''} — ${v['vehicleType'] ?? ''}'),
            trailing: Chip(label: Text(v['status'] ?? '')),
          ),
        );
      case 1:
        return SimpleListScreen(
          title: 'Drivers',
          endpoint: '/drivers',
          itemBuilder: (context, d) => ListTile(
            leading: const Icon(Icons.person),
            title: Text(d['fullName'] ?? ''),
            subtitle: Text(d['phone'] ?? ''),
            trailing: Chip(
              label: Text(d['isActive'] == true ? 'ACTIVE' : 'INACTIVE'),
              backgroundColor: d['isActive'] == true ? null : Colors.grey.shade300,
            ),
          ),
        );
      case 2:
        return SimpleListScreen(
          title: 'Customers',
          endpoint: '/customers',
          itemBuilder: (context, c) => ListTile(
            leading: const Icon(Icons.store),
            title: Text(c['name'] ?? ''),
            subtitle: Text(c['contactName'] ?? ''),
            trailing: Text(c['contactPhone'] ?? ''),
          ),
        );
      case 3:
        return SimpleListScreen(
          title: 'Orders',
          endpoint: '/orders',
          itemBuilder: (context, o) => ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(o['orderNumber'] ?? ''),
            subtitle: Text('${o['pickupLocation'] ?? ''} → ${o['destinationLocation'] ?? ''}'),
            trailing: Chip(label: Text(o['status'] ?? '')),
          ),
        );
      case 4:
        return SimpleListScreen(
          title: 'Trips',
          endpoint: '/trips',
          itemBuilder: (context, t) => ListTile(
            leading: const Icon(Icons.route),
            title: Text(t['transportOrder']?['orderNumber'] ?? t['id'] ?? ''),
            subtitle: Text('${t['vehicle']?['plateNumber'] ?? ''} — ${t['driver']?['fullName'] ?? ''}'),
            trailing: Chip(label: Text(t['status'] ?? '')),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    final body = _buildScreen(_selectedIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text('Fleet Ops — ${_destinations[_selectedIndex].label}'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map((d) => NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: _destinations
                  .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
                  .toList(),
            ),
    );
  }
}
