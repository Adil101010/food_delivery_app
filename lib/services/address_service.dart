// lib/services/address_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address.dart';
import '../config/api_config.dart';
import 'token_manager.dart';

class AddressService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<Address>> getUserAddresses() async {
    try {
      print('Fetching user addresses...');
      
      final token = await TokenManager.getToken();
      final userData = await TokenManager.getUserData();
      
      final dynamic userIdDynamic = userData['userId'];
      final int userId;
      if (userIdDynamic is int) {
        userId = userIdDynamic;
      } else if (userIdDynamic is String) {
        userId = int.parse(userIdDynamic);
      } else {
        throw Exception('Invalid userId');
      }

      print('Fetching addresses for userId: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/api/addresses/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
      ).timeout(Duration(seconds: 60));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Address.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to fetch addresses: ${response.body}');
      }
    } catch (e) {
      print('Error fetching addresses: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Address> addAddress(Address address) async {
    try {
      print('Adding new address...');
      print('Address data: ${address.toJson()}');
      
      final token = await TokenManager.getToken();
      final userData = await TokenManager.getUserData();
      
      final dynamic userIdDynamic = userData['userId'];
      final int userId;
      if (userIdDynamic is int) {
        userId = userIdDynamic;
      } else if (userIdDynamic is String) {
        userId = int.parse(userIdDynamic);
      } else {
        throw Exception('Invalid userId');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
        body: json.encode(address.toJson()),
      ).timeout(Duration(seconds: 60));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Address.fromJson(data);
      } else {
        throw Exception('Failed to add address: ${response.body}');
      }
    } catch (e) {
      print('Error adding address: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Address> updateAddress(int id, Address address) async {
    try {
      print('Updating address $id...');
      
      final token = await TokenManager.getToken();
      final userData = await TokenManager.getUserData();
      
      final dynamic userIdDynamic = userData['userId'];
      final int userId;
      if (userIdDynamic is int) {
        userId = userIdDynamic;
      } else if (userIdDynamic is String) {
        userId = int.parse(userIdDynamic);
      } else {
        throw Exception('Invalid userId');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/addresses/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
        body: json.encode(address.toJson()),
      ).timeout(Duration(seconds: 60));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Address.fromJson(data);
      } else {
        throw Exception('Failed to update address: ${response.body}');
      }
    } catch (e) {
      print('Error updating address: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      print('Deleting address $id...');
      
      final token = await TokenManager.getToken();
      final userData = await TokenManager.getUserData();
      
      final dynamic userIdDynamic = userData['userId'];
      final int userId;
      if (userIdDynamic is int) {
        userId = userIdDynamic;
      } else if (userIdDynamic is String) {
        userId = int.parse(userIdDynamic);
      } else {
        throw Exception('Invalid userId');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/addresses/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
      ).timeout(Duration(seconds: 60));

      print('Response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete address');
      }
    } catch (e) {
      print('Error deleting address: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Address> setDefaultAddress(int id) async {
    try {
      print('Setting default address $id...');
      
      final token = await TokenManager.getToken();
      final userData = await TokenManager.getUserData();
      
      final dynamic userIdDynamic = userData['userId'];
      final int userId;
      if (userIdDynamic is int) {
        userId = userIdDynamic;
      } else if (userIdDynamic is String) {
        userId = int.parse(userIdDynamic);
      } else {
        throw Exception('Invalid userId');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/api/addresses/$id/default'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
      ).timeout(Duration(seconds: 60));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Address.fromJson(data);
      } else {
        throw Exception('Failed to set default address');
      }
    } catch (e) {
      print('Error setting default address: $e');
      throw Exception('Network error: $e');
    }
  }
}
