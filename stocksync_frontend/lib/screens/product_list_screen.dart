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

  // Predefined gradient color pairs for product images
  static const List<List<Color>> _gradientPalette = [
    [Color(0xFF4361EE), Color(0xFF3A0CA3)],
    [Color(0xFF7209B7), Color(0xFFF72585)],
    [Color(0xFF00B4D8), Color(0xFF0077B6)],
    [Color(0xFF06D6A0), Color(0xFF118AB2)],
    [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
    [Color(0xFFF77F00), Color(0xFFFC4F30)],
    [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    [Color(0xFF00CEC9), Color(0xFF55E6C1)],
    [Color(0xFFE17055), Color(0xFFD63031)],
    [Color(0xFF0984E3), Color(0xFF74B9FF)],
  ];

  // Pharmaceutical icons for variety
  static const List<IconData> _productIcons = [
    Icons.medication_rounded,
    Icons.vaccines,
    Icons.medical_services_rounded,
    Icons.local_pharmacy_rounded,
    Icons.biotech_rounded,
    Icons.science_rounded,
    Icons.health_and_safety_rounded,
    Icons.healing_rounded,
  ];

  List<Color> _getGradient(int index) {
    return _gradientPalette[index % _gradientPalette.length];
  }

  IconData _getIcon(int index) {
    return _productIcons[index % _productIcons.length];
  }

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

  // ── Show Product Detail Bottom Sheet ──
  void _showProductDetail(Map<String, dynamic> product, int index) {
    final name = product['productName']?.toString() ??
        product['name']?.toString() ?? 'Unknown Product';
    final division = product['divisionName']?.toString() ?? '';
    final salesPrice = product['salesPrice'] ?? product['price'];
    final mrp = product['mrp'];
    final quantity = product['quantity'] ?? 0;
    final quantityNum = quantity is num ? quantity.toInt() : (int.tryParse(quantity.toString()) ?? 0);
    final isOutOfStock = quantityNum == 0;
    final isLowStock = quantityNum > 0 && quantityNum < 10;
    final gradient = _getGradient(index);
    final icon = _getIcon(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ──
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Product Image Area ──
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradient[0], gradient[1]],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern circles
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // Center icon
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 56, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        if (division.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              division,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Stock badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                                ? Colors.orange
                                : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'OUT OF STOCK'
                            : isLowStock
                                ? 'LOW STOCK'
                                : 'IN STOCK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Product Details ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      height: 1.2,
                    ),
                  ),
                  if (division.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      division,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Price + Stock Cards ──
                  Row(
                    children: [
                      // Sales Price
                      Expanded(
                        child: _detailCard(
                          icon: Icons.sell_rounded,
                          iconColor: const Color(0xFF06D6A0),
                          label: 'Sales Price',
                          value: '₹${salesPrice ?? '—'}',
                          valueColor: const Color(0xFF06D6A0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // MRP
                      Expanded(
                        child: _detailCard(
                          icon: Icons.receipt_long_rounded,
                          iconColor: const Color(0xFF4361EE),
                          label: 'MRP',
                          value: '₹${mrp ?? '—'}',
                          valueColor: const Color(0xFF4361EE),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Quantity
                      Expanded(
                        child: _detailCard(
                          icon: Icons.inventory_2_rounded,
                          iconColor: isOutOfStock
                              ? Colors.red
                              : isLowStock
                                  ? Colors.orange
                                  : const Color(0xFF0077B6),
                          label: 'Stock Quantity',
                          value: '$quantityNum units',
                          valueColor: isOutOfStock
                              ? Colors.red
                              : isLowStock
                                  ? Colors.orange
                                  : const Color(0xFF0077B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Margin
                      Expanded(
                        child: _detailCard(
                          icon: Icons.trending_up_rounded,
                          iconColor: const Color(0xFF7209B7),
                          label: 'Margin',
                          value: _calcMargin(salesPrice, mrp),
                          valueColor: const Color(0xFF7209B7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calcMargin(dynamic salesPrice, dynamic mrp) {
    if (salesPrice == null || mrp == null) return '—';
    final sp = (salesPrice is num) ? salesPrice.toDouble() : double.tryParse(salesPrice.toString());
    final m = (mrp is num) ? mrp.toDouble() : double.tryParse(mrp.toString());
    if (sp == null || m == null || m == 0) return '—';
    final margin = ((m - sp) / m * 100);
    return '${margin.toStringAsFixed(1)}%';
  }

  Widget _detailCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
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
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Prominent Add Product button (admin only) ──
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final created = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const ProductFormScreen(),
                                ),
                              );
                              if (created == true) await _loadProducts();
                            },
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Add New Product',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4361EE),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: const Color(0xFF4361EE).withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    
                    // ── Product grid ──
                    _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No products found',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Text('Add your first product to get started',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
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
                        final name = product['productName']?.toString() ??
                            product['name']?.toString() ?? '';
                        final price = product['salesPrice']?.toString() ??
                            product['price']?.toString() ?? '';
                        final quantity = product['quantity']?.toString() ?? '';
                        final isLowStock = (int.tryParse(quantity) ?? 0) < 10;
                        final isOutOfStock = (int.tryParse(quantity) ?? 0) == 0;
                        final gradient = _getGradient(index);
                        final icon = _getIcon(index);

                        return GestureDetector(
                          onTap: () => _showProductDetail(product, index),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with gradient + icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [gradient[0].withOpacity(0.15), gradient[1].withOpacity(0.08)],
                                    ),
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
                                          gradient: LinearGradient(colors: gradient),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(icon, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 14,
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
                                    padding: const EdgeInsets.all(14),
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
                                        
                                        const SizedBox(height: 10),
                                        
                                        // Quantity
                                        Row(
                                          children: [
                                            Icon(
                                              isOutOfStock
                                                  ? Icons.do_not_disturb_on_rounded
                                                  : Icons.inventory_2_outlined,
                                              size: 16,
                                              color: isOutOfStock
                                                  ? Colors.red
                                                  : isLowStock
                                                      ? Colors.orange
                                                      : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                isOutOfStock
                                                    ? 'Out of stock'
                                                    : 'Stock: $quantity',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isOutOfStock
                                                      ? Colors.red
                                                      : isLowStock
                                                          ? Colors.orange
                                                          : Colors.grey[600],
                                                  fontWeight: (isLowStock || isOutOfStock)
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (isLowStock && !isOutOfStock)
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                          ],
                                        ),
                                        
                                        const Spacer(),

                                        // Tap hint
                                        Center(
                                          child: Text(
                                            'Tap for details',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[400],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        
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
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
