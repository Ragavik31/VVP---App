import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  bool _isLoading = false;
  List<dynamic> _pendingOrders = [];
  List<dynamic> _staffMembers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // connect socket and listen for updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token != null) {
        SocketService().connect(token: token);
        SocketService().on('order:created', (data) => _loadData());
        SocketService().on('order:assigned', (data) => _loadData());
        SocketService().on('order:status_changed', (data) => _loadData());
        SocketService().on('order:deleted', (data) => _loadData());
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load pending orders
      final ordersData = await ApiClient.get('/orders/pending');
      if (ordersData is Map<String, dynamic>) {
        final list = ordersData['data'];
        if (list is List) {
          setState(() {
            _pendingOrders = list;
          });
        }
      }

      // Load staff members
      final usersData = await ApiClient.get('/auth/users/by-role?role=staff');
      if (usersData is Map<String, dynamic>) {
        final list = usersData['data'];
        if (list is List) {
          setState(() {
            _staffMembers = list;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignOrder(String orderId, String staffId, String staffName) async {
    try {
      await ApiClient.patch('/orders/$orderId/assign', {
        'staffId': staffId,
        'staffName': staffName,
      });

      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order assigned to $staffName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      await ApiClient.delete('/orders/$orderId');
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this order?'),
            const SizedBox(height: 16),
            Text('Vaccine: ${order['vaccineName']}'),
            Text('Quantity: ${order['quantity']} units'),
            Text('Client: ${order['clientName']}'),
            Text('Total: ₹${order['totalPrice']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteOrder(order['_id']);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client: ${order['clientName']}'),
              Text('Contact: ${order['clientContact'] ?? '—'}'),
              const SizedBox(height: 12),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (order['items'] is List)
                ...(order['items'] as List).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• ${item['vaccineName']} - ${item['quantity']} units @ ₹${item['sellingPrice']}'),
                  );
                }).toList()
              else
                Text('Single vaccine order'),
              const SizedBox(height: 8),
              Text('Total: ₹${order['totalPrice']}'),
              const SizedBox(height: 16),
              const Text('Assign to Staff:'),
              const SizedBox(height: 8),
              if (_staffMembers.isNotEmpty)
                ..._staffMembers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final staff = entry.value;
                  final label = (idx == 0)
                      ? 'Staff 1'
                      : (idx == 1)
                          ? 'Staff 2'
                          : (staff['name'] ?? 'Unknown');
                  return ListTile(
                    title: Text(label),
                    onTap: () {
                      _assignOrder(
                        order['_id'],
                        staff['_id'],
                        label,
                      );
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `HomeShell` provides the Scaffold and AppBar. Return the body only
    // so we don't end up with duplicate app bars when this screen is used
    // as a tab page.
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_pendingOrders.isEmpty) return const Center(child: Text('No pending orders'));

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          itemCount: _pendingOrders.length,
          itemBuilder: (context, index) {
            final order = _pendingOrders[index];
            
            // Get order summary
            String orderSummary = '';
            int totalItems = 0;
            if (order['items'] is List && (order['items'] as List).isNotEmpty) {
              final items = order['items'] as List;
              totalItems = items.length;
              if (items.length == 1) {
                final item = items[0];
                orderSummary = '${item['vaccineName']} - ${item['quantity']} units';
              } else {
                orderSummary = '${items.length} items - ${order['totalQuantity']} units total';
              }
            } else {
              orderSummary = 'Order #${order['_id']?.toString().substring(0, 8) ?? 'Unknown'}';
            }

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(orderSummary),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client: ${order['clientName']} (${order['clientContact'] ?? '—'})'),
                    Text('Status: ${order['status']}'),
                    Text('Total: ₹${order['totalPrice']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showAssignDialog(order),
                      child: const Text('Assign'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showDeleteConfirmDialog(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.delete, size: 18),
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
      SocketService().off('order:status_changed');
      SocketService().off('order:deleted');
    } catch (_) {}
    super.dispose();
  }
}

