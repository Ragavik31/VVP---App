import 'package:flutter/material.dart';
import '../api_client.dart';

class VaccineFormScreen extends StatefulWidget {
  final Map<String, dynamic>? vaccine;

  const VaccineFormScreen({super.key, this.vaccine});

  @override
  State<VaccineFormScreen> createState() => _VaccineFormScreenState();
}

class _VaccineFormScreenState extends State<VaccineFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final divisionCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final salesCtrl = TextEditingController();
  final mrpCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  bool _loading = false;
  bool get isEdit => widget.vaccine != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final v = widget.vaccine!;
      divisionCtrl.text = v['divisionName'] ?? '';
      nameCtrl.text = v['productName'] ?? '';
      salesCtrl.text = v['salesPrice'].toString();
      mrpCtrl.text = v['mrp'].toString();
      qtyCtrl.text = v['quantity'].toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      "divisionName": divisionCtrl.text,
      "productName": nameCtrl.text,
      "salesPrice": double.parse(salesCtrl.text),
      "mrp": double.parse(mrpCtrl.text),
      "quantity": int.parse(qtyCtrl.text),
    };

    try {
      if (isEdit) {
        await ApiClient.put('/products/${widget.vaccine!['_id']}', body);
      } else {
        await ApiClient.post('/products', body);
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Vaccine" : "Add Vaccine")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              field("Division Name", divisionCtrl),
              field("Product Name", nameCtrl),
              field("Sales Price", salesCtrl),
              field("MRP", mrpCtrl),
              field("Quantity", qtyCtrl),

              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text("Save"))
            ],
          ),
        ),
      ),
    );
  }
}
