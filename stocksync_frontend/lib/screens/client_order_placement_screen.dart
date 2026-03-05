import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../api_client.dart';
import '../services/payment_service.dart';

class ClientOrderPlacementScreen extends StatefulWidget {
  const ClientOrderPlacementScreen({super.key});

  @override
  State<ClientOrderPlacementScreen> createState() =>
      _ClientOrderPlacementScreenState();
}

class _ClientOrderPlacementScreenState extends State<ClientOrderPlacementScreen> {
  bool _isLoading = false;

  // 🔹 Ask payment method
  Future<String?> _selectPaymentMethod() async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Payment Method"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, "cash"),
            child: const Text("Cash"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, "online"),
            child: const Text("Online Payment"),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Cart is empty")));
      return;
    }

    final paymentMethod = await _selectPaymentMethod();
    if (paymentMethod == null) return;

    // 🔹 Razorpay flow
    if (paymentMethod == "online") {
      final success = await PaymentService().pay(cart.totalPrice);
      if (!success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Payment Failed")));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await ApiClient.post('/orders', {
        'items': cart.items,
        'paymentMethod': paymentMethod,
        'totalPrice': cart.totalPrice,
      });

      cart.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          "My Cart",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        // 🛒 CART ITEMS
        Expanded(
          child: cart.items.isEmpty
              ? const Center(child: Text("Cart is empty"))
              : ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Card(
                      child: ListTile(
                        title: Text(item['vaccineName']),
                        subtitle: Text(
                          "Qty: ${item['quantity']}  •  ₹${item['sellingPrice']}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => cart.removeItem(i),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // 💰 TOTAL + ORDER BUTTON
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Total: ₹${cart.totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cart.items.isEmpty ? null : _placeOrder,
                  child: const Text("Place Order"),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
