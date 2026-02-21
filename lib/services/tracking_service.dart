import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/delivery_tracking_model.dart';
import '../config/api_config.dart';
import 'token_manager.dart';

class TrackingService {
  final String baseUrl = ApiConfig.baseUrl;
  Timer? _locationUpdateTimer;

  Future<DeliveryTracking> getDeliveryTracking(int orderId) async {
    try {
      final token = await TokenManager.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/deliveries/order/$orderId'), 
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(' Tracking response: ${response.statusCode}');
      print(' Tracking body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle wrapped response 
        final trackingData = data['data'] ?? data;
        return DeliveryTracking.fromJson(trackingData);
      } else if (response.statusCode == 404) {
        throw Exception('Tracking not available yet. Order may still be pending.');
      } else {
        throw Exception('Failed to fetch tracking: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tracking: $e');
      rethrow;
    }
  }

  Future<DeliveryLocation> getPartnerLocation(int partnerId) async {
    try {
      final token = await TokenManager.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/locations/partner/$partnerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locationData = data['data'] ?? data;
        return DeliveryLocation.fromJson(locationData);
      } else {
        throw Exception('Failed to fetch location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching location: $e');
      rethrow;
    }
  }

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

  void stopLiveTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  
  void dispose() {
    stopLiveTracking();
  }

  Future<Map<String, dynamic>> calculateETA({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/locations/distance'),
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
        
        return _calculateStraightLineETA(fromLat, fromLng, toLat, toLng);
      }
    } catch (e) {
      print('Error calculating ETA: $e');
      
      return _calculateStraightLineETA(fromLat, fromLng, toLat, toLng);
    }
  }

  
  Map<String, dynamic> _calculateStraightLineETA(
    double fromLat, double fromLng,
    double toLat, double toLng,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRad(toLat - fromLat);
    final dLon = _toRad(toLng - fromLng);
    final a = (dLat / 2) * (dLat / 2) +
        (_toRad(fromLat)) *
            (_toRad(toLat)) *
            (dLon / 2) *
            (dLon / 2);
    final c = 2 * (a > 0 ? 1 : 0); // simplified
    final distance = earthRadius * c;
    final duration = (distance / 30 * 60).round(); // 30km/h avg speed

    return {
      'distance': distance.clamp(0.1, 50.0),
      'duration': duration.clamp(1, 120),
    };
  }

  double _toRad(double deg) => deg * 3.141592653589793 / 180;
}
