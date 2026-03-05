import 'package:flutter/material.dart';
import '../api_client.dart';

class ClientFormScreen extends StatefulWidget {
  final Map<String, dynamic>? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Database field controllers
  final _customerCodeController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _dealerTypeController = TextEditingController();
  final _specializationController = TextEditingController();
  final _gstNumberController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    if (client != null) {
      _customerCodeController.text = client['customerCode']?.toString() ?? '';
      _customerNameController.text = client['customerName']?.toString() ?? '';
      _contactController.text = client['contact']?.toString() ?? '';
      _customerAddressController.text = client['customerAddress']?.toString() ?? '';
      _dealerTypeController.text = client['dealerType']?.toString() ?? '';
      _specializationController.text = client['specialization']?.toString() ?? '';
      _gstNumberController.text = client['gstNumber']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _customerCodeController.dispose();
    _customerNameController.dispose();
    _contactController.dispose();
    _customerAddressController.dispose();
    _dealerTypeController.dispose();
    _specializationController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);

  try {
    // ⭐ MAP FORM FIELDS → BACKEND FIELDS
    final body = {
      "name": _customerNameController.text.trim(),
      "specialization": _specializationController.text.trim(),
      "contact": _contactController.text.trim(),
      "address": _customerAddressController.text.trim(),
    };

    if (widget.client == null) {
      // CREATE
      await ApiClient.post('/clients', body);
    } else {
      // UPDATE
      final id = widget.client!['_id'].toString();
      await ApiClient.put('/clients/$id', body);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.client != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Client' : 'Add Client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Customer Code
                TextFormField(
                  controller: _customerCodeController,
                  decoration: const InputDecoration(labelText: 'Customer Code'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Customer Code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Customer Name
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Customer Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Minimum 2 characters required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Contact
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                
                // Customer Address
                TextFormField(
                  controller: _customerAddressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Dealer Type
                DropdownButtonFormField<String>(
                  value: _dealerTypeController.text.trim().isEmpty 
                      ? null 
                      : _dealerTypeController.text.trim(),
                  decoration: const InputDecoration(labelText: 'Dealer Type'),
                  items: const [
                    DropdownMenuItem(value: 'GST', child: Text('GST')),
                    DropdownMenuItem(value: 'Non GST', child: Text('Non GST')),
                  ],
                  onChanged: (value) {
                    _dealerTypeController.text = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value!.trim().isEmpty) {
                      return 'Dealer Type is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Specialization
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                      labelText: 'Specialization / Clinic Type'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Specialization is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // GST Number
                TextFormField(
                  controller: _gstNumberController,
                  decoration: const InputDecoration(labelText: 'GST Number'),
                  validator: (value) {
                    final dealerType = _dealerTypeController.text.trim();
                    if (dealerType == 'GST' && (value == null || value.trim().isEmpty)) {
                      return 'GST Number is required for GST dealers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting
                          ? 'Saving...'
                          : (isEdit ? 'Update' : 'Add Client'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
