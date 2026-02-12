// lib/screens/address/address_list_screen.dart

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/address.dart';
import '../../services/address_service.dart';
import 'add_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  final bool isSelectionMode;

  const AddressListScreen({
    Key? key,
    this.isSelectionMode = false,
  }) : super(key: key);

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final AddressService _addressService = AddressService();
  
  List<Address> _addresses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final addresses = await _addressService.getUserAddresses();
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(int id) async {
    try {
      await _addressService.deleteAddress(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted successfully')),
      );
      _loadAddresses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete address: $e')),
      );
    }
  }

  Future<void> _setDefaultAddress(int id) async {
    try {
      await _addressService.setDefaultAddress(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default address updated')),
      );
      _loadAddresses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update default address: $e')),
      );
    }
  }

  void _showDeleteDialog(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete ${address.label}?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(address.id!);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Select Address' : 'My Addresses'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _addresses.isEmpty
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _loadAddresses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          return _buildAddressCard(_addresses[index]);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAddressScreen(),
            ),
          );

          if (result == true) {
            _loadAddresses();
          }
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load addresses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAddresses,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No addresses saved',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery address',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: address.isDefault
            ? const BorderSide(color: AppTheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: widget.isSelectionMode
            ? () => Navigator.pop(context, address)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getAddressIcon(address.label),
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        address.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!widget.isSelectionMode)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAddressScreen(
                                address: address,
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadAddresses();
                            }
                          });
                        } else if (value == 'default') {
                          _setDefaultAddress(address.id!);
                        } else if (value == 'delete') {
                          _showDeleteDialog(address);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (!address.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 20),
                                SizedBox(width: 12),
                                Text('Set as Default'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: AppTheme.error),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: AppTheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address.displayAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
      case 'office':
        return Icons.work;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.location_on;
    }
  }
}
