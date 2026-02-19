import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../services/api_service.dart';
import '../../services/favorite_service.dart';
import '../restaurant/restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  final _favoriteService = FavoriteService();

  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;
  String _userEmail = '';
  String _userName = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(); // ✅ FIX 5: mic ke liye

  // ✅ FIX 2: favorites state
  Set<int> _favoriteIds = {};
  final Map<int, bool> _togglingFavorite = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchRestaurants();
    _loadFavorites();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email') ?? 'User';
      _userName = prefs.getString('name') ?? _userEmail.split('@')[0];
    });
  }

  // ✅ FIX 2: favorites load
  Future<void> _loadFavorites() async {
    try {
      final ids = await _favoriteService.getUserFavoriteRestaurantIds();
      if (mounted) setState(() => _favoriteIds = ids.toSet());
    } catch (_) {}
  }

  // ✅ FIX 2: toggle favorite
  Future<void> _toggleFavorite(int restaurantId) async {
    if (_togglingFavorite[restaurantId] == true) return;

    setState(() => _togglingFavorite[restaurantId] = true);

    // Optimistic update
    setState(() {
      if (_favoriteIds.contains(restaurantId)) {
        _favoriteIds.remove(restaurantId);
      } else {
        _favoriteIds.add(restaurantId);
      }
    });

    try {
      await _favoriteService.toggleFavorite(restaurantId);
    } catch (_) {
      // Rollback on error
      setState(() {
        if (_favoriteIds.contains(restaurantId)) {
          _favoriteIds.remove(restaurantId);
        } else {
          _favoriteIds.add(restaurantId);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favourite')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingFavorite[restaurantId] = false);
    }
  }

  Future<void> _fetchRestaurants() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAllRestaurants();
      final restaurants =
          data.map((json) => Restaurant.fromJson(json)).toList();
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
            .where((r) =>
                r.name.toLowerCase().contains(query.toLowerCase()) ||
                r.cuisine.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ================================================================
  //  BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchRestaurants,
            color: Colors.white,
            child: CustomScrollView(
              slivers: [
                _buildOrangeHeader(),
                _buildSearchBar(),
                _buildOffersSection(),
                _buildCategoriesSection(),
                _buildWhiteBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  //  ORANGE HEADER  ✅ FIX 4: address click → /address
  // ================================================================
  Widget _buildOrangeHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            // ✅ Address block — clickable
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/address'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 18),
                          ],
                        ),
                        Text(
                          'Hi $_userName 👋',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Cart
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_bag_outlined,
                    color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
            ),
            const SizedBox(width: 8),

            // Profile avatar
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  //  SEARCH BAR  ✅ FIX 5: mic opens keyboard/focus
  // ================================================================
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _searchRestaurants,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: "Search for restaurants or cuisines",
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _searchRestaurants('');
                },
                child: Icon(Icons.clear,
                    color: AppTheme.textSecondary, size: 20),
              )
            else
              // ✅ FIX 5: mic taps → keyboard opens
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                },
                child: Icon(Icons.mic_outlined,
                    color: AppTheme.primary, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  //  OFFERS SECTION  ✅ FIX 3: overflow fix — no Spacer, fixed layout
  // ================================================================
  Widget _buildOffersSection() {
    final offers = [
      {
        'title': 'FEB DEALS',
        'subtitle': '60% OFF\n+20% CASHBACK',
        'color': const Color(0xFFE91E63),
        'icon': '🎉',
      },
      {
        'title': '99 STORE',
        'subtitle': 'MEALS AT\n₹99',
        'color': const Color(0xFF6A1B9A),
        'icon': '🍔',
      },
      {
        'title': 'FAST DELIVERY',
        'subtitle': 'Under\n30 mins',
        'color': const Color(0xFF00897B),
        'icon': '⚡',
      },
    ];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 155, // ✅ Fixed height — no overflow
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final o = offers[index];
            return _buildOfferCard(
              o['title'] as String,
              o['subtitle'] as String,
              o['color'] as Color,
              o['icon'] as String,
            );
          },
        ),
      ),
    );
  }

  // ✅ FIX 3: Spacer hataya, fixed Column layout
  Widget _buildOfferCard(
      String title, String subtitle, Color color, String icon) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // Content — no Spacer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 70, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Subtitle
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),

                  // Button
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'ORDER NOW',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Emoji — top right
            Positioned(
              right: 10,
              top: 14,
              child: Text(icon, style: const TextStyle(fontSize: 44)),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  //  CATEGORIES  ✅ FIX 1: Biryani image URL fixed
  // ================================================================
  Widget _buildCategoriesSection() {
    final categories = [
      {
        'name': 'Pizza',
        'image':
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=150&h=150&fit=crop',
      },
      {
        'name': 'Burgers',
        'image':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=150&h=150&fit=crop',
      },
      {
        'name': 'Biryani',
        // ✅ FIX 1: working biryani image URL
        'image':
            'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=150&h=150&fit=crop',
      },
      {
        'name': 'Chinese',
        'image':
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=150&h=150&fit=crop',
      },
      {
        'name': 'Desserts',
        'image':
            'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=150&h=150&fit=crop',
      },
      {
        'name': 'Beverages',
        'image':
            'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=150&h=150&fit=crop',
      },
      {
        'name': 'Rolls',
        'image':
            'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=150&h=150&fit=crop',
      },
      {
        'name': 'South Indian',
        'image':
            'https://images.unsplash.com/photo-1630383249896-424e482df921?w=150&h=150&fit=crop',
      },
    ];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 105,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return GestureDetector(
              onTap: () => _searchRestaurants(cat['name']!),
              child: Container(
                width: 72,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          cat['image']!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.white.withOpacity(0.3),
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withOpacity(0.25),
                              child: Center(
                                child: Text(
                                  cat['name']![0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['name']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // ================================================================
  //  WHITE BODY WRAPPER
  // ================================================================
  Widget _buildWhiteBody() {
    return SliverToBoxAdapter(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSectionTitle(),
            _buildRestaurantsList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            TextButton.icon(
              onPressed: _fetchRestaurants,
              icon: Icon(Icons.refresh, size: 16, color: AppTheme.primary),
              label: Text(
                'Refresh',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================================================================
  //  RESTAURANT LIST
  // ================================================================
  Widget _buildRestaurantsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_filteredRestaurants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu_outlined,
                size: 80, color: AppTheme.textLight),
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
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) =>
          _buildRestaurantCard(_filteredRestaurants[index]),
    );
  }

  // ================================================================
  //  RESTAURANT CARD  ✅ FIX 2: working favorite toggle
  // ================================================================
  Widget _buildRestaurantCard(Restaurant restaurant) {
    final isFav = _favoriteIds.contains(restaurant.id);
    final isToggling = _togglingFavorite[restaurant.id] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + overlays
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: restaurant.imageUrl != null &&
                          restaurant.imageUrl!.isNotEmpty
                      ? Image.network(
                          restaurant.imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _restaurantImagePlaceholder(),
                        )
                      : _restaurantImagePlaceholder(),
                ),

                // Closed overlay
                if (restaurant.isOpen == false)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                        child: const Center(
                          child: Text(
                            'CLOSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Discount badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
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

                // ✅ FIX 2: Favourite button — working toggle
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(restaurant.id),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: isToggling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                          : Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: isFav
                                  ? Colors.red
                                  : AppTheme.textPrimary,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            // Details
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
                        fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ratingBadge(restaurant.rating),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      restaurant.deliveryFee != null &&
                              restaurant.deliveryFee! > 0
                          ? '🛵 ₹${restaurant.deliveryFee!.toStringAsFixed(0)} delivery fee'
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

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _restaurantImagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      child: Icon(
        Icons.restaurant_rounded,
        size: 60,
        color: AppTheme.primary.withOpacity(0.3),
      ),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.rating,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
