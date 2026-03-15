import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _vaccines = [];
  List<Map<String, dynamic>> _filtered = [];

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
    _load();
    _searchCtrl.addListener(_filter);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        SocketService().connect(token: token);
        SocketService().on('product:updated', (_) => _load());
        SocketService().on('product:deleted', (_) => _load());
      }
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _vaccines
          : _vaccines.where((v) {
              final name = (v['productName'] ?? '').toString().toLowerCase();
              final div = (v['divisionName'] ?? '').toString().toLowerCase();
              return name.contains(q) || div.contains(q);
            }).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient.get('/products');
      if (resp is Map && resp['data'] is List) {
        _vaccines = List<Map<String, dynamic>>.from(resp['data']);
      } else if (resp is List) {
        _vaccines = List<Map<String, dynamic>>.from(resp);
      }
      _vaccines.sort((a, b) {
        final qtyA = int.tryParse(a['quantity']?.toString() ?? '0') ?? 0;
        final qtyB = int.tryParse(b['quantity']?.toString() ?? '0') ?? 0;
        if (qtyA == 0 && qtyB > 0) return 1;
        if (qtyA > 0 && qtyB == 0) return -1;
        return 0; // alphabetical or other sort can be added here if needed
      });
      _filtered = _vaccines;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addToCart(Map vaccine) async {
    final ctrl = TextEditingController(text: '1');
    final qty = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(vaccine['productName'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select quantity to add to cart',
                style: TextStyle(color: Color(0xFF6B7A9D), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF4361EE)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7A9D))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text) ?? 1),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
    if (qty == null) return;
    Provider.of<CartProvider>(context, listen: false).addItem(vaccine, qty);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart ✓'),
        backgroundColor: const Color(0xFF06D6A0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _delete(String id) async {
    await ApiClient.delete('/products/$id');
    _load();
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
    final isClient = auth.currentUser?.role == 'client';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4361EE)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () { _searchCtrl.clear(); _filter(); },
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Count bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFEEF2FF),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded,
                    size: 16, color: Color(0xFF4361EE)),
                const SizedBox(width: 6),
                Text(
                  '${_filtered.length} product${_filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF4361EE)),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4361EE)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.inventory_2_outlined,
                                  size: 40, color: Color(0xFF4361EE)),
                            ),
                            const SizedBox(height: 16),
                            const Text('No products found',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D1B2A))),
                            const SizedBox(height: 4),
                            const Text('Try a different search term',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF6B7A9D))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final v = _filtered[i];
                          final name = v['productName']?.toString() ?? '';
                          final qty = int.tryParse(v['quantity']?.toString() ?? '0') ?? 0;
                          final price = v['salesPrice']?.toString() ?? '0';
                          final low = qty < 10 && qty > 0;
                          final out = qty == 0;
                          final gradient = _getGradient(i);
                          final icon = _getIcon(i);

                          return GestureDetector(
                            onTap: () => _showProductDetail(v, i),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4361EE).withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradient,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(icon, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name.isNotEmpty ? name : 'Unknown Product',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: Color(0xFF0D1B2A))),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text('₹$price',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF4361EE),
                                                      fontSize: 14)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: out
                                                      ? Colors.red.withOpacity(0.1)
                                                      : low
                                                          ? const Color(0xFFFFF8E1)
                                                          : const Color(0xFFE6FFF9),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  out ? 'Out of Stock' : low ? '⚠ $qty left' : '$qty in stock',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: out
                                                          ? Colors.red
                                                          : low
                                                              ? const Color(0xFFFFB703)
                                                              : const Color(0xFF06D6A0)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Actions
                                    if (isAdmin)
                                      Row(
                                        children: [
                                          _iconBtn(Icons.edit_rounded, const Color(0xFF4361EE), () async {
                                            await Navigator.push(context,
                                              MaterialPageRoute(builder: (_) => VaccineFormScreen(vaccine: v)));
                                            _load();
                                          }),
                                          _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF233C), () => _delete(v['_id'])),
                                        ],
                                      )
                                    else if (isClient)
                                      ElevatedButton.icon(
                                        onPressed: qty > 0 ? () => _addToCart(v) : null,
                                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                        label: Text(qty > 0 ? 'Add' : 'Out'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          backgroundColor: qty > 0 ? const Color(0xFF06D6A0) : Colors.grey[300],
                                          foregroundColor: qty > 0 ? Colors.white : Colors.grey[600],
                                          elevation: qty > 0 ? 2 : 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }

  @override
  void dispose() {
    try {
      SocketService().off('product:updated');
      SocketService().off('product:deleted');
    } catch (_) {}
    _searchCtrl.dispose();
    super.dispose();
  }
}
