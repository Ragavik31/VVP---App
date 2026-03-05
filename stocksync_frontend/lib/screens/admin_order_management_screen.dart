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

  Future<void> _assignOrder(String orderId, String staffId) async {
    await ApiClient.patch('/orders/$orderId/assign', {
      'staffId': staffId,
    });
    _loadData();
  }

  Future<void> _deleteOrder(String orderId) async {
    await ApiClient.delete('/orders/$orderId');
    _loadData();
  }

  void _showAssignDialog(Map order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Assign Order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _staffMembers
              .map((s) => ListTile(
                    title: Text(s['name'] ?? "Staff"),
                    onTap: () {
                      _assignOrder(order['_id'], s['_id']);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showOrderDetails(Map order) {
    final items = order['items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Text("Client: ${order['clientName'] ?? 'Unknown'}"),
            Text("Payment: ${order['paymentMethod']}"),
            Text("Total: ₹${order['totalPrice']}"),

            const SizedBox(height: 15),
            const Text("Items:",
                style: TextStyle(fontWeight: FontWeight.bold)),

            ...items.map((item) => Text(
                "• ${item['productName']}  x${item['quantity']}  = ₹${item['itemTotal']}")),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_pendingOrders.isEmpty)
      return const Center(child: Text("No pending orders"));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _pendingOrders.length,
        itemBuilder: (_, i) {
          final order = _pendingOrders[i];
          final items = order['items'] as List? ?? [];

          return Card(
            child: ListTile(
              onTap: () => _showOrderDetails(order),

              title: Text(
                "${order['clientName']} • ${items.length} items",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Payment: ${order['paymentMethod']}"),
                  Text("Total: ₹${order['totalPrice']}"),
                ],
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.assignment_ind),
                    onPressed: () => _showAssignDialog(order),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteOrder(order['_id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    try {
      SocketService().off('order:created');
      SocketService().off('order:assigned');
      SocketService().off('order:deleted');
    } catch (_) {}
    super.dispose();
  }
}
