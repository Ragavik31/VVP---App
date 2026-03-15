import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class ClientMyOrdersScreen extends StatefulWidget {
  const ClientMyOrdersScreen({super.key});

  @override
  State<ClientMyOrdersScreen> createState() => _ClientMyOrdersScreenState();
}

class _ClientMyOrdersScreenState extends State<ClientMyOrdersScreen> {
  bool _isLoading = false;
  List<dynamic> _orders = [];
  String? _error;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        SocketService().connect(token: token);
        SocketService().on('order:created', (_) => _loadOrders());
        SocketService().on('order:status_changed', (_) => _loadOrders());
      }
    });
  }

  @override
  void dispose() {
    try {
      SocketService().off('order:created');
      SocketService().off('order:status_changed');
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _expanded.clear();
    });
    try {
      final resp = await ApiClient.get('/orders');
      List<dynamic> orders = [];
      if (resp is Map<String, dynamic>) {
        final data = resp['data'];
        if (data is List) orders = data;
      } else if (resp is List) {
        orders = resp;
      }
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelOrder(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF233C)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.patch('/orders/$id/cancel', {});
      _loadOrders();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel order: $e')));
      }
    }
  }

  /// Build a short, readable Order ID like "370-001"
  String _buildOrderId(Map<String, dynamic> o, int index) {
    final code = (o['clientCode'] ?? '').toString().trim();
    final num = (index + 1).toString().padLeft(3, '0');
    if (code.isNotEmpty) return '$code-$num';
    // Fallback for old orders without clientCode
    final clientName = (o['clientName'] ?? '').toString().trim();
    final words = clientName
        .split(RegExp(r'[\s.]+'))
        .where((w) => w.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(w))
        .toList();
    final initials = words.take(3).map((w) => w[0].toUpperCase()).join();
    return '${initials.isEmpty ? 'ORD' : initials}-$num';
  }

  (Color, Color) _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return (const Color(0xFF06D6A0), const Color(0xFFE6FFF9));
      case 'rejected':
        return (const Color(0xFFEF233C), const Color(0xFFFFE8EC));
      case 'accepted':
        return (const Color(0xFF4361EE), const Color(0xFFEEF2FF));
      case 'assigned':
        return (const Color(0xFF7B2FBE), const Color(0xFFF3E8FF));
      default:
        return (const Color(0xFFFFB703), const Color(0xFFFFF8E1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF4361EE),
      onRefresh: _loadOrders,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF233C), size: 48),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Color(0xFF6B7A9D))),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No orders found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7A9D))),
                          const SizedBox(height: 4),
                          const Text('Your order history will appear here',
                              style: TextStyle(fontSize: 13, color: Color(0xFF6B7A9D))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final o = _orders[index] as Map<String, dynamic>;
                        return _buildOrderCard(o, index);
                      },
                    ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o, int index) {
    final totalPrice = o['totalPrice'] ?? 0;
    final status = o['status'] ?? 'pending';
    final items = o['items'] as List? ?? [];
    final createdAt = o['createdAt'];
    final paymentMethod = o['paymentMethod'] ?? '';
    final isExpanded = _expanded.contains(index);

    // Parse date + time
    String date = '';
    String time = '';
    if (createdAt != null) {
      try {
        final d = DateTime.parse(createdAt.toString()).toLocal();
        date = '${d.day}/${d.month}/${d.year}';
        time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        date = createdAt.toString();
      }
    }

    final orderId = _buildOrderId(o, index);
    final statusData = _statusStyle(status);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expanded.remove(index);
          } else {
            _expanded.add(index);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4361EE).withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Collapsed header (always visible) ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_rounded, size: 18, color: Color(0xFF4361EE)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderId,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0D1B2A)),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            time.isNotEmpty ? '$date  •  $time' : date,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D)),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusData.$2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 12, color: statusData.$1, fontWeight: FontWeight.w600)),
                  ),
                  if (status != 'delivered' && status != 'cancelled' && status != 'rejected' && paymentMethod == 'cash')
                    GestureDetector(
                      onTap: () => _cancelOrder(o['_id']),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFFFFE8EC), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF233C)),
                      ),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6B7A9D), size: 20),
                  ),
                ],
              ),
            ),

            // ── Expanded details ────────────────────────────────────────
            if (isExpanded) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              const SizedBox(height: 10),

              // Items
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Items',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7A9D),
                              letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      ...items.map((item) {
                        final name =
                            item['vaccineName'] ?? item['productName'] ?? 'Product';
                        final qty = item['quantity'] ?? 0;
                        final unitPrice =
                            item['sellingPrice'] ?? item['unitPrice'] ?? item['price'] ?? 0;
                        final lineTotal = item['itemTotal'] ?? (qty * unitPrice);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.vaccines_rounded,
                                  size: 15, color: Color(0xFF4361EE)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF0D1B2A),
                                        fontWeight: FontWeight.w500)),
                              ),
                              Text(
                                '$qty × ₹$unitPrice',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7A9D)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '= ₹$lineTotal',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4361EE)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              // Staff info (when assigned or accepted)
              if ((status == 'assigned' || status == 'accepted') &&
                  (o['assignedStaffName'] != null))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4361EE).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4361EE).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delivery_dining_rounded,
                              size: 20, color: Color(0xFF4361EE)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivery Staff',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B7A9D))),
                              const SizedBox(height: 2),
                              Text(o['assignedStaffName']?.toString() ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D1B2A))),
                              if ((o['assignedStaffPhone'] ?? '').toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    o['assignedStaffPhone'].toString(),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4361EE),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if ((o['assignedStaffPhone'] ?? '').toString().isNotEmpty)
                          GestureDetector(
                            onTap: () async {
                              final phone = o['assignedStaffPhone'].toString();
                              final uri = Uri.parse('tel:$phone');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF06D6A0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.phone_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const Divider(height: 16, indent: 16, endIndent: 16),

              // Footer: payment + due date + total
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  children: [
                    // Payment method + due date row
                    Row(
                      children: [
                        if (paymentMethod.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                paymentMethod == 'online'
                                    ? Icons.payment_rounded
                                    : Icons.money_rounded,
                                size: 15,
                                color: const Color(0xFF6B7A9D),
                              ),
                              const SizedBox(width: 4),
                              Text(paymentMethod.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7A9D))),
                            ],
                          ),
                        const SizedBox(width: 10),
                        _buildPaymentBadge(o),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Total row
                    Row(
                      children: [
                        const Text('Total: ',
                            style: TextStyle(fontSize: 14, color: Color(0xFF6B7A9D))),
                        const Spacer(),
                        Text('₹$totalPrice',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4361EE))),
                      ],
                    ),
                    // Delivered time (if delivered)
                    if (o['deliveredAt'] != null) ...[  
                      const SizedBox(height: 6),
                      Builder(builder: (_) {
                        try {
                          final d = DateTime.parse(o['deliveredAt'].toString()).toLocal();
                          final ds = '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
                          return Row(
                            children: [
                              const Icon(Icons.local_shipping_rounded, size: 13, color: Color(0xFF06D6A0)),
                              const SizedBox(width: 4),
                              Text('Delivered on $ds', style: const TextStyle(fontSize: 12, color: Color(0xFF06D6A0), fontWeight: FontWeight.w600)),
                            ],
                          );
                        } catch (_) { return const SizedBox.shrink(); }
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildPaymentBadge(Map<String, dynamic> o) {
    final paymentMethod = (o['paymentMethod'] ?? '').toString();
    final paymentStatus = (o['paymentStatus'] ?? '').toString();
    final dueDateStr = (o['paymentDueDate'] ?? '').toString();

    if (paymentMethod == 'online' || paymentStatus == 'paid') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE6FFF9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF06D6A0)),
            SizedBox(width: 4),
            Text('PAID',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF06D6A0))),
          ],
        ),
      );
    }

    // Cash: calculate days remaining
    if (dueDateStr.isNotEmpty && dueDateStr != 'null') {
      try {
        final dueDate = DateTime.parse(dueDateStr).toLocal();
        final now = DateTime.now();
        final daysLeft = dueDate.difference(now).inDays;

        if (daysLeft < 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFEF233C)),
                SizedBox(width: 4),
                Text('OVERDUE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF233C))),
              ],
            ),
          );
        }

        final isUrgent = daysLeft <= 7;
        final badgeColor = isUrgent ? const Color(0xFFFFB703) : const Color(0xFF4361EE);
        final bgColor = isUrgent ? const Color(0xFFFFF8E1) : const Color(0xFFEEF2FF);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isUrgent ? Icons.timer_rounded : Icons.schedule_rounded,
                  size: 12, color: badgeColor),
              const SizedBox(width: 4),
              Text('Due in $daysLeft days',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor)),
            ],
          ),
        );
      } catch (_) {}
    }

    // Fallback: unpaid with no due date
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('UNPAID',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFB703))),
    );
  }
}
