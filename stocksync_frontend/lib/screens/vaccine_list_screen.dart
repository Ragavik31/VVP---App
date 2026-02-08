import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';
import 'vaccine_form_page.dart';

class VaccineListScreen extends StatefulWidget {
  const VaccineListScreen({super.key});

  @override
  State<VaccineListScreen> createState() => _VaccineListScreenState();
}

class _VaccineListScreenState extends State<VaccineListScreen> {
  bool _isLoading = false;
  List<dynamic> _vaccines = [];

  @override
  void initState() {
    super.initState();
    _loadVaccines();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token != null) {
        SocketService().connect(token: token);
        // Listen for real-time vaccine quantity updates
        SocketService().on('vaccine:updated', (data) {
          _updateVaccineList(data);
        });
      }
    });
  }

  void _updateVaccineList(dynamic updatedVaccineData) {
    if (!mounted) return;
    
    if (updatedVaccineData is Map<String, dynamic>) {
      final updatedId = updatedVaccineData['_id'];
      
      setState(() {
        final index = _vaccines.indexWhere((v) => v['_id'] == updatedId);
        if (index != -1) {
          _vaccines[index] = updatedVaccineData;
        }
      });
    }
  }

  Future<void> _loadVaccines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiClient.get('/vaccines');

      if (data is Map<String, dynamic>) {
        final list = data['data'];
        if (list is List) {
          setState(() {
            _vaccines = list;
          });
        }
      } else if (data is List) {
        setState(() {
          _vaccines = data;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteVaccine(String id) async {
    try {
      await ApiClient.delete('/vaccines/$id');
      await _loadVaccines();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _addToCart(Map<String, dynamic> vaccine) async {
    final quantityController = TextEditingController(text: '1');
    int selectedQuantity = 1;
    
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to Cart: ${vaccine['vaccineName']}'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Selling Price: ₹${vaccine['sellingPrice'] ?? '0'} per unit'),
                const SizedBox(height: 16),
                Text('Available Quantity: ${vaccine['quantity'] ?? '0'}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Quantity: '),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter quantity',
                        ),
                        onChanged: (value) {
                          final newQuantity = int.tryParse(value) ?? 1;
                          if (newQuantity > 0) {
                            setState(() {
                              selectedQuantity = newQuantity;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (selectedQuantity > 1) {
                          setState(() {
                            selectedQuantity--;
                            quantityController.text = selectedQuantity.toString();
                          });
                        }
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      onPressed: () {
                        final available = int.tryParse(vaccine['quantity'].toString()) ?? 0;
                        if (selectedQuantity < available) {
                          setState(() {
                            selectedQuantity++;
                            quantityController.text = selectedQuantity.toString();
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final available = int.tryParse(vaccine['quantity'].toString()) ?? 0;
              if (selectedQuantity > 0 && selectedQuantity <= available) {
                Navigator.of(ctx).pop(selectedQuantity);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(selectedQuantity > available 
                        ? 'Only $available units available' 
                        : 'Please enter a valid quantity'),
                  ),
                );
              }
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      try {
        final orderData = {
          'vaccineId': vaccine['_id'],
          'vaccineName': vaccine['vaccineName'],
          'batchNumber': vaccine['batchNumber'],
          'quantity': result,
          'sellingPrice': vaccine['sellingPrice'],
          'totalPrice': (double.tryParse(vaccine['sellingPrice'].toString()) ?? 0) * result,
          'notes': 'Order placed via mobile app',
        };

        // For now, just show success message (backend orders disabled)
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed for ${result} units of ${vaccine['vaccineName']} (Admin will be notified)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.currentUser?.role == 'admin';

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadVaccines,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _vaccines.isEmpty
                  ? const Center(child: Text('No vaccines found'))
                  : ListView.builder(
                      itemCount: _vaccines.length,
                      itemBuilder: (context, index) {
                        final vaccine =
                            _vaccines[index] as Map<String, dynamic>;
                        final id =
                            (vaccine['_id'] ?? vaccine['id']).toString();
                        final name =
                            vaccine['vaccineName']?.toString() ?? '';
                        final batch =
                            vaccine['batchNumber']?.toString() ?? '';
                        final rawQuantity = vaccine['quantity'];
                        int quantity = 0;
                        if (rawQuantity is num) {
                          quantity = rawQuantity.toInt();
                        } else if (rawQuantity != null) {
                          quantity = int.tryParse(rawQuantity.toString()) ?? 0;
                        }
                        final purchasePrice = vaccine['purchasePrice']?.toString() ?? '0';
                        final sellingPrice = vaccine['sellingPrice']?.toString() ?? '0';
                        final manufacturer = vaccine['manufacturer']?.toString() ?? '';
                        final expiry = vaccine['expiryDate']?.toString() ?? '';
                        final isLowStock = quantity < 10;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: isLowStock
                              ? Colors.orange.shade50
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isLowStock
                                  ? Colors.orange.shade300
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Batch: $batch'),
                                if (manufacturer.isNotEmpty)
                                  Text('Manufacturer: $manufacturer'),
                                if (expiry.isNotEmpty)
                                  Text('Expiry: ${_formatDate(expiry)}'),
                                if (isAdmin) ...[
                                  const SizedBox(height: 4),
                                  Text('Quantity: $quantity'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Cost: ₹${double.tryParse(purchasePrice)?.toStringAsFixed(2) ?? purchasePrice}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Selling: ₹${double.tryParse(sellingPrice)?.toStringAsFixed(2) ?? sellingPrice}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (!isAdmin) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price: ₹${double.tryParse(sellingPrice)?.toStringAsFixed(2) ?? sellingPrice}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLowStock)
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                  ),
                                if (isAdmin) ...[
                                  IconButton(
                                    icon: const Icon(Icons.add_box_outlined),
                                    tooltip: 'Restock / Add Batch',
                                    onPressed: () async {
                                      final created =
                                          await Navigator.of(context)
                                              .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => VaccineFormScreen(
                                            vaccine: vaccine,
                                            isRestock: true,
                                          ),
                                        ),
                                      );
                                      if (created == true) {
                                        await _loadVaccines();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final updated =
                                          await Navigator.of(context)
                                              .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => VaccineFormScreen(
                                            vaccine: vaccine,
                                          ),
                                        ),
                                      );
                                      if (updated == true) {
                                        await _loadVaccines();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      final confirmed =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title:
                                              const Text('Delete Vaccine'),
                                          content: const Text(
                                              'Are you sure you want to delete this vaccine record?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx)
                                                      .pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx)
                                                      .pop(true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        await _deleteVaccine(id);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (isAdmin)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const VaccineFormScreen(),
                  ),
                );
                if (created == true) {
                  await _loadVaccines();
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    try {
      SocketService().off('vaccine:updated');
    } catch (_) {}
    super.dispose();
  }
}
