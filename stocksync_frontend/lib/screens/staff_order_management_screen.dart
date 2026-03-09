import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class StaffOrderManagementScreen extends StatefulWidget {
  const StaffOrderManagementScreen({super.key});

  @override
  State<StaffOrderManagementScreen> createState() =>
      _StaffOrderManagementScreenState();
}

class _StaffOrderManagementScreenState
    extends State<StaffOrderManagementScreen> {
  bool _isLoading = false;
  List<dynamic> _assignedOrders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignedOrders();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token != null) {
        SocketService().connect(token: token);
        SocketService().on('order:assigned', (_) => _loadAssignedOrders());
        SocketService().on('order:accepted', (_) => _loadAssignedOrders());
        SocketService().on('order:status_changed', (_) => _loadAssignedOrders());
      }
    });
  }

  Future<void> _loadAssignedOrders() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final data = await ApiClient.get('/orders');
      List<dynamic> orders = [];
      if (data is Map && data['data'] is List) {
        orders = data['data'];
      } else if (data is List) {
        orders = data;
      }
      if (mounted) setState(() => _assignedOrders = orders);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(String id) async {
    try {
      await ApiClient.patch('/orders/$id/accept', {});
      _loadAssignedOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deliverOrder(String id) async {
    try {
      await ApiClient.patch('/orders/$id/status', {'status': 'delivered'});
      _loadAssignedOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as Delivered!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deliver order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, dynamic> _statusStyle(String status) {
    switch (status) {
      case 'assigned':
        return {'color': const Color(0xFF4361EE), 'bg': const Color(0xFFE8EDFF), 'label': 'Assigned'};
      case 'accepted':
        return {'color': const Color(0xFFFF9800), 'bg': const Color(0xFFFFF3E0), 'label': 'Accepted'};
      case 'delivered':
        return {'color': const Color(0xFF4CAF50), 'bg': const Color(0xFFE8F5E9), 'label': 'Delivered'};
      default:
        return {'color': const Color(0xFF6B7A9D), 'bg': const Color(0xFFF0F4FF), 'label': status};
    }
  }

  void _showOrderDetails(Map order) {
    final items = order['items'] as List? ?? [];
    final statusData = _statusStyle(order['status'] ?? '');

    String dateFormatted = 'Unknown Date';
    if (order['createdAt'] != null || order['orderDate'] != null) {
      try {
        final d = DateTime.parse((order['createdAt'] ?? order['orderDate']).toString()).toLocal();
        dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(d);
      } catch (_) {}
    }

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
            Row(
              children: [
                const Text('Order Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusData['bg'] as Color,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statusData['label']?.toString() ?? '',
                      style: TextStyle(
                          color: (statusData['color'] as Color?) ?? const Color(0xFF6B7A9D),
                          fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(dateFormatted, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A9D))),
            const SizedBox(height: 16),
            _detailRow(Icons.person_rounded, 'Client', order['clientName']?.toString() ?? 'Unknown'),
            _detailRow(Icons.payments_rounded, 'Payment', (order['paymentMethod']?.toString() ?? '—').toUpperCase()),
            _detailRow(Icons.currency_rupee_rounded, 'Total', '₹${order['totalPrice'] ?? 0}'),
            if (order['deliveredAt'] != null)
              _detailRow(Icons.local_shipping_rounded, 'Delivered At', _formatTimestamp(order['deliveredAt'])),
            const Divider(height: 24),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 8),
            ...items.map((item) {
              final iName = item['vaccineName']?.toString() ?? item['productName']?.toString() ?? 'Unknown Item';
              final iQty = item['quantity']?.toString() ?? '0';
              final iTot = item['itemTotal']?.toString() ?? '0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF4361EE)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$iName  ×$iQty',
                        style: const TextStyle(color: Color(0xFF0D1B2A)))),
                    Text('₹$iTot',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4361EE))),
                  ],
                ),
              );
            }),
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
          Text(value, style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    try {
      final d = DateTime.parse(ts.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: RefreshIndicator(
        color: const Color(0xFF4361EE),
        onRefresh: _loadAssignedOrders,
        child: _isLoading && _assignedOrders.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)))
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _assignedOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No assigned orders yet',
                                style: TextStyle(color: Color(0xFF6B7A9D), fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _assignedOrders.length,
                        itemBuilder: (_, i) {
                          final order = _assignedOrders[i] as Map<String, dynamic>;
                          final status = order['status'] ?? 'assigned';
                          final isAccepted = status == 'accepted';
                          final isDelivered = status == 'delivered';
                          final items = order['items'] as List? ?? [];
                          final statusData = _statusStyle(status);

                          String summary = '';
                          if (items.isNotEmpty) {
                            if (items.length == 1) {
                              summary = '${items[0]['vaccineName']} — ${items[0]['quantity']} units';
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
                                      color: (statusData['bg'] as Color),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isDelivered ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                                      color: (statusData['color'] as Color?) ?? const Color(0xFF6B7A9D), size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(order['clientName'] ?? 'Unknown',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D1B2A))),
                                        const SizedBox(height: 3),
                                        Text(summary,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D))),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusData['bg'] as Color,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(statusData['label']?.toString() ?? '',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: (statusData['color'] as Color?) ?? const Color(0xFF6B7A9D),
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        // Delivery time — only shown after delivery
                                        if (isDelivered && order['deliveredAt'] != null)
                                          Builder(builder: (_) {
                                            try {
                                              final d = DateTime.parse(order['deliveredAt'].toString()).toLocal();
                                              final ds = '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 3),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.local_shipping_rounded, size: 11, color: Color(0xFF4CAF50)),
                                                    const SizedBox(width: 3),
                                                    Text('Delivered $ds', style: const TextStyle(fontSize: 10, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              );
                                            } catch (_) { return const SizedBox.shrink(); }
                                          }),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isDelivered)
                                    ElevatedButton(
                                      onPressed: () => isAccepted
                                          ? _deliverOrder(order['_id'])
                                          : _acceptOrder(order['_id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isAccepted ? const Color(0xFF4CAF50) : const Color(0xFF4361EE),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      child: Text(isAccepted ? 'Deliver' : 'Accept',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    )
                                  else
                                    const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
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
      SocketService().off('order:assigned');
      SocketService().off('order:accepted');
      SocketService().off('order:status_changed');
    } catch (_) {}
    super.dispose();
  }
}
