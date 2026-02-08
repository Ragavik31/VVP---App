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

  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    if (client != null) {
      _nameController.text = client['name']?.toString() ?? '';
      _specializationController.text =
          client['specialization']?.toString() ?? '';
      _contactController.text = client['contact']?.toString() ?? '';
      _addressController.text = client['address']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final body = {
        'name': _nameController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
      };

      if (widget.client == null) {
        await ApiClient.post('/clients', body);
      } else {
        final id =
            widget.client!['_id']?.toString() ?? widget.client!['id'].toString();
        await ApiClient.put('/clients/$id', body);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Minimum 2 characters required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                      labelText: 'Specialisation / Clinic Type'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Specialization is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting
                          ? 'Saving...'
                          : (isEdit ? 'Save' : 'Add'),
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
