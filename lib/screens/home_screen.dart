// ignore_for_file: deprecated_member_use

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
import 'package:yourhome/screens/admin/admin_users_screen.dart';
import 'package:yourhome/screens/booking/first_booking_discount_screen.dart';
import 'package:yourhome/screens/reels/reels_feed_screen.dart';
import 'package:yourhome/screens/refer_and_earn_screen.dart';
import 'package:yourhome/screens/rental/my_rentals_screen.dart';
import 'package:yourhome/utils/constants.dart';

import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/user_dashboard_provider.dart';

import 'properties_screen.dart';
import 'profile_screen.dart';
import 'property_detail_screen.dart';
import 'chat/chat_list_screen.dart';
import 'notifications/notification_screen.dart';

import 'owner/owner_dashboard_page.dart';
import 'owner/owner_property_management_page.dart';
import 'owner/owner_booking_management_page.dart';

import 'admin/admin_dashboard_page.dart';
import 'admin/admin_property_management_page.dart';

// ══════════════════════════════════════════════════════════════
// GLOBAL ROUTE OBSERVER
// ══════════════════════════════════════════════════════════════
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// ══════════════════════════════════════════════════════════════
// PALETTE
// ══════════════════════════════════════════════════════════════
class _HP {
  static const primary = Color(0xFF1E5EFF);
  static const primaryLight = Color(0xFF4B7BFF);
  static const primarySoft = Color(0xFFEBF1FF);

  // Student nav active blue
  static const navBlue = Color(0xFF0F13E4);
  static const navDarkBg = Color(0xFF15192B);

  static const ownerPrimary = Color(0xFFF59E0B);
  static const ownerGold = Color(0xFFD4AF37);
  static const adminPrimary = Color(0xFF7C3AED);
  static const adminPrimaryLight = Color(0xFF8B5CF6);

  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFF9F7AEA);
  static const pink = Color(0xFFEC4899);
  static const orange = Color(0xFFF59E0B);
  static const teal = Color(0xFF14B8A6);
  static const cyan = Color(0xFF06B6D4);

  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const darkSurfaceElevated = Color(0xFF1B2338);

  static const lightBg = Color(0xFFF7F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFEDEFF5);
  static const lightTextPrimary = Color(0xFF0B1220);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextTertiary = Color(0xFF9CA3AF);
}

// ══════════════════════════════════════════════════════════════
// HOME SCREEN (Root)
// ══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();

  static final GlobalKey<HomeScreenState> navigatorKey =
      GlobalKey<HomeScreenState>();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const int tabHome = 0;
  static const int tabExplore = 1;
  static const int tabReels = 2;
  static const int tabProfile = 3;

  int _selectedIndex = 0;
  DateTime? _lastPressed;

  late final AnimationController _navAnimationController;
  late final Animation<double> _navAnimation;

  @override
  void initState() {
    super.initState();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 450),
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
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  Future<bool> _onWillPop() async {
    final role =
        Provider.of<AuthProvider>(context, listen: false).user?.role ??
            'STUDENT';
    if (_selectedIndex != 0 && role != 'ADMIN' && role != 'OWNER') {
      setState(() => _selectedIndex = 0);
      return false;
    }

    final now = DateTime.now();
    if (_lastPressed == null ||
        now.difference(_lastPressed!) > const Duration(seconds: 2)) {
      _lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Press back again to exit',
                  style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }
    return true;
  }

  List<Widget> _getPages(String role) {
    switch (role) {
      case 'ADMIN':
        return const [
          AdminDashboardPage(),
          AdminUsersScreen(),
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
          ProfileScreen(),
        ];
    }
  }

  List<_NavSpec> _getNavSpecs(String role) {
    switch (role) {
      case 'ADMIN':
        return const [
          _NavSpec('Dashboard', Icons.dashboard_outlined,
              Icons.dashboard_rounded),
          _NavSpec('Users', Icons.people_outline_rounded,
              Icons.people_rounded),
          _NavSpec('Properties', Icons.apartment_outlined,
              Icons.apartment_rounded),
          _NavSpec('Profile', Icons.person_outline_rounded,
              Icons.person_rounded),
        ];
      case 'OWNER':
        return const [
          _NavSpec('Dashboard', Icons.dashboard_outlined,
              Icons.dashboard_rounded),
          _NavSpec('Properties', Icons.apartment_outlined,
              Icons.apartment_rounded),
          _NavSpec('Bookings', Icons.book_online_outlined,
              Icons.book_online_rounded),
          _NavSpec('Chat', Icons.chat_bubble_outline_rounded,
              Icons.chat_bubble_rounded),
        ];
      default:
        return const [
          _NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
          _NavSpec('Explore', Icons.search_rounded, Icons.search_rounded),
          _NavSpec('Reels', Icons.movie_creation_outlined,
              Icons.movie_creation_rounded),
          _NavSpec('Profile', Icons.person_outline_rounded,
              Icons.person_rounded),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final user = authProvider.user;
    final userRole = user?.role ?? 'STUDENT';
    final isStudent = userRole != 'OWNER' && userRole != 'ADMIN';

    final pages = _getPages(userRole);
    final specs = _getNavSpecs(userRole);

    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    final bool reelsOpen = isStudent && _selectedIndex == tabReels;
    final bool navDark = reelsOpen ? true : isDark;
    final Color scaffoldBg = reelsOpen
        ? Colors.black
        : (isDark ? _HP.darkBg : _HP.lightBg);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: navDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: navDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: scaffoldBg,
      systemNavigationBarIconBrightness:
          navDark ? Brightness.light : Brightness.dark,
    ));

    final Widget bottomNav;
    switch (userRole) {
      case 'OWNER':
        bottomNav = _RoleNavBar(
          specs: specs,
          selectedIndex: _selectedIndex,
          isDark: isDark,
          accent: const Color.fromARGB(255, 315, 19, 228),
          gradient: const [Color.fromARGB(255, 15, 19, 228), Color.fromARGB(255, 15, 19, 228)],
          onTap: changeTab,
        );
        break;
      case 'ADMIN':
        bottomNav = _RoleNavBar(
          specs: specs,
          selectedIndex: _selectedIndex,
          isDark: isDark,
          accent: _HP.adminPrimary,
          gradient: const [_HP.adminPrimary, _HP.adminPrimaryLight],
          onTap: changeTab,
        );
        break;
      default:
        bottomNav = _StudentNavBar(
          specs: specs,
          selectedIndex: _selectedIndex,
          dark: navDark,
          profileIndex: tabProfile,
          profileImage: profileProvider.profile?.profilePic,
          userInitial: (user?.name?.isNotEmpty == true)
              ? user!.name[0].toUpperCase()
              : 'U',
          onTap: (i) {
            HapticFeedback.lightImpact();
            changeTab(i);
          },
        );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: HomeScreen.navigatorKey,
        backgroundColor: scaffoldBg,
        extendBody: userRole == 'OWNER',
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('${userRole}_$_selectedIndex'),
            child: pages[_selectedIndex],
          ),
        ),
        bottomNavigationBar: FadeTransition(
          opacity: _navAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.4),
              end: Offset.zero,
            ).animate(_navAnimation),
            child: bottomNav,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// NAV MODEL
// ══════════════════════════════════════════════════════════════
class _NavSpec {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavSpec(this.label, this.icon, this.activeIcon);
}

// ══════════════════════════════════════════════════════════════
// STUDENT BOTTOM NAV — Blue active
// ══════════════════════════════════════════════════════════════
class _StudentNavBar extends StatelessWidget {
  final List<_NavSpec> specs;
  final int selectedIndex;
  final bool dark;
  final int profileIndex;
  final String? profileImage;
  final String userInitial;
  final ValueChanged<int> onTap;

  const _StudentNavBar({
    required this.specs,
    required this.selectedIndex,
    required this.dark,
    required this.profileIndex,
    required this.profileImage,
    required this.userInitial,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = dark ? _HP.navDarkBg : Colors.white;
    final inactive =
        dark ? const Color(0xFF8A93A6) : const Color(0xFF8E9BB5);

    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.45 : 0.10),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(specs.length, (i) {
              final selected = i == selectedIndex;
              return _StudentNavItem(
                spec: specs[i],
                selected: selected,
                inactiveColor: inactive,
                isProfile: i == profileIndex,
                profileImage: profileImage,
                userInitial: userInitial,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StudentNavItem extends StatelessWidget {
  final _NavSpec spec;
  final bool selected;
  final Color inactiveColor;
  final bool isProfile;
  final String? profileImage;
  final String userInitial;
  final VoidCallback onTap;

  const _StudentNavItem({
    required this.spec,
    required this.selected,
    required this.inactiveColor,
    required this.isProfile,
    required this.profileImage,
    required this.userInitial,
    required this.onTap,
  });

  Widget _leading() {
    if (!isProfile) {
      return Icon(
        selected ? spec.activeIcon : spec.icon,
        size: 24,
        color: selected ? Colors.white : inactiveColor,
      );
    }

    final hasImage = profileImage != null && profileImage!.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasImage
            ? Colors.transparent
            : (selected ? Colors.white24 : inactiveColor.withOpacity(0.18)),
        border: Border.all(
          color: selected ? Colors.white : inactiveColor.withOpacity(0.6),
          width: 1.6,
        ),
        image: hasImage
            ? DecorationImage(
                image: CachedNetworkImageProvider(profileImage!,
                    cacheKey: profileImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : Text(
              userInitial,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : inactiveColor,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 14),
        decoration: BoxDecoration(
          color: selected ? _HP.navBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _HP.navBlue.withOpacity(0.40),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _leading(),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        spec.label,
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// OWNER / ADMIN NAV
// ══════════════════════════════════════════════════════════════
class _RoleNavBar extends StatelessWidget {
  final List<_NavSpec> specs;
  final int selectedIndex;
  final bool isDark;
  final Color accent;
  final List<Color> gradient;
  final ValueChanged<int> onTap;

  const _RoleNavBar({
    required this.specs,
    required this.selectedIndex,
    required this.isDark,
    required this.accent,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final idleColor = isDark ? Colors.grey[400] : _HP.lightTextTertiary;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: (isDark ? _HP.darkSurfaceElevated : Colors.white)
                  .withOpacity(isDark ? 0.82 : 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: accent.withOpacity(isDark ? 0.20 : 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(isDark ? 0.15 : 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / specs.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * selectedIndex + 10,
                      top: 10,
                      width: itemWidth - 20,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(specs.length, (index) {
                        final selected = selectedIndex == index;
                        final color = selected ? Colors.white : idleColor;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onTap(index);
                            },
                            child: SizedBox(
                              height: 72,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    duration:
                                        const Duration(milliseconds: 260),
                                    curve: Curves.easeOutCubic,
                                    scale: selected ? 1.1 : 1.0,
                                    child: Icon(
                                      selected
                                          ? specs[index].activeIcon
                                          : specs[index].icon,
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  AnimatedDefaultTextStyle(
                                    duration:
                                        const Duration(milliseconds: 220),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: color,
                                    ),
                                    child: Text(specs[index].label),
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
}

// ══════════════════════════════════════════════════════════════
// HOME PAGE
// ══════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, RouteAware {
  late final AnimationController _staggerController;

  // ✅ UPDATED: 4px — same as hero card (SafeArea ke andar almost full width)
  static const double _hPad = 4.0;

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'PG', 'image': 'assets/images/pg.jpg', 'color': _HP.primary},
    {'name': 'Hostel', 'image': 'assets/images/hostel.jpg', 'color': _HP.purple},
    {'name': 'Hotel', 'image': 'assets/images/hotel.jpg', 'color': _HP.orange},
    {'name': 'Flat', 'image': 'assets/images/flats.png', 'color': _HP.success},
    {'name': 'Villa', 'image': 'assets/images/villa.png', 'color': _HP.cyan},
    {'name': 'Resort', 'image': 'assets/images/restourent.png', 'color': _HP.pink},
  ];

  static const List<Map<String, dynamic>> _popularCities = [
    {'name': 'Delhi', 'icon': Icons.account_balance_rounded, 'count': '240+ PGs'},
    {'name': 'Noida', 'icon': Icons.location_city_rounded, 'count': '180+ PGs'},
    {'name': 'Gurgaon', 'icon': Icons.apartment_rounded, 'count': '210+ PGs'},
    {'name': 'Mumbai', 'icon': Icons.water_rounded, 'count': '320+ PGs'},
    {'name': 'Bangalore', 'icon': Icons.park_rounded, 'count': '450+ PGs'},
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _staggerController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    if (!mounted) return;
    try {
      await Provider.of<ProfileProvider>(context, listen: false).getProfile();
    } catch (_) {}
  }

  Future<void> _loadAll() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      if (propertyProvider.properties.isEmpty) {
        propertyProvider.searchProperties();
      }

      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.profile == null) {
        try {
          await profileProvider.getProfile();
        } catch (_) {}
      }

      if (!mounted) return;
      await Provider.of<UserDashboardProvider>(context, listen: false)
          .loadSummary(showLoader: false);

      if (!mounted) return;
      await Provider.of<NotificationProvider>(context, listen: false)
          .loadUnreadCount();

      if (!mounted) return;
      await Provider.of<ChatProvider>(context, listen: false)
          .loadUnreadCount();

      if (!mounted) return;
      await Provider.of<ReferralProvider>(context, listen: false)
          .fetchReferralInfo();

      if (mounted) _staggerController.forward(from: 0);
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _navigateToTab(int index) {
    HomeScreen.navigatorKey.currentState?.changeTab(index);
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
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 360),
      ),
    );
  }

  Widget _animated(int index, Widget child) {
    final delay = index * 0.05;
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (_, __) {
        final raw = _staggerController.value - delay;
        final t =
            Curves.easeOutCubic.transform(raw.clamp(0.0, 1.0).toDouble());
        return Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }

  Color _surface(bool isDark) =>
      isDark ? _HP.darkSurface : _HP.lightSurface;
  Color _border(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.06) : _HP.lightBorder;
  Color _textPrimary(bool isDark) =>
      isDark ? Colors.white : _HP.lightTextPrimary;
  Color _textSecondary(bool isDark) =>
      isDark ? Colors.white70 : _HP.lightTextSecondary;
  Color _textTertiary(bool isDark) =>
      isDark ? Colors.white38 : _HP.lightTextTertiary;

  BoxDecoration _cardDeco(bool isDark,
      {double radius = 20, double shadow = 0.04}) {
    return BoxDecoration(
      color: _surface(isDark),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border(isDark)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.20 : shadow),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _sectionHeader(
    bool isDark, {
    required String title,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onAction,
    String actionLabel = 'See All',
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? _HP.primary, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary(isDark),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                color: _HP.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthProvider>(context).user;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profileImage = profileProvider.profile?.profilePic;
    final dashboard = Provider.of<UserDashboardProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? _HP.darkBg : _HP.lightBg,
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            final pp = Provider.of<PropertyProvider>(context, listen: false);
            await pp.searchProperties();
            await profileProvider.getProfile();
            await dashboard.loadSummary(showLoader: false);
          },
          color: _HP.primary,
          backgroundColor: isDark ? _HP.darkSurface : Colors.white,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animated(
                  0,
                  _buildTopBar(context, isDark, user, profileImage, dashboard),
                ),
                const SizedBox(height: 20),
                _animated(1, _buildHeroCard(context, isDark)),
                const SizedBox(height: 22),
                if (dashboard.hasActiveTenancy) ...[
                  _animated(
                      2, _buildRentalWidget(context, isDark, dashboard)),
                  const SizedBox(height: 22),
                ],
                _animated(3, _buildQuickActions(context, isDark)),
                const SizedBox(height: 22),
                _animated(4, _buildWalletCard(context, isDark, dashboard)),
                const SizedBox(height: 22),
                _animated(5, _buildOfferBanner(context, isDark)),
                const SizedBox(height: 26),
                _animated(6, _buildCategories(context, isDark)),
                const SizedBox(height: 26),
                _animated(7, _buildTrendingSection(context, isDark)),
                const SizedBox(height: 26),
                _animated(8, _buildAnalyticsCard(context, isDark, dashboard)),
                const SizedBox(height: 26),
                _animated(9, _buildRecentActivity(context, isDark, dashboard)),
                const SizedBox(height: 26),
                _animated(10, _buildPopularCities(context, isDark)),
                const SizedBox(height: 26),
                _animated(11, _buildTrustBadges(context, isDark)),
                const SizedBox(height: 26),
                _animated(12, _buildSupportCTA(context, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================
  Widget _buildTopBar(
    BuildContext context,
    bool isDark,
    dynamic user,
    String? profileImage,
    UserDashboardProvider dashboard,
  ) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad + 12, 12, _hPad + 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToTab(HomeScreenState.tabProfile),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasImage
                    ? null
                    : const LinearGradient(
                        colors: [_HP.primary, _HP.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: hasImage ? _surface(isDark) : null,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : _HP.lightBorder,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _HP.primary.withOpacity(isDark ? 0.25 : 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 23,
                backgroundColor: Colors.transparent,
                backgroundImage: hasImage
                    ? CachedNetworkImageProvider(profileImage,
                        cacheKey: profileImage)
                    : null,
                child: hasImage
                    ? null
                    : Text(
                        user?.name?.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
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
                    color: _textSecondary(isDark),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name?.isNotEmpty == true ? user!.name : 'Guest',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary(isDark),
                    letterSpacing: -0.3,
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
            onTap: () => _navigateToScreen(const ChatListScreen()),
          ),
          const SizedBox(width: 10),
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
          color: _surface(isDark),
          shape: BoxShape.circle,
          border: Border.all(color: _border(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.03),
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
                color: isDark ? Colors.white70 : _HP.lightTextPrimary,
                size: 20,
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
  // HERO CARD — full width, rounded, SafeArea ke andar
  // ============================================================
  Widget _buildHeroCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1B2338), const Color(0xFF141A2C)]
                : [_HP.primary, _HP.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : _HP.primary)
                  .withOpacity(isDark ? 0.30 : 0.28),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(isDark ? 0.03 : 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(isDark ? 0.02 : 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Nestora',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white70
                          : Colors.white.withOpacity(0.85),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Find your perfect\nstay today',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Handpicked PGs, hostels, flats & more\nacross India',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white60
                          : Colors.white.withOpacity(0.80),
                      height: 1.5,
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

  // ============================================================
  // RENTAL WIDGET
  // ============================================================
  Widget _buildRentalWidget(
    BuildContext context,
    bool isDark,
    UserDashboardProvider dashboard,
  ) {
    final tenancy = dashboard.currentTenancy!;
    final daysUntilDue = tenancy['daysUntilDue'] as int? ?? 0;

    final totalPaid = dashboard.totalPaid;
    final totalTransactions = dashboard.totalTransactions;
    final monthlyRent = (tenancy['monthlyRent'] as num? ?? 0).toDouble();

    final bool firstMonthAlreadyPaid =
        totalTransactions == 1 && totalPaid >= monthlyRent && totalPaid > 0;

    final bool rentDue = tenancy['rentDue'] == true && !firstMonthAlreadyPaid;
    final bool showAsOverdue = rentDue && daysUntilDue < 0;

    final int adjustedDaysUntilDue =
        firstMonthAlreadyPaid ? (daysUntilDue.abs() + 30) : daysUntilDue;

    final bool isDueSoon = !showAsOverdue &&
        adjustedDaysUntilDue >= 0 &&
        adjustedDaysUntilDue <= 5;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;
    final String statusSubtitle;

    if (showAsOverdue) {
      statusColor = _HP.danger;
      statusLabel = 'Payment Overdue';
      statusIcon = Icons.warning_amber_rounded;
      statusSubtitle =
          '${adjustedDaysUntilDue.abs()} days past due — pay now to avoid penalty';
    } else if (isDueSoon) {
      statusColor = _HP.orange;
      statusLabel = 'Rent Due Soon';
      statusIcon = Icons.schedule_rounded;
      statusSubtitle = adjustedDaysUntilDue == 0
          ? 'Due today — pay now'
          : 'Due in $adjustedDaysUntilDue days';
    } else {
      statusColor = _HP.success;
      statusLabel = 'All Paid';
      statusIcon = Icons.check_circle_rounded;
      statusSubtitle = adjustedDaysUntilDue == 0
          ? 'Next rent due today'
          : 'Next rent due in $adjustedDaysUntilDue days';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Container(
        decoration: _cardDeco(isDark, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _HP.primarySoft.withOpacity(isDark ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_work_rounded,
                        size: 14, color: _HP.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'YOUR RENTAL',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: _HP.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_HP.primary, _HP.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _HP.primary.withOpacity(0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.apartment_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenancy['propertyTitle'] ?? 'Property',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary(isDark),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12, color: _textSecondary(isDark)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                tenancy['propertyCity'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: _textSecondary(isDark),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _textTertiary(isDark),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.meeting_room_rounded,
                                size: 12, color: _textSecondary(isDark)),
                            const SizedBox(width: 3),
                            Text(
                              'Room ${tenancy['roomNumber'] ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: _textSecondary(isDark),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.10 : 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: statusColor.withOpacity(0.15), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _HP.primarySoft.withOpacity(isDark ? 0.10 : 1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _HP.primary.withOpacity(isDark ? 0.15 : 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MONTHLY RENT',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: _HP.primary,
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
                                  color: _textPrimary(isDark),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${(tenancy['nextRentAmount'] ?? 0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary(isDark),
                                  height: 1,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 44,
                      color: _HP.primary.withOpacity(0.15),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DUE DATE',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: _HP.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                showAsOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.calendar_today_rounded,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  adjustedDaysUntilDue < 0
                                      ? '${adjustedDaysUntilDue.abs()} days late'
                                      : adjustedDaysUntilDue == 0
                                          ? 'Today'
                                          : 'in ${adjustedDaysUntilDue}d',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary(isDark),
                                    letterSpacing: -0.2,
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
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (dashboard.upcomingPayments.isNotEmpty) {
                            final invoiceId =
                                dashboard.upcomingPayments.first['invoiceId'];
                            _showRentPaymentSheet(context, invoiceId);
                          }
                        },
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: Text(
                          'Pay Rent',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _HP.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: _HP.primary.withOpacity(0.40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Material(
                      color: _HP.primarySoft.withOpacity(isDark ? 0.10 : 1),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () =>
                            _navigateToScreen(const MyRentalsScreen()),
                        borderRadius: BorderRadius.circular(14),
                        child: const Icon(Icons.description_rounded,
                            color: _HP.primary, size: 22),
                      ),
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

  // ============================================================
  // QUICK ACTIONS
  // ============================================================
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = <Map<String, dynamic>>[
      {
        'icon': Icons.search_rounded,
        'label': 'Explore',
        'color': _HP.primary,
        'onTap': () => _navigateToTab(HomeScreenState.tabExplore),
      },
      {
        'icon': Icons.movie_creation_rounded,
        'label': 'Reels',
        'color': _HP.pink,
        'onTap': () => _navigateToTab(HomeScreenState.tabReels),
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
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Row(
        children: List.generate(actions.length, (index) {
          final action = actions[index];
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  decoration: _cardDeco(isDark, radius: 18, shadow: 0.03),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(isDark ? 0.15 : 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action['icon'] as IconData,
                            color: color, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // WALLET
  // ============================================================
  Widget _buildWalletCard(
    BuildContext context,
    bool isDark,
    UserDashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: GestureDetector(
        onTap: () => _navigateToScreen(const ReferAndEarnScreen()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(isDark),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _HP.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: _HP.primary, size: 24),
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
                        color: _textSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary(isDark),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          dashboard.walletBalance.toStringAsFixed(2),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary(isDark),
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _primaryChip(icon: Icons.share_rounded, text: 'Refer'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryChip({
    required IconData icon,
    required String text,
    double radius = 12,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _HP.primary,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: _HP.primary.withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFER BANNER
  // ============================================================
  Widget _buildOfferBanner(BuildContext context, bool isDark) {
    final offers = <Map<String, dynamic>>[
      {
        'title': '20% OFF First Booking',
        'subtitle': 'Use code FIRST20',
        'color': _HP.primary,
        'icon': Icons.local_offer_rounded,
        'type': 'FIRST',
      },
      {
        'title': 'Refer & Earn ₹19',
        'subtitle': 'Share with friends',
        'color': _HP.purple,
        'icon': Icons.share_rounded,
        'type': 'REFER',
      },
      {
        'title': 'Premium at 10% OFF',
        'subtitle': 'Limited time offer',
        'color': _HP.orange,
        'icon': Icons.workspace_premium_rounded,
        'type': 'PREMIUM',
      },
    ];

    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final color = offer['color'] as Color;
          return GestureDetector(
            onTap: () {
              final type = offer['type'];
              if (type == 'REFER') {
                _navigateToScreen(const ReferAndEarnScreen());
              } else if (type == 'FIRST') {
                _navigateToScreen(const FirstBookingDiscountScreen());
              } else {
                _navigateToTab(HomeScreenState.tabExplore);
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width - 72,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: _cardDeco(isDark, radius: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(offer['icon'] as IconData,
                        color: color, size: 22),
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
                            color: _textPrimary(isDark),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          offer['subtitle'] as String,
                          style: GoogleFonts.poppins(
                            color: _textSecondary(isDark),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: _textSecondary(isDark), size: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            isDark,
            title: 'Browse by Type',
            onAction: () => _navigateToTab(HomeScreenState.tabExplore),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
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
        _navigateToTab(HomeScreenState.tabExplore);
      },
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _surface(isDark),
                border: Border.all(color: color.withOpacity(0.25), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isDark ? 0.20 : 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withOpacity(0.10),
                    child: Icon(Icons.home_rounded, color: color, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TRENDING
  // ============================================================
  Widget _buildTrendingSection(BuildContext context, bool isDark) {
    final provider = Provider.of<PropertyProvider>(context);
    final trending =
        provider.properties.where((p) => p.viewCount > 50).take(6).toList();

    if (trending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            isDark,
            title: 'Trending Now',
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange[600],
            onAction: () => _navigateToTab(HomeScreenState.tabExplore),
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
    final placeholderColor = isDark ? Colors.grey[600] : Colors.grey[400];

    return GestureDetector(
      onTap: () => _navigateToScreen(
          PropertyDetailScreen(propertyId: property.propertyId)),
      child: Container(
        decoration: _cardDeco(isDark, radius: 18, shadow: 0.05),
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
                    color:
                        isDark ? Colors.grey[800] : const Color(0xFFEEF2F8),
                    child: property.coverImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: property.coverImage,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                                Icons.home_rounded,
                                size: 32,
                                color: placeholderColor),
                          )
                        : Icon(Icons.home_rounded,
                            size: 32, color: placeholderColor),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _HP.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          'TRENDING',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
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
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          '${property.viewCount}',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
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
                      color: _textPrimary(isDark),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: _textSecondary(isDark)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.city,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _textSecondary(isDark),
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
                          color: _HP.primary,
                        ),
                      ),
                      Text(
                        '/mo',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: _textSecondary(isDark),
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
  // ANALYTICS
  // ============================================================
  Widget _buildAnalyticsCard(
    BuildContext context,
    bool isDark,
    UserDashboardProvider dashboard,
  ) {
    final growth = dashboard.monthlyGrowthPercent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _HP.primarySoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: _HP.primary, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary(isDark),
                  ),
                ),
                const Spacer(),
                if (growth != 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (growth > 0 ? _HP.success : _HP.danger)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          growth > 0 ? Icons.trending_up : Icons.trending_down,
                          size: 11,
                          color: growth > 0 ? _HP.success : _HP.danger,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${growth.toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: growth > 0 ? _HP.success : _HP.danger,
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
                    color: _HP.primary,
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
                      color: _textSecondary(isDark),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${dashboard.totalPaid.toStringAsFixed(0)} total',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _HP.primary,
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
        color: color.withOpacity(isDark ? 0.10 : 0.07),
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
              color: _textPrimary(isDark),
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: _textSecondary(isDark),
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
        final ratio = maxVal > 0 ? values[i] / maxVal : 0.0;
        final rawMonth = trend[i]['month']?.toString() ?? '';
        final monthLabel =
            rawMonth.length >= 3 ? rawMonth.substring(0, 3) : rawMonth;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    width: double.infinity,
                    height: (55 * ratio).clamp(4.0, 55.0).toDouble(),
                    decoration: BoxDecoration(
                      color: _HP.primary,
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
                    color: _textTertiary(isDark),
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
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _HP.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
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
                    color: _textPrimary(isDark),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _navigateToScreen(const MyRentalsScreen()),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'My Rentals',
                    style: GoogleFonts.poppins(
                      color: _HP.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...activities.take(5).map((a) => _activityTile(a, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(Map<String, dynamic> item, bool isDark) {
    final color = _hex(item['color']?.toString() ?? '#1E5EFF');
    final referenceType = item['referenceType']?.toString() ?? '';

    final bool isRentalActivity = referenceType == 'RENT_PAYMENT' ||
        referenceType == 'RENTAL_AGREEMENT' ||
        item['activityType']?.toString() == 'RENT_PAID';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isRentalActivity) _navigateToScreen(const MyRentalsScreen());
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
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
                      color: _textPrimary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['description']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: _textSecondary(isDark),
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
                    color: _textTertiary(isDark),
                  ),
                ),
                if (isRentalActivity)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: _HP.primary),
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
      return _HP.primary;
    }
  }

  // ============================================================
  // POPULAR CITIES
  // ============================================================
  Widget _buildPopularCities(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            isDark,
            title: 'Popular Cities',
            icon: Icons.location_city_rounded,
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
        _navigateToTab(HomeScreenState.tabExplore);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: _cardDeco(isDark, radius: 14, shadow: 0.03),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _HP.primarySoft.withOpacity(isDark ? 0.12 : 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(city['icon'] as IconData,
                  size: 14, color: _HP.primary),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary(isDark),
                  ),
                ),
                Text(
                  city['count'],
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: _textSecondary(isDark),
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
    final badges = <Map<String, dynamic>>[
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Verified Owners',
        'color': _HP.success,
      },
      {
        'icon': Icons.lock_rounded,
        'title': 'Secure Payments',
        'color': _HP.primary,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': '24x7 Support',
        'color': _HP.purple,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: _cardDeco(isDark, radius: 18, shadow: 0.02),
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
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary(isDark),
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
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: GestureDetector(
        onTap: () => _navigateToScreen(const ChatListScreen()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(isDark, radius: 18, shadow: 0.03),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _HP.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: _HP.primary, size: 22),
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
                        color: _textPrimary(isDark),
                      ),
                    ),
                    Text(
                      'Chat with our support team 24x7',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: _textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              _primaryChip(
                  icon: Icons.chat_rounded, text: 'Chat', radius: 10),
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
// RENT PAYMENT SHEET
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
      final isDark = Theme.of(context).brightness == Brightness.dark;

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
        'theme': {'color': isDark ? '#7C3AED' : '#1E5EFF'},
        'retry': {'enabled': true, 'max_count': 2},
        'timeout': 300,
      };

      _razorpay!.open(options);
    } catch (e) {
      debugPrint('❌ Payment initiate error: $e');
      if (mounted) {
        setState(() {
          _isInitiating = false;
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final provider =
        Provider.of<UserDashboardProvider>(context, listen: false);

    final confirmed = await provider.confirmRentPayment(
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
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
    if (!mounted) return;
    setState(() {
      _isInitiating = false;
      _errorMessage = response.message ?? 'Payment failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _HP.darkSurface : Colors.white;
    final textPrimary = isDark ? Colors.white : _HP.lightTextPrimary;
    final textSecondary = isDark ? Colors.white54 : _HP.lightTextSecondary;
    final primaryAccent = isDark ? _HP.purple : _HP.primary;
    final primaryAccentLight = isDark ? _HP.purpleLight : _HP.primaryLight;

    if (_paymentSuccess) {
      return Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _HP.success.withOpacity(0.10),
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
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your rent has been paid successfully.\nOwner will receive payout automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop(true);
                  nav.push(
                    MaterialPageRoute(
                        builder: (_) => const MyRentalsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('View My Rentals',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
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
                      color: textSecondary,
                    )),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
      decoration: BoxDecoration(
        color: surface,
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
                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
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
                    gradient: LinearGradient(
                      colors: [primaryAccent, primaryAccentLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAccent.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
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
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'You will be redirected to Razorpay secure checkout to complete the payment.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _HP.danger.withOpacity(0.10),
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
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
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
                    color: textSecondary,
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