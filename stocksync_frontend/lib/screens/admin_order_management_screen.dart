import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState
    extends State<AdminOrderManagementScreen> {
  bool _isLoading = false;
  List<dynamic> _pendingOrders = [];
  List<dynamic> _staffMembers = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        SocketService().connect(token: token);
        SocketService().on('order:created', (_) => _loadData());
        SocketService().on('order:assigned', (_) => _loadData());
        SocketService().on('order:accepted', (_) => _loadData());
        SocketService().on('order:status_changed', (_) => _loadData());
        SocketService().on('order:deleted', (_) => _loadData());
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final ordersData = await ApiClient.get('/orders/pending');
      if (ordersData['data'] != null) {
        _pendingOrders = ordersData['data'];
      }

      final usersData =
          await ApiClient.get('/auth/users/by-role?role=staff');
      if (usersData['data'] != null) {
        _staffMembers = usersData['data'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _assignOrder(String orderId, String staffId, String staffName) async {
    try {
      await ApiClient.patch('/orders/$orderId/assign', {
        'staffId': staffId,
        'staffName': staffName,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order assigned to $staffName ✓'),
            backgroundColor: const Color(0xFF4361EE),
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assign failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    await ApiClient.delete('/orders/$orderId');
    _loadData();
  }

  void _showAssignDialog(Map order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Assign Order',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: _staffMembers.isEmpty
            ? const Text('No staff members found.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _staffMembers.map((s) {
                  final isFree = s['isFree'] == true;
                  final activeOrders = s['activeOrders'] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isFree
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isFree
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                          width: 1),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isFree
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        child: Text(
                          (s['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(s['name'] ?? 'Staff',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        isFree
                            ? '✓ Free'
                            : '${activeOrders} active order${activeOrders != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: isFree
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        final oId = order['_id']?.toString() ?? '';
                        final sId = s['_id']?.toString() ?? '';
                        final sName = s['name']?.toString() ?? 'Staff';
                        _assignOrder(oId, sId, sName);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Map order) {
    final items = order['items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Order Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 12),
            _detailRow(Icons.person_rounded, 'Client', order['clientName'] ?? 'Unknown'),
            _detailRow(Icons.payments_rounded, 'Payment', (order['paymentMethod'] ?? '—').toString().toUpperCase()),
            _detailRow(Icons.info_outline_rounded, 'Payment Status', (order['paymentStatus'] ?? '—').toString().toUpperCase()),
            if (order['paymentMethod'] == 'cash' && order['paymentDueDate'] != null)
              _detailRow(Icons.event_rounded, 'Due Date', _formatDueDate(order['paymentDueDate'])),
            _detailRow(Icons.currency_rupee_rounded, 'Total', '₹${order['totalPrice']}'),
            if (order['assignedStaffName'] != null)
              _detailRow(Icons.person_pin_rounded, 'Assigned To', order['assignedStaffName']),
            const Divider(height: 24),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF4361EE)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${item['vaccineName'] ?? item['productName']}  ×${item['quantity']}',
                    style: const TextStyle(color: Color(0xFF0D1B2A)),
                  )),
                  Text('₹${item['itemTotal']}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4361EE))),
                ],
              ),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7A9D)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Color(0xFF6B7A9D), fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _pendingOrders.isEmpty)
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: RefreshIndicator(
        color: const Color(0xFF4361EE),
        onRefresh: _loadData,
        child: _pendingOrders.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('No pending orders',
                        style: TextStyle(color: Color(0xFF6B7A9D), fontSize: 16)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _pendingOrders.length,
                itemBuilder: (_, i) {
                  final order = _pendingOrders[i] as Map<String, dynamic>;
                  final items = order['items'] as List? ?? [];
                  final assigned = order['assignedStaffName'];

                  String summary = '';
                  if (items.isNotEmpty) {
                    if (items.length == 1) {
                      summary = '${items[0]['vaccineName'] ?? items[0]['productName']} — ${items[0]['quantity']} units';
                    } else {
                      final qty = items.fold<int>(0, (s, itm) => s + (itm['quantity'] as int? ?? 0));
                      summary = '${items.length} items — $qty units';
                    }
                  } else {
                    summary = 'Order #${order['_id']?.toString().substring(0, 8) ?? '—'}';
                  }

                  return GestureDetector(
                    onTap: () => _showOrderDetails(order),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4361EE).withOpacity(0.07),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EDFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_long_rounded,
                                color: Color(0xFF4361EE), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['clientName'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D1B2A))),
                                const SizedBox(height: 2),
                                Text(summary,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D))),
                                const SizedBox(height: 4),
                                Text('₹${order['totalPrice']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4361EE), fontSize: 14)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      order['paymentMethod'] == 'online'
                                          ? Icons.payment_rounded
                                          : Icons.money_rounded,
                                      size: 12, color: const Color(0xFF6B7A9D),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (order['paymentMethod'] ?? 'cash').toString().toUpperCase(),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7A9D)),
                                    ),
                                    if (order['paymentStatus'] != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: order['paymentStatus'] == 'paid'
                                              ? const Color(0xFFE6FFF9)
                                              : order['paymentStatus'] == 'overdue'
                                                  ? const Color(0xFFFFE8EC)
                                                  : const Color(0xFFFFF8E1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          (order['paymentStatus'] ?? '').toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: order['paymentStatus'] == 'paid'
                                                ? const Color(0xFF06D6A0)
                                                : order['paymentStatus'] == 'overdue'
                                                    ? const Color(0xFFEF233C)
                                                    : const Color(0xFFFFB703),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (assigned != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_pin_rounded, size: 13, color: Color(0xFF4CAF50)),
                                        const SizedBox(width: 4),
                                        Text('Assigned: $assigned',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  // Status badge
                                  Builder(builder: (_) {
                                    final status = (order['status'] ?? 'pending').toString();
                                    Color bgColor; Color txtColor; String label;
                                    if (status == 'accepted') {
                                      bgColor = const Color(0xFFE8F5E9); txtColor = const Color(0xFF4CAF50); label = '✔ Accepted by Staff';
                                    } else if (status == 'assigned') {
                                      bgColor = const Color(0xFFE8EDFF); txtColor = const Color(0xFF4361EE); label = 'Assigned';
                                    } else {
                                      bgColor = const Color(0xFFFFF8E1); txtColor = const Color(0xFFFFB703); label = 'Pending';
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                                      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: txtColor)),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if (order['status'] != 'accepted')
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4361EE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.assignment_ind_rounded,
                                        color: Colors.white, size: 18),
                                  ),
                                  onPressed: () => _showAssignDialog(order),
                                  tooltip: 'Assign to Staff',
                                ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE8EC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: Color(0xFFEF233C), size: 18),
                                ),
                                onPressed: () => _deleteOrder(order['_id']),
                                tooltip: 'Delete Order',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      SocketService().off('order:created');
      SocketService().off('order:assigned');
      SocketService().off('order:accepted');
      SocketService().off('order:status_changed');
      SocketService().off('order:deleted');
    } catch (_) {}
    super.dispose();
  }

  String _formatDueDate(dynamic dueDateStr) {
    try {
      final dueDate = DateTime.parse(dueDateStr.toString()).toLocal();
      final daysLeft = dueDate.difference(DateTime.now()).inDays;
      final dateStr = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
      if (daysLeft < 0) return '$dateStr (OVERDUE)';
      return '$dateStr ($daysLeft days left)';
    } catch (_) {
      return dueDateStr.toString();
    }
  }
}
