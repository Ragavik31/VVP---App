import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class StaffOrderManagementScreen extends StatefulWidget {
  const StaffOrderManagementScreen({super.key});

  @override
  State<StaffOrderManagementScreen> createState() => _StaffOrderManagementScreenState();
}

class _StaffOrderManagementScreenState extends State<StaffOrderManagementScreen> {
  bool _isLoading = false;
  List<dynamic> _assignedOrders = [];

  @override
  void initState() {
    super.initState();
    _loadAssignedOrders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      final userId = auth.currentUser?.id;
      if (token != null) {
        SocketService().connect(token: token);
        SocketService().on('order:assigned', (data) {
          try {
            if (data != null && data['assignedTo'] == userId) {
              _loadAssignedOrders();
            }
          } catch (_) {}
        });

        SocketService().on('order:accepted', (data) {
          // reload to reflect accepted/completed status
          _loadAssignedOrders();
        });
      }
    });
  }

  Future<void> _loadAssignedOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiClient.get('/orders?status=assigned');

      if (data is Map<String, dynamic>) {
        final list = data['data'];
        if (list is List) {
          setState(() {
            _assignedOrders = list;
          });
        }
      } else if (data is List) {
        setState(() {
          _assignedOrders = data;
        });
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

  Future<void> _acceptOrder(String orderId) async {
    try {
      await ApiClient.patch('/orders/$orderId/accept', {});

      await _loadAssignedOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _completeOrder(String orderId) async {
    try {
      await ApiClient.patch('/orders/$orderId/status', {
        'status': 'completed',
      });

      await _loadAssignedOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order completed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Orders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedOrders.isEmpty
              ? const Center(child: Text('No assigned orders'))
              : RefreshIndicator(
                  onRefresh: _loadAssignedOrders,
                  child: ListView.builder(
                    itemCount: _assignedOrders.length,
                    itemBuilder: (context, index) {
                      final order = _assignedOrders[index];
                      final isAccepted = order['status'] == 'accepted';

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('${order['vaccineName']} - ${order['quantity']} units'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Client: ${order['clientName']}'),
                              Text('Status: ${order['status']}'),
                              Text('Total: ₹${order['totalPrice']}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isAccepted)
                                ElevatedButton(
                                  onPressed: () => _acceptOrder(order['_id']),
                                  child: const Text('Accept'),
                                )
                              else
                                ElevatedButton(
                                  onPressed: () => _completeOrder(order['_id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Complete'),
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
      SocketService().off('order:assigned');
      SocketService().off('order:accepted');
    } catch (_) {}
    super.dispose();
  }
}
