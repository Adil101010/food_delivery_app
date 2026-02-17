// lib/services/favorite_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/favorite.dart';
import 'token_manager.dart';

class FavoriteService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<int>> getUserFavoriteRestaurantIds() async {
    try {
      final token = await TokenManager.getToken();
      final userId = await TokenManager.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('Get favorites response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final favorites = data.map((json) => Favorite.fromJson(json)).toList();
        return favorites.map((f) => f.restaurantId).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  Future<bool> isFavorite(int restaurantId) async {
    try {
      final token = await TokenManager.getToken();
      final userId = await TokenManager.getUserId();

      if (userId == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites/check/$userId/$restaurantId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(int restaurantId) async {
    try {
      final token = await TokenManager.getToken();
      final userId = await TokenManager.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('Toggling favorite: userId=$userId, restaurantId=$restaurantId');

      final response = await http.post(
        Uri.parse('$baseUrl/api/favorites/toggle'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'restaurantId': restaurantId,
        }),
      ).timeout(Duration(seconds: 30));

      print('Toggle response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorite'] ?? false;
      } else {
        throw Exception('Failed to toggle favorite: ${response.body}');
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> addFavorite(int restaurantId) async {
    try {
      final token = await TokenManager.getToken();
      final userId = await TokenManager.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'restaurantId': restaurantId,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to add favorite');
      }
    } catch (e) {
      print('Error adding favorite: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> removeFavorite(int restaurantId) async {
    try {
      final token = await TokenManager.getToken();
      final userId = await TokenManager.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/favorites/$userId/$restaurantId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to remove favorite');
      }
    } catch (e) {
      print('Error removing favorite: $e');
      throw Exception('Network error: $e');
    }
  }
}
