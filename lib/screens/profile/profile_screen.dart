import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/token_manager.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../notifications/notifications_screen.dart';
import 'about_screen.dart';
import '../address/address_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  User? _user;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad(); // ✅ Direct _loadUserProfile() nahi
  }

  // ─────────────────────────────────────────
  // Auth Check — login nahi hai toh login screen
  // ─────────────────────────────────────────
  Future<void> _checkAuthAndLoad() async {
    final isLoggedIn = await TokenManager.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
      return;
    }
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _apiService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle),
              child:
                  Icon(Icons.logout, color: AppTheme.error, size: 32),
            ),
            const SizedBox(height: 12),
            const Text('Logout?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                          color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Logout',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
        actionsPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    if (confirm == true) {
      await TokenManager.clearAuthData(); //  clearToken() → clearAuthData()
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        // automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary))
          : _errorMessage != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  color: AppTheme.primary,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 8),
                        _buildMenuSection(),
                        const SizedBox(height: 8),
                        _buildSettingsSection(),
                        const SizedBox(height: 24),
                        _buildLogoutButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ═══════════════════════════════════════════
  //  ERROR WIDGET
  // ═══════════════════════════════════════════
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.error_outline,
                  size: 64, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load profile',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  PROFILE HEADER
  // ═══════════════════════════════════════════
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                      width: 2),
                ),
                child: Center(
                  child: Text(
                    _user!.name.isNotEmpty
                        ? _user!.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const EditProfileScreen()),
                    );
                    if (result == true) _loadUserProfile();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_user!.name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(_user!.email,
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(_user!.phone,
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary)),
          if (_user!.role != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_user!.role!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary)),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  MENU SECTION
  // ═══════════════════════════════════════════
  Widget _buildMenuSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ACCOUNT'),
          _buildMenuItem(
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            title: 'Edit Profile',
            subtitle: 'Update your name and phone',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const EditProfileScreen()),
              );
              if (result == true) _loadUserProfile();
            },
          ),
          Divider(
              color: AppTheme.border, height: 1, indent: 72),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.orange,
            title: 'My Orders',
            subtitle: 'View your order history',
            onTap: () =>
                Navigator.pushNamed(context, '/orders'),
          ),
          Divider(
              color: AppTheme.border, height: 1, indent: 72),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            iconColor: Colors.red,
            title: 'Saved Addresses',
            subtitle: 'Manage delivery addresses',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const AddressListScreen()),
            ),
          ),
          Divider(
              color: AppTheme.border, height: 1, indent: 72),
          _buildMenuItem(
            icon: Icons.favorite_outline,
            iconColor: Colors.pink,
            title: 'Favorites',
            subtitle: 'Your favorite restaurants',
            onTap: () =>
                Navigator.pushNamed(context, '/favorites'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  SETTINGS SECTION
  // ═══════════════════════════════════════════
  Widget _buildSettingsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('SETTINGS'),
          _buildMenuItem(
            icon: Icons.lock_outline,
            iconColor: Colors.purple,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const ChangePasswordScreen()),
            ),
          ),
          Divider(
              color: AppTheme.border, height: 1, indent: 72),
          _buildMenuItem(
            icon: Icons.notifications_none,
            iconColor: Colors.amber,
            title: 'Notifications',
            subtitle: 'Manage your notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const NotificationsScreen()),
            ),
          ),
          Divider(
              color: AppTheme.border, height: 1, indent: 72),
          _buildMenuItem(
            icon: Icons.help_outline,
            iconColor: Colors.teal,
            title: 'Help & Support',
            subtitle: 'Get help with your orders',
            onTap: () => _showComingSoon('Help & Support'),
          ),
          Divider(
              color: AppTheme.border, height: 1, indent: 72),
          _buildMenuItem(
            icon: Icons.info_outline,
            iconColor: Colors.blueGrey,
            title: 'About',
            subtitle: 'App version & info',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0)),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — Coming soon!'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            side: const BorderSide(color: AppTheme.error),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Logout',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
      trailing:
          Icon(Icons.chevron_right, color: AppTheme.textLight),
    );
  }
}
