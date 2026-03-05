import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth/auth_provider.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _isLoading = false;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiClient.get('/products');
      if (data is List) {
        setState(() {
          _products = data;
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

  Future<void> _deleteProduct(String id) async {
    try {
      await ApiClient.delete('/products/$id');
      await _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.currentUser?.role == 'admin';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first product to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index] as Map<String, dynamic>;
                        final id = product['_id']?.toString() ?? product['id'];
                        final name = product['name']?.toString() ?? '';
                        final price = product['price']?.toString() ?? '';
                        final quantity = product['quantity']?.toString() ?? '';
                        final isLowStock = int.tryParse(quantity) ?? 0 < 10;

                        return Card(
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with icon
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.inventory,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Price
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '₹$price',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Quantity
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 16,
                                            color: isLowStock ? Colors.orange : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Stock: $quantity',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isLowStock ? Colors.orange : Colors.grey[600],
                                              fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                          if (isLowStock) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                          ],
                                        ],
                                      ),
                                      
                                      const Spacer(),
                                      
                                      // Actions
                                      if (isAdmin)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              onPressed: () async {
                                                final updated = await Navigator.of(context)
                                                    .push<bool>(
                                                  MaterialPageRoute(
                                                    builder: (_) => ProductFormScreen(
                                                      product: product,
                                                    ),
                                                  ),
                                                );
                                                if (updated == true) {
                                                  await _loadProducts();
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20),
                                              onPressed: () async {
                                                final confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Delete Product'),
                                                    content: Text(
                                                        'Are you sure you want to delete $name?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                        child: const Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirmed == true) {
                                                  await _deleteProduct(id);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const ProductFormScreen(),
                  ),
                );
                if (created == true) {
                  await _loadProducts();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
