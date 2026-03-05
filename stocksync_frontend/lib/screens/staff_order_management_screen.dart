import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    setState(() => _isLoading = true);

    try {
      final data = await ApiClient.get('/orders?status=assigned');
      if (data['data'] != null) {
        _assignedOrders = data['data'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _acceptOrder(String id) async {
    await ApiClient.patch('/orders/$id/accept', {});
    _loadAssignedOrders();
  }

  Future<void> _completeOrder(String id) async {
    await ApiClient.patch('/orders/$id/status', {"status": "completed"});
    _loadAssignedOrders();
  }

  void _showOrderDetails(Map order) {
    final items = order['items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),
            Text("Client: ${order['clientName']}"),
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
    if (_assignedOrders.isEmpty)
      return const Center(child: Text("No assigned orders"));

    return RefreshIndicator(
      onRefresh: _loadAssignedOrders,
      child: ListView.builder(
        itemCount: _assignedOrders.length,
        itemBuilder: (_, i) {
          final order = _assignedOrders[i];
          final isAccepted = order['status'] == 'accepted';
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
                  Text("Status: ${order['status']}"),
                ],
              ),

              trailing: ElevatedButton(
                onPressed: () => isAccepted
                    ? _completeOrder(order['_id'])
                    : _acceptOrder(order['_id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isAccepted ? Colors.green : Colors.black,
                ),
                child: Text(isAccepted ? "Complete" : "Accept"),
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
      SocketService().off('order:assigned');
      SocketService().off('order:accepted');
      SocketService().off('order:status_changed');
    } catch (_) {}
    super.dispose();
  }
}
