import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../widgets/simple_list_screen.dart';
import '../widgets/create_vehicle_dialog.dart';
import '../widgets/create_customer_dialog.dart';
import '../widgets/create_driver_dialog.dart';
import '../widgets/create_order_dialog.dart';
import '../widgets/dispatch_trip_dialog.dart';
import '../widgets/vehicle_detail_dialog.dart';
import '../widgets/driver_detail_dialog.dart';
import '../widgets/customer_detail_dialog.dart';
import '../widgets/order_detail_dialog.dart';
import 'login_screen.dart';
import 'trip_detail_screen.dart';
import 'dashboard_summary_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _api = ApiClient();

  final _vehiclesController = ListRefreshController();
  final _customersController = ListRefreshController();
  final _driversController = ListRefreshController();
  final _ordersController = ListRefreshController();
  final _tripsController = ListRefreshController();

  static const _destinations = [
    (icon: Icons.dashboard, label: 'Dashboard'),
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
        return const DashboardSummaryScreen();
      case 1:
        return SimpleListScreen(
          title: 'Vehicles',
          endpoint: '/vehicles',
          controller: _vehiclesController,
          itemBuilder: (context, v) => ListTile(
            leading: const Icon(Icons.local_shipping),
            title: Text(v['plateNumber'] ?? ''),
            subtitle: Text('${v['make'] ?? ''} ${v['model'] ?? ''} — ${v['vehicleType'] ?? ''}'),
            trailing: Chip(label: Text(v['status'] ?? '')),
            onTap: () async {
              final changed = await showVehicleDetailDialog(context, v as Map<String, dynamic>);
              if (changed == true) _vehiclesController.refresh();
            },
          ),
        );
      case 2:
        return SimpleListScreen(
          title: 'Drivers',
          endpoint: '/drivers',
          controller: _driversController,
          itemBuilder: (context, d) => ListTile(
            leading: const Icon(Icons.person),
            title: Text(d['fullName'] ?? ''),
            subtitle: Text(d['phone'] ?? ''),
            trailing: Chip(
              label: Text(d['isActive'] == true ? 'ACTIVE' : 'INACTIVE'),
              backgroundColor: d['isActive'] == true ? null : Colors.grey.shade300,
            ),
            onTap: () async {
              final changed = await showDriverDetailDialog(context, d as Map<String, dynamic>);
              if (changed == true) _driversController.refresh();
            },
          ),
        );
      case 3:
        return SimpleListScreen(
          title: 'Customers',
          endpoint: '/customers',
          controller: _customersController,
          itemBuilder: (context, c) => ListTile(
            leading: const Icon(Icons.store),
            title: Text(c['name'] ?? ''),
            subtitle: Text(c['contactName'] ?? ''),
            trailing: Text(c['contactPhone'] ?? ''),
            onTap: () async {
              final changed = await showCustomerDetailDialog(context, c as Map<String, dynamic>);
              if (changed == true) _customersController.refresh();
            },
          ),
        );
      case 4:
        return SimpleListScreen(
          title: 'Orders',
          endpoint: '/orders',
          controller: _ordersController,
          itemBuilder: (context, o) => ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(o['orderNumber'] ?? ''),
            subtitle: Text('${o['pickupLocation'] ?? ''} → ${o['destinationLocation'] ?? ''}'),
            trailing: Chip(label: Text(o['status'] ?? '')),
            onTap: () async {
              final changed = await showOrderDetailDialog(context, o as Map<String, dynamic>);
              if (changed == true) _ordersController.refresh();
            },
          ),
        );
      case 5:
        return SimpleListScreen(
          title: 'Trips',
          endpoint: '/trips',
          controller: _tripsController,
          itemBuilder: (context, t) => ListTile(
            leading: const Icon(Icons.route),
            title: Text(t['transportOrder']?['orderNumber'] ?? t['id'] ?? ''),
            subtitle: Text('${t['vehicle']?['plateNumber'] ?? ''} — ${t['driver']?['fullName'] ?? ''}'),
            trailing: Chip(label: Text(t['status'] ?? '')),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: t['id'] as String)),
              );
              _tripsController.refresh();
            },
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onFabPressed() async {
    bool? created;
    switch (_selectedIndex) {
      case 1:
        created = await showCreateVehicleDialog(context);
        if (created == true) _vehiclesController.refresh();
        break;
      case 2:
        created = await showCreateDriverDialog(context);
        if (created == true) _driversController.refresh();
        break;
      case 3:
        created = await showCreateCustomerDialog(context);
        if (created == true) _customersController.refresh();
        break;
      case 4:
        created = await showCreateOrderDialog(context);
        if (created == true) _ordersController.refresh();
        break;
      case 5:
        created = await showDispatchTripDialog(context);
        if (created == true) _tripsController.refresh();
        break;
    }
  }

  bool get _hasFabForCurrentTab => _selectedIndex >= 1 && _selectedIndex <= 5;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    final body = _buildScreen(_selectedIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text('Fleet Ops — ${_destinations[_selectedIndex].label}'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      floatingActionButton: _hasFabForCurrentTab
          ? FloatingActionButton(onPressed: _onFabPressed, child: const Icon(Icons.add))
          : null,
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
