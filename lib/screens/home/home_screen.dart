import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../services/api_service.dart';
import '../restaurant/restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;
  String _userEmail = '';
  String _userName = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchRestaurants();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email') ?? 'User';
      _userName = prefs.getString('name') ?? _userEmail.split('@')[0];
    });
  }

  Future<void> _fetchRestaurants() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getAllRestaurants();
      final restaurants = data.map((json) => Restaurant.fromJson(json)).toList();

      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load restaurants: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _searchRestaurants(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRestaurants = _restaurants;
      } else {
        _filteredRestaurants = _restaurants
            .where((restaurant) =>
                restaurant.name.toLowerCase().contains(query.toLowerCase()) ||
                restaurant.cuisine.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRestaurants,
          color: AppTheme.primary,
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(),
              
              // Search Bar
              _buildSearchBar(),
              
              // Offers Section
              _buildOffersSection(),
              
              // Categories
              _buildCategoriesSection(),
              
              // Section Title
              _buildSectionTitle(),
              
              // Restaurant List
              _buildRestaurantsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hi $_userName 👋',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Profile Icon
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.person_outline, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
            ),
            const SizedBox(width: 8),
            // Cart Icon
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: TextField(
          controller: _searchController,
          onChanged: _searchRestaurants,
          decoration: InputDecoration(
            hintText: 'Search for restaurants or cuisines',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _searchRestaurants('');
                    },
                  )
                : Icon(Icons.mic_outlined, color: AppTheme.textSecondary),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildOffersSection() {
    final offers = [
      {
        'title': 'FEB DEALS',
        'subtitle': '60% OFF +\n20% CASHBACK',
        'color': const Color(0xFFE91E63),
        'icon': '🎉',
      },
      {
        'title': '99 STORE',
        'subtitle': 'MEALS AT\n₹99',
        'color': AppTheme.primary,
        'icon': '🍔',
      },
      {
        'title': 'FAST DELIVERY',
        'subtitle': 'Under\n30 mins',
        'color': const Color(0xFF9C27B0),
        'icon': '⚡',
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _buildOfferCard(
              offer['title'] as String,
              offer['subtitle'] as String,
              offer['color'] as Color,
              offer['icon'] as String,
            );
          },
        ),
      ),
    );
  }

  Widget _buildOfferCard(String title, String subtitle, Color color, String icon) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ORDER NOW',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 20,
            child: Text(
              icon,
              style: const TextStyle(fontSize: 50),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Pizza', 'icon': '🍕'},
      {'name': 'Burgers', 'icon': '🍔'},
      {'name': 'Biryani', 'icon': '🍛'},
      {'name': 'Chinese', 'icon': '🥡'},
      {'name': 'Desserts', 'icon': '🍰'},
      {'name': 'Beverages', 'icon': '🥤'},
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                // Filter by category
                _searchRestaurants(category['name']!);
              },
              child: Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category['icon']!,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Restaurants (${_filteredRestaurants.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (!_isLoading)
              TextButton(
                onPressed: _fetchRestaurants,
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsList() {
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      );
    }

    if (_filteredRestaurants.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu_outlined,
                  size: 80,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No restaurants found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final restaurant = _filteredRestaurants[index];
            return _buildRestaurantCard(restaurant);
          },
          childCount: _filteredRestaurants.length,
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image with Overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: const Color(0xFFF5F5F5),
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 60,
                      color: AppTheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
                // Discount Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '50% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            // Restaurant Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisine,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.rating,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delivery Time
                      Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.avgDeliveryTime != null
                            ? '${restaurant.avgDeliveryTime} mins'
                            : '30 mins',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price
                      Text(
                        '₹200 for one',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Offer Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      restaurant.deliveryFee != null && restaurant.deliveryFee! > 0
                          ? '₹${restaurant.deliveryFee!.toStringAsFixed(0)} delivery fee'
                          : '🎉 Free delivery on orders above ₹199',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC2185B),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
