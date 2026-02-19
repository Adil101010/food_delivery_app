import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('About',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App Logo & Version
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant,
                        size: 60, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Food Delivery',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Version 1.0.0',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text('Stable Release',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Info Cards
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.code,
                    iconColor: Colors.blue,
                    title: 'Technology',
                    value: 'Flutter + Spring Boot',
                  ),
                  Divider(color: AppTheme.border, height: 1, indent: 72),
                  _buildInfoTile(
                    icon: Icons.storage,
                    iconColor: Colors.orange,
                    title: 'Architecture',
                    value: 'Microservices',
                  ),
                  Divider(color: AppTheme.border, height: 1, indent: 72),
                  _buildInfoTile(
                    icon: Icons.payment,
                    iconColor: Colors.green,
                    title: 'Payment',
                    value: 'Razorpay Integrated',
                  ),
                  Divider(color: AppTheme.border, height: 1, indent: 72),
                  _buildInfoTile(
                    icon: Icons.security,
                    iconColor: Colors.purple,
                    title: 'Security',
                    value: 'JWT Authentication',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Features
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Features',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  _buildFeatureChip('🍕 Multi-Restaurant Ordering'),
                  _buildFeatureChip('📍 Saved Addresses'),
                  _buildFeatureChip('💳 Multiple Payment Methods'),
                  _buildFeatureChip('🎟️ Coupon & Promo Codes'),
                  _buildFeatureChip('❤️ Favourite Restaurants'),
                  _buildFeatureChip('📦 Real-time Order Tracking'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Developer Info
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Made with ❤️ in India',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('© 2026 Food Delivery App',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textLight)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 13, color: AppTheme.textSecondary)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
