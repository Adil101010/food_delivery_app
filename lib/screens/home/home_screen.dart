import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../config/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../services/api_service.dart';
import '../../services/favorite_service.dart';
import '../../providers/notification_provider.dart';
import '../restaurant/restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _apiService = ApiService();
  final _favoriteService = FavoriteService();
  
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  Set<int> _favoriteRestaurantIds = {};
  bool _isLoading = true;
  String _userEmail = '';
  String _userName = '';
  final _searchController = TextEditingController();
  
  late PageController _carouselController;
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;

  String _selectedCategory = 'All';
  bool _isVegOnly = false;
  String? _selectedCuisine;
  double? _minRating;
  String _sortBy = 'rating';
  String _priceFilter = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': '🍲', 'image': null},
    {'name': 'Pizza', 'icon': '🍕', 'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200&h=200&fit=crop'},
    {'name': 'Burger', 'icon': '🍔', 'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&h=200&fit=crop'},
    {'name': 'Biryani', 'icon': '🍛', 'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=200&h=200&fit=crop'},
    {'name': 'Chinese', 'icon': '🥡', 'image': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=200&h=200&fit=crop'},
    {'name': 'Indian', 'icon': '🥘', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=200&h=200&fit=crop'},
    {'name': 'Desserts', 'icon': '🍰', 'image': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=200&h=200&fit=crop'},
    {'name': 'Beverages', 'icon': '🥤', 'image': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=200&h=200&fit=crop'},
  ];

  final List<String> _cuisineTypes = [
    'All', 'Italian', 'Chinese', 'Indian', 'Mexican', 'Fast Food', 'Desserts', 'Beverages',
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(viewportFraction: 0.92);
    _startCarouselAutoPlay();
    _loadUserData();
    _fetchRestaurants();
    _loadFavorites();
    Future.microtask(() {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  void _startCarouselAutoPlay() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentCarouselPage < 2) {
        _currentCarouselPage++;
      } else {
        _currentCarouselPage = 0;
      }
      
      if (_carouselController.hasClients) {
        _carouselController.animateToPage(
          _currentCarouselPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
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
      final favoriteIds = await _favoriteService.getUserFavoriteRestaurantIds();
      setState(() {
        _favoriteRestaurantIds = favoriteIds.toSet();
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(int restaurantId) async {
    try {
      final isFavorite = await _favoriteService.toggleFavorite(restaurantId);
      
      setState(() {
        if (isFavorite) {
          _favoriteRestaurantIds.add(restaurantId);
        } else {
          _favoriteRestaurantIds.remove(restaurantId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(isFavorite 
                    ? 'Added to favorites ❤️' 
                    : 'Removed from favorites'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: isFavorite ? Colors.red : AppTheme.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  Future<void> _fetchRestaurants() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getAllRestaurants();
      final restaurants = data.map((json) => Restaurant.fromJson(json)).toList();

      setState(() {
        _restaurants = restaurants;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to load restaurants: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final matchesSearch = restaurant.name.toLowerCase().contains(searchQuery) ||
              restaurant.cuisine.toLowerCase().contains(searchQuery);
          if (!matchesSearch) return false;
        }

        if (_selectedCategory != 'All') {
          if (!restaurant.cuisine.toLowerCase().contains(_selectedCategory.toLowerCase())) {
            return false;
          }
        }

        if (_selectedCuisine != null && _selectedCuisine != 'All') {
          if (!restaurant.cuisine.toLowerCase().contains(_selectedCuisine!.toLowerCase())) {
            return false;
          }
        }

        if (_minRating != null) {
          if (restaurant.rating < _minRating!) {
            return false;
          }
        }

        return true;
      }).toList();

      switch (_sortBy) {
        case 'rating':
          _filteredRestaurants.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'deliveryTime':
          _filteredRestaurants.sort((a, b) => 
              (a.avgDeliveryTime ?? 30).compareTo(b.avgDeliveryTime ?? 30));
          break;
        case 'name':
          _filteredRestaurants.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _isVegOnly = false;
      _selectedCuisine = null;
      _minRating = null;
      _sortBy = 'rating';
      _priceFilter = 'All';
      _searchController.clear();
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchRestaurants();
          await _loadFavorites();
          await context.read<NotificationProvider>().refresh();
        },
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(),
            _buildSearchBar(),
            _buildQuickFilters(),
            _buildOffersCarousel(),
            _buildCategoriesGrid(),
            _buildActiveFiltersChips(),
            _buildSectionTitle(),
            _buildRestaurantsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary,
                AppTheme.primary.withOpacity(0.85),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'Sector 63, Noida',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down, 
                                  color: Colors.white, size: 20),
                              ],
                            ),
                            Text(
                              'Hi $_userName 👋',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                              onPressed: () => Navigator.pushNamed(context, '/notifications'),
                            ),
                          ),
                          Consumer<NotificationProvider>(
                            builder: (context, provider, child) {
                              if (provider.unreadCount > 0) {
                                return Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '${provider.unreadCount > 9 ? '9+' : provider.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 4),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/cart'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {});
            _applyFilters();
          },
          decoration: InputDecoration(
            hintText: 'Search restaurants, cuisines...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: AppTheme.primary, size: 22),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _applyFilters();
                    },
                  ),
                Icon(Icons.mic, color: AppTheme.primary, size: 22),
                const SizedBox(width: 12),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SliverToBoxAdapter(
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
              icon: Icons.tune,
              label: 'Filters',
              isSelected: false,
              onTap: _showFilterBottomSheet,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              icon: _isVegOnly ? Icons.check_circle : Icons.eco_outlined,
              label: 'Pure Veg',
              isSelected: _isVegOnly,
              onTap: () {
                setState(() => _isVegOnly = !_isVegOnly);
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              icon: Icons.electric_bolt,
              label: 'Fast Delivery',
              isSelected: _sortBy == 'deliveryTime',
              onTap: () {
                setState(() => _sortBy = _sortBy == 'deliveryTime' ? 'rating' : 'deliveryTime');
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              icon: Icons.local_offer,
              label: 'Offers',
              isSelected: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Showing restaurants with offers'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              icon: Icons.star,
              label: '4.0+',
              isSelected: _minRating == 4.0,
              onTap: () {
                setState(() {
                  _minRating = _minRating == 4.0 ? null : 4.0;
                });
                _applyFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersCarousel() {
    final offers = [
      {
        'title': 'FLAT 60% OFF',
        'subtitle': 'On your first 3 orders',
        'color': const Color(0xFFFF6B6B),
        'gradient': [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)],
        'icon': '🎉',
      },
      {
        'title': 'FREE DELIVERY',
        'subtitle': 'On orders above ₹199',
        'color': const Color(0xFF4CAF50),
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF45A049)],
        'icon': '🚀',
      },
      {
        'title': '₹99 MEALS',
        'subtitle': 'Super saver combos',
        'color': const Color(0xFFFF9800),
        'gradient': [const Color(0xFFFF9800), const Color(0xFFFB8C00)],
        'icon': '🍔',
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 170,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: PageView.builder(
          controller: _carouselController,
          onPageChanged: (index) {
            setState(() => _currentCarouselPage = index);
          },
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: offer['gradient'] as List<Color>,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (offer['color'] as Color).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offer['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          offer['subtitle'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            'Order Now',
                            style: TextStyle(
                              color: offer['color'] as Color,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Text(
                      offer['icon'] as String,
                      style: const TextStyle(fontSize: 70),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return SliverToBoxAdapter(
      child: Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['name'];
            
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category['name'] as String);
                _applyFilters();
              },
              child: Container(
                width: 85,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppTheme.primary.withOpacity(0.2),
                                AppTheme.primary.withOpacity(0.1),
                              ],
                            )
                          : null,
                        color: isSelected ? null : Colors.white,
                        border: Border.all(
                          color: isSelected 
                            ? AppTheme.primary 
                            : Colors.grey.shade300,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                              ? AppTheme.primary.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.15),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: category['image'] != null
                          ? Image.network(
                              category['image'] as String,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primary,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: Text(
                                      category['icon'] as String,
                                      style: const TextStyle(fontSize: 36),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade50,
                              child: Center(
                                child: Text(
                                  category['icon'] as String,
                                  style: const TextStyle(fontSize: 38),
                                ),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
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

  Widget _buildActiveFiltersChips() {
    final hasActiveFilters = _selectedCategory != 'All' || 
                            _isVegOnly ||
                            _selectedCuisine != null || 
                            _minRating != null || 
                            _sortBy != 'rating' ||
                            _priceFilter != 'All';

    if (!hasActiveFilters) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedCategory != 'All')
                      _buildActiveFilterChip(
                        _selectedCategory,
                        () => setState(() {
                          _selectedCategory = 'All';
                          _applyFilters();
                        }),
                      ),
                    if (_isVegOnly)
                      _buildActiveFilterChip(
                        'Pure Veg',
                        () => setState(() {
                          _isVegOnly = false;
                          _applyFilters();
                        }),
                      ),
                    if (_minRating != null)
                      _buildActiveFilterChip(
                        '${_minRating}+ ⭐',
                        () => setState(() {
                          _minRating = null;
                          _applyFilters();
                        }),
                      ),
                    if (_sortBy == 'deliveryTime')
                      _buildActiveFilterChip(
                        'Fast Delivery',
                        () => setState(() {
                          _sortBy = 'rating';
                          _applyFilters();
                        }),
                      ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters & Sort',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                const Text(
                  'Cuisine Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cuisineTypes.map((cuisine) {
                    final isSelected = _selectedCuisine == cuisine;
                    return ChoiceChip(
                      label: Text(cuisine),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          _selectedCuisine = selected ? cuisine : null;
                        });
                      },
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Minimum Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [3.0, 3.5, 4.0, 4.5].map((rating) {
                    final isSelected = _minRating == rating;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(rating.toString()),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, size: 16),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _minRating = selected ? rating : null;
                          });
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSortOption(
                        'Rating',
                        'rating',
                        Icons.star,
                        setModalState,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSortOption(
                        'Time',
                        'deliveryTime',
                        Icons.electric_bolt,
                        setModalState,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSortOption(
                        'Name',
                        'name',
                        Icons.sort_by_alpha,
                        setModalState,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Apply Filters (${_filteredRestaurants.length} restaurants)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    String label,
    String value,
    IconData icon,
    StateSetter setModalState,
  ) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setModalState(() {
          _sortBy = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primary.withOpacity(0.1) 
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '${_filteredRestaurants.length} RESTAURANTS',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 0.8,
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
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading delicious food...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredRestaurants.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 100,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No restaurants found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear All Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final restaurant = _filteredRestaurants[index];
            return _buildRestaurantCard(restaurant, index);
          },
          childCount: _filteredRestaurants.length,
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, int index) {
    final isFavorite = _favoriteRestaurantIds.contains(restaurant.id);
    
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 100 * (index + 1)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
              ),
            );
            
            if (result == true) {
              await _loadFavorites();
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Restaurant Image with Network Loading
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty
                      ? Image.network(
                          restaurant.imageUrl!,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 190,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppTheme.primary,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                  ),
                  
                  // Gradient Overlay
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Discount Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        '50% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  
                  // Favorite Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(restaurant.id),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: isFavorite ? Colors.red : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Open/Closed Status
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: restaurant.isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            restaurant.isOpen ? Icons.circle : Icons.schedule,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.isOpen ? 'Open Now' : 'Closed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Restaurant Info
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: restaurant.rating >= 4.0 
                              ? Colors.green 
                              : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.star, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      restaurant.cuisine,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          restaurant.avgDeliveryTime != null
                              ? '${restaurant.avgDeliveryTime} mins'
                              : '30 mins',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.currency_rupee, size: 16, color: Colors.grey.shade600),
                        Text(
                          '₹250 for two',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, size: 14, color: Color(0xFFFF6F00)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              restaurant.deliveryFee != null && restaurant.deliveryFee! > 0
                                  ? '₹${restaurant.deliveryFee!.toStringAsFixed(0)} delivery fee • Free above ₹199'
                                  : '🎉 FREE delivery on this order',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF6F00),
                                fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        size: 70,
        color: AppTheme.primary.withOpacity(0.2),
      ),
    );
  }
}
