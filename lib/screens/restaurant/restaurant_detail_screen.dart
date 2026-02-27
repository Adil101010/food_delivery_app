import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../reviews/restaurant_reviews_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({
    Key? key,
    required this.restaurant,
  }) : super(key: key);

  @override
  State<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends State<RestaurantDetailScreen> {
  final _apiService = ApiService();
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'ALL';
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await _apiService.getMenuItems(widget.restaurant.id);
      final items =
          data.map((json) => MenuItem.fromJson(json)).toList();
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load menu: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  List<MenuItem> get _filteredMenuItems {
    if (_selectedCategory == 'ALL') return _menuItems;
    return _menuItems
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  List<String> get _categories {
    final categories =
        _menuItems.map((item) => item.category).toSet().toList();
    categories.sort();
    categories.insert(0, 'ALL');
    return categories;
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildRestaurantInfo(),
              _buildReviewsSection(),
              _buildOffersSection(),
              _buildDivider(),
              _buildCategoryFilter(),
              _isLoading
                  ? _buildShimmerMenuList()
                  : _buildMenuItems(),
            ],
          ),
          _buildFloatingCartButton(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  APP BAR — Restaurant banner image
  // ═══════════════════════════════════════════
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8)
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        _appBarActionButton(
          icon: _isFavorite
              ? Icons.favorite
              : Icons.favorite_border,
          color: _isFavorite ? Colors.red : AppTheme.textPrimary,
          onTap: () {
            setState(() => _isFavorite = !_isFavorite);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_isFavorite
                  ? 'Added to favorites'
                  : 'Removed from favorites'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ));
          },
        ),
        _appBarActionButton(
          icon: Icons.share_outlined,
          color: AppTheme.textPrimary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share feature coming soon'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ Real restaurant image
            widget.restaurant.imageUrl != null &&
                    widget.restaurant.imageUrl!.isNotEmpty
                ? Image.network(
                    widget.restaurant.imageUrl!,
                    fit: BoxFit.cover,
                    // ✅ Fade-in animation — instant feel
                    frameBuilder: (context, child, frame,
                        wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration:
                            const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    errorBuilder: (_, __, ___) =>
                        _bannerPlaceholder(),
                  )
                : _bannerPlaceholder(),

            // ✅ Gradient overlay — text readable
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.white,
                  ],
                  stops: const [0.4, 0.75, 1.0],
                ),
              ),
            ),

            // Open/Closed badge
            if (widget.restaurant.isOpen == false)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Text(
                    'CLOSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _appBarActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8)
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      color: AppTheme.primary.withOpacity(0.08),
      child: Center(
        child: Icon(Icons.restaurant_rounded,
            size: 100,
            color: AppTheme.primary.withOpacity(0.25)),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  RESTAURANT INFO
  // ═══════════════════════════════════════════
  Widget _buildRestaurantInfo() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurant.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.restaurant.cuisine,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.star,
                  label: widget.restaurant.rating
                      .toStringAsFixed(1),
                  bgColor: AppTheme.rating,
                  textColor: Colors.white,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.access_time_outlined,
                  label: widget.restaurant.avgDeliveryTime !=
                          null
                      ? '${widget.restaurant.avgDeliveryTime} mins'
                      : '30 mins',
                  bgColor: const Color(0xFFF5F5F5),
                  textColor: AppTheme.textPrimary,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.currency_rupee,
                  label: widget.restaurant.deliveryFee != null
                      ? '${widget.restaurant.deliveryFee!.toStringAsFixed(0)} delivery'
                      : 'Free',
                  bgColor: const Color(0xFFF5F5F5),
                  textColor: AppTheme.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.restaurant.address,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('VIEW MAP',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  REVIEWS SECTION
  // ═══════════════════════════════════════════
  Widget _buildReviewsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantReviewsScreen(
                restaurantId: widget.restaurant.id,
                restaurantName: widget.restaurant.name,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star,
                      color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('Reviews & Ratings',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.restaurant.rating
                                .toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                          ),
                          Text(' • See all reviews',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  OFFERS SECTION
  // ═══════════════════════════════════════════
  Widget _buildOffersSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.orange.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🎉',
                  style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Free Delivery',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text('On orders above ₹199',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return SliverToBoxAdapter(
      child: Container(height: 8, color: const Color(0xFFF5F5F5)),
    );
  }

  // ═══════════════════════════════════════════
  //  CATEGORY FILTER
  // ═══════════════════════════════════════════
  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Menu (${_filteredMenuItems.length} items)',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected =
                      category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(
                          () => _selectedCategory = category),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFFF5F5F5),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  SHIMMER LOADER — menu items ke liye
  // ═══════════════════════════════════════════
  Widget _buildShimmerMenuList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerCard(),
          childCount: 5, // 5 placeholder cards
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image shimmer
          _shimmerBox(width: 110, height: 110, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: double.infinity, height: 16, radius: 6),
                const SizedBox(height: 8),
                _shimmerBox(width: 80, height: 20, radius: 6),
                const SizedBox(height: 8),
                _shimmerBox(width: double.infinity, height: 12, radius: 6),
                const SizedBox(height: 4),
                _shimmerBox(width: 180, height: 12, radius: 6),
                const SizedBox(height: 14),
                _shimmerBox(width: 80, height: 36, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
      onEnd: () => setState(() {}), // ✅ loop effect
    );
  }

  // ═══════════════════════════════════════════
  //  MENU ITEMS LIST
  // ═══════════════════════════════════════════
  Widget _buildMenuItems() {
    if (_filteredMenuItems.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://images.unsplash.com/photo-1514190051997-0f6f39ca5cde?w=200&h=200&fit=crop',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.restaurant_menu_outlined,
                    size: 80,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('No menu items found',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Try selecting a different category',
                  style: TextStyle(color: AppTheme.textLight)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _buildMenuItemCard(_filteredMenuItems[index]),
          childCount: _filteredMenuItems.length,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  MENU ITEM CARD — optimized image loading
  // ═══════════════════════════════════════════
  Widget _buildMenuItemCard(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Food Image ──
            Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            width: 110,
                            height: 110,
                            // ✅ Smooth fade-in — image ready hone pe
                            frameBuilder: (context, child,
                                frame,
                                wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded)
                                return child;
                              return AnimatedSwitcher(
                                duration: const Duration(
                                    milliseconds: 300),
                                child: frame != null
                                    ? child
                                    : _menuImageShimmer(),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                Center(
                              child: Icon(
                                Icons.fastfood_outlined,
                                size: 45,
                                color: AppTheme.textLight,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.fastfood_outlined,
                              size: 45,
                              color: AppTheme.textLight,
                            ),
                          ),
                  ),
                ),
                // Veg/Non-veg badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                            color:
                                Colors.black.withOpacity(0.1),
                            blurRadius: 4)
                      ],
                    ),
                    child: Icon(
                      Icons.circle,
                      size: 12,
                      color: item.isVegetarian
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // ── Item Details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description!,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildAddButton(item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Shimmer placeholder jab tak image load ho
  Widget _menuImageShimmer() {
    return Container(
      width: 110,
      height: 110,
      color: const Color(0xFFE8E8E8),
      child: Center(
        child: Icon(Icons.image_outlined,
            color: Colors.grey.shade400, size: 32),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  ADD/QUANTITY BUTTON
  // ═══════════════════════════════════════════
  Widget _buildAddButton(MenuItem item) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getItemQuantity(item.id);

        if (!item.isAvailable) {
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text('Not Available',
                style: TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          );
        }

        if (quantity == 0) {
          return InkWell(
            onTap: () async {
              final success = await cartProvider.addItem(
                menuItemId: item.id,
                itemName: item.name,
                price: item.price,
                quantity: 1,
                restaurantId: widget.restaurant.id,
                restaurantName: widget.restaurant.name,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('${item.name} added to cart'),
                      ],
                    ),
                    duration:
                        const Duration(milliseconds: 1000),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8)),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primary, width: 2),
              ),
              child: const Text('ADD',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () =>
                      cartProvider.decreaseQuantity(item.id),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.remove,
                        color: Colors.white, size: 18),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$quantity',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
                InkWell(
                  onTap: () =>
                      cartProvider.increaseQuantity(item.id),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // ═══════════════════════════════════════════
  //  FLOATING CART BUTTON
  // ═══════════════════════════════════════════
  Widget _buildFloatingCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (!cartProvider.hasCart) return const SizedBox.shrink();

        return Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withOpacity(0.85)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CartScreen()),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_cart,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Text('${cartProvider.totalItems}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text('View Cart',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        '₹${cartProvider.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
