import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../api_client.dart';
import '../auth/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
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
                          final low = qty < 10;

                          return Container(
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
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4361EE), Color(0xFF7B9EFF)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.vaccines_rounded,
                                        color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
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
                                                color: low
                                                    ? const Color(0xFFFFF8E1)
                                                    : const Color(0xFFE6FFF9),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                low ? '⚠ $qty left' : '$qty in stock',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: low
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
                                      onPressed: () => _addToCart(v),
                                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                      label: const Text('Add'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        textStyle: const TextStyle(fontSize: 13),
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
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VaccineFormScreen()));
                _load();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product'),
            )
          : null,
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
    _searchCtrl.dispose();
    super.dispose();
  }
}
