import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _recentVaccines = [];
  List<dynamic> _recentOrders = [];
  String? _error;

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
      final vaccinesResponse = await ApiClient.get('/vaccines');
      List<dynamic> vaccinesList = [];
      if (vaccinesResponse is Map<String, dynamic>) {
        final data = vaccinesResponse['data'];
        if (data is List) vaccinesList = data;
      } else if (vaccinesResponse is List) {
        vaccinesList = vaccinesResponse;
      }
      if (!mounted) return;
      setState(() => _recentVaccines = vaccinesList.take(5).toList());
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOrders() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isAdmin = auth.currentUser?.role == 'admin';
      final resp = await ApiClient.get(isAdmin ? '/orders/pending?limit=5' : '/orders?limit=5');
      List<dynamic> ordersList = [];
      if (resp is Map<String, dynamic>) {
        final data = resp['data'];
        if (data is List) ordersList = data;
      } else if (resp is List) ordersList = resp;
      if (!mounted) return;
      setState(() => _recentOrders = ordersList);
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
                              'Hello, ${user?.name ?? ''} 👋',
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
                          '${_recentVaccines.length}', 'Products'),
                      const SizedBox(width: 12),
                      _statChip(Icons.receipt_long_rounded,
                          '${_recentOrders.length}', 'Orders'),
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
                    if ((isAdmin || isClient)) _buildOrdersCard(),
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
              ..._recentOrders.map((order) {
                final o = order as Map<String, dynamic>;
                final clientName = o['clientName'] ?? 'Unknown';
                final totalPrice = o['totalPrice'] ?? 0;
                final status = o['status'] ?? 'pending';
                final items = o['items'] as List? ?? [];
                final createdAt = o['createdAt'];

                String summary = '';
                if (items.isNotEmpty) {
                  if (items.length == 1) {
                    summary = '${items[0]['vaccineName']} — ${items[0]['quantity']} units';
                  } else {
                    final qty = items.fold<int>(0, (s, i) => s + (i['quantity'] as int));
                    summary = '${items.length} items — $qty units';
                  }
                } else {
                  summary = 'Order #${o['_id']?.toString().substring(0, 8) ?? '—'}';
                }

                String date = '';
                if (createdAt != null) {
                  try {
                    final d = DateTime.parse(createdAt.toString());
                    date = '${d.day}/${d.month}/${d.year}';
                  } catch (_) { date = createdAt.toString(); }
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
                            Text('$clientName  •  $date',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7A9D))),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Stock',
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
            child: const Text('No stock activity.', style: TextStyle(color: Color(0xFF6B7A9D))),
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
                final rawQty = v['quantity'];
                final qty = rawQty is num ? rawQty.toInt() : int.tryParse(rawQty?.toString() ?? '0') ?? 0;
                final low = qty < 10;
                final isLast = i == _recentVaccines.length - 1;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: low ? const Color(0xFFFFF8E1) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.vaccines_rounded,
                          size: 20,
                          color: low ? const Color(0xFFFFB703) : const Color(0xFF4361EE),
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
                          Text('$qty units',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: low ? const Color(0xFFFFB703) : const Color(0xFF0D1B2A))),
                          if (low)
                            const Text('Low Stock',
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
