// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yourhome/models/property_model.dart';
import 'package:yourhome/providers/theme_provider.dart';
import '../providers/property_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'property_detail_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart';

/// ==================================================================
/// DESIGN TOKENS
/// ==================================================================
class _Palette {
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF3B82F6);
  static const primarySoft = Color(0xFF60A5FA);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF0C550);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);

  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const darkSurfaceElevated = Color(0xFF1B2338);
  static const lightBg = Color(0xFFF7F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
}

/// Grid sizing constants.
/// - [visibleColumns]: how many columns fit exactly on screen without any
///   horizontal scroll (card width is computed dynamically from this).
/// - [totalColumns]: how many columns exist in the full matrix. Columns
///   beyond [visibleColumns] are reached by scrolling left/right.
///   e.g. visibleColumns = 2, totalColumns = 4 -> user sees 2 cards per
///   row on screen, and can scroll horizontally to reveal 2 more.
class _GridSpec {
  static const int visibleColumns = 2;
  static const int totalColumns = 4;
  static const double cardImageHeight = 130;
  static const double spacing = 14;
  static const double horizontalPadding = 20;
}

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Horizontal + vertical controllers for the two-directional grid.
  final ScrollController _gridHorizontalController = ScrollController();
  final ScrollController _gridVerticalController = ScrollController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  // ---- Price range defaults to ₹1,000 – ₹10,000 ----
  static const double _priceFloor = 1000;
  static const double _priceCeil = 10000;
  double _minPrice = _priceFloor;
  double _maxPrice = _priceCeil;

  bool _showFilters = false;
  bool _isFirstLoad = true;
  bool _isSearchFocused = false;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _filterPanelController;

  final Set<int> _favoriteIds = {};

  final List<Map<String, dynamic>> _filterOptions = const [
    {'label': 'All', 'icon': Icons.apps_rounded},
    {'label': 'PG', 'icon': Icons.other_houses_rounded},
    {'label': 'Hostel', 'icon': Icons.holiday_village_rounded},
    {'label': 'Hotel', 'icon': Icons.hotel_rounded},
    {'label': 'Flat', 'icon': Icons.apartment_rounded},
    {'label': 'Villa', 'icon': Icons.villa_rounded},
    {'label': 'Resort', 'icon': Icons.beach_access_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProperties();

    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  void _setupAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _filterPanelController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    _entranceController.forward();
  }

  void _loadProperties() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        final propertyProvider = Provider.of<PropertyProvider>(
          context,
          listen: false,
        );
        if (propertyProvider.properties.isEmpty &&
            propertyProvider.error == null) {
          propertyProvider.searchProperties();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _gridHorizontalController.dispose();
    _gridVerticalController.dispose();
    _entranceController.dispose();
    _filterPanelController.dispose();
    super.dispose();
  }

  void _toggleFavorite(int propertyId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_favoriteIds.contains(propertyId)) {
        _favoriteIds.remove(propertyId);
      } else {
        _favoriteIds.add(propertyId);
      }
    });
  }

  void _toggleFilterPanel() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterPanelController.forward();
    } else {
      _filterPanelController.reverse();
    }
  }

  // ✅ Opens the real Profile screen (push, with a smooth fade + scale
  // transition) instead of switching bottom-nav tabs.
  void _navigateToProfile() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Properties without a price are still shown (treated as "contact for
  // price") — only the numeric price filter applies when a price exists.
  List<Property> _getFilteredProperties(
    List<Property> properties,
    String query,
    String filter,
    double minPrice,
    double maxPrice,
  ) {
    return properties.where((property) {
      final matchesSearch = query.isEmpty ||
          property.title.toLowerCase().contains(query.toLowerCase()) ||
          property.city.toLowerCase().contains(query.toLowerCase()) ||
          property.propertyType.toLowerCase().contains(query.toLowerCase());

      final matchesFilter = filter == 'All' ||
          property.propertyType.toUpperCase() == filter.toUpperCase();

      final matchesPrice = property.monthlyRentMin == null ||
          (property.monthlyRentMin! >= minPrice &&
              property.monthlyRentMin! <= maxPrice);

      return matchesSearch && matchesFilter && matchesPrice;
    }).toList();
  }

  List<Property> _getSortedProperties(List<Property> properties) {
    final premium = properties.where((p) => p.isFeatured).toList();
    final normal = properties.where((p) => !p.isFeatured).toList();

    premium.sort(
        (a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
    normal.sort(
        (a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));

    return [...premium, ...normal];
  }

  void _navigateToPropertyDetail(int propertyId) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PropertyDetailScreen(propertyId: propertyId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // ✅ Real profile picture (same source as Home screen's avatar)
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profileImage = profileProvider.profile?.profilePic;

    final filtered = _getFilteredProperties(
      propertyProvider.properties,
      _searchQuery,
      _selectedFilter,
      _minPrice,
      _maxPrice,
    );
    final sortedProperties = _getSortedProperties(filtered);

    final premiumProperties =
        sortedProperties.where((p) => p.isFeatured).toList();
    final normalProperties =
        sortedProperties.where((p) => !p.isFeatured).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? _Palette.darkBg : _Palette.lightBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildPremiumAppBar(
                  context, isDark, user, profileImage, propertyProvider),
              _buildSmartSearchBar(context, isDark),
              _buildFilterChips(context, isDark),
              Expanded(
                child: propertyProvider.isLoading
                    ? _buildLoadingState(isDark)
                    : propertyProvider.error != null
                        ? _buildErrorState(context, propertyProvider, isDark)
                        : sortedProperties.isEmpty
                            ? _buildEmptyState(context, isDark)
                            : SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildPropertyGridArea(
                                    context,
                                    premiumProperties,
                                    normalProperties,
                                    isDark,
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== PREMIUM APP BAR ==============
  Widget _buildPremiumAppBar(
    BuildContext context,
    bool isDark,
    dynamic user,
    String? profileImage,
    PropertyProvider propertyProvider,
  ) {
    final totalProperties = propertyProvider.properties.length;
    final activeFilterCount = (_selectedFilter != 'All' ? 1 : 0) +
        ((_minPrice > _priceFloor || _maxPrice < _priceCeil) ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _buildProfileAvatar(isDark, user, profileImage),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isDark
                        ? [Colors.white, Colors.white.withOpacity(0.75)]
                        : [const Color(0xFF14171F), _Palette.primary],
                  ).createShader(bounds),
                  child: Text(
                    'Find Your Stay',
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalProperties curated stays available',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _AppBarIconButton(
            icon: isDark
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_round_outlined,
            isDark: isDark,
            active: false,
            onTap: () {
              final themeProvider =
                  Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          const SizedBox(width: 8),
          _AppBarIconButton(
            icon: Icons.tune_rounded,
            isDark: isDark,
            active: _showFilters,
            badgeCount: activeFilterCount,
            onTap: _toggleFilterPanel,
          ),
        ],
      ),
    );
  }

  // ✅ PREMIUM PROFILE AVATAR — shows the real profile picture when
  // available (same source as the Home screen), with a gradient ring and
  // glow. Falls back to the user's initial when no picture is set. Tapping
  // it opens the real Profile screen.
  Widget _buildProfileAvatar(bool isDark, dynamic user, String? profileImage) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;

    return GestureDetector(
      onTap: _navigateToProfile,
      child: Hero(
        tag: 'profile_avatar',
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2.2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_Palette.gold, _Palette.primary, _Palette.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _Palette.primary.withOpacity(0.32),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? _Palette.darkSurface : Colors.white,
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: profileImage,
                      fit: BoxFit.cover,
                      width: 42,
                      height: 42,
                      placeholder: (context, url) => Container(
                        color: _Palette.primary.withOpacity(0.15),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => _avatarInitial(user),
                    )
                  : _avatarInitial(user),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarInitial(dynamic user) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_Palette.primary, _Palette.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
    );
  }

  // ============== SMART SEARCH BAR ==============
  Widget _buildSmartSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isDark ? _Palette.darkSurface : _Palette.lightSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isSearchFocused
                    ? _Palette.primary
                    : (isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.black.withOpacity(0.06)),
                width: _isSearchFocused ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isSearchFocused
                      ? _Palette.primary.withOpacity(0.14)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: _isSearchFocused ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontSize: 14.5,
              ),
              decoration: InputDecoration(
                hintText: 'Search PG, Hostel, Hotel, city...',
                hintStyle: GoogleFonts.poppins(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _isSearchFocused
                      ? _Palette.primary
                      : (isDark ? Colors.grey[500] : Colors.grey[400]),
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        splashRadius: 18,
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          size: 19,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 15),
              ),
            ),
          ),
          _buildPriceSlider(context, isDark),
        ],
      ),
    );
  }

  // ============== PRICE SLIDER (₹1,000 – ₹10,000, animated collapse) ==============
  Widget _buildPriceSlider(BuildContext context, bool isDark) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _filterPanelController,
        curve: Curves.easeOutCubic,
      ),
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _filterPanelController,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          decoration: BoxDecoration(
            color: isDark ? _Palette.darkSurface : _Palette.lightSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 15,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Price Range',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _Palette.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${_minPrice.toInt()} – ₹${_maxPrice.toInt()}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _Palette.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 8,
                    elevation: 3,
                  ),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: _Palette.primary,
                  inactiveTrackColor:
                      isDark ? Colors.grey[800] : Colors.grey[300],
                  thumbColor: _Palette.primary,
                  overlayColor: _Palette.primary.withOpacity(0.15),
                ),
                child: RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: _priceFloor,
                  max: _priceCeil,
                  divisions: 18, // ₹500 steps across the 1,000–10,000 range
                  labels: RangeLabels(
                    '₹${_minPrice.toInt()}',
                    '₹${_maxPrice.toInt()}',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${_priceFloor.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        )),
                    Text('₹${_priceCeil.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== FILTER CHIPS ==============
  Widget _buildFilterChips(BuildContext context, bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filterOptions.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final label = option['label'] as String;
          final icon = option['icon'] as IconData;
          final isSelected = _selectedFilter == label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: label,
              icon: icon,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFilter = isSelected ? 'All' : label;
                });
              },
            ),
          );
        },
      ),
    );
  }

  // ============== PROPERTY GRID AREA (bidirectional scroll) ==============
  // A LayoutBuilder measures the visible screen width and derives a card
  // width so exactly `visibleColumns` (2) cards fit on screen without any
  // horizontal scroll. The full matrix has `totalColumns` (4) columns, so
  // scrolling right reveals the remaining columns, while scrolling down
  // reveals more rows — a true two-directional grid.
  Widget _buildPropertyGridArea(
    BuildContext context,
    List<Property> premium,
    List<Property> normal,
    bool isDark,
  ) {
    final all = [...premium, ...normal];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - (_GridSpec.horizontalPadding * 2);
        final cardWidth = (availableWidth -
                (_GridSpec.spacing * (_GridSpec.visibleColumns - 1))) /
            _GridSpec.visibleColumns;

        final rows = <List<Property>>[];
        for (var i = 0; i < all.length; i += _GridSpec.totalColumns) {
          rows.add(
            all.sublist(
              i,
              (i + _GridSpec.totalColumns > all.length)
                  ? all.length
                  : i + _GridSpec.totalColumns,
            ),
          );
        }

        final gridWidth = _GridSpec.totalColumns * cardWidth +
            (_GridSpec.totalColumns - 1) * _GridSpec.spacing;

        return Scrollbar(
          controller: _gridHorizontalController,
          thumbVisibility: true,
          notificationPredicate: (notif) => notif.depth == 0,
          child: SingleChildScrollView(
            controller: _gridHorizontalController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: _GridSpec.horizontalPadding),
            child: Scrollbar(
              controller: _gridVerticalController,
              thumbVisibility: true,
              notificationPredicate: (notif) => notif.depth == 0,
              child: SingleChildScrollView(
                controller: _gridVerticalController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: gridWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (premium.isNotEmpty) _buildPremiumBanner(isDark),
                      for (var r = 0; r < rows.length; r++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: r == rows.length - 1
                                ? 0
                                : _GridSpec.spacing,
                          ),
                          child: _FadeSlideIn(
                            index: r,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var c = 0; c < rows[r].length; c++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: c == rows[r].length - 1
                                          ? 0
                                          : _GridSpec.spacing,
                                    ),
                                    child: _buildGridCard(
                                      context,
                                      rows[r][c],
                                      isDark,
                                      cardWidth: cardWidth,
                                      isPremium: rows[r][c].isFeatured,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
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

  // ============== PREMIUM BANNER (sits above the grid) ==============
  Widget _buildPremiumBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141A2C), Color(0xFF1F2A44), _Palette.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _Palette.primary.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _Palette.gold.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: _Palette.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Stays',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Handpicked & verified for you',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              'Featured',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== COMPACT GRID CARD ==============
  Widget _buildGridCard(
    BuildContext context,
    Property property,
    bool isDark, {
    required double cardWidth,
    required bool isPremium,
  }) {
    final isFavorite = _favoriteIds.contains(property.propertyId);

    return _PressableScale(
      onTap: () => _navigateToPropertyDetail(property.propertyId),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color:
              isDark ? _Palette.darkSurfaceElevated : _Palette.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPremium
                ? _Palette.gold.withOpacity(0.4)
                : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.05)),
            width: isPremium ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPremium
                  ? _Palette.gold.withOpacity(isDark ? 0.12 : 0.1)
                  : Colors.black.withOpacity(isDark ? 0.18 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'property_image_${property.propertyId}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Container(
                      height: _GridSpec.cardImageHeight,
                      width: double.infinity,
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      child: property.coverImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: property.coverImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color:
                                    isDark ? Colors.grey[850] : Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.home_rounded,
                                size: 36,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            )
                          : Icon(
                              Icons.home_rounded,
                              size: 36,
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                    ),
                  ),
                ),
                // Subtle bottom gradient for legibility of overlaid badges
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.18),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                if (isPremium)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_Palette.gold, _Palette.goldLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _Palette.gold.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _CompactFavoriteButton(
                    isFavorite: isFavorite,
                    onTap: () => _toggleFavorite(property.propertyId),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: _Palette.goldLight, size: 11),
                        const SizedBox(width: 2),
                        Text(
                          property.averageRating?.toStringAsFixed(1) ?? '4.5',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (property.isVerifiedOwner)
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child: Icon(
                            Icons.verified_rounded,
                            color: _Palette.primary,
                            size: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.city,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          property.monthlyRentMin != null
                              ? '₹${property.monthlyRentMin!.toStringAsFixed(0)}'
                              : 'Contact',
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: _Palette.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _Palette.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${property.availableRooms} left',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: _Palette.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== LOADING STATE (skeleton shimmer grid) ==============
  Widget _buildLoadingState(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - (_GridSpec.horizontalPadding * 2);
        final cardWidth = (availableWidth -
                (_GridSpec.spacing * (_GridSpec.visibleColumns - 1))) /
            _GridSpec.visibleColumns;
        final gridWidth = _GridSpec.totalColumns * cardWidth +
            (_GridSpec.totalColumns - 1) * _GridSpec.spacing;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: _GridSpec.horizontalPadding, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: gridWidth,
            child: Column(
              children: List.generate(3, (r) {
                return Padding(
                  padding:
                      EdgeInsets.only(bottom: r == 2 ? 0 : _GridSpec.spacing),
                  child: Row(
                    children: List.generate(_GridSpec.totalColumns, (c) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: c == _GridSpec.totalColumns - 1
                              ? 0
                              : _GridSpec.spacing,
                        ),
                        child:
                            _SkeletonCard(isDark: isDark, cardWidth: cardWidth),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ============== ERROR STATE ==============
  Widget _buildErrorState(
      BuildContext context, PropertyProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _Palette.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: _Palette.danger.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Failed to load properties',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.clearError();
                  provider.searchProperties();
                },
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: _Palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== EMPTY STATE ==============
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.home_rounded,
                size: 56,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No properties found'
                  : 'No properties available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Check back later for new listings',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty ||
                _selectedFilter != 'All' ||
                _minPrice > _priceFloor ||
                _maxPrice < _priceCeil) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedFilter = 'All';
                      _minPrice = _priceFloor;
                      _maxPrice = _priceCeil;
                    });
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 19),
                  label: Text(
                    'Clear All Filters',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: _Palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ==================================================================
/// REUSABLE WIDGETS
/// ==================================================================

/// Wraps any card with a subtle premium "press to shrink" tactile effect.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    setState(() => _scale = pressed ? 0.97 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.isDark,
    required this.active,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: active
                ? _Palette.primary
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? _Palette.primary
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06)),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _Palette.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  size: 21,
                  color: active
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                ),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: _Palette.gold,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$badgeCount',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_Palette.primary, _Palette.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.035)),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _Palette.primary.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact favorite (heart) button used on grid cards, with bounce.
class _CompactFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _CompactFavoriteButton(
      {required this.isFavorite, required this.onTap});

  @override
  State<_CompactFavoriteButton> createState() =>
      _CompactFavoriteButtonState();
}

class _CompactFavoriteButtonState extends State<_CompactFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    lowerBound: 0.85,
    upperBound: 1.0,
    value: 1.0,
  );

  void _handleTap() {
    widget.onTap();
    _controller.forward(from: 0.85);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(9),
        ),
        padding: const EdgeInsets.all(5),
        child: ScaleTransition(
          scale: _controller,
          child: Icon(
            widget.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: widget.isFavorite ? _Palette.danger : Colors.white,
            size: 15,
          ),
        ),
      ),
    );
  }
}

/// Staggered fade + slide entrance wrapper for grid rows.
class _FadeSlideIn extends StatefulWidget {
  final int index;
  final Widget child;

  const _FadeSlideIn({required this.index, required this.child});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 70 * (widget.index.clamp(0, 6)));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Shimmering skeleton card shown while properties are loading (grid form).
class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  final double cardWidth;

  const _SkeletonCard({required this.isDark, required this.cardWidth});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isDark ? _Palette.darkSurface : Colors.grey[200]!;
    final highlight =
        widget.isDark ? _Palette.darkSurfaceElevated : Colors.grey[100]!;

    return Container(
      width: widget.cardWidth,
      decoration: BoxDecoration(
        color: widget.isDark ? _Palette.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBlock(
                  height: _GridSpec.cardImageHeight,
                  t: t,
                  base: baseColor,
                  hi: highlight),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBlock(
                        height: 13,
                        width: 120,
                        t: t,
                        base: baseColor,
                        hi: highlight),
                    const SizedBox(height: 8),
                    _shimmerBlock(
                        height: 10,
                        width: 80,
                        t: t,
                        base: baseColor,
                        hi: highlight),
                    const SizedBox(height: 12),
                    _shimmerBlock(
                        height: 16,
                        width: 70,
                        t: t,
                        base: baseColor,
                        hi: highlight),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _shimmerBlock({
    required double height,
    double? width,
    required double t,
    required Color base,
    required Color hi,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * t, 0),
            end: Alignment(1 + 2 * t, 0),
            colors: [base, hi, base],
            stops: const [0.35, 0.5, 0.65],
          ),
        ),
      ),
    );
  }
}