import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/delivery_tracking_model.dart';
import '../config/api_config.dart';
import 'token_manager.dart';

class TrackingService {
  final String baseUrl = ApiConfig.baseUrl;
  Timer? _locationUpdateTimer;

  // Get delivery tracking info
  Future<DeliveryTracking> getDeliveryTracking(int orderId) async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/order/$orderId/tracking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeliveryTracking.fromJson(data);
      } else {
        throw Exception('Failed to fetch tracking: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tracking: $e');
      rethrow;
    }
  }

  // Get partner current location
  Future<DeliveryLocation> getPartnerLocation(int partnerId) async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/locations/partner/$partnerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeliveryLocation.fromJson(data);
      } else {
        throw Exception('Failed to fetch location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching location: $e');
      rethrow;
    }
  }

  // Start live tracking (Auto-refresh every 10 seconds)
  void startLiveTracking(
    int partnerId,
    Function(DeliveryLocation) onLocationUpdate,
  ) {
    _locationUpdateTimer?.cancel();
    
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        try {
          final location = await getPartnerLocation(partnerId);
          onLocationUpdate(location);
        } catch (e) {
          print('Error updating location: $e');
        }
      },
    );
  }

  // Stop live tracking
  void stopLiveTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  // Calculate ETA
  Future<Map<String, dynamic>> calculateETA({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/locations/distance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fromLatitude': fromLat,
          'fromLongitude': fromLng,
          'toLatitude': toLat,
          'toLongitude': toLng,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate ETA');
      }
    } catch (e) {
      print('Error calculating ETA: $e');
      rethrow;
    }
  }
}
