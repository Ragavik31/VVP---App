import 'package:flutter/material.dart';

import '../api_client.dart';

class VaccineFormScreen extends StatefulWidget {
  final Map<String, dynamic>? vaccine;
  final bool isRestock;

  const VaccineFormScreen({super.key, this.vaccine, this.isRestock = false});

  @override
  State<VaccineFormScreen> createState() => _VaccineFormScreenState();
}

class _VaccineFormScreenState extends State<VaccineFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _vaccineNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _doseVolumeController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _expiryDateController = TextEditingController();

  String? _selectedVaccineType;
  bool _boosterRequired = false;
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final vaccine = widget.vaccine;
    if (vaccine != null) {
      _vaccineNameController.text =
          vaccine['vaccineName']?.toString() ?? '';
      _manufacturerController.text =
          vaccine['manufacturer']?.toString() ?? '';
      _selectedVaccineType = vaccine['vaccineType']?.toString();
      _doseVolumeController.text =
          vaccine['doseVolumeMl']?.toString() ?? '';
      _boosterRequired = vaccine['boosterRequired'] == true;

      if (!widget.isRestock) {
        _batchNumberController.text =
            vaccine['batchNumber']?.toString() ?? '';
        _quantityController.text = vaccine['quantity']?.toString() ?? '';
        _purchasePriceController.text = vaccine['purchasePrice']?.toString() ?? '';
        _sellingPriceController.text = vaccine['sellingPrice']?.toString() ?? '';

        final expiryRaw = vaccine['expiryDate']?.toString();
        if (expiryRaw != null && expiryRaw.isNotEmpty) {
          _expiryDate = DateTime.tryParse(expiryRaw);
          if (_expiryDate != null) {
            _expiryDateController.text =
                _expiryDate!.toIso8601String().split('T').first;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _manufacturerController.dispose();
    _doseVolumeController.dispose();
    _batchNumberController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  void _calculateSellingPrice() {
    final purchasePriceText = _purchasePriceController.text.trim();
    if (purchasePriceText.isNotEmpty) {
      final purchasePrice = double.tryParse(purchasePriceText);
      if (purchasePrice != null && purchasePrice > 0) {
        final sellingPrice = purchasePrice * 1.03;
        _sellingPriceController.text = sellingPrice.toStringAsFixed(2);
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final initialDate = _expiryDate != null && _expiryDate!.isAfter(now)
        ? _expiryDate!
        : now.add(const Duration(days: 1));

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (selected != null) {
      setState(() {
        _expiryDate = selected;
        _expiryDateController.text =
            _expiryDate!.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    if (_expiryDate == null || !_expiryDate!.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry date must be a future date (after today)'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final body = {
        'vaccineName': _vaccineNameController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'vaccineType': _selectedVaccineType,
        'doseVolumeMl':
            double.parse(_doseVolumeController.text.trim()),
        'boosterRequired': _boosterRequired,
        'batchNumber': _batchNumberController.text.trim(),
        'expiryDate': _expiryDate!.toIso8601String(),
        'quantity': int.parse(_quantityController.text.trim()),
        'purchasePrice': double.parse(_purchasePriceController.text.trim()),
        'sellingPrice': double.parse(_sellingPriceController.text.trim()),
      };

      if (widget.vaccine == null) {
        await ApiClient.post('/vaccines', body);
      } else {
        final id =
            widget.vaccine!['_id']?.toString() ?? widget.vaccine!['id'].toString();
        await ApiClient.put('/vaccines/$id', body);
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
    final isEdit = widget.vaccine != null && !widget.isRestock;
    final title = widget.isRestock
        ? 'Restock Vaccine'
        : (isEdit ? 'Edit Vaccine' : 'Add Vaccine');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _vaccineNameController,
                  decoration:
                      const InputDecoration(labelText: 'Vaccine Name'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Vaccine name is required';
                    }
                    if (text.length < 2) {
                      return 'Minimum 2 characters required';
                    }
                    final regex = RegExp(r'^[A-Za-z0-9 ]+');
                    if (!regex.hasMatch(text)) {
                      return 'Only letters, numbers and spaces are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _manufacturerController,
                  decoration:
                      const InputDecoration(labelText: 'Manufacturer'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Manufacturer is required';
                    }
                    if (text.length < 2) {
                      return 'Minimum 2 characters required';
                    }
                    final regex = RegExp(r'^[A-Za-z0-9 ]+');
                    if (!regex.hasMatch(text)) {
                      return 'Only letters, numbers and spaces are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedVaccineType,
                  items: const [
                    DropdownMenuItem(
                      value: 'Live',
                      child: Text('Live'),
                    ),
                    DropdownMenuItem(
                      value: 'Inactivated',
                      child: Text('Inactivated'),
                    ),
                    DropdownMenuItem(
                      value: 'mRNA',
                      child: Text('mRNA'),
                    ),
                    DropdownMenuItem(
                      value: 'Subunit',
                      child: Text('Subunit'),
                    ),
                  ],
                  decoration:
                      const InputDecoration(labelText: 'Vaccine Type'),
                  onChanged: (value) {
                    setState(() {
                      _selectedVaccineType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vaccine type is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doseVolumeController,
                  decoration: const InputDecoration(
                    labelText: 'Dose Volume (ml)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Dose volume is required';
                    }
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a number greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Booster Required'),
                  value: _boosterRequired,
                  onChanged: (value) {
                    setState(() {
                      _boosterRequired = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _batchNumberController,
                  decoration:
                      const InputDecoration(labelText: 'Vaccine Batch Number'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Batch number is required';
                    }
                    if (text.length < 3) {
                      return 'Minimum 3 characters required';
                    }
                    final regex = RegExp(r'^[A-Za-z0-9]+$');
                    if (!regex.hasMatch(text)) {
                      return 'Batch number must be alphanumeric only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _expiryDateController,
                  readOnly: true,
                  decoration:
                      const InputDecoration(labelText: 'Expiry Date'),
                  onTap: _pickExpiryDate,
                  validator: (value) {
                    if (_expiryDate == null) {
                      return 'Expiry date is required';
                    }
                    final now = DateTime.now();
                    if (!_expiryDate!.isAfter(now)) {
                      return 'Expiry date must be in the future';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purchasePriceController,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price (Cost)',
                    prefixText: '₹ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    _calculateSellingPrice();
                  },
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Purchase price is required';
                    }
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a number greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sellingPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (Purchase + 3%)',
                    prefixText: '₹ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  readOnly: true,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Selling price is calculated automatically';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration:
                      const InputDecoration(labelText: 'Product Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Quantity is required';
                    }
                    final parsed = int.tryParse(text);
                    if (parsed == null || parsed < 0) {
                      return 'Enter a whole number greater than or equal to 0';
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
                          : (widget.isRestock
                              ? 'Add Stock'
                              : (isEdit ? 'Save' : 'Add')),
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
