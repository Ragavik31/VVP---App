import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api_client.dart';

class CancelledOrdersScreen extends StatefulWidget {
  const CancelledOrdersScreen({super.key});

  @override
  State<CancelledOrdersScreen> createState() => _CancelledOrdersScreenState();
}

class _CancelledOrdersScreenState extends State<CancelledOrdersScreen> {
  bool _isLoading = false;
  List<dynamic> _cancelledOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final ordersData = await ApiClient.get('/orders/pending?status=cancelled');
      if (ordersData['data'] != null) {
        _cancelledOrders = ordersData['data'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showOrderDetails(Map order) {
    final items = order['items'] as List? ?? [];

    String dateFormatted = 'Unknown Date';
    if (order['createdAt'] != null || order['orderDate'] != null) {
      try {
        final d = DateTime.parse((order['createdAt'] ?? order['orderDate']).toString()).toLocal();
        dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(d);
      } catch (_) {}
    }

    String cancelDate = '';
    if (order['cancelledAt'] != null) {
      try {
        final d = DateTime.parse(order['cancelledAt'].toString()).toLocal();
        cancelDate = DateFormat('dd MMM yyyy, hh:mm a').format(d);
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
            const Text('Cancelled Order',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 4),
            Text('Created: $dateFormatted', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A9D))),
            if (cancelDate.isNotEmpty)
              Text('Cancelled: $cancelDate', style: const TextStyle(fontSize: 13, color: Color(0xFFEF233C), fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _detailRow(Icons.person_rounded, 'Client', order['clientName']?.toString() ?? 'Unknown'),
            _detailRow(Icons.payments_rounded, 'Payment', (order['paymentMethod']?.toString() ?? '—').toUpperCase()),
            _detailRow(Icons.currency_rupee_rounded, 'Total', '₹${order['totalPrice'] ?? 0}'),
            const Divider(height: 24),
            const Text('Items (Restored to Stock)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 8),
            ...items.map((item) {
              final iName = item['vaccineName']?.toString() ?? item['productName']?.toString() ?? 'Unknown Item';
              final iQty = item['quantity']?.toString() ?? '0';
              final iTot = item['itemTotal']?.toString() ?? '0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF233C)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      '$iName  ×$iQty',
                      style: const TextStyle(color: Color(0xFF0D1B2A), decoration: TextDecoration.lineThrough),
                    )),
                    Text('₹$iTot',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6B7A9D))),
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
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Cancelled Orders', style: TextStyle(color: Color(0xFF0D1B2A), fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0D1B2A)),
      ),
      body: _isLoading && _cancelledOrders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF233C)))
          : RefreshIndicator(
              color: const Color(0xFFEF233C),
              onRefresh: _loadData,
              child: _cancelledOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel_presentation_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No cancelled orders',
                              style: TextStyle(color: Color(0xFF6B7A9D), fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _cancelledOrders.length,
                      itemBuilder: (_, i) {
                        final order = _cancelledOrders[i] as Map<String, dynamic>;
                        
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
                                  color: const Color(0xFFEF233C).withOpacity(0.04),
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
                                    color: const Color(0xFFFFE8EC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.cancel_outlined,
                                      color: Color(0xFFEF233C), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(order['clientName'] ?? 'Unknown',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D1B2A), decoration: TextDecoration.lineThrough)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE8EC),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text('CANCELLED',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFEF233C),
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
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
}
