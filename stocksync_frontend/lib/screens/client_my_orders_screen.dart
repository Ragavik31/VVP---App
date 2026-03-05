import 'package:flutter/material.dart';
import '../api_client.dart';

class ClientMyOrdersScreen extends StatefulWidget {
  const ClientMyOrdersScreen({super.key});

  @override
  State<ClientMyOrdersScreen> createState() => _ClientMyOrdersScreenState();
}

class _ClientMyOrdersScreenState extends State<ClientMyOrdersScreen> {
  bool _isLoading = false;
  List<dynamic> _orders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF233C), size: 48),
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: const TextStyle(color: Color(0xFF6B7A9D))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadOrders, child: const Text('Retry')),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No orders found',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7A9D))),
                          const SizedBox(height: 4),
                          const Text('Your order history will appear here',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF6B7A9D))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final o = _orders[index] as Map<String, dynamic>;
                        return _buildOrderCard(o);
                      },
                    ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final totalPrice = o['totalPrice'] ?? 0;
    final status = o['status'] ?? 'pending';
    final items = o['items'] as List? ?? [];
    final createdAt = o['createdAt'];
    final paymentMethod = o['paymentMethod'] ?? '';

    String date = '';
    if (createdAt != null) {
      try {
        final d = DateTime.parse(createdAt.toString());
        date = '${d.day}/${d.month}/${d.year}';
      } catch (_) {
        date = createdAt.toString();
      }
    }

    final statusData = _statusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4361EE).withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_rounded,
                      size: 18, color: Color(0xFF4361EE)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${o['_id']?.toString().substring(0, 8) ?? '—'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0D1B2A)),
                      ),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7A9D))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusData.$2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 12,
                          color: statusData.$1,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          const Divider(height: 16, indent: 16, endIndent: 16),

          // Items list
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: items.map((item) {
                  final name = item['vaccineName'] ??
                      item['productName'] ??
                      'Product';
                  final qty = item['quantity'] ?? 0;
                  final price = item['price'] ?? item['unitPrice'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.vaccines_rounded,
                            size: 16, color: Color(0xFF4361EE)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0D1B2A),
                                  fontWeight: FontWeight.w500)),
                        ),
                        Text('$qty × ₹$price',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7A9D))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 16, indent: 16, endIndent: 16),

          // Footer: total + payment
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                if (paymentMethod.isNotEmpty)
                  Row(
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
                const Spacer(),
                Text('Total: ',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF6B7A9D))),
                Text('₹$totalPrice',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4361EE))),
              ],
            ),
          ),
        ],
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
}
