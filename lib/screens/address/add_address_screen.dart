// lib/screens/address/add_address_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../models/address.dart';
import '../../services/address_service.dart';
import '../../services/token_manager.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address;

  const AddAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService = AddressService();

  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isDefault = false;
  bool _isSaving = false;
  String _selectedLabel = 'Home';

  final List<String> _addressLabels = ['Home', 'Work', 'Hotel', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _loadAddressData();
    }
  }

  void _loadAddressData() {
    final address = widget.address!;
    _selectedLabel = address.label;
    _labelController.text = address.label;
    _addressController.text = address.fullAddress;
    _landmarkController.text = address.landmark ?? '';
    _cityController.text = address.city;
    _stateController.text = address.state;
    _pincodeController.text = address.pincode;
    _isDefault = address.isDefault;
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userData = await TokenManager.getUserData();
      print('User data: $userData');
      
      final dynamic userIdDynamic = userData['userId'];
      print('UserId dynamic: $userIdDynamic (type: ${userIdDynamic.runtimeType})');
      
      final int userId;
      if (userIdDynamic is int) {
        userId = userIdDynamic;
      } else if (userIdDynamic is String) {
        userId = int.parse(userIdDynamic);
      } else if (userIdDynamic == null) {
        throw Exception('UserId is null');
      } else {
        throw Exception('Invalid userId type: ${userIdDynamic.runtimeType}');
      }
      
      print('UserId converted: $userId');

      final address = Address(
        id: widget.address?.id,
        userId: userId,
        label: _selectedLabel == 'Other' 
            ? _labelController.text.trim() 
            : _selectedLabel,
        fullAddress: _addressController.text.trim(),
        landmark: _landmarkController.text.trim().isNotEmpty 
            ? _landmarkController.text.trim() 
            : null,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        isDefault: _isDefault,
      );

      print('Address to save: ${address.toJson()}');

      if (widget.address == null) {
        await _addressService.addAddress(address);
      } else {
        await _addressService.updateAddress(widget.address!.id!, address);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address == null 
                ? 'Address added successfully' 
                : 'Address updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Address Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _addressLabels.map((label) {
                    return ChoiceChip(
                      label: Text(label),
                      selected: _selectedLabel == label,
                      onSelected: (selected) {
                        setState(() {
                          _selectedLabel = label;
                          if (label != 'Other') {
                            _labelController.clear();
                          }
                        });
                      },
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: _selectedLabel == label 
                            ? Colors.white 
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedLabel == 'Other') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      labelText: 'Custom Label',
                      hintText: 'e.g., Friend\'s Place',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (_selectedLabel == 'Other' && 
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter a label';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Address Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Full Address',
                    hintText: 'House No, Building Name, Street',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter full address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landmarkController,
                  decoration: InputDecoration(
                    labelText: 'Landmark (Optional)',
                    hintText: 'Nearby landmark',
                    prefixIcon: const Icon(Icons.place),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: InputDecoration(
                          labelText: 'State',
                          prefixIcon: const Icon(Icons.map),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pincodeController,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    prefixIcon: const Icon(Icons.pin_drop),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter pincode';
                    }
                    if (value.length != 6) {
                      return 'Pincode must be 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: CheckboxListTile(
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value ?? false;
                      });
                    },
                    title: const Text(
                      'Set as default address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'This address will be used for deliveries by default',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.address == null ? 'Save Address' : 'Update Address',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
