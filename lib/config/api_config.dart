class ApiConfig {
  // Detect platform and network
  static bool get isAndroid => true;  
  static bool get isIOS => false;
  
  // Base URLs for different environments
  static const String LOCALHOST = 'http://localhost:8080';
  static const String ANDROID_EMULATOR = 'http://10.0.2.2:8080';
  
  //  PC's local IP 
  static const String LOCAL_NETWORK = 'http://192.168.0.124:8080';  
  
  // Production server (when deployed)
  static const String PRODUCTION = 'https://your-api.com';
  
  // Current environment
  static const AppEnvironment environment = AppEnvironment.localNetwork;
  
  // Get base URL based on environment
  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.localhost:
        return LOCALHOST;
      case AppEnvironment.androidEmulator:
        return ANDROID_EMULATOR;
      case AppEnvironment.localNetwork:
        return LOCAL_NETWORK;
      case AppEnvironment.production:
        return PRODUCTION;
    }
  }
  
  
  static const Duration connectTimeout = Duration(seconds: 60); 
  static const Duration receiveTimeout = Duration(seconds: 60); 
  static const Duration sendTimeout = Duration(seconds: 60);    
  
  
  static const bool isDebugMode = true;
}

enum AppEnvironment {
  localhost,        // For Windows desktop app
  androidEmulator,  // For Android emulator
  localNetwork,     // For real phone on same WiFi
  production,       // For deployed backend
}
