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
        SocketService().on('vaccine:updated', (data) => _loadDashboardData());
        SocketService().on('order:created', (data) {
          // Refresh orders for both admin and client
          _loadOrders();
        });
        SocketService().on('order:status_changed', (data) {
          try {
            if (data != null && data['clientId'] == userId) {
              _loadDashboardData();
            }
          } catch (_) {}
        });
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vaccinesResponse = await ApiClient.get('/vaccines');

      List<dynamic> vaccinesList = [];
      if (vaccinesResponse is Map<String, dynamic>) {
        final data = vaccinesResponse['data'];
        if (data is List) {
          vaccinesList = data;
        }
      } else if (vaccinesResponse is List) {
        vaccinesList = vaccinesResponse;
      }

      if (!mounted) return;

      setState(() {
        _recentVaccines = vaccinesList.take(5).toList();
      });

      // Load orders as well
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isAdmin = auth.currentUser?.role == 'admin';
      
      late dynamic ordersResponse;
      if (isAdmin) {
        ordersResponse = await ApiClient.get('/orders/pending?limit=5');
      } else {
        ordersResponse = await ApiClient.get('/orders?limit=5');
      }

      List<dynamic> ordersList = [];
      if (ordersResponse is Map<String, dynamic>) {
        final data = ordersResponse['data'];
        if (data is List) {
          ordersList = data;
        }
      } else if (ordersResponse is List) {
        ordersList = ordersResponse;
      }

      if (!mounted) return;

      setState(() {
        _recentOrders = ordersList;
      });
    } catch (e) {
      if (!mounted) return;
      // Silent fail for orders
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
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? ''}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isAdmin
                  ? 'Admin – Stock & Sales overview'
                  : isClient
                      ? 'Client – Vaccine overview'
                      : 'Staff – Read-only overview',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            if (_error != null) const SizedBox(height: 16),
            _buildLatestOrdersCard(context, isAdmin, isClient),
            const SizedBox(height: 16),
            // Show recent stock activity only to admins (hide for clients and staff)
            if (isAdmin) _buildRecentStockActivitySection(context, isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestOrdersCard(BuildContext context, bool isAdmin, bool isClient) {
    // Hide the orders placeholder for staff users (show only to admin/client)
    if (!isAdmin && !isClient) return const SizedBox.shrink();

    if (_recentOrders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No orders placed yet',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._recentOrders.map((order) {
              final orderMap = order as Map<String, dynamic>;
              final clientName = orderMap['clientName'] ?? 'Unknown';
              final clientContact = orderMap['clientContact'] ?? '—';
              final totalPrice = orderMap['totalPrice'] ?? 0;
              final status = orderMap['status'] ?? 'pending';
              final createdAt = orderMap['createdAt'];
              final items = orderMap['items'] as List? ?? [];

              String orderSummary = '';
              if (items.isNotEmpty) {
                if (items.length == 1) {
                  final item = items[0];
                  orderSummary = '${item['vaccineName']} - ${item['quantity']} units';
                } else {
                  final totalQty = items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
                  orderSummary = '${items.length} items - $totalQty units';
                }
              } else {
                orderSummary = 'Order #${orderMap['_id']?.toString().substring(0, 8) ?? 'Unknown'}';
              }

              String formattedDate = '';
              if (createdAt != null) {
                try {
                  final date = DateTime.parse(createdAt.toString());
                  formattedDate = '${date.day}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                } catch (_) {
                  formattedDate = createdAt.toString();
                }
              }

              final statusColor = status == 'completed'
                  ? Colors.green
                  : status == 'rejected'
                      ? Colors.red
                      : status == 'accepted'
                          ? Colors.blue
                          : Colors.orange;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(orderSummary),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client: $clientName'),
                      Text('Contact: $clientContact'),
                      Text('Date: $formattedDate'),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹$totalPrice', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentStockActivitySection(
      BuildContext context, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Stock Activity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_isLoading && _recentVaccines.isEmpty)
          const Center(child: CircularProgressIndicator()),
        if (!_isLoading)
          Column(
            children: [
              if (_recentVaccines.isNotEmpty)
                _buildVaccineActivityCard(context, isAdmin),
              if (_recentVaccines.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No recent stock activity found.'),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildVaccineActivityCard(BuildContext context, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Vaccine Batches',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._recentVaccines.map((v) {
              final vaccine = v as Map<String, dynamic>;
              final name = vaccine['vaccineName']?.toString() ?? '';
              final batch = vaccine['batchNumber']?.toString() ?? '';

              final rawQuantity = vaccine['quantity'];
              int quantity = 0;
              if (rawQuantity is num) {
                quantity = rawQuantity.toInt();
              } else if (rawQuantity != null) {
                quantity = int.tryParse(rawQuantity.toString()) ?? 0;
              }

              final lowStock = quantity < 10;

              final manufacturer =
                  vaccine['manufacturer']?.toString() ?? '';
              final expiry = vaccine['expiryDate']?.toString() ?? '';
              
              final purchasePrice = vaccine['purchasePrice']?.toString() ?? '0';
              final sellingPrice = vaccine['sellingPrice']?.toString() ?? '0';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color:
                      lowStock ? Colors.orange.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: lowStock
                        ? Colors.orange.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(name),
                  subtitle: isAdmin
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Batch: $batch • Qty: $quantity'),
                            if (purchasePrice != '0' && sellingPrice != '0')
                              Text(
                                'Cost: ₹${double.tryParse(purchasePrice)?.toStringAsFixed(2) ?? purchasePrice} • Selling: ₹${double.tryParse(sellingPrice)?.toStringAsFixed(2) ?? sellingPrice}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            Text('Manufacturer: $manufacturer\nExpiry: $expiry'),
                          ],
                        )
                      : Text('Batch: $batch • Qty: $quantity'),
                  trailing: lowStock
                      ? const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        )
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
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
