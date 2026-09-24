import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:yourhome/models/property_model.dart';
import 'package:yourhome/providers/notification_provider.dart';
import 'package:yourhome/screens/admin/admin_profile_screen.dart';
import 'package:yourhome/screens/booking/first_booking_discount_screen.dart';
import 'package:yourhome/screens/owner/owner_profile_screen.dart';
import 'package:yourhome/screens/reels/reels_feed_screen.dart';
import 'package:yourhome/screens/refer_and_earn_screen.dart';
import 'package:yourhome/screens/rental/my_rentals_screen.dart';
import 'package:yourhome/utils/constants.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/property_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/user_dashboard_provider.dart';

import 'properties_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'property_detail_screen.dart';
import 'chat/chat_list_screen.dart';
import 'notifications/notification_screen.dart';

import 'owner/owner_dashboard_page.dart';
import 'owner/owner_property_management_page.dart';
import 'owner/owner_booking_management_page.dart';

import 'admin/admin_dashboard_page.dart';
import 'admin/admin_user_management_page.dart';
import 'admin/admin_property_management_page.dart';

class _HP {
  static const studentPrimary = Color(0xFF2563EB);
  static const studentPrimaryLight = Color(0xFF3B82F6);
  static const studentPrimarySoft = Color(0xFF60A5FA);
  static const ownerPrimary = Color(0xFFF59E0B);
  static const ownerPrimaryLight = Color(0xFFFBBF24);
  static const ownerGold = Color(0xFFD4AF37);
  static const adminPrimary = Color(0xFF7C3AED);
  static const adminPrimaryLight = Color(0xFF8B5CF6);
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFF22C55E);
  static const danger = Color(0xFFDC2626);
  static const dangerLight = Color(0xFFEF4444);
  static const gold = Color(0xFFD4AF37);
  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFF9F7AEA);
  static const pink = Color(0xFFEC4899);
  static const orange = Color(0xFFF59E0B);
  static const teal = Color(0xFF14B8A6);
  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const darkSurfaceElevated = Color(0xFF1B2338);
  static const darkCard = Color(0xFF1A1F33);
  static const lightBg = Color(0xFFF7F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();

  static final GlobalKey<HomeScreenState> navigatorKey =
      GlobalKey<HomeScreenState>();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  DateTime? _lastPressed;

  late AnimationController _navAnimationController;
  late Animation<double> _navAnimation;

  @override
  void initState() {
    super.initState();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeOutCubic,
    );
    _navAnimationController.forward();
  }

  @override
  void dispose() {
    _navAnimationController.dispose();
    super.dispose();
  }

  void changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastPressed == null ||
        now.difference(_lastPressed!) > const Duration(seconds: 2)) {
      _lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text('Press back again to exit', style: GoogleFonts.poppins()),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }
    return true;
  }

  Color _getPrimaryColor(String role) {
    switch (role) {
      case 'ADMIN':
        return _HP.adminPrimary;
      case 'OWNER':
        return _HP.ownerPrimary;
      default:
        return _HP.studentPrimary;
    }
  }

  List<Widget> _getPages(String role) {
    switch (role) {
      case 'ADMIN':
        return const [
          AdminDashboardPage(),
          AdminUserManagementPage(),
          AdminPropertyManagementPage(),
          AdminProfileScreen(),
        ];
      case 'OWNER':
        return const [
          OwnerDashboardPage(),
          OwnerPropertyManagementPage(),
          OwnerBookingManagementPage(),
          ChatListScreen(),
        ];
      default:
        return const [
          HomePage(),
          PropertiesScreen(),
          ReelsFeedScreen(),
          FavoritesScreen(),
          ChatListScreen(),
        ];
    }
  }

  List<String> _getLabels(String role) {
    switch (role) {
      case 'ADMIN':
        return ['Dashboard', 'Users', 'Properties', 'Profile'];
      case 'OWNER':
        return ['Dashboard', 'Properties', 'Bookings', 'Chat'];
      default:
        return ['Home', 'Explore', 'Reels', 'Saved', 'Chat'];
    }
  }

  List<IconData> _getIcons(String role) {
    switch (role) {
      case 'ADMIN':
        return [
          Icons.dashboard_outlined,
          Icons.people_outlined,
          Icons.apartment_outlined,
          Icons.person_outlined,
        ];
      case 'OWNER':
        return [
          Icons.dashboard_outlined,
          Icons.apartment_outlined,
          Icons.book_online_outlined,
          Icons.chat_bubble_outline_outlined,
        ];
      default:
        return [
          Icons.home_outlined,
          Icons.search_outlined,
          Icons.movie_creation_outlined,
          Icons.favorite_border_outlined,
          Icons.chat_bubble_outline_outlined,
        ];
    }
  }

  List<IconData> _getActiveIcons(String role) {
    switch (role) {
      case 'ADMIN':
        return [
          Icons.dashboard_rounded,
          Icons.people_rounded,
          Icons.apartment_rounded,
          Icons.person_rounded,
        ];
      case 'OWNER':
        return [
          Icons.dashboard_rounded,
          Icons.apartment_rounded,
          Icons.book_online_rounded,
          Icons.person_rounded,
        ];
      default:
        return [
          Icons.home_rounded,
          Icons.search_rounded,
          Icons.movie_creation_rounded,
          Icons.favorite_rounded,
          Icons.chat_bubble_rounded,
        ];
    }
  }

  // ============================================================
  // PROFESSIONAL STUDENT BOTTOM NAV
  // ============================================================
  Widget _buildStudentBottomNav(
    bool isDark,
    List<Widget> pages,
    List<String> labels,
    List<IconData> icons,
    List<IconData> activeIcons,
  ) {
    final bool isReelsTab = _selectedIndex == 2;
    final bool useDark = isReelsTab ? true : isDark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isReelsTab) {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xFF1A1F33),
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ));
      } else {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          systemNavigationBarColor:
              isDark ? const Color(0xFF0A0E1A) : Colors.white,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ));
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: useDark
            ? const Color(0xFF15192B)
            : (isDark ? _HP.darkSurface : Colors.white),
        border: Border(
          top: BorderSide(
            color: useDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(useDark ? 0.4 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(pages.length, (index) {
              final isSelected = _selectedIndex == index;
              final primaryColor = _HP.studentPrimary;
              final bool isReels = index == 2;
              final Color selectedColor =
                  isReels ? _HP.orange : primaryColor;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 250),
                          scale: isSelected ? 1.1 : 1.0,
                          child: Icon(
                            isSelected ? activeIcons[index] : icons[index],
                            color: isSelected
                                ? selectedColor
                                : (useDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400]),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? selectedColor
                                : (useDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400]),
                          ),
                          child: Text(labels[index]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFESSIONAL OWNER BOTTOM NAV
  // ============================================================
  Widget _buildOwnerBottomNav(
    bool isDark,
    List<Widget> pages,
    List<String> labels,
    List<IconData> icons,
    List<IconData> activeIcons,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: (isDark ? _HP.darkSurfaceElevated : Colors.white)
                  .withOpacity(isDark ? 0.82 : 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _HP.ownerPrimary.withOpacity(0.2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _HP.ownerPrimary.withOpacity(0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / pages.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * _selectedIndex + 10,
                      top: 10,
                      width: itemWidth - 20,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_HP.ownerPrimary, _HP.ownerGold],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _HP.ownerPrimary.withOpacity(0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(pages.length, (index) {
                        final isSelected = _selectedIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedIndex = index);
                            },
                            child: SizedBox(
                              height: 72,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected
                                        ? activeIcons[index]
                                        : icons[index],
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[500]),
                                    size: 22,
                                  ),
                                  const SizedBox(height: 3),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[500]),
                                    ),
                                    child: Text(labels[index]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFESSIONAL ADMIN BOTTOM NAV
  // ============================================================
  Widget _buildAdminBottomNav(
    bool isDark,
    List<Widget> pages,
    List<String> labels,
    List<IconData> icons,
    List<IconData> activeIcons,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: (isDark ? _HP.darkSurfaceElevated : Colors.white)
                  .withOpacity(isDark ? 0.82 : 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _HP.adminPrimary.withOpacity(0.2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _HP.adminPrimary.withOpacity(0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / pages.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * _selectedIndex + 10,
                      top: 10,
                      width: itemWidth - 20,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              _HP.adminPrimary,
                              _HP.adminPrimaryLight
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _HP.adminPrimary.withOpacity(0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(pages.length, (index) {
                        final isSelected = _selectedIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedIndex = index);
                            },
                            child: SizedBox(
                              height: 72,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected
                                        ? activeIcons[index]
                                        : icons[index],
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[500]),
                                    size: 22,
                                  ),
                                  const SizedBox(height: 3),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[500]),
                                    ),
                                    child: Text(labels[index]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? 'STUDENT';

    final pages = _getPages(userRole);
    final labels = _getLabels(userRole);
    final icons = _getIcons(userRole);
    final activeIcons = _getActiveIcons(userRole);

    Widget bottomNav;
    switch (userRole) {
      case 'OWNER':
        bottomNav =
            _buildOwnerBottomNav(isDark, pages, labels, icons, activeIcons);
        break;
      case 'ADMIN':
        bottomNav =
            _buildAdminBottomNav(isDark, pages, labels, icons, activeIcons);
        break;
      default:
        bottomNav =
            _buildStudentBottomNav(isDark, pages, labels, icons, activeIcons);
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: HomeScreen.navigatorKey,
        extendBody: userRole == 'OWNER',
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey('${userRole}_$_selectedIndex'),
            child: pages[_selectedIndex],
          ),
        ),
        bottomNavigationBar: ScaleTransition(
          scale: _navAnimation,
          child: bottomNav,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOME PAGE — RESTRUCTURED
// ══════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _staggerController;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'PG', 'image': 'assets/images/pg.jpg', 'color': _HP.studentPrimary},
    {'name': 'Hostel', 'image': 'assets/images/hostel.jpg', 'color': _HP.purple},
    {'name': 'Hotel', 'image': 'assets/images/hotel.jpg', 'color': _HP.orange},
    {'name': 'Flat', 'image': 'assets/images/flats.png', 'color': _HP.success},
    {'name': 'Villa', 'image': 'assets/images/villa.png', 'color': const Color(0xFF06B6D4)},
    {'name': 'Resort', 'image': 'assets/images/restourent.png', 'color': _HP.pink},
  ];

  final List<Map<String, dynamic>> _popularCities = [
    {'name': 'Delhi', 'emoji': '🏛️', 'count': '240+ PGs'},
    {'name': 'Noida', 'emoji': '🏙️', 'count': '180+ PGs'},
    {'name': 'Gurgaon', 'emoji': '🌆', 'count': '210+ PGs'},
    {'name': 'Mumbai', 'emoji': '🌊', 'count': '320+ PGs'},
    {'name': 'Bangalore', 'emoji': '🌴', 'count': '450+ PGs'},
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadAll();
  }

  Future<void> _loadAll() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      if (propertyProvider.properties.isEmpty) {
        propertyProvider.searchProperties();
      }

      final userDashboard =
          Provider.of<UserDashboardProvider>(context, listen: false);
      await userDashboard.loadSummary(showLoader: false);

      final notifProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      await notifProvider.loadUnreadCount();

      final chatProvider =
          Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loadUnreadCount();

      final referralProvider =
          Provider.of<ReferralProvider>(context, listen: false);
      await referralProvider.fetchReferralInfo();

      if (mounted) _staggerController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _navigateToTab(int index) {
    final homeState = HomeScreen.navigatorKey.currentState;
    if (homeState != null) homeState.changeTab(index);
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Widget _animated(int index, Widget child) {
    final delay = index * 0.05;
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (_, __) {
        final raw = _staggerController.value - delay;
        final t = Curves.easeOutCubic.transform(raw.clamp(0.0, 1.0).toDouble());
        return Transform.translate(
          offset: Offset(0, 20 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profileImage = profileProvider.profile?.profilePic;
    final dashboard = Provider.of<UserDashboardProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? _HP.darkBg : _HP.lightBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            final pp = Provider.of<PropertyProvider>(context, listen: false);
            await pp.searchProperties();
            await dashboard.loadSummary(showLoader: false);
          },
          color: _HP.studentPrimary,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER
                _animated(0,
                    _buildHeader(context, isDark, user, profileImage, dashboard)),
                const SizedBox(height: 20),

                // 2. ACTIVE RENTAL (if exists)
                if (dashboard.hasActiveTenancy) ...[
                  _animated(1,
                      _buildActiveRentalCard(context, isDark, dashboard)),
                  const SizedBox(height: 20),
                ],

                // 3. QUICK ACTIONS
                _animated(2, _buildQuickActions(context, isDark)),
                const SizedBox(height: 20),

                // 4. WALLET
                _animated(3, _buildWalletCard(context, isDark, dashboard)),
                const SizedBox(height: 20),

                // 5. OFFERS
                _animated(4, _buildOfferBanner(context, isDark)),
                const SizedBox(height: 20),

                // 6. CATEGORIES
                _animated(5, _buildCategories(context, isDark)),
                const SizedBox(height: 24),

                // 7. TRENDING
                _animated(6, _buildTrendingSection(context, isDark)),
                const SizedBox(height: 24),

                // 8. ANALYTICS
                _animated(7, _buildAnalyticsCard(context, isDark, dashboard)),
                const SizedBox(height: 24),

                // 9. RECENT ACTIVITY
                _animated(8,
                    _buildRecentActivity(context, isDark, dashboard)),
                const SizedBox(height: 24),

                // 10. POPULAR CITIES
                _animated(9, _buildPopularCities(context, isDark)),
                const SizedBox(height: 24),

                // 11. TRUST BADGES
                _animated(10, _buildTrustBadges(context, isDark)),
                const SizedBox(height: 24),

                // 12. SUPPORT
                _animated(11, _buildSupportCTA(context, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. HEADER
  // ============================================================
  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    dynamic user,
    String? profileImage,
    UserDashboardProvider dashboard,
  ) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToScreen(const ProfileScreen()),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasImage
                    ? null
                    : const LinearGradient(
                        colors: [
                          _HP.studentPrimary,
                          _HP.studentPrimaryLight
                        ],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: _HP.studentPrimary.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.transparent,
                backgroundImage: hasImage
                    ? CachedNetworkImageProvider(profileImage!)
                    : null,
                child: hasImage
                    ? null
                    : Text(
                        user?.name?.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name?.isNotEmpty == true ? user!.name : 'Guest',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _iconBtn(
            icon: Icons.chat_bubble_outline_rounded,
            badge: dashboard.unreadMessages,
            badgeColor: _HP.success,
            isDark: isDark,
            onTap: () => _navigateToTab(4),
          ),
          const SizedBox(width: 8),
          _iconBtn(
            icon: Icons.notifications_outlined,
            badge: dashboard.unreadNotifications,
            badgeColor: _HP.danger,
            isDark: isDark,
            onTap: () => _navigateToScreen(const NotificationScreen()),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required int badge,
    required Color badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? _HP.darkSurface : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                size: 21,
              ),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? _HP.darkBg : _HP.lightBg,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    badge > 99 ? '99+' : badge.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 2. ACTIVE RENTAL CARD (PROFESSIONAL)
  // ============================================================
  Widget _buildActiveRentalCard(
    BuildContext context,
    bool isDark,
    UserDashboardProvider dashboard,
  ) {
    final tenancy = dashboard.currentTenancy!;
    final daysUntilDue = tenancy['daysUntilDue'] as int? ?? 0;

    final totalPaid = dashboard.totalPaid;
    final totalTransactions = dashboard.totalTransactions;
    final monthlyRent = (tenancy['monthlyRent'] as num? ?? 0).toDouble();

    final bool firstMonthAlreadyPaid = totalTransactions == 1 &&
        totalPaid >= monthlyRent &&
        totalPaid > 0;

    final bool rentDue = tenancy['rentDue'] == true && !firstMonthAlreadyPaid;
    final bool showAsOverdue = rentDue && daysUntilDue < 0;

    final int adjustedDaysUntilDue = firstMonthAlreadyPaid
        ? (daysUntilDue.abs() + 30)
        : daysUntilDue;

    final gradient = showAsOverdue
        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
        : [const Color(0xFF7C3AED), const Color(0xFF9F7AEA)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  (showAsOverdue ? _HP.danger : _HP.purple).withOpacity(0.35),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            showAsOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.home_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                showAsOverdue ? 'Rent Overdue' : 'Your Room',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                tenancy['propertyTitle'] ?? 'Property',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            tenancy['status'] ?? 'ACTIVE',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Location + Room
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          tenancy['propertyCity'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.meeting_room_rounded,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Room ${tenancy['roomNumber'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Rent + Due info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Next Rent',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    )),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${(tenancy['nextRentAmount'] ?? 0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Due',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    )),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      adjustedDaysUntilDue < 0
                                          ? Icons.warning_amber_rounded
                                          : Icons.schedule_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        adjustedDaysUntilDue < 0
                                            ? '${adjustedDaysUntilDue.abs()} days late'
                                            : adjustedDaysUntilDue == 0
                                                ? 'Today'
                                                : 'in $adjustedDaysUntilDue days',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                    const SizedBox(height: 14),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () {
                                if (dashboard.upcomingPayments.isNotEmpty) {
                                  final invoiceId = dashboard
                                      .upcomingPayments.first['invoiceId'];
                                  _showRentPaymentSheet(context, invoiceId);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: showAsOverdue
                                    ? _HP.danger
                                    : _HP.purple,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.payment_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pay Rent Now',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 46,
                          width: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              _navigateToScreen(const MyRentalsScreen());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                            ),
                            child: const Icon(Icons.description_rounded,
                                size: 20),
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
      ),
    );
  }

  // ============================================================
  // 3. QUICK ACTIONS (NEW — professional chips row)
  // ============================================================
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      {
        'icon': Icons.search_rounded,
        'label': 'Explore',
        'color': _HP.studentPrimary,
        'onTap': () => _navigateToTab(1),
      },
      {
        'icon': Icons.movie_creation_rounded,
        'label': 'Reels',
        'color': _HP.pink,
        'onTap': () => _navigateToTab(2),
      },
      {
        'icon': Icons.book_online_rounded,
        'label': 'Bookings',
        'color': _HP.purple,
        'onTap': () => _navigateToScreen(const MyRentalsScreen()),
      },
      {
        'icon': Icons.workspace_premium_rounded,
        'label': 'Offers',
        'color': _HP.orange,
        'onTap': () => _navigateToScreen(const FirstBookingDiscountScreen()),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final color = action['color'] as Color;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < actions.length - 1 ? 10 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  (action['onTap'] as VoidCallback)();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? _HP.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.18),
                              color.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // 4. WALLET CARD
  // ============================================================
  Widget _buildWalletCard(
    BuildContext context,
    bool isDark,
    UserDashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _navigateToScreen(const ReferAndEarnScreen()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _HP.purple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Balance',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          dashboard.walletBalance.toStringAsFixed(2),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.share_rounded,
                      color: Color(0xFF7C3AED),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Refer',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
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

  // ============================================================
  // 5. OFFER BANNER
  // ============================================================
  Widget _buildOfferBanner(BuildContext context, bool isDark) {
    final offers = [
      {
        'title': '🎉 20% OFF First Booking!',
        'subtitle': 'Use code: FIRST20',
        'color': _HP.purple,
        'icon': Icons.local_offer_rounded,
        'type': 'FIRST',
      },
      {
        'title': '🏠 Refer & Earn ₹19!',
        'subtitle': 'Share with friends',
        'color': _HP.studentPrimary,
        'icon': Icons.share_rounded,
        'type': 'REFER',
      },
      {
        'title': '🌟 Premium at 10% OFF',
        'subtitle': 'Limited time offer',
        'color': _HP.orange,
        'icon': Icons.workspace_premium_rounded,
        'type': 'PREMIUM',
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return GestureDetector(
            onTap: () {
              final type = offer['type'];
              if (type == 'REFER') {
                _navigateToScreen(const ReferAndEarnScreen());
              } else if (type == 'FIRST') {
                _navigateToScreen(const FirstBookingDiscountScreen());
              } else {
                _navigateToTab(1);
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width - 80,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    offer['color'] as Color,
                    (offer['color'] as Color).withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (offer['color'] as Color).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      offer['icon'] as IconData,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offer['title'] as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offer['subtitle'] as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 6. CATEGORIES
  // ============================================================
  Widget _buildCategories(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Browse by Type',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToTab(1),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: _HP.studentPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final c = _categories[index];
                return _categoryItem(
                    context, c['name'], c['image'], c['color'], isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(
    BuildContext context,
    String name,
    String imagePath,
    Color color,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Provider.of<PropertyProvider>(context, listen: false)
            .searchProperties(type: name);
        _navigateToTab(1);
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.25), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withOpacity(0.1),
                    child: Icon(Icons.home_rounded, color: color, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 7. TRENDING
  // ============================================================
  Widget _buildTrendingSection(BuildContext context, bool isDark) {
    final provider = Provider.of<PropertyProvider>(context);
    final trending =
        provider.properties.where((p) => p.viewCount > 50).take(6).toList();

    if (trending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Trending Now',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _navigateToTab(1),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: _HP.studentPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trending.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, i) =>
                _trendingSquareCard(context, trending[i], isDark),
          ),
        ],
      ),
    );
  }

  Widget _trendingSquareCard(
      BuildContext context, Property property, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToScreen(
          PropertyDetailScreen(propertyId: property.propertyId)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? _HP.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: property.coverImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: property.coverImage,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.home_rounded,
                              size: 32,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                          )
                        : Icon(
                            Icons.home_rounded,
                            size: 32,
                            color:
                                isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Colors.white, size: 9),
                        const SizedBox(width: 2),
                        Text(
                          'TRENDING',
                          style: GoogleFonts.poppins(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded,
                            color: Colors.white, size: 9),
                        const SizedBox(width: 2),
                        Text(
                          '${property.viewCount}',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
                  Text(
                    property.title,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 10,
                          color:
                              isDark ? Colors.grey[500] : Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.city,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        property.monthlyRentMin != null
                            ? '₹${property.monthlyRentMin!.toStringAsFixed(0)}'
                            : 'Contact',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _HP.studentPrimary,
                        ),
                      ),
                      Text(
                        '/mo',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color:
                              isDark ? Colors.grey[500] : Colors.grey[500],
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

  // ============================================================
  // 8. ANALYTICS
  // ============================================================
  Widget _buildAnalyticsCard(
    BuildContext context,
    bool isDark,
    UserDashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? _HP.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF0F0F8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _HP.studentPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: _HP.studentPrimary, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                if (dashboard.monthlyGrowthPercent != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (dashboard.monthlyGrowthPercent > 0
                              ? _HP.success
                              : _HP.danger)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          dashboard.monthlyGrowthPercent > 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 11,
                          color: dashboard.monthlyGrowthPercent > 0
                              ? _HP.success
                              : _HP.danger,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${dashboard.monthlyGrowthPercent.toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: dashboard.monthlyGrowthPercent > 0
                                ? _HP.success
                                : _HP.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    label: 'Bookings',
                    value: '${dashboard.totalBookings}',
                    icon: Icons.book_online_rounded,
                    color: _HP.studentPrimary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statTile(
                    label: 'Active',
                    value: '${dashboard.activeBookings}',
                    icon: Icons.check_circle_rounded,
                    color: _HP.success,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statTile(
                    label: 'Saved',
                    value: '${dashboard.savedProperties}',
                    icon: Icons.favorite_rounded,
                    color: _HP.pink,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            if (dashboard.monthlyTrend.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Monthly Spend',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF666680),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${dashboard.totalPaid.toStringAsFixed(0)} total',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _HP.studentPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: _buildMiniBarChart(dashboard, isDark),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBarChart(UserDashboardProvider dashboard, bool isDark) {
    final trend = dashboard.monthlyTrend;
    if (trend.isEmpty) return const SizedBox();

    final values =
        trend.map((e) => (e['amount'] as num? ?? 0).toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(trend.length, (i) {
        final amount = values[i];
        final ratio = maxVal > 0 ? amount / maxVal : 0.0;
        final monthLabel =
            trend[i]['month']?.toString().substring(0, 3) ?? '';

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    width: double.infinity,
                    height: (55 * ratio).clamp(4.0, 55.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          _HP.studentPrimary,
                          _HP.studentPrimaryLight
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? Colors.white38 : const Color(0xFFB0B3C0),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // 9. RECENT ACTIVITY
  // ============================================================
  Widget _buildRecentActivity(
    BuildContext context,
    bool isDark,
    UserDashboardProvider dashboard,
  ) {
    final activities = dashboard.recentActivity;
    if (activities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _HP.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF0F0F8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _HP.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded,
                      color: _HP.teal, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      _navigateToScreen(const MyRentalsScreen()),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                  ),
                  child: Text(
                    'My Rentals',
                    style: GoogleFonts.poppins(
                      color: _HP.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...activities
                .take(5)
                .map((a) => _activityTile(a, isDark))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(Map<String, dynamic> item, bool isDark) {
    final color = _hex(item['color']?.toString() ?? '#7C3AED');
    final referenceType = item['referenceType']?.toString() ?? '';

    final bool isRentalActivity = referenceType == 'RENT_PAYMENT' ||
        referenceType == 'RENTAL_AGREEMENT' ||
        item['activityType']?.toString() == 'RENT_PAID';

    return GestureDetector(
      onTap: () {
        if (isRentalActivity) {
          _navigateToScreen(const MyRentalsScreen());
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconFromName(item['icon']?.toString() ?? 'info'),
                color: color,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['description']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color:
                          isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item['timeAgo']?.toString() ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? Colors.white38 : const Color(0xFFB0B3C0),
                  ),
                ),
                if (isRentalActivity)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: _HP.teal,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'payment':
        return Icons.payment_rounded;
      case 'booking':
        return Icons.book_online_rounded;
      case 'check':
        return Icons.check_circle_rounded;
      case 'cancel':
        return Icons.cancel_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'visibility':
        return Icons.visibility_rounded;
      case 'contract':
        return Icons.description_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _hex(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return _HP.purple;
    }
  }

  // ============================================================
  // 10. POPULAR CITIES
  // ============================================================
  Widget _buildPopularCities(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city_rounded,
                  color: _HP.studentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Popular Cities',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _popularCities
                .map((city) => _cityChip(context, city, isDark))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _cityChip(
      BuildContext context, Map<String, dynamic> city, bool isDark) {
    return GestureDetector(
      onTap: () {
        Provider.of<PropertyProvider>(context, listen: false)
            .searchProperties(city: city['name']);
        _navigateToTab(1);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? _HP.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFF0F0F8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(city['emoji'], style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  city['count'],
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color:
                        isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 11. TRUST BADGES
  // ============================================================
  Widget _buildTrustBadges(BuildContext context, bool isDark) {
    final badges = [
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Verified Owners',
        'color': _HP.success,
      },
      {
        'icon': Icons.lock_rounded,
        'title': 'Secure Payments',
        'color': _HP.studentPrimary,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': '24x7 Support',
        'color': _HP.purple,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _HP.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF0F0F8),
          ),
        ),
        child: Row(
          children: badges.map((b) {
            return Expanded(
              child: Column(
                children: [
                  Icon(b['icon'] as IconData,
                      color: b['color'] as Color, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    b['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF666680),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // 12. SUPPORT CTA
  // ============================================================
  Widget _buildSupportCTA(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _navigateToTab(4),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1F33), const Color(0xFF141A2C)]
                  : [const Color(0xFFF0F4FF), const Color(0xFFE0E7FF)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _HP.studentPrimary.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _HP.studentPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: _HP.studentPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need help?',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      'Chat with our support team 24x7',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF8A8FA3),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _HP.studentPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  void _showRentPaymentSheet(BuildContext context, int invoiceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RentPaymentSheet(invoiceId: invoiceId),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// RENT PAYMENT SHEET (unchanged)
// ══════════════════════════════════════════════════════════════
class _RentPaymentSheet extends StatefulWidget {
  final int invoiceId;
  const _RentPaymentSheet({required this.invoiceId});

  @override
  State<_RentPaymentSheet> createState() => _RentPaymentSheetState();
}

class _RentPaymentSheetState extends State<_RentPaymentSheet> {
  Razorpay? _razorpay;
  bool _isInitiating = false;
  bool _paymentSuccess = false;
  String? _errorMessage;
  String? _utr;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      final provider =
          Provider.of<UserDashboardProvider>(context, listen: false);
      final result = await provider.initiateRentPayment(widget.invoiceId);

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isInitiating = false;
          _errorMessage = provider.error ?? 'Failed to initiate payment';
        });
        return;
      }

      final double rawAmount = (result['amount'] as num?)?.toDouble() ?? 0;
      final int amountInPaise =
          rawAmount < 10000 ? (rawAmount * 100).round() : rawAmount.round();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final options = {
        'key': AppConstants.razorpayKeyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'order_id': result['razorpayOrderId']?.toString() ?? '',
        'name': AppConstants.appName,
        'description': 'Monthly Rent Payment',
        'prefill': {
          'contact': authProvider.user?.phone ?? '',
          'email': authProvider.user?.email ?? '',
        },
        'theme': {'color': '#7C3AED'},
        'retry': {
          'enabled': true,
          'max_count': 2,
        },
        'timeout': 300,
      };

      _razorpay!.open(options);
    } catch (e) {
      debugPrint('❌ Payment initiate error: $e');
      if (mounted) {
        setState(() {
          _isInitiating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final provider =
        Provider.of<UserDashboardProvider>(context, listen: false);

    final confirmed = await provider.confirmRentPayment(
      razorpayOrderId: response.orderId!,
      razorpayPaymentId: response.paymentId!,
      razorpaySignature: response.signature!,
    );

    if (!mounted) return;

    if (confirmed) {
      setState(() {
        _isInitiating = false;
        _paymentSuccess = true;
      });
      provider.loadSummary(showLoader: false);
    } else {
      setState(() {
        _isInitiating = false;
        _errorMessage = provider.error ?? 'Payment confirmation failed';
      });
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() {
      _isInitiating = false;
      _errorMessage = response.message ?? 'Payment failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_paymentSuccess) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? _HP.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _HP.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 56, color: _HP.success),
            ),
            const SizedBox(height: 20),
            Text(
              'Rent Paid!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your rent has been paid successfully.\nOwner will receive payout automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            if (_utr != null) ...[
              const SizedBox(height: 4),
              Text('Ref: $_utr',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[400])),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyRentalsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _HP.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('View My Rentals',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Done',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    )),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? _HP.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE0E0E8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payment_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pay Rent',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'You will be redirected to Razorpay secure checkout to complete the payment.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                height: 1.5,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _HP.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: _HP.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _HP.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isInitiating ? null : _initiatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _HP.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isInitiating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Proceed to Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}