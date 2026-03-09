import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'admin_order_management_screen.dart';
import 'client_form_screen.dart';
import 'client_list_screen.dart';
import 'dashboard_screen.dart';
import 'sales_billing_placeholder_screen.dart';
import 'staff_order_management_screen.dart';
import 'vaccine_form_page.dart';
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
    if (isClient) return [
      DashboardScreen(onGoToProducts: () => setState(() => _currentIndex = 1)),
      const VaccineListScreen(),
    ];
    final isStaff = auth.currentUser?.role == 'staff';
    if (isStaff) return const [DashboardScreen(), StaffOrderManagementScreen(), VaccineListScreen()];
    return const [DashboardScreen(), AdminOrderManagementScreen(), ClientListScreen(), VaccineListScreen(), SalesBillingPlaceholderScreen()];
  }

  List<String> get _titles {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser?.role == 'client') return ['Dashboard', 'Vaccines'];
    if (auth.currentUser?.role == 'staff') return ['Dashboard', 'Orders', 'Vaccines'];
    return ['Dashboard', 'Orders', 'Clients', 'Vaccines', 'Sales'];
  }

  List<_NavItem> get _navDefs {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser?.role == 'client') {
      return [
        _NavItem(Icons.dashboard_rounded, Icons.dashboard, 'Dashboard'),
        _NavItem(Icons.vaccines_rounded, Icons.vaccines, 'Vaccines'),
      ];
    }
    if (auth.currentUser?.role == 'staff') {
      return [
        _NavItem(Icons.dashboard_rounded, Icons.dashboard, 'Dashboard'),
        _NavItem(Icons.assignment_rounded, Icons.assignment, 'Orders'),
        _NavItem(Icons.vaccines_rounded, Icons.vaccines, 'Vaccines'),
      ];
    }
    return [
      _NavItem(Icons.dashboard_rounded, Icons.dashboard, 'Dashboard'),
      _NavItem(Icons.assignment_rounded, Icons.assignment, 'Orders'),
      _NavItem(Icons.people_alt_rounded, Icons.people, 'Clients'),
      _NavItem(Icons.vaccines_rounded, Icons.vaccines, 'Vaccines'),
      _NavItem(Icons.receipt_long_rounded, Icons.receipt_long, 'Sales'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final navDefs = _navDefs;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      extendBody: true,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(2),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 2 && auth.currentUser?.role == 'admin')
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
              tooltip: 'Add Client',
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ClientFormScreen()));
              },
            ),
          if (_currentIndex == 3 && auth.currentUser?.role == 'admin')
            IconButton(
              icon: const Icon(Icons.add_box_rounded, color: Colors.white),
              tooltip: 'Add Product',
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VaccineFormScreen()));
              },
            ),
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => auth.logout(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Logout',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4361EE).withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navDefs.length, (i) {
                final item = navDefs[i];
                final selected = i == _currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF4361EE).withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected ? const Color(0xFF4361EE) : const Color(0xFF6B7A9D),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? const Color(0xFF4361EE) : const Color(0xFF6B7A9D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}
