import 'dart:async';
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
  final _searchFocusNode = FocusNode();

  Set<int> _favoriteIds = {};
  final Map<int, bool> _togglingFavorite = {};

  final ScrollController _offersScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  Timer? _offersTimer;
  Timer? _categoryTimer;
  double _offersOffset = 0;
  double _categoryOffset = 0;

  static const double _offerItemWidth = 252.0;
  static const int _offerCount = 5;
  static const double _catItemWidth = 84.0;
  static const int _catCount = 15;

  String _activeFilter = 'All';
  final List<String> _filterChips = [
    'All', 'Sort By', 'Rating 4+', 'Pure Veg', 'Under ₹99', 'Fast Delivery',
  ];

  final List<Map<String, dynamic>> _offers = [
    {'title': 'FEB DEALS',     'subtitle': '60% OFF\n+20% CASHBACK', 'color': const Color(0xFFE91E63), 'icon': '🎉'},
    {'title': '99 STORE',      'subtitle': 'MEALS AT\n₹99',          'color': const Color(0xFF6A1B9A), 'icon': '🍔'},
    {'title': 'FAST DELIVERY', 'subtitle': 'Under\n30 mins',         'color': const Color(0xFF00897B), 'icon': '⚡'},
    {'title': 'NEW USER',      'subtitle': 'First Order\nFREE',      'color': const Color(0xFF1565C0), 'icon': '🎁'},
    {'title': 'WEEKEND',       'subtitle': 'Flat ₹50\nOFF',          'color': const Color(0xFFE65100), 'icon': '🔥'},
  ];

  final List<Map<String, String>> _categories = [
    {'name': 'Pizza',        'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=150&h=150&fit=crop'},
    {'name': 'Burgers',      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=150&h=150&fit=crop'},
    {'name': 'Biryani',      'image': 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=150&h=150&fit=crop'},
    {'name': 'Chinese',      'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=150&h=150&fit=crop'},
    {'name': 'Desserts',     'image': 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=150&h=150&fit=crop'},
    {'name': 'Beverages',    'image': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=150&h=150&fit=crop'},
    {'name': 'Rolls',        'image': 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=150&h=150&fit=crop'},
    {'name': 'South Indian', 'image': 'https://images.unsplash.com/photo-1630383249896-424e482df921?w=150&h=150&fit=crop'},
    {'name': 'Momos',        'image': 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=150&h=150&fit=crop'},
    {'name': 'Pasta',        'image': 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=150&h=150&fit=crop'},
    {'name': 'Sandwich',     'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=150&h=150&fit=crop'},
    {'name': 'Noodles',      'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=150&h=150&fit=crop'},
    {'name': 'Thali',        'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=150&h=150&fit=crop'},
    {'name': 'Ice Cream',    'image': 'https://images.unsplash.com/photo-1488900128323-21503983a07e?w=150&h=150&fit=crop'},
    {'name': 'Salads',       'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=150&h=150&fit=crop'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchRestaurants();
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOffersAutoScroll();
      _startCategoryAutoScroll();
    });
  }

  void _startOffersAutoScroll() {
    const double oneSetWidth = _offerCount * _offerItemWidth;
    _offersTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!mounted || !_offersScrollController.hasClients) return;
      _offersOffset += 0.5;
      if (_offersOffset >= oneSetWidth) _offersOffset = 0;
      _offersScrollController.jumpTo(_offersOffset);
    });
  }

  void _startCategoryAutoScroll() {
    const double oneSetWidth = _catCount * _catItemWidth;
    _categoryTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!mounted || !_categoryScrollController.hasClients) return;
      _categoryOffset += 0.5;
      if (_categoryOffset >= oneSetWidth) _categoryOffset = 0;
      _categoryScrollController.jumpTo(_categoryOffset);
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email') ?? 'User';
      _userName = prefs.getString('name') ?? _userEmail.split('@')[0];
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final ids = await _favoriteService.getUserFavoriteRestaurantIds();
      if (mounted) setState(() => _favoriteIds = ids.toSet());
    } catch (_) {}
  }

  Future<void> _toggleFavorite(int restaurantId) async {
    if (_togglingFavorite[restaurantId] == true) return;
    setState(() => _togglingFavorite[restaurantId] = true);
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
      final restaurants = data.map((json) => Restaurant.fromJson(json)).toList();
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load restaurants: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
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

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      switch (filter) {
        case 'Rating 4+':
          _filteredRestaurants =
              _restaurants.where((r) => r.rating >= 4.0).toList();
          break;
        case 'Pure Veg':
          _filteredRestaurants = _restaurants
              .where((r) => r.cuisine.toLowerCase().contains('veg'))
              .toList();
          break;
        case 'Fast Delivery':
          _filteredRestaurants = _restaurants
              .where((r) =>
                  r.avgDeliveryTime != null && r.avgDeliveryTime! <= 30)
              .toList();
          break;
        case 'Under ₹99':
          _filteredRestaurants = _restaurants
              .where((r) => r.deliveryFee == null || r.deliveryFee! == 0)
              .toList();
          break;
        default:
          _filteredRestaurants = List.from(_restaurants);
      }
    });
  }

  @override
  void dispose() {
    _offersTimer?.cancel();
    _categoryTimer?.cancel();
    _offersScrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ════════════════════════════
  //  BUILD
  // ════════════════════════════
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

  // ════════════════════════════
  //  HEADER
  // ════════════════════════════
  Widget _buildOrangeHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/address'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('Home',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 18),
                          ],
                        ),
                        Text('Hi $_userName',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
            ),
            const SizedBox(width: 8),
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
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════
  //  SEARCH BAR
  // ════════════════════════════
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
                offset: const Offset(0, 2)),
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
                  hintText: 'Search for restaurants or cuisines',
                  hintStyle:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
                child:
                    Icon(Icons.clear, color: AppTheme.textSecondary, size: 20),
              )
            else
              GestureDetector(
                onTap: () =>
                    FocusScope.of(context).requestFocus(_searchFocusNode),
                child: Icon(Icons.mic_outlined,
                    color: AppTheme.primary, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════
  //  OFFERS — slow scroll
  // ════════════════════════════
  Widget _buildOffersSection() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 155,
        child: ListView.builder(
          controller: _offersScrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
          itemCount: _offers.length * 2,
          itemBuilder: (context, index) {
            final o = _offers[index % _offers.length];
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
              offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -20, bottom: -20,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 70, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.3)),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: color,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('ORDER NOW',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10, top: 14,
              child: Text(icon, style: const TextStyle(fontSize: 44)),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════
  //  CATEGORIES — fast scroll
  // ════════════════════════════
  Widget _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text("What's on your mind?",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
              itemCount: _categories.length * 2,
              itemBuilder: (context, index) {
                final cat = _categories[index % _categories.length];
                return GestureDetector(
                  onTap: () => _searchRestaurants(cat['name']!),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              cat['image']!,
                              width: 64, height: 64,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.white.withOpacity(0.3),
                                  child: const Center(
                                    child: SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2)),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.25),
                                child: Center(
                                  child: Text(cat['name']![0],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(cat['name']!,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ════════════════════════════
  //  WHITE BODY
  // ════════════════════════════
  Widget _buildWhiteBody() {
    return SliverToBoxAdapter(
      child: Container(
        constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildFilterChips(),
            _buildSectionTitle(),
            _buildRestaurantsList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════
  //  FILTER CHIPS
  // ════════════════════════════
  Widget _buildFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterChips.length,
        itemBuilder: (context, index) {
          final chip = _filterChips[index];
          final isActive = _activeFilter == chip;
          final isSort = chip == 'Sort By';

          return GestureDetector(
            onTap: () => _applyFilter(chip),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppTheme.primary : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chip,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : Colors.black87)),
                  if (isSort) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: isActive ? Colors.white : Colors.black54),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════
  //  SECTION TITLE
  // ════════════════════════════
  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        '${_filteredRestaurants.length} restaurants',
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54),
      ),
    );
  }

  // ════════════════════════════════════
  //  RESPONSIVE LIST — Mobile 1 col
  //  Tablet 2-3 col | Desktop 4 col
  // ════════════════════════════════════
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
            Text('No restaurants found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text('Try searching with different keywords',
                style: TextStyle(color: AppTheme.textLight)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // ✅ Mobile = 1 col full-width list
        if (w < 600) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            itemCount: _filteredRestaurants.length,
            itemBuilder: (context, index) =>
                _buildMobileCard(_filteredRestaurants[index]),
          );
        }

        // ✅ Tablet / Desktop = grid
        int cols = w >= 1200 ? 4 : w >= 900 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 20,
            childAspectRatio: 0.70,
          ),
          itemCount: _filteredRestaurants.length,
          itemBuilder: (context, index) =>
              _buildGridCard(_filteredRestaurants[index]),
        );
      },
    );
  }

  // ════════════════════════════
  //  MOBILE CARD — 1 col, full width
  // ════════════════════════════
  Widget _buildMobileCard(Restaurant restaurant) {
    final isFav = _favoriteIds.contains(restaurant.id);
    final isToggling = _togglingFavorite[restaurant.id] == true;
    final isOpen = restaurant.isOpen != false;
    final discountText =
        (restaurant.deliveryFee == null || restaurant.deliveryFee! == 0)
            ? '60% OFF UPTO ₹120'
            : '50% OFF UPTO ₹100';

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  RestaurantDetailScreen(restaurant: restaurant))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColorFiltered(
                    colorFilter: isOpen
                        ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply)
                        : ColorFilter.mode(
                            Colors.black.withOpacity(0.45), BlendMode.darken),
                    child: restaurant.imageUrl != null &&
                            restaurant.imageUrl!.isNotEmpty
                        ? Image.network(
                            restaurant.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(200),
                          )
                        : _placeholder(200),
                  ),
                ),
                // Bottom gradient
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                // Discount
                Positioned(
                  bottom: 10, left: 12,
                  child: Text(discountText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ])),
                ),
                // Closed
                if (!isOpen)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('CLOSED',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3)),
                        ),
                      ),
                    ),
                  ),
                // Fav
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(restaurant.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: isToggling
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: isFav ? Colors.red : Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Name
            Text(restaurant.name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),

            const SizedBox(height: 4),

            // Rating row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Color(0xFF1A9B4B), shape: BoxShape.circle),
                  child: const Icon(Icons.star, color: Colors.white, size: 10),
                ),
                const SizedBox(width: 4),
                Text(restaurant.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(width: 4),
                Text('•',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  restaurant.avgDeliveryTime != null
                      ? '${restaurant.avgDeliveryTime}-${restaurant.avgDeliveryTime! + 5} mins'
                      : '30-35 mins',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 3),

            Text(restaurant.cuisine,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),

            const SizedBox(height: 2),

            Text('Greater Noida',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),

            const SizedBox(height: 12),

            Divider(
                color: Colors.grey.shade200, height: 1, thickness: 1),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════
  //  GRID CARD — Tablet / Desktop
  // ════════════════════════════
  Widget _buildGridCard(Restaurant restaurant) {
    final isFav = _favoriteIds.contains(restaurant.id);
    final isToggling = _togglingFavorite[restaurant.id] == true;
    final isOpen = restaurant.isOpen != false;
    final discountText =
        (restaurant.deliveryFee == null || restaurant.deliveryFee! == 0)
            ? '60% OFF UPTO ₹120'
            : '50% OFF UPTO ₹100';

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  RestaurantDetailScreen(restaurant: restaurant))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColorFiltered(
                    colorFilter: isOpen
                        ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply)
                        : ColorFilter.mode(
                            Colors.black.withOpacity(0.45), BlendMode.darken),
                    child: restaurant.imageUrl != null &&
                            restaurant.imageUrl!.isNotEmpty
                        ? Image.network(
                            restaurant.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(double.infinity),
                          )
                        : _placeholder(double.infinity),
                  ),
                ),
                // Gradient
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    child: Container(
                      height: 65,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                // Discount
                Positioned(
                  bottom: 8, left: 10,
                  child: Text(discountText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                // Closed
                if (!isOpen)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('CLOSED',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2)),
                        ),
                      ),
                    ),
                  ),
                // Fav
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(restaurant.id),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle),
                      child: isToggling
                          ? const SizedBox(
                              width: 13, height: 13,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 13,
                              color: isFav ? Colors.red : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Text(restaurant.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),

          const SizedBox(height: 3),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: Color(0xFF1A9B4B), shape: BoxShape.circle),
                child: const Icon(Icons.star, color: Colors.white, size: 9),
              ),
              const SizedBox(width: 3),
              Text(restaurant.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(width: 3),
              Text('•',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  restaurant.avgDeliveryTime != null
                      ? '${restaurant.avgDeliveryTime}-${restaurant.avgDeliveryTime! + 5} mins'
                      : '30-35 mins',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          Text(restaurant.cuisine,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),

          const SizedBox(height: 2),

          Text('Greater Noida',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ════════════════════════════
  //  SHARED PLACEHOLDER
  // ════════════════════════════
  Widget _placeholder(double height) {
    return Container(
      height: height == double.infinity ? null : height,
      width: double.infinity,
      color: const Color(0xFFF0F0F0),
      child: Icon(Icons.restaurant_rounded,
          size: 50, color: AppTheme.primary.withOpacity(0.3)),
    );
  }
}
