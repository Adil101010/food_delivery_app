
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';

class UserService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<User> getUserProfile(String token) async {
    try {
      print('Fetching user profile...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 60));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to fetch profile: ${response.body}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<User> updateUserProfile({
    required String token,
    String? name,
    String? phone,
  }) async {
    try {
      print('Updating user profile...');
      
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      ).timeout(Duration(seconds: 60));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Network error: $e');
    }
  }
}
