// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yourhome/models/property_model.dart';
import 'package:yourhome/screens/admin/admin_profile_screen.dart';
import 'package:yourhome/screens/owner/owner_profile_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/property_provider.dart';
import '../providers/profile_provider.dart';

// ==================== STUDENT PANEL (USER) ====================
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
class _HomePalette {
  // Student Panel Colors (Blue)
  static const studentPrimary = Color(0xFF2563EB);
  static const studentPrimaryLight = Color(0xFF3B82F6);
  static const studentPrimarySoft = Color(0xFF60A5FA);

  // Owner Panel Colors (Orange/Gold)
  static const ownerPrimary = Color(0xFFF59E0B);
  static const ownerPrimaryLight = Color(0xFFFBBF24);
  static const ownerGold = Color(0xFFD4AF37);

  // Admin Panel Colors (Purple)
  static const adminPrimary = Color(0xFF7C3AED);
  static const adminPrimaryLight = Color(0xFF8B5CF6);

  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const gold = Color(0xFFD4AF37);
  static const purple = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const orange = Color(0xFFF59E0B);

  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const darkSurfaceElevated = Color(0xFF1B2338);
  static const lightBg = Color(0xFFF7F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
}

// ==================== HOME SCREEN WITH BOTTOM NAV ====================
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

  // ✅ NEW: Pulse animation for Owner panel's raised "Add Property" button
  late AnimationController _addPulseController;
  late Animation<double> _addPulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeOutCubic,
    );
    _navAnimationController.forward();

    // ✅ NEW: Owner Add-Property button pulse
    _addPulseController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
    _addPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _addPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _navAnimationController.dispose();
    _addPulseController.dispose(); // ✅ NEW
    super.dispose();
  }

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
              Text(
                'Press back again to exit',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }
    return true;
  }

  // ✅ GET PRIMARY COLOR BASED ON ROLE
  Color _getPrimaryColor(String role) {
    switch (role) {
      case 'ADMIN':
        return _HomePalette.adminPrimary;
      case 'OWNER':
        return _HomePalette.ownerPrimary;
      default:
        return _HomePalette.studentPrimary;
    }
  }

  Color _getPrimaryLightColor(String role) {
    switch (role) {
      case 'ADMIN':
        return _HomePalette.adminPrimaryLight;
      case 'OWNER':
        return _HomePalette.ownerPrimaryLight;
      default:
        return _HomePalette.studentPrimaryLight;
    }
  }

  // ✅ ROLE-BASED PAGES
  List<Widget> _getPages(String role) {
    switch (role) {
      case 'ADMIN':
        return [
          const AdminDashboardPage(),
          const AdminUserManagementPage(),
          const AdminPropertyManagementPage(),
          const AdminProfileScreen(),
        ];
      case 'OWNER':
        return [
          const OwnerDashboardPage(),
          const OwnerPropertyManagementPage(),
          const OwnerBookingManagementPage(),
          const ChatListScreen(),
          const OwnerProfileScreen(),
        ];
      default: // STUDENT
        return [
          const HomePage(), // Student Home
          const PropertiesScreen(), // Search/Explore
          const FavoritesScreen(), // Saved
          const ChatListScreen(), // Chat
        ];
    }
  }

  List<String> _getLabels(String role) {
    switch (role) {
      case 'ADMIN':
        return ['Dashboard', 'Users', 'Properties', 'Profile'];
     case 'OWNER':
        return ['Dashboard', 'Properties', 'Bookings', 'Chat', 'Profile'];
      default:
        return ['Home', 'Explore', 'Saved', 'Chat'];
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
          Icons.person_outlined,
        ];
      default:
        return [
          Icons.home_outlined,
          Icons.search_outlined,
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
          Icons.favorite_rounded,
          Icons.chat_bubble_rounded,
        ];
    }
  }

  // ✅ STUDENT NAV ITEM (unchanged design)
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: isSelected ? 28 : 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ✅ STUDENT BOTTOM NAV (unchanged) ====================
  Widget _buildStudentBottomNav(
    bool isDark,
    List<Widget> pages,
    List<String> labels,
    List<IconData> icons,
    List<IconData> activeIcons,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _HomePalette.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(pages.length, (index) {
              return _buildNavItem(
                icon: icons[index],
                activeIcon: activeIcons[index],
                label: labels[index],
                index: index,
                isDark: isDark,
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
    final barColor = isDark ? _HomePalette.darkSurface : Colors.white;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Widget ownerItem(int index) {
      final isSelected = _selectedIndex == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedIndex = index);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcons[index] : icons[index],
                color: isSelected
                    ? _HomePalette.ownerPrimary
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
                size: isSelected ? 26 : 23,
              ),
              const SizedBox(height: 3),
              Text(
                labels[index],
                style: GoogleFonts.poppins(
                  fontSize: isSelected ? 10.5 : 9.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? _HomePalette.ownerPrimary
                      : (isDark ? Colors.grey[500] : Colors.grey[400]),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(top: 3),
                width: isSelected ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: _HomePalette.ownerPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    const double barHeight = 72;
    const double buttonPoke = 22;

    final total = pages.length;
    final leftCount = (total / 2).floor();
    final leftIndices = List.generate(leftCount, (i) => i);
    final rightIndices = List.generate(total - leftCount, (i) => i + leftCount);

    return SizedBox(
      height: barHeight + buttonPoke + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: barHeight + bottomInset,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: _HomePalette.ownerPrimary.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                ...leftIndices.map(ownerItem),
                const SizedBox(width: 68),
                ...rightIndices.map(ownerItem),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                changeTab(1);
              },
              child: AnimatedBuilder(
                animation: _addPulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _addPulseAnimation.value,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_HomePalette.ownerPrimaryLight, _HomePalette.ownerGold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: barColor, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: _HomePalette.ownerPrimary.withOpacity(0.45),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_home_work_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
    final bottomInset = MediaQuery.of(context).padding.bottom; // ✅ system nav bar height

    return Padding(
      // ✅ bottom margin now includes system inset so the floating bar clears it
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: (isDark ? _HomePalette.darkSurfaceElevated : Colors.white)
                  .withOpacity(isDark ? 0.78 : 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _HomePalette.adminPrimary.withOpacity(0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _HomePalette.adminPrimary.withOpacity(0.2),
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
                            colors: [_HomePalette.adminPrimary, _HomePalette.adminPrimaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _HomePalette.adminPrimary.withOpacity(0.4),
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
                                    isSelected ? activeIcons[index] : icons[index],
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.grey[400] : Colors.grey[500]),
                                    size: 22,
                                  ),
                                  const SizedBox(height: 3),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : Colors.grey[500]),
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

    // ✅ GET USER ROLE
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? 'STUDENT';

    print('🔴 Current User Role: $userRole');

    final pages = _getPages(userRole);
    final labels = _getLabels(userRole);
    final icons = _getIcons(userRole);
    final activeIcons = _getActiveIcons(userRole);

    // ✅ Pick a completely different bottom nav per role
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
        extendBody: userRole ==
            'OWNER', // lets the raised Add button float over content
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

// ==================== HOME PAGE (STUDENT) ====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isFirstLoad = true;

  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;

  late AnimationController _greetingController;
  late Animation<double> _greetingAnimation;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'PG',
      'icon': Icons.apartment_rounded,
      'color': _HomePalette.studentPrimary
    },
    {'name': 'Hostel', 'icon': Icons.bed_rounded, 'color': _HomePalette.purple},
    {
      'name': 'Hotel',
      'icon': Icons.hotel_rounded,
      'color': _HomePalette.orange
    },
    {'name': 'Flat', 'icon': Icons.home_rounded, 'color': _HomePalette.success},
    {
      'name': 'Villa',
      'icon': Icons.villa_rounded,
      'color': const Color(0xFF06B6D4)
    },
    {
      'name': 'Resort',
      'icon': Icons.beach_access_rounded,
      'color': _HomePalette.pink
    },
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'name': 'Top Rated',
      'icon': Icons.star_rounded,
      'color': _HomePalette.gold
    },
    {
      'name': 'Nearby',
      'icon': Icons.location_on_rounded,
      'color': _HomePalette.studentPrimary
    },
    {
      'name': 'Budget',
      'icon': Icons.attach_money_rounded,
      'color': _HomePalette.success
    },
    {
      'name': 'Luxury',
      'icon': Icons.workspace_premium_rounded,
      'color': _HomePalette.purple
    },
  ];

  final List<Map<String, dynamic>> _popularCities = [
    {'name': 'Delhi', 'emoji': '🏛️'},
    {'name': 'Noida', 'emoji': '🏙️'},
    {'name': 'Gurgaon', 'emoji': '🌆'},
    {'name': 'Mumbai', 'emoji': '🌊'},
    {'name': 'Bangalore', 'emoji': '🌴'},
  ];

  final List<Map<String, dynamic>> _offers = [
    {
      'title': '🎉 20% OFF on First Booking!',
      'subtitle': 'Use code: FIRST20',
      'color': _HomePalette.purple,
      'icon': Icons.local_offer_rounded,
    },
    {
      'title': '🏠 Refer & Earn ₹500!',
      'subtitle': 'Share with friends and earn rewards',
      'color': _HomePalette.pink,
      'icon': Icons.share_rounded,
    },
    {
      'title': '🌟 Premium Properties at 10% OFF',
      'subtitle': 'Limited time offer',
      'color': _HomePalette.orange,
      'icon': Icons.workspace_premium_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProperties();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOutCubic),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _scaleIn = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _greetingAnimation = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeOutCubic,
    );

    _mainController.forward();
    _greetingController.forward();
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
    _mainController.dispose();
    _greetingController.dispose();
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
    if (homeState != null) {
      homeState.changeTab(index);
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profileImage = profileProvider.profile?.profilePic;

    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        return Scaffold(
          backgroundColor: isDark ? _HomePalette.darkBg : _HomePalette.lightBg,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await propertyProvider.searchProperties();
              },
              color: _HomePalette.studentPrimary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========== PREMIUM HEADER ==========
                    FadeTransition(
                      opacity: _greetingAnimation,
                      child: _buildPremiumHeader(
                        context,
                        isDark,
                        user,
                        profileImage,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ========== SEARCH BAR ==========
                    FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: _buildSearchBar(context, isDark),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ========== 🎉 OFFER BANNER ==========
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _buildOfferBanner(context, isDark),
                    ),

                    const SizedBox(height: 20),

                    // ========== QUICK ACTIONS ==========
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _buildQuickActions(context, isDark),
                    ),

                    const SizedBox(height: 24),

                    // ========== CATEGORIES ==========
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _buildCategories(context, isDark),
                    ),

                    const SizedBox(height: 24),

                    // ========== ⭐ FEATURED PROPERTIES ==========
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _buildFeaturedSection(
                          context, propertyProvider, isDark),
                    ),

                    const SizedBox(height: 24),

                    // ========== 🔥 TRENDING SECTION ==========
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _buildTrendingSection(
                          context, propertyProvider, isDark),
                    ),

                    const SizedBox(height: 24),

                    // ========== POPULAR PROPERTIES ==========
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _buildPopularSection(
                          context, propertyProvider, isDark),
                    ),

                    const SizedBox(height: 24),

                    // ========== 🏙️ POPULAR CITIES ==========
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _buildPopularCities(context, isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ========== PREMIUM HEADER ==========
  Widget _buildPremiumHeader(
    BuildContext context,
    bool isDark,
    dynamic user,
    String? profileImage,
  ) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name.isNotEmpty == true ? user!.name : 'Guest',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _HomePalette.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _HomePalette.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _HomePalette.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🏠 Explorer',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildNotificationBell(isDark),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(bool isDark, dynamic user, String? profileImage) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;

    return GestureDetector(
      onTap: () => _navigateToScreen(const ProfileScreen()),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasImage
              ? null
              : const LinearGradient(
                  colors: [
                    _HomePalette.studentPrimary,
                    _HomePalette.studentPrimaryLight
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: _HomePalette.studentPrimary.withOpacity(0.3),
              blurRadius: 16,
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
                  user?.name.isNotEmpty == true
                      ? user.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _HomePalette.darkSurface : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              size: 26,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: _HomePalette.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  '3',
                  style: GoogleFonts.poppins(
                    fontSize: 7,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        onPressed: () {
          _navigateToScreen(const NotificationScreen());
        },
      ),
    );
  }

  // ========== SEARCH BAR ==========
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _navigateToTab(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? _HomePalette.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
              width: 1,
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
                  color: _HomePalette.studentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: _HomePalette.studentPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Where are you going?',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _HomePalette.studentPrimary,
                      _HomePalette.studentPrimaryLight
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Search',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== OFFER BANNER ==========
  Widget _buildOfferBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _offers.length,
          itemBuilder: (context, index) {
            final offer = _offers[index];
            return Container(
              width: MediaQuery.of(context).size.width - 80,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    offer['color'] as Color,
                    (offer['color'] as Color).withOpacity(0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (offer['color'] as Color).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                      offer['icon'],
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offer['title'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offer['subtitle'],
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Claim',
                      style: GoogleFonts.poppins(
                        color: offer['color'] as Color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
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

  // ========== QUICK ACTIONS ==========
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _quickActions.map((action) {
              return Expanded(
                child: _buildQuickActionItem(
                  context,
                  action['name'],
                  action['icon'],
                  action['color'],
                  isDark,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _navigateToTab(1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? _HomePalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== CATEGORIES ==========
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
                'Categories',
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
                    color: _HomePalette.studentPrimary,
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
                final category = _categories[index];
                return _buildCategoryItem(
                  context,
                  category['name'],
                  category['icon'],
                  category['color'],
                  isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        try {
          final propertyProvider = Provider.of<PropertyProvider>(
            context,
            listen: false,
          );
          propertyProvider.searchProperties(type: name);
          _navigateToTab(1);
        } catch (e) {
          print('❌ Error: $e');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
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

  // ========== FEATURED PROPERTIES ==========
  Widget _buildFeaturedSection(
    BuildContext context,
    PropertyProvider provider,
    bool isDark,
  ) {
    final featured = provider.properties.where((p) => p.isFeatured).toList();

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
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: _HomePalette.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '⭐ Featured Stays',
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
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: _HomePalette.studentPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.isLoading)
            _buildLoadingShimmer(isDark)
          else if (provider.error != null)
            _buildErrorWidget(context, provider, isDark)
          else if (featured.isEmpty)
            _buildEmptyWidget(isDark, 'No featured properties')
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: featured.length > 6 ? 6 : featured.length,
                itemBuilder: (context, index) {
                  final property = featured[index];
                  return _buildFeaturedCard(
                    context,
                    property,
                    isDark,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    Property property,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        _navigateToScreen(
            PropertyDetailScreen(propertyId: property.propertyId));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? _HomePalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: property.coverImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: property.coverImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.home_rounded,
                              size: 40,
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          )
                        : Icon(
                            Icons.home_rounded,
                            size: 40,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          'Premium',
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
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      property.monthlyRentMin != null
                          ? '₹${property.monthlyRentMin!.toStringAsFixed(0)}'
                          : 'Contact',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
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
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFD700), size: 10),
                        const SizedBox(width: 2),
                        Text(
                          property.averageRating?.toStringAsFixed(1) ?? '4.5',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.city,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _HomePalette.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${property.availableRooms} rooms left',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: _HomePalette.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (property.isVerifiedOwner)
                        const Icon(Icons.verified,
                            color: Colors.blue, size: 12),
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

  // ========== TRENDING SECTION ==========
  Widget _buildTrendingSection(
    BuildContext context,
    PropertyProvider provider,
    bool isDark,
  ) {
    final trending =
        provider.properties.where((p) => p.viewCount > 50).take(5).toList();

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
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🔥 Trending Now',
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
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: _HomePalette.studentPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...trending
              .map((property) => _buildTrendingCard(
                    context,
                    property,
                    isDark,
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(
    BuildContext context,
    Property property,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        _navigateToScreen(
            PropertyDetailScreen(propertyId: property.propertyId));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? _HomePalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: property.coverImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: property.coverImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.home_rounded,
                          size: 30,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      )
                    : Icon(
                        Icons.home_rounded,
                        size: 30,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.city,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.orange,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${property.viewCount} views',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _HomePalette.studentPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '₹${property.monthlyRentMin?.toStringAsFixed(0)}/mo',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: _HomePalette.studentPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ========== POPULAR PROPERTIES ==========
  Widget _buildPopularSection(
    BuildContext context,
    PropertyProvider provider,
    bool isDark,
  ) {
    final popular =
        provider.properties.where((p) => !p.isFeatured).take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Properties',
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
                    color: _HomePalette.studentPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.isLoading)
            _buildLoadingShimmer(isDark)
          else if (provider.error != null)
            _buildErrorWidget(context, provider, isDark)
          else if (popular.isEmpty)
            _buildEmptyWidget(isDark, 'No properties available')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: popular.length,
              itemBuilder: (context, index) {
                final property = popular[index];
                return _buildPopularCard(
                  context,
                  property,
                  isDark,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPopularCard(
    BuildContext context,
    Property property,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        _navigateToScreen(
            PropertyDetailScreen(propertyId: property.propertyId));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? _HomePalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: property.coverImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: property.coverImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.home_rounded,
                          size: 30,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      )
                    : Icon(
                        Icons.home_rounded,
                        size: 30,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.city,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _HomePalette.studentPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          property.propertyType,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: _HomePalette.studentPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        property.monthlyRentMin != null
                            ? '₹${property.monthlyRentMin!.toStringAsFixed(0)}/mo'
                            : 'Contact',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _HomePalette.studentPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              property.averageRating?.toStringAsFixed(1) ??
                                  '4.5',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (property.isVerifiedOwner)
                        const Icon(Icons.verified,
                            color: Colors.blue, size: 12),
                    ],
                  ),
                ],
              ),
            ),
            Consumer<PropertyProvider>(
              builder: (context, propertyProvider, child) {
                final isSaved = propertyProvider.savedProperties
                    .any((p) => p.propertyId == property.propertyId);
                return GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    try {
                      if (isSaved) {
                        await propertyProvider
                            .removeSavedProperty(property.propertyId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Removed from favorites'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.grey[800],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } else {
                        await propertyProvider
                            .saveProperty(property.propertyId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to favorites ❤️'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: _HomePalette.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      print('❌ Error: $e');
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSaved
                          ? _HomePalette.danger.withOpacity(0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isSaved
                          ? _HomePalette.danger
                          : (isDark ? Colors.grey[500] : Colors.grey[400]),
                      size: 22,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== POPULAR CITIES ==========
  Widget _buildPopularCities(BuildContext context, bool isDark) {
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
                  Icon(
                    Icons.location_city_rounded,
                    color: _HomePalette.studentPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🏙️ Popular Cities',
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
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: _HomePalette.studentPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _popularCities.map((city) {
              return _buildCityChip(
                  context, city['name'], city['emoji'], isDark);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChip(
      BuildContext context, String city, String emoji, bool isDark) {
    return GestureDetector(
      onTap: () {
        final propertyProvider = Provider.of<PropertyProvider>(
          context,
          listen: false,
        );
        propertyProvider.searchProperties(city: city);
        _navigateToTab(1);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? _HomePalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!,
            width: 1,
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
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              city,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== LOADING SHIMMER ==========
  Widget _buildLoadingShimmer(bool isDark) {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? _HomePalette.darkSurface : Colors.white,
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 50,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
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

  // ========== ERROR WIDGET ==========
  Widget _buildErrorWidget(
    BuildContext context,
    PropertyProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _HomePalette.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: _HomePalette.danger.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load properties',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? 'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => provider.searchProperties(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _HomePalette.studentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== EMPTY WIDGET ==========
  Widget _buildEmptyWidget(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _HomePalette.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.home_outlined,
            size: 40,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
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
