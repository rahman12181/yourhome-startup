// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yourhome/models/property_model.dart';
import 'package:yourhome/providers/notification_provider.dart';
import 'package:yourhome/screens/admin/admin_profile_screen.dart';
import 'package:yourhome/screens/booking/first_booking_discount_screen.dart';
import 'package:yourhome/screens/owner/owner_profile_screen.dart';
import 'package:yourhome/screens/reels/reels_feed_screen.dart';
import 'package:yourhome/screens/refer_and_earn_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/property_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/user_dashboard_provider.dart';

// ==================== STUDENT PANEL ====================
import 'properties_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'property_detail_screen.dart';
import 'chat/chat_list_screen.dart';
import 'notifications/notification_screen.dart';

// ==================== OWNER PANEL ====================
import 'owner/owner_dashboard_page.dart';
import 'owner/owner_property_management_page.dart';
import 'owner/owner_booking_management_page.dart';

// ==================== ADMIN PANEL ====================
import 'admin/admin_dashboard_page.dart';
import 'admin/admin_user_management_page.dart';
import 'admin/admin_property_management_page.dart';

// ==================== DESIGN TOKENS ====================
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

// ==================== HOME SCREEN (Bottom Nav) ====================
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDark,
    required String userRole,
  }) {
    final isSelected = _selectedIndex == index;
    final primaryColor = _getPrimaryColor(userRole);
    final bool isReelsTab = index == 2;
    final Color selectedColor = isReelsTab ? _HP.orange : primaryColor;
    final Color? unselectedColor = isReelsTab
        ? (isDark ? Colors.grey[400]! : Colors.grey[400]!)
        : (isDark ? Colors.grey[500] : Colors.grey[400]);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isSelected ? selectedColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: selectedColor.withOpacity(0.2), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: isSelected ? 24 : 22,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSelected ? 9 : 8,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? selectedColor
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        if (isDark) {
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF0A0E1A),
            systemNavigationBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ));
        } else {
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ));
        }
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: useDark
            ? const Color(0xFF1A1F33)
            : (isDark ? _HP.darkSurface : Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(useDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(pages.length, (index) {
              return _buildNavItem(
                icon: icons[index],
                activeIcon: activeIcons[index],
                label: labels[index],
                index: index,
                isDark: useDark,
                userRole: 'STUDENT',
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerBottomNav(
    bool isDark,
    List<Widget> pages,
    List<String> labels,
    List<IconData> icons,
    List<IconData> activeIcons,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: (isDark ? _HP.darkSurfaceElevated : Colors.white)
                  .withOpacity(isDark ? 0.78 : 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _HP.ownerPrimary.withOpacity(0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _HP.ownerPrimary.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / pages.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * _selectedIndex + 8,
                      top: 8,
                      width: itemWidth - 16,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_HP.ownerPrimary, _HP.ownerGold],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _HP.ownerPrimary.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
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
                              height: 68,
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
                                    duration:
                                        const Duration(milliseconds: 200),
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

  Widget _buildAdminBottomNav(
    bool isDark,
    List<Widget> pages,
    List<String> labels,
    List<IconData> icons,
    List<IconData> activeIcons,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: (isDark ? _HP.darkSurfaceElevated : Colors.white)
                  .withOpacity(isDark ? 0.78 : 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _HP.adminPrimary.withOpacity(0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _HP.adminPrimary.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / pages.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * _selectedIndex + 8,
                      top: 8,
                      width: itemWidth - 16,
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
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _HP.adminPrimary.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
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
                              height: 68,
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
                                    duration:
                                        const Duration(milliseconds: 200),
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
          child: pages[_selectedIndex],
        ),
        bottomNavigationBar: ScaleTransition(
          scale: _navAnimation,
          child: bottomNav,
        ),
      ),
    );
  }
}

// ==================== HOME PAGE (STUDENT) — PRODUCTION READY ====================
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

      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      if (propertyProvider.properties.isEmpty) {
        propertyProvider.searchProperties();
      }

      final userDashboard = Provider.of<UserDashboardProvider>(context, listen: false);
      await userDashboard.loadSummary(showLoader: false);

      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notifProvider.loadUnreadCount();

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loadUnreadCount();

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
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animated(0, _buildHeader(context, isDark, user, profileImage, dashboard)),
                const SizedBox(height: 12),
                _animated(1, _buildSearchBar(context, isDark)),

                if (dashboard.hasActiveTenancy) ...[
                  const SizedBox(height: 16),
                  _animated(2, _buildActiveRentalCard(context, isDark, dashboard)),
                ],

                const SizedBox(height: 16),
                _animated(3, _buildWalletCard(context, isDark, dashboard)),

                const SizedBox(height: 16),
                _animated(4, _buildOfferBanner(context, isDark)),

                const SizedBox(height: 20),
                _animated(5, _buildAnalyticsCard(context, isDark, dashboard)),

                const SizedBox(height: 24),
                _animated(6, _buildCategories(context, isDark)),

                const SizedBox(height: 24),
                _animated(7, _buildTrendingSection(context, isDark)),

                const SizedBox(height: 24),
                _animated(8, _buildRecentActivity(context, isDark, dashboard)),

                const SizedBox(height: 24),
                _animated(9, _buildPopularCities(context, isDark)),

                const SizedBox(height: 24),
                _animated(10, _buildTrustBadges(context, isDark)),

                const SizedBox(height: 24),
                _animated(11, _buildSupportCTA(context, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                        colors: [_HP.studentPrimary, _HP.studentPrimaryLight],
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
                backgroundImage:
                    hasImage ? CachedNetworkImageProvider(profileImage!) : null,
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
              color: Colors.black.withOpacity(0.05),
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
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
  // SEARCH BAR
  // ============================================================
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _navigateToTab(1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? _HP.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _HP.studentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search_rounded,
                    color: _HP.studentPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Search PG, Hostel, Flat...',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _HP.studentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: _HP.studentPrimary, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVE RENTAL CARD
  // ============================================================
  Widget _buildActiveRentalCard(
    BuildContext context,
    bool isDark,
    UserDashboardProvider dashboard,
  ) {
    final tenancy = dashboard.currentTenancy!;
    final daysUntilDue = tenancy['daysUntilDue'] as int? ?? 0;
    final rentDue = tenancy['rentDue'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: rentDue
                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                : [const Color(0xFF7C3AED), const Color(0xFF9F7AEA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (rentDue ? _HP.danger : _HP.purple).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
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
                  child: Icon(
                    rentDue ? Icons.warning_amber_rounded : Icons.home_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rentDue ? '⚠️ Rent Overdue' : '🏠 Your Active Room',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tenancy['status'] ?? 'ACTIVE',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tenancy['propertyTitle'] ?? 'Property',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(
                  tenancy['propertyCity'] ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.meeting_room_rounded,
                    color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Room ${tenancy['roomNumber'] ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Next Rent',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${(tenancy['nextRentAmount'] ?? 0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withOpacity(0.2)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Due',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(
                          daysUntilDue < 0
                              ? '${daysUntilDue.abs()} days late'
                              : daysUntilDue == 0
                                  ? 'Today'
                                  : 'in $daysUntilDue days',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (dashboard.upcomingPayments.isNotEmpty) {
                    final invoiceId =
                        dashboard.upcomingPayments.first['invoiceId'];
                    _showRentPaymentSheet(context, invoiceId);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: rentDue ? _HP.danger : _HP.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Pay Rent Now',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WALLET CARD
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _HP.purple.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet Balance',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70)),
                        const SizedBox(width: 2),
                        Text(
                          dashboard.walletBalance.toStringAsFixed(2),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.share_rounded,
                        color: _HP.purple, size: 14),
                    const SizedBox(width: 4),
                    Text('Refer',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _HP.purple)),
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
  // ANALYTICS CARD
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
        final monthLabel = trend[i]['month']?.toString().substring(0, 3) ?? '';

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
                        colors: [_HP.studentPrimary, _HP.studentPrimaryLight],
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
                    color: isDark ? Colors.white38 : const Color(0xFFB0B3C0),
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
  // OFFER BANNER
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
                    child: Icon(offer['icon'] as IconData,
                        color: Colors.white, size: 22),
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
                              color: Colors.white70, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white70, size: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CATEGORIES
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
                  fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
  // TRENDING — SQUARE BOXES
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
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _navigateToTab(1),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: Text('See All',
                    style: GoogleFonts.poppins(
                        color: _HP.studentPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12)),
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
              color: Colors.black.withOpacity(0.05),
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
                                    : Colors.grey[400]),
                          )
                        : Icon(Icons.home_rounded,
                            size: 32,
                            color:
                                isDark ? Colors.grey[600] : Colors.grey[400]),
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
  // RECENT ACTIVITY
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
              ],
            ),
            const SizedBox(height: 12),
            ...activities.take(5).map((a) => _activityTile(a, isDark)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(Map<String, dynamic> item, bool isDark) {
    final color = _hex(item['color']?.toString() ?? '#7C3AED');
    return Padding(
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
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item['timeAgo']?.toString() ?? '',
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : const Color(0xFFB0B3C0),
            ),
          ),
        ],
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
  // POPULAR CITIES
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
                  fontWeight: FontWeight.w600,
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
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
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
  // TRUST BADGES
  // ============================================================
  Widget _buildTrustBadges(BuildContext context, bool isDark) {
    final badges = [
      {'icon': Icons.verified_user_rounded, 'title': 'Verified Owners', 'color': _HP.success},
      {'icon': Icons.lock_rounded, 'title': 'Secure Payments', 'color': _HP.studentPrimary},
      {'icon': Icons.support_agent_rounded, 'title': '24x7 Support', 'color': _HP.purple},
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
                      color: isDark ? Colors.white70 : const Color(0xFF666680),
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
  // SUPPORT CTA
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
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      'Chat with our support team 24x7',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF8A8FA3),
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

  // ============================================================
  // RENT PAYMENT SHEET
  // ============================================================
  void _showRentPaymentSheet(BuildContext context, int invoiceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RentPaymentSheet(invoiceId: invoiceId),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _loadingShimmer(bool isDark) {
    return Column(
      children: List.generate(2, (_) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? _HP.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _emptyWidget(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _HP.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.home_outlined,
              size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== RENT PAYMENT SHEET ====================
class _RentPaymentSheet extends StatefulWidget {
  final int invoiceId;
  const _RentPaymentSheet({required this.invoiceId});

  @override
  State<_RentPaymentSheet> createState() => _RentPaymentSheetState();
}

class _RentPaymentSheetState extends State<_RentPaymentSheet> {
  bool _isInitiating = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          valueColor: AlwaysStoppedAnimation(Colors.white),
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
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    setState(() => _isInitiating = true);

    try {
      final provider = Provider.of<UserDashboardProvider>(context, listen: false);
      final result = await provider.initiateRentPayment(widget.invoiceId);

      if (mounted && result != null) {
        // TODO: Open Razorpay checkout with result['razorpayOrderId']
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order created: ${result['razorpayOrderId']}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: _HP.purple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}

    if (mounted) setState(() => _isInitiating = false);
  }
}