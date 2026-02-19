import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';  
import 'providers/review_provider.dart';  
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/orders/order_history_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash/animated_splash_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/notifications/notifications_screen.dart';  
import 'screens/reviews/user_reviews_screen.dart';
import 'screens/cart/cart_screen.dart';
import '../screens/address/address_list_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()), 
        ChangeNotifierProvider(create: (_) => ReviewProvider()),        
      ],
      child: MaterialApp(
        title: 'Food Delivery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AnimatedSplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(), 
          '/orders': (context) => const OrderHistoryScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/notifications': (context) => const NotificationsScreen(),  
          '/my-reviews': (context) => const UserReviewsScreen(),      
           '/address':       (context) => const AddressListScreen(), 
        },
      ),
    );
  }
}
