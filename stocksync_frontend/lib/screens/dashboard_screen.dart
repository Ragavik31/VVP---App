import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onGoToProducts;
  const DashboardScreen({super.key, this.onGoToProducts});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _recentVaccines = [];
  List<dynamic> _recentOrders = [];
  int _totalProductCount = 0;
  String? _error;
  final Set<int> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      final userId = auth.currentUser?.id;
      if (token != null) {
        SocketService().connect(token: token);
        SocketService().on('vaccine:updated', (_) => _loadDashboardData());
        SocketService().on('order:created', (_) => _loadOrders());
        SocketService().on('order:status_changed', (data) {
          try {
            if (data != null && data['clientId'] == userId) _loadDashboardData();
          } catch (_) {}
        });
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final vaccinesResponse = await ApiClient.get('/products');
      List<dynamic> vaccinesList = [];
      if (vaccinesResponse is Map<String, dynamic>) {
        final data = vaccinesResponse['data'];
        if (data is List) vaccinesList = data;
      } else if (vaccinesResponse is List) {
        vaccinesList = vaccinesResponse;
      }
      if (!mounted) return;
      setState(() {
        _totalProductCount = vaccinesList.length; // ← full count
        
        // Filter for out of stock vaccines
        final outOfStock = vaccinesList.where((v) {
          final qty = int.tryParse(v['quantity']?.toString() ?? '0') ?? 0;
          return qty == 0;
        }).toList();
        
        _recentVaccines = outOfStock.take(5).toList();
      });
      await _loadOrders();
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

  Future<void> _loadOrders() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isAdmin = auth.currentUser?.role == 'admin';
      final isStaff = auth.currentUser?.role == 'staff';
      
      // Get all orders to count total orders properly
      final allResp = await ApiClient.get('/orders');
      int totalCount = 0;
      if (allResp is Map<String, dynamic> && allResp['data'] is List) {
        totalCount = (allResp['data'] as List).length;
      } else if (allResp is List) {
        totalCount = allResp.length;
      }

      final resp = await ApiClient.get(isAdmin ? '/orders/pending?limit=20' : '/orders?limit=20');
      List<dynamic> ordersList = [];
      if (resp is Map<String, dynamic>) {
        final data = resp['data'];
        if (data is List) ordersList = data;
      } else if (resp is List) ordersList = resp;
      // For admin/staff: sort by fewest items first
      if (isAdmin || isStaff) {
        if (isStaff) {
          ordersList = ordersList.where((o) => o['status'] == 'assigned' || o['status'] == 'accepted').toList();
        }
        ordersList.sort((a, b) {
          final aLen = (a['items'] is List) ? (a['items'] as List).length : 0;
          final bLen = (b['items'] is List) ? (b['items'] as List).length : 0;
          return aLen.compareTo(bLen);
        });
        ordersList = ordersList.take(5).toList();
      }
      if (!mounted) return;
      setState(() {
        _recentOrders = ordersList;
        _totalOrderCount = totalCount;
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isAdmin = user?.role == 'admin';
    final isClient = user?.role == 'client';

    return RefreshIndicator(
      color: const Color(0xFF4361EE),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()}, ${user?.name?.split(' ')[0] ?? ''} 👋',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAdmin ? 'Admin' : isClient ? 'Client' : 'Staff',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      _statChip(Icons.inventory_2_rounded,
                          '$_totalProductCount', 'Products'),
                      const SizedBox(width: 12),
                      _statChip(Icons.receipt_long_rounded,
                          '$_totalOrderCount', 'Orders'),
                    ],
                  ),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
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
                                  style: const TextStyle(color: Color(0xFFEF233C), fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    if (isClient)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: widget.onGoToProducts,
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
                      ),
                    if (isAdmin || isClient || user?.role == 'staff') _buildOrdersCard(),
                    const SizedBox(height: 16),
                    if (isAdmin) _buildStockSection(),
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

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersCard() {
    return Container(
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
                const Text('Latest Orders',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B2A))),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentOrders.isEmpty)
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
              ..._recentOrders.asMap().entries.map((entry) {
                final idx = entry.key;
                final o = entry.value as Map<String, dynamic>;
                final clientName = o['clientName'] ?? 'Unknown';
                final totalPrice = o['totalPrice'] ?? 0;
                final status = o['status'] ?? 'pending';
                final items = o['items'] as List? ?? [];
                final createdAt = o['createdAt'];
                final isExpanded = _expandedOrders.contains(idx);

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

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedOrders.remove(idx);
                      } else {
                        _expandedOrders.add(idx);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Always visible: Doctor name + status ──
                        Row(
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 16, color: Color(0xFF4361EE)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(clientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF0D1B2A))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
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
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF6B7A9D), size: 18),
                            ),
                          ],
                        ),

                        // ── Expanded details ──
                        if (isExpanded) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFD6DEFF)),
                          const SizedBox(height: 10),

                          // Items list
                          ...items.map((item) {
                            final name = item['vaccineName'] ?? item['productName'] ?? 'Product';
                            final qty = item['quantity'] ?? 0;
                            final price = item['sellingPrice'] ?? item['unitPrice'] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.fiber_manual_record,
                                      size: 6, color: Color(0xFF4361EE)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF0D1B2A))),
                                  ),
                                  Text('$qty × ₹$price',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7A9D))),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 6),
                          // Date, Time, Payment
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 13, color: Color(0xFF6B7A9D)),
                                  const SizedBox(width: 4),
                                  Text(
                                    date.isNotEmpty
                                        ? (timeStr.isNotEmpty
                                            ? '$date  $timeStr'
                                            : date)
                                        : '—',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF6B7A9D)),
                                  ),
                                ],
                              ),
                              if ((o['paymentMethod'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.payment_rounded,
                                        size: 13, color: Color(0xFF6B7A9D)),
                                    const SizedBox(width: 4),
                                    Text(
                                      (o['paymentMethod'] ?? '')
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7A9D)),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('Total: ',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7A9D))),
                              Text('₹$totalPrice',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4361EE))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Out of Stock',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B2A))),
        const SizedBox(height: 12),
        if (_isLoading && _recentVaccines.isEmpty)
          const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)))
        else if (_recentVaccines.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('No out of stock items.', style: TextStyle(color: Color(0xFF6B7A9D))),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4361EE).withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _recentVaccines.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value as Map<String, dynamic>;
                final name = v['vaccineName']?.toString() ?? v['productName']?.toString() ?? '';
                final batch = v['batchNumber']?.toString() ?? '';
                final isLast = i == _recentVaccines.length - 1;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: Color(0xFFFFB703),
                        ),
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0D1B2A))),
                      subtitle: Text('Batch: $batch',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D))),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('0 units',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFB703))),
                          const Text('Out of Stock',
                              style: TextStyle(fontSize: 11, color: Color(0xFFFFB703))),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 72, color: Color(0xFFE8ECFF)),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  (Color, Color) _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return (const Color(0xFF06D6A0), const Color(0xFFE6FFF9));
      case 'rejected': return (const Color(0xFFEF233C), const Color(0xFFFFE8EC));
      case 'accepted': return (const Color(0xFF4361EE), const Color(0xFFEEF2FF));
      default: return (const Color(0xFFFFB703), const Color(0xFFFFF8E1));
    }
  }

  @override
  void dispose() {
    try {
      SocketService().off('vaccine:updated');
      SocketService().off('order:status_changed');
      SocketService().off('order:created');
    } catch (_) {}
    super.dispose();
  }
}
