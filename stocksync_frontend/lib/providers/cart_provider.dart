import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += (item['itemTotal'] as num).toDouble();
    }
    return total;
  }

  void addItem(Map product, int qty) {
    final price = (product['salesPrice'] ?? product['sellingPrice'] ?? 0).toDouble();

    _items.add({
      'vaccineId': product['_id'],
      'vaccineName': product['productName'],
      'quantity': qty,
      'sellingPrice': price,
      'itemTotal': price * qty,
    });

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
