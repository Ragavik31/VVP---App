import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'client_dashboard_screen.dart';
import 'client_my_orders_screen.dart';
import 'client_order_placement_screen.dart';
import 'vaccine_list_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _index = 0;

  void _goToCart() {
    setState(() => _index = 2);
  }

  static const _pageTitles = ['Dashboard', 'Products', 'Cart', 'My Orders'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      ClientDashboardScreen(onPlaceOrder: _goToCart),
      const VaccineListScreen(),
      ClientOrderPlacementScreen(onOrderPlaced: () => setState(() => _index = 3)),
      const ClientMyOrdersScreen(),
    ];

    return Scaffold(
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
          if (_index == 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => Provider.of<AuthProvider>(context, listen: false).logout(),
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
      body: IndexedStack(index: _index, children: pages),
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
              children: [
                _navItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
                _navItem(1, Icons.medical_services_rounded, Icons.medical_services_outlined, 'Products'),
                _navItem(2, Icons.shopping_cart_rounded, Icons.shopping_cart_outlined, 'Cart'),
                _navItem(3, Icons.history_rounded, Icons.history_outlined, 'My Orders'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData icon, String label) {
    final selected = _index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = index),
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
              selected ? activeIcon : icon,
              color: selected ? const Color(0xFF4361EE) : const Color(0xFF6B7A9D),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF4361EE) : const Color(0xFF6B7A9D),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
