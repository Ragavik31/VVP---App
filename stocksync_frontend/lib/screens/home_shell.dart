import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import 'admin_order_management_screen.dart';
import 'client_list_screen.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';
import 'sales_billing_placeholder_screen.dart';
import 'staff_order_management_screen.dart';
import 'vaccine_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  List<Widget> get _pages {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isClient = auth.currentUser?.role == 'client';
    
    if (isClient) {
      return const [
        DashboardScreen(),
        VaccineListScreen(),
      ];
    } else {
      final isStaff = auth.currentUser?.role == 'staff';
      if (isStaff) {
        return const [
          DashboardScreen(),
          StaffOrderManagementScreen(),
          VaccineListScreen(),
        ];
      } else {
        return const [
          DashboardScreen(),
          AdminOrderManagementScreen(),
          ClientListScreen(),
          VaccineListScreen(),
          SalesBillingPlaceholderScreen(),
        ];
      }
    }
  }

  List<String> get _titles {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isClient = auth.currentUser?.role == 'client';
    
    if (isClient) {
      return const [
        'Dashboard',
        'Vaccines',
      ];
    } else {
      final isStaff = auth.currentUser?.role == 'staff';
      if (isStaff) {
        return const [
          'Dashboard',
          'Orders',
          'Vaccines',
        ];
      } else {
        return const [
          'Dashboard',
          'Order Management',
          'Clients',
          'Vaccines',
          'Sales',
        ];
      }
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isClient = auth.currentUser?.role == 'client';
    
    if (isClient) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.vaccines),
          label: 'Vaccines',
        ),
      ];
    } else {
      final isStaff = auth.currentUser?.role == 'staff';
      if (isStaff) {
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vaccines),
            label: 'Vaccines',
          ),
        ];
      } else {
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vaccines),
            label: 'Vaccines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Sales',
          ),
        ];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    auth.logout();
                  },
                ),
              ]
            : null,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navItems,
      ),
    );
  }
}
