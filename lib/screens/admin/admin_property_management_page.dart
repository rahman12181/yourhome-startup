import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/admin_provider.dart';
import '../../models/property_model.dart';
import '../property_detail_screen.dart';

// ==================== DESIGN TOKENS ====================
class _AdminPalette {
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF9F67F5);
  static const gold = Color(0xFFD4AF37);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF2563EB);

  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const lightBg = Color(0xFFF5F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
}

class AdminPropertyManagementPage extends StatefulWidget {
  const AdminPropertyManagementPage({super.key});

  @override
  State<AdminPropertyManagementPage> createState() =>
      _AdminPropertyManagementPageState();
}

class _AdminPropertyManagementPageState
    extends State<AdminPropertyManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isFirstLoad = true;
  String _searchQuery = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Counts
  int _totalProperties = 0;
  int _pendingCount = 0;
  int _publishedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadData();
      }
      _fadeController.forward();
    });
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(
      context,
      listen: false,
    );
    await adminProvider.getPendingProperties();
    await adminProvider.getAllPropertiesAdmin();

    setState(() {
      _totalProperties = adminProvider.allProperties.length + adminProvider.pendingProperties.length;
      _pendingCount = adminProvider.pendingProperties.length;
      _publishedCount = adminProvider.allProperties.length;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? _AdminPalette.darkBg : _AdminPalette.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            elevation: 0,
            backgroundColor: isDark ? _AdminPalette.darkBg : _AdminPalette.lightBg,
            expandedHeight: 0,
            toolbarHeight: 64,
            title: Text(
              'Property Management',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? _AdminPalette.darkSurface : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: _AdminPalette.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _loadData();
                    },
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(160),
              child: _buildStatsBar(context, isDark, adminProvider),
            ),
          ),
        ],
        body: adminProvider.isLoading && adminProvider.pendingProperties.isEmpty
            ? _buildLoadingState(isDark)
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildSearchBar(context, isDark),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        color: _AdminPalette.primary,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAllPropertiesList(context, isDark, adminProvider),
                            _buildPendingPropertiesList(context, isDark, adminProvider),
                            _buildPublishedPropertiesList(context, isDark, adminProvider),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _AdminPalette.primary),
          const SizedBox(height: 16),
          Text(
            'Loading properties...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============== STATS BAR ==============
  Widget _buildStatsBar(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  _totalProperties.toString(),
                  Icons.apartment_rounded,
                  [const Color(0xFF7C3AED), const Color(0xFF9F67F5)],
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  _pendingCount.toString(),
                  Icons.pending_actions_rounded,
                  [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Published',
                  _publishedCount.toString(),
                  Icons.check_circle_rounded,
                  [const Color(0xFF16A34A), const Color(0xFF22C55E)],
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? _AdminPalette.darkSurface : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_AdminPalette.primary, _AdminPalette.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _AdminPalette.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(12),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Published'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    List<Color> gradientColors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 15),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============== SEARCH BAR ==============
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? _AdminPalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search by title, city or owner...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _AdminPalette.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: _AdminPalette.primary,
                size: 18,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ============== ALL PROPERTIES LIST ==============
  Widget _buildAllPropertiesList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    List<Map<String, dynamic>> allProperties = [];

    for (var p in provider.pendingProperties) {
      allProperties.add({
        'propertyId': p.propertyId,
        'title': p.title,
        'city': p.city,
        'state': p.state,
        'propertyType': p.propertyType,
        'ownerName': p.ownerName,
        'isPublished': p.isPublished,
        'coverImage': '',
        'availableRooms': 0,
        'monthlyRentMin': 0,
        'isVerifiedOwner': false,
        'isPending': true,
      });
    }

    for (var p in provider.allProperties) {
      allProperties.add({
        'propertyId': p.propertyId,
        'title': p.title,
        'city': p.city,
        'state': p.state,
        'propertyType': p.propertyType,
        'ownerName': '',
        'isPublished': true,
        'coverImage': p.coverImage,
        'availableRooms': p.availableRooms,
        'monthlyRentMin': p.monthlyRentMin ?? 0,
        'isVerifiedOwner': p.isVerifiedOwner,
        'isPending': false,
      });
    }

    final filtered = allProperties.where((property) {
      final title = (property['title'] as String?)?.toLowerCase() ?? '';
      final city = (property['city'] as String?)?.toLowerCase() ?? '';
      final owner = (property['ownerName'] as String?)?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return title.contains(query) ||
          city.contains(query) ||
          owner.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(isDark, 'No properties found');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final property = filtered[index];
        final isPending = property['isPending'] as bool;
        return _buildPropertyCard(
          context,
          property,
          isDark,
          provider,
          isPending: isPending,
        );
      },
    );
  }

  // ============== PENDING PROPERTIES LIST ==============
  Widget _buildPendingPropertiesList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    final filtered = provider.pendingProperties.where((property) {
      final title = property.title.toLowerCase();
      final city = property.city.toLowerCase();
      final owner = property.ownerName.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) ||
          city.contains(query) ||
          owner.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(isDark, 'No pending properties');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final property = filtered[index];
        return _buildPropertyCardFromPending(
          context,
          property,
          isDark,
          provider,
        );
      },
    );
  }

  // ============== PUBLISHED PROPERTIES LIST ==============
  Widget _buildPublishedPropertiesList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    final filtered = provider.allProperties.where((property) {
      final title = property.title.toLowerCase();
      final city = property.city.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || city.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(isDark, 'No published properties');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final property = filtered[index];
        return _buildPropertyCardFromPublished(
          context,
          property,
          isDark,
          provider,
        );
      },
    );
  }

  // ============== PROPERTY CARD (For All Properties) ==============
  Widget _buildPropertyCard(
    BuildContext context,
    Map<String, dynamic> property,
    bool isDark,
    AdminProvider provider, {
    required bool isPending,
  }) {
    final title = property['title'] ?? 'Unknown Property';
    final city = property['city'] ?? 'Unknown City';
    final state = property['state'] ?? '';
    final propertyType = property['propertyType'] ?? 'PG';
    final ownerName = property['ownerName'] ?? 'Unknown Owner';
    final coverImage = property['coverImage'] ?? '';
    final availableRooms = property['availableRooms'] ?? 0;
    final monthlyRentMin = property['monthlyRentMin'] ?? 0;
    final isVerifiedOwner = property['isVerifiedOwner'] ?? false;
    final propertyId = property['propertyId'] ?? 0;

    return _buildCardUI(
      context,
      title: title,
      city: city,
      state: state,
      propertyType: propertyType,
      ownerName: ownerName,
      coverImage: coverImage,
      availableRooms: availableRooms,
      monthlyRentMin: monthlyRentMin,
      isVerifiedOwner: isVerifiedOwner,
      propertyId: propertyId,
      isPending: isPending,
      isDark: isDark,
      provider: provider,
    );
  }

  // ============== PROPERTY CARD (From PendingProperty) ==============
  Widget _buildPropertyCardFromPending(
    BuildContext context,
    dynamic property,
    bool isDark,
    AdminProvider provider,
  ) {
    return _buildCardUI(
      context,
      title: property.title,
      city: property.city,
      state: property.state,
      propertyType: property.propertyType,
      ownerName: property.ownerName,
      coverImage: '',
      availableRooms: 0,
      monthlyRentMin: 0,
      isVerifiedOwner: false,
      propertyId: property.propertyId,
      isPending: true,
      isDark: isDark,
      provider: provider,
    );
  }

  // ============== PROPERTY CARD (From Property) ==============
  Widget _buildPropertyCardFromPublished(
    BuildContext context,
    Property property,
    bool isDark,
    AdminProvider provider,
  ) {
    return _buildCardUI(
      context,
      title: property.title,
      city: property.city,
      state: property.state,
      propertyType: property.propertyType,
      ownerName: '',
      coverImage: property.coverImage,
      availableRooms: property.availableRooms,
      monthlyRentMin: property.monthlyRentMin ?? 0,
      isVerifiedOwner: property.isVerifiedOwner,
      propertyId: property.propertyId,
      isPending: false,
      isDark: isDark,
      provider: provider,
    );
  }

  // ============== CARD UI ==============
  Widget _buildCardUI(
    BuildContext context, {
    required String title,
    required String city,
    required String state,
    required String propertyType,
    required String ownerName,
    required String coverImage,
    required int availableRooms,
    required double monthlyRentMin,
    required bool isVerifiedOwner,
    required int propertyId,
    required bool isPending,
    required bool isDark,
    required AdminProvider provider,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? _AdminPalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPending
                ? _AdminPalette.warning.withOpacity(0.35)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04)),
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPending
                  ? _AdminPalette.warning.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailScreen(
                      propertyId: propertyId,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  // Header with Image
                  Container(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Property Image
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 84,
                                height: 84,
                                color: isDark ? Colors.grey[850] : Colors.grey[200],
                                child: coverImage.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: coverImage,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: isDark ? Colors.grey[850] : Colors.grey[200],
                                          child: const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _AdminPalette.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Icon(
                                          Icons.apartment_rounded,
                                          size: 32,
                                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                      )
                                    : Icon(
                                        Icons.apartment_rounded,
                                        size: 32,
                                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? _AdminPalette.warning
                                      : _AdminPalette.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Icon(
                                  isPending
                                      ? Icons.access_time_rounded
                                      : Icons.check_rounded,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      size: 12,
                                      color: isDark ? Colors.grey[500] : Colors.grey[500]),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      '$city, $state',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildBadge(propertyType, _AdminPalette.info),
                                  _buildBadge(
                                    isPending ? 'Pending' : 'Published',
                                    isPending ? _AdminPalette.warning : _AdminPalette.success,
                                  ),
                                  if (isVerifiedOwner)
                                    _buildBadge('Verified', _AdminPalette.gold,
                                        icon: Icons.verified_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                    height: 1,
                  ),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        _buildStatItem(
                          Icons.bed_rounded,
                          '$availableRooms rooms',
                          isDark,
                        ),
                        const SizedBox(width: 16),
                        _buildStatItem(
                          Icons.currency_rupee_rounded,
                          '₹${monthlyRentMin.toStringAsFixed(0)}/mo',
                          isDark,
                          color: _AdminPalette.primary,
                        ),
                        const Spacer(),
                        if (ownerName.isNotEmpty)
                          Flexible(
                            child: Text(
                              'Owner: $ownerName',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyDetailScreen(
                                    propertyId: propertyId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: Text('View Detail',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _AdminPalette.primary,
                              side: const BorderSide(color: _AdminPalette.primary, width: 1.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_AdminPalette.success, Color(0xFF22C55E)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _AdminPalette.success.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  final success = await provider.publishProperty(propertyId);
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text('Property published successfully ✅',
                                                style: GoogleFonts.poppins()),
                                          ],
                                        ),
                                        backgroundColor: _AdminPalette.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    _loadData();
                                  }
                                },
                                icon: const Icon(Icons.publish_rounded, size: 16),
                                label: Text('Publish',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                final success = await provider.unpublishProperty(propertyId);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.remove_circle, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text('Property unpublished',
                                              style: GoogleFonts.poppins()),
                                        ],
                                      ),
                                      backgroundColor: _AdminPalette.warning,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                  _loadData();
                                }
                              },
                              icon: const Icon(Icons.remove_circle_rounded, size: 16),
                              label: Text('Unpublish',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _AdminPalette.warning,
                                side: const BorderSide(color: _AdminPalette.warning, width: 1.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, bool isDark, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? (isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: color != null ? FontWeight.w700 : FontWeight.w500,
            color: color ?? (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _AdminPalette.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 52,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}