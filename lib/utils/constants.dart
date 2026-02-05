class AppConstants {
  // Backend API Base URL
  // Note: Android Emulator ke liye 10.0.2.2 = localhost
  // Real device ke liye apna laptop ka IP use karo (192.168.x.x)
  // Windows/Web ke liye localhost use karo
  static const String baseUrl = 'http://localhost:8080';  // ← /api REMOVE KIYA
  
  // Razorpay Test Key
  static const String razorpayKey = 'rzp_test_S7dzWtY5DsSafC';
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String restaurantsEndpoint = '/api/restaurants';
  static const String ordersEndpoint = '/api/orders';
  static const String paymentsEndpoint = '/api/payments/razorpay';
}
