import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class ClientOrderPlacementScreen extends StatefulWidget {
  const ClientOrderPlacementScreen({super.key});

  @override
  State<ClientOrderPlacementScreen> createState() => _ClientOrderPlacementScreenState();
}

class _ClientOrderPlacementScreenState extends State<ClientOrderPlacementScreen> {
  bool _isLoading = false;
  List<dynamic> _vaccines = [];
  List<Map<String, dynamic>> _cart = [];
  double _totalPrice = 0;

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
        // Listen for real-time vaccine quantity updates from other orders
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

  void _addToCart(Map<String, dynamic> vaccine) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final quantityController = TextEditingController(text: '1');

          return AlertDialog(
            title: Text('Add ${vaccine['vaccineName']} to Cart'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price: ₹${vaccine['sellingPrice']} per unit'),
                  const SizedBox(height: 8),
                  Text('Available: ${vaccine['quantity']} units'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  quantityController.dispose();
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text) ?? 1;
                  final availableQty = vaccine['quantity'] ?? 0;

                  if (quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quantity must be greater than 0')),
                    );
                    return;
                  }

                  if (quantity > availableQty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Only $availableQty units available')),
                    );
                    return;
                  }

                  setState(() {
                    _cart.add({
                      'vaccineId': vaccine['_id'],
                      'vaccineName': vaccine['vaccineName'],
                      'batchNumber': vaccine['batchNumber'],
                      'quantity': quantity,
                      'sellingPrice': vaccine['sellingPrice'],
                      'totalPrice': quantity * (vaccine['sellingPrice'] as num).toDouble(),
                    });
                    _calculateTotal();
                  });

                  quantityController.dispose();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${vaccine['vaccineName']} added to cart')),
                  );
                },
                child: const Text('Add to Cart'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalPrice = 0;
    for (var item in _cart) {
      _totalPrice += (item['totalPrice'] as num).toDouble();
    }
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate and create items list
      final items = <Map<String, dynamic>>[];
      
      for (int i = 0; i < _cart.length; i++) {
        final item = _cart[i];
        
        // Validate each required field
        if (item['vaccineId'] == null || (item['vaccineId'] as String).isEmpty) {
          throw Exception('Item ${i + 1}: vaccineId is missing');
        }
        if (item['vaccineName'] == null || (item['vaccineName'] as String).isEmpty) {
          throw Exception('Item ${i + 1}: vaccineName is missing');
        }
        if (item['batchNumber'] == null || (item['batchNumber'] as String).isEmpty) {
          throw Exception('Item ${i + 1}: batchNumber is missing');
        }
        if (item['quantity'] == null || item['quantity'] <= 0) {
          throw Exception('Item ${i + 1}: quantity must be greater than 0');
        }
        if (item['sellingPrice'] == null) {
          throw Exception('Item ${i + 1}: sellingPrice is missing');
        }
        if (item['totalPrice'] == null) {
          throw Exception('Item ${i + 1}: totalPrice is missing');
        }

        // Build item with proper types
        final itemData = {
          'vaccineId': item['vaccineId'] as String,
          'vaccineName': item['vaccineName'] as String,
          'batchNumber': item['batchNumber'] as String,
          'quantity': item['quantity'] as int,
          'sellingPrice': (item['sellingPrice'] as num).toDouble(),
          'itemTotal': (item['totalPrice'] as num).toDouble(),
        };
        
        debugPrint('Cart Item ${i + 1}: $itemData');
        items.add(itemData);
      }

      final orderPayload = {
        'items': items,
        'notes': '',
      };
      
      debugPrint('Sending Order Payload: $orderPayload');

      await ApiClient.post('/orders', orderPayload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );

      setState(() {
        _cart = [];
        _totalPrice = 0;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Order Error: $e');
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

  @override
  Widget build(BuildContext context) {
    // This screen is shown inside `ClientHomeScreen` which provides the
    // scaffold and app bar. Do not create another Scaffold here to avoid
    // duplicate app bars when used as a tab page.
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        // Vaccines list widget
        Widget vaccinesList = ListView.builder(
          itemCount: _vaccines.length,
          itemBuilder: (context, index) {
            final vaccine = _vaccines[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  vaccine['vaccineName'] ?? 'Unknown',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Batch: ${vaccine['batchNumber']}'),
                    Text('Price: ₹${vaccine['sellingPrice']}/unit'),
                    Text('Available: ${vaccine['quantity']} units'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _addToCart(vaccine),
                  child: const Text('Add'),
                ),
              ),
            );
          },
        );

        // Cart widget
        Widget cartWidget = Container(
          color: Colors.grey[100],
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Order Cart',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _cart.isEmpty
                    ? const Center(child: Text('Cart is empty'))
                    : ListView.builder(
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text(
                                item['vaccineName'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('Qty: ${item['quantity']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeFromCart(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Total: ₹${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _cart.isEmpty ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Place Order'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              Expanded(flex: 2, child: vaccinesList),
              SizedBox(height: 8),
              SizedBox(height: 320, child: cartWidget),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: vaccinesList),
            Expanded(flex: 1, child: cartWidget),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      SocketService().off('vaccine:updated');
    } catch (_) {}
    super.dispose();
  }
}
