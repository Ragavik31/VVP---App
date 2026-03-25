import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += (item['itemTotal'] as num).toDouble();
    }
    return double.parse(total.toStringAsFixed(2));
  }

  void addItem(Map product, int qty) {
    final price = double.parse(((product['salesPrice'] ?? product['sellingPrice'] ?? 0).toDouble()).toStringAsFixed(2));
    final itemTotal = double.parse((price * qty).toStringAsFixed(2));

    _items.add({
      'vaccineId': product['_id'],
      'vaccineName': product['productName'],
      'quantity': qty,
      'sellingPrice': price,
      'itemTotal': itemTotal,
    });

    notifyListeners();
  }

  void updateQuantity(int index, int newQty) {
    if (newQty <= 0) {
      removeItem(index);
      return;
    }
    final item = _items[index];
    final price = item['sellingPrice'] as double;
    final itemTotal = double.parse((price * newQty).toStringAsFixed(2));

    item['quantity'] = newQty;
    item['itemTotal'] = itemTotal;

    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
