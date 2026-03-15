import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../auth/auth_provider.dart';

class ClientDashboardScreen extends StatefulWidget {
  final VoidCallback? onPlaceOrder;
  const ClientDashboardScreen({super.key, this.onPlaceOrder});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _recentOrders = [];
  List<dynamic> _dueSoonOrders = [];
  double _totalSpent = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resp = await ApiClient.get('/orders?limit=100');
      List<dynamic> orders = [];
      if (resp is Map<String, dynamic>) {
        final data = resp['data'];
        if (data is List) orders = data;
      } else if (resp is List) {
        orders = resp;
      }
      double total = 0;
      for (final o in orders) {
        final price = o['totalPrice'];
        if (price is num) total += price.toDouble();
      }
      if (!mounted) return;
      setState(() {
        _recentOrders = orders.take(5).toList();
        _totalSpent = total;
      });
      // Fetch due-soon cash orders
      try {
        final dueResp = await ApiClient.get('/orders/due-soon');
        List<dynamic> dueOrders = [];
        if (dueResp is Map<String, dynamic>) {
          final data = dueResp['data'];
          if (data is List) dueOrders = data;
        }
        if (mounted) setState(() => _dueSoonOrders = dueOrders);
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF233C)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return RefreshIndicator(
      color: const Color(0xFF4361EE),
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header banner with logo
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          (user?.name ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_getGreeting()} 👋',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Total amount spent chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Amount Spent',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              _totalSpent.toStringAsFixed(2),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Place Order button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onPlaceOrder,
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                        label: const Text('Place New Order',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06D6A0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF06D6A0).withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8EC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFEF233C), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Color(0xFFEF233C), fontSize: 13)),
                            ),
                          ],
                        ),
                      ),

                    // Payment Due Alert
                    if (_dueSoonOrders.isNotEmpty)
                      _buildDueAlertCard(),

                    // Last 5 orders card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4361EE).withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4361EE), Color(0xFF7B9EFF)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Text('Last 5 Orders',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0D1B2A))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isLoading)
                              const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                    color: Color(0xFF4361EE)),
                              ))
                            else if (_recentOrders.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_rounded,
                                          size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      const Text('No orders yet',
                                          style: TextStyle(color: Color(0xFF6B7A9D))),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._recentOrders.map((order) {
                                final o = order as Map<String, dynamic>;
                                final totalPrice = o['totalPrice'] ?? 0;
                                final status = o['status'] ?? 'pending';
                                final items = o['items'] as List? ?? [];
                                final createdAt = o['createdAt'];

                                String summary = '';
                                if (items.isNotEmpty) {
                                  if (items.length == 1) {
                                    summary =
                                        '${items[0]['vaccineName'] ?? items[0]['productName'] ?? 'Product'} — ${items[0]['quantity']} units';
                                  } else {
                                    final qty = items.fold<int>(
                                        0, (s, i) => s + (i['quantity'] as int? ?? 0));
                                    summary = '${items.length} items — $qty units';
                                  }
                                } else {
                                  summary =
                                      'Order #${o['_id']?.toString().substring(0, 8) ?? '—'}';
                                }

                                String date = '';
                                String timeStr = '';
                                if (createdAt != null) {
                                  try {
                                    final d = DateTime.parse(createdAt.toString()).toLocal();
                                    date = '${d.day}/${d.month}/${d.year}';
                                    final h = d.hour.toString().padLeft(2, '0');
                                    final m = d.minute.toString().padLeft(2, '0');
                                    timeStr = '$h:$m';
                                  } catch (_) {
                                    date = createdAt.toString();
                                  }
                                }

                                final statusData = _statusStyle(status);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(summary,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Color(0xFF0D1B2A))),
                                            const SizedBox(height: 4),
                                            Tooltip(
                                              message: timeStr.isNotEmpty ? "Ordered at $timeStr" : "",
                                              triggerMode: TooltipTriggerMode.tap,
                                              child: Text(date,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF6B7A9D))),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('₹$totalPrice',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF4361EE))),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusData.$2,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(status,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: statusData.$1,
                                                    fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return (const Color(0xFF06D6A0), const Color(0xFFE6FFF9));
      case 'rejected':
        return (const Color(0xFFEF233C), const Color(0xFFFFE8EC));
      case 'accepted':
        return (const Color(0xFF4361EE), const Color(0xFFEEF2FF));
      default:
        return (const Color(0xFFFFB703), const Color(0xFFFFF8E1));
    }
  }

  Widget _buildDueAlertCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB703).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB703).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20, color: Color(0xFFFFB703)),
                SizedBox(width: 8),
                Text('Payment Due',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B2A))),
              ],
            ),
            const SizedBox(height: 12),
            ..._dueSoonOrders.map((order) {
              final o = order as Map<String, dynamic>;
              final dueDateStr = (o['paymentDueDate'] ?? '').toString();
              final totalPrice = o['totalPrice'] ?? 0;
              final paymentStatus = (o['paymentStatus'] ?? '').toString();

              int daysLeft = 0;
              bool isOverdue = paymentStatus == 'overdue';
              if (dueDateStr.isNotEmpty && dueDateStr != 'null') {
                try {
                  final dueDate = DateTime.parse(dueDateStr).toLocal();
                  daysLeft = dueDate.difference(DateTime.now()).inDays;
                  if (daysLeft < 0) isOverdue = true;
                } catch (_) {}
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? const Color(0xFFFFE8EC)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverdue
                          ? Icons.error_rounded
                          : Icons.timer_rounded,
                      size: 16,
                      color: isOverdue
                          ? const Color(0xFFEF233C)
                          : const Color(0xFFFFB703),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '₹$totalPrice',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D1B2A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? const Color(0xFFEF233C)
                            : daysLeft <= 7
                                ? const Color(0xFFFFB703)
                                : const Color(0xFF4361EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOverdue
                            ? 'OVERDUE'
                            : 'Due in $daysLeft days',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
