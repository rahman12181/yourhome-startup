// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:yourhome/widgets/no_internet_widget.dart';

import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/dashboard_model.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notification_screen.dart';
import 'owner_profile_screen.dart';
import 'owner_my_reels_screen.dart';
import 'owner_reels_upload_screen.dart';
import 'owner_property_management_page.dart';
import 'owner_booking_management_page.dart';
import 'property_access_subscription_page.dart';
import 'listing_subscription_page.dart';
import 'owner_apply_page.dart';

// ============================================================
// DESIGN TOKENS
// ============================================================
class _P {
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF9F7AEA);
  static const gold = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const teal = Color(0xFF14B8A6);
  static const blue = Color(0xFF3B82F6);
  static const pink = Color(0xFFEC4899);
  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF121729);
  static const darkCard = Color(0xFF1A1F33);
  static const lightBg = Color(0xFFF7F8FC);
  static const lightCard = Colors.white;
}

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage>
    with TickerProviderStateMixin {
  bool _isFirstLoad = true;
  int _unreadNotifications = 0;
  bool _hasPayoutUpi = false;

  late AnimationController _fadeController;
  late AnimationController _staggerController;

  int _selectedPropertyId = 0;
  String _selectedPropertyTitle = 'Property Access';
  StreamSubscription? _connectivitySub;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // ✅ Internet listener
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final hasNet = result != ConnectivityResult.none;
      if (hasNet && mounted && !_isDisposed) {
        _loadAll();
      } else if (!hasNet && mounted && !_isDisposed) {
        final p = Provider.of<OwnerProvider>(context, listen: false);
        p.checkConnectivity();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fadeController.forward();
      if (_isFirstLoad) {
        _isFirstLoad = false;
        _loadAll();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySub?.cancel();
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    await ownerProvider.loadAllOwnerData();
    if (!mounted) return;
    _loadPropertyData(ownerProvider);
    _loadUnreadNotifications();
    _staggerController.forward(from: 0);
  }

  void _loadPropertyData(OwnerProvider provider) {
    if (provider.myProperties.isNotEmpty) {
      final firstProperty = provider.myProperties.first;
      if (mounted) {
        setState(() {
          _selectedPropertyId = firstProperty.propertyId ?? 0;
          _selectedPropertyTitle = firstProperty.title ?? 'Property';
        });
      }
    }
  }

  Future<void> _loadUnreadNotifications() async {
    if (!mounted) return;
    final p = Provider.of<OwnerProvider>(context, listen: false);
    setState(() => _unreadNotifications = p.unreadBookingCount);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _navigateTo(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
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

  void _navigateToPropertyAccess() {
    _navigateTo(
      PropertyAccessSubscriptionPage(
        propertyId: _selectedPropertyId,
        propertyTitle: _selectedPropertyTitle,
      ),
    );
  }

  void _navigateToListingSubscription() {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    String title = 'Listing Subscription';
    int id = 0;
    if (ownerProvider.myProperties.isNotEmpty) {
      final p = ownerProvider.myProperties.first;
      id = p.propertyId ?? 0;
      title = p.title ?? 'Listing';
    }
    _navigateTo(ListingSubscriptionPage(
      propertyId: id,
      propertyTitle: title,
    ));
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final ownerProvider = Provider.of<OwnerProvider>(context);

    final user = authProvider.user;
    final profileImage = profileProvider.profile?.profilePic;
    final stats = ownerProvider.dashboardStats;
    final verification = ownerProvider.verificationStatus;
    final accessStatus = ownerProvider.propertyAccessStatus;
    final listingSub = ownerProvider.listingSubscription;
    final ownerProfile = ownerProvider.ownerProfile;
    final summary = ownerProvider.dashboardSummary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? _P.darkBg : _P.lightBg,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? _P.darkBg : _P.lightBg,
        body: SafeArea(
          bottom: false,
          child: !ownerProvider.hasInternet
              ? NoInternetWidget(
                  isDark: isDark,
                  onRetry: () async {
                    HapticFeedback.lightImpact();
                    final ok = await ownerProvider.checkConnectivity();
                    if (ok) {
                      await _loadAll();
                    }
                  },
                )
              : ownerProvider.isLoading && stats == null
                  ? _loading(isDark)
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: _P.primary,
                      backgroundColor: isDark ? _P.darkSurface : Colors.white,
                      child: FadeTransition(
                        opacity: _fadeController,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child:
                                  _appBar(context, isDark, user, profileImage),
                            ),
                            SliverToBoxAdapter(
                              child:
                                  _greeting_section(isDark, user, ownerProfile),
                            ),
                            // ============ ACTION REQUIRED ============
                            if (summary?.actionsRequired != null &&
                                (summary!.actionsRequired!.totalActions > 0))
                              SliverToBoxAdapter(
                                child: _animated(
                                  0,
                                  _actionRequiredSection(
                                      isDark, summary.actionsRequired!),
                                ),
                              ),
                            // ============ REVENUE CARD ============
                            if (summary?.revenue != null)
                              SliverToBoxAdapter(
                                child: _animated(
                                  1,
                                  _revenueSection(isDark, summary!.revenue!),
                                ),
                              ),
                            // ============ OCCUPANCY DONUT ============
                            if (summary?.occupancy != null)
                              SliverToBoxAdapter(
                                child: _animated(
                                  2,
                                  _occupancySection(
                                      isDark, summary!.occupancy!),
                                ),
                              ),
                            // ============ TRENDS BAR CHART ============
                            if (summary?.trends != null)
                              SliverToBoxAdapter(
                                child: _animated(
                                  3,
                                  _trendsSection(isDark, summary!.trends!),
                                ),
                              ),
                            // ============ TODAY'S SCHEDULE ============
                            if (summary?.todaySchedule != null &&
                                (summary!.todaySchedule!.totalEvents > 0))
                              SliverToBoxAdapter(
                                child: _animated(
                                  4,
                                  _todayScheduleSection(
                                      isDark, summary.todaySchedule!),
                                ),
                              ),
                            // ============ TOP PROPERTY ============
                            if (summary?.topProperty != null)
                              SliverToBoxAdapter(
                                child: _animated(
                                  5,
                                  _topPropertySection(
                                      isDark, summary!.topProperty!),
                                ),
                              ),
                            // ============ RECENT ACTIVITY ============
                            if (summary?.recentActivity != null &&
                                summary!.recentActivity!.activities.isNotEmpty)
                              SliverToBoxAdapter(
                                child: _animated(
                                  6,
                                  _activitySection(
                                      isDark, summary.recentActivity!),
                                ),
                              ),
                            // ============ PAYOUT SETUP ============
                            SliverToBoxAdapter(
                              child: _animated(7, _payoutCard(isDark)),
                            ),
                            // ============ STATS GRID ============
                            if (stats != null)
                              SliverToBoxAdapter(
                                child: _animated(8, _statsGrid(isDark, stats)),
                              ),
                            // ============ VERIFICATION ============
                            if (verification != null)
                              SliverToBoxAdapter(
                                child: _animated(
                                  9,
                                  _verificationCard(isDark, verification),
                                ),
                              ),
                            // ============ SUBSCRIPTIONS ============
                            SliverToBoxAdapter(
                              child: _animated(
                                10,
                                _subscriptionSection(
                                    isDark, accessStatus, listingSub),
                              ),
                            ),
                            // ============ REELS ============
                            SliverToBoxAdapter(
                              child: _animated(11, _reelsSection(isDark)),
                            ),
                            // ============ QUICK ACTIONS ============
                            SliverToBoxAdapter(
                              child: _animated(12, _quickActions(isDark)),
                            ),
                            // ============ BOOKING OVERVIEW ============
                            SliverToBoxAdapter(
                              child: _animated(
                                  13, _bookingOverview(isDark, ownerProvider)),
                            ),
                            // ============ BOTTOM SPACING ============
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 20,
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

  Widget _animated(int index, Widget child) {
    final delay = index * 0.06;
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (_, __) {
        final raw = _staggerController.value - delay;
        final t = Curves.easeOutCubic.transform(raw.clamp(0.0, 1.0).toDouble());
        return Transform.translate(
          offset: Offset(0, 22 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  Widget _appBar(
      BuildContext context, bool isDark, dynamic user, String? profileImage) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;
    final initial =
        (user?.name?.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'O';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateTo(const OwnerProfileScreen()),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasImage
                    ? null
                    : const LinearGradient(
                        colors: [_P.primary, _P.primaryLight],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: _P.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: profileImage,
                        fit: BoxFit.cover,
                        width: 46,
                        height: 46,
                        errorWidget: (_, __, ___) => _avatarFallback(initial),
                      )
                    : _avatarFallback(initial),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ NAYA
                Text(
                  (user?.name?.isNotEmpty == true) ? user!.name : 'Owner',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _greeting(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ],
            ),
          ),
          _circleBtn(
            icon: isDark
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_round_outlined,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              final tp = Provider.of<ThemeProvider>(context, listen: false);
              tp.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          const SizedBox(width: 8),
          _notifButton(isDark),
        ],
      ),
    );
  }

  Widget _avatarFallback(String initial) => Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      );

  Widget _circleBtn({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? _P.darkCard : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE8E8F0),
          ),
        ),
        child: Icon(
          icon,
          size: 19,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _notifButton(bool isDark) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _navigateTo(const NotificationScreen());
      },
      borderRadius: BorderRadius.circular(50),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? _P.darkCard : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8E8F0),
              ),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 19,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          if (_unreadNotifications > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _P.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? _P.darkCard : Colors.white,
                    width: 2,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  _unreadNotifications > 9
                      ? '9+'
                      : _unreadNotifications.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _greeting_section(bool isDark, dynamic user, dynamic ownerProfile) {
    final businessName = ownerProfile?.businessName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
  
          if (businessName != null && businessName.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                businessName.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION REQUIRED SECTION
  // ============================================================
  Widget _actionRequiredSection(bool isDark, ActionRequired actions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _P.danger.withOpacity(0.15),
                      _P.danger.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.bolt_rounded, color: _P.danger, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Action Required',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _P.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${actions.totalActions}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _P.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...actions.items.take(3).map((a) => _actionCard(isDark, a)),
        ],
      ),
    );
  }

  Widget _actionCard(bool isDark, ActionItem item) {
    final c = _hex(item.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withOpacity(0.10), c.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.25), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            // Navigate based on type
            if (item.type == 'PENDING_BOOKING') {
              _navigateTo(const OwnerBookingManagementPage());
            } else if (item.type == 'EXPIRING_SUBSCRIPTION') {
              _navigateToPropertyAccess();
            } else if (item.type == 'UPI_MISSING') {
              _showPayoutUpiDialog();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_actionIcon(item.icon), color: c, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.priority == 'HIGH')
                            Container(
                              margin: const EdgeInsets.only(right: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: _P.danger,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'URGENT',
                                style: GoogleFonts.poppins(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.actionLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _actionIcon(String name) {
    switch (name) {
      case 'schedule':
        return Icons.schedule_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'visibility_off':
        return Icons.visibility_off_rounded;
      case 'verified_user':
        return Icons.verified_user_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ============================================================
  // REVENUE SECTION — LINE CHART
  // ============================================================
  Widget _revenueSection(bool isDark, RevenueSummary rev) {
    final isUp = rev.growthPercent >= 0;
    final growthColor = isUp ? _P.success : _P.danger;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1F33), const Color(0xFF141A2C)]
                : [Colors.white, const Color(0xFFF8F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF0F0F8),
          ),
          boxShadow: [
            BoxShadow(
              color: _P.primary.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _P.primary.withOpacity(0.2),
                        _P.primary.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: _P.primary, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Revenue',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: growthColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUp ? Icons.trending_up : Icons.trending_down,
                        size: 11,
                        color: growthColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${rev.growthPercent.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: growthColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Big Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF8A8FA3),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  _formatNumber(rev.thisMonthTotal),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'this month',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Line chart
            if (rev.monthlyTrend.isNotEmpty)
              SizedBox(
                height: 100,
                child: _buildRevenueLineChart(rev, isDark),
              ),

            const SizedBox(height: 14),

            // Bottom stats
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      'Paid',
                      '₹${_formatNumber(rev.paidAmount)}',
                      _P.success,
                      isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE8E8F0),
                  ),
                  Expanded(
                    child: _miniStat(
                      'Pending',
                      '₹${_formatNumber(rev.pendingAmount)}',
                      _P.gold,
                      isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE8E8F0),
                  ),
                  Expanded(
                    child: _miniStat(
                      'Collected',
                      '${rev.collectionRate.toStringAsFixed(0)}%',
                      _P.blue,
                      isDark,
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

  Widget _buildRevenueLineChart(RevenueSummary rev, bool isDark) {
    final trend = rev.monthlyTrend;
    if (trend.isEmpty) return const SizedBox();

    final maxAmt = trend.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final maxY = maxAmt > 0 ? maxAmt * 1.2 : 1000.0;

    List<FlSpot> spots = [];
    for (int i = 0; i < trend.length; i++) {
      spots.add(FlSpot(i.toDouble(), trend[i].amount));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF0F0F8),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    trend[i].month,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (trend.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? _P.darkCard : const Color(0xFF1A1A2E),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt();
              return LineTooltipItem(
                '${trend[i].month}\n₹${_formatNumber(trend[i].amount)}',
                GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: _P.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: _P.primary,
                strokeWidth: 2,
                strokeColor: isDark ? _P.darkCard : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _P.primary.withOpacity(0.35),
                  _P.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
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
    );
  }

  // ============================================================
  // OCCUPANCY — DONUT CHART
  // ============================================================
  Widget _occupancySection(bool isDark, OccupancyData occ) {
    final rate = occ.occupancyRate;
    final rateColor = rate >= 85
        ? _P.success
        : rate >= 70
            ? _P.blue
            : rate >= 50
                ? _P.gold
                : _P.danger;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                    color: rateColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.home_work_rounded, color: rateColor, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Occupancy Rate',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: rateColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    occ.occupancyLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: rateColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Donut chart
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                              value: rate,
                              color: rateColor,
                              radius: 14,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: 100 - rate,
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFF0F0F8),
                              radius: 12,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${rate.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                              height: 1,
                            ),
                          ),
                          Text(
                            'occupied',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF8A8FA3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _occStat(
                        'Occupied',
                        occ.occupiedRooms.toString(),
                        _P.success,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _occStat(
                        'Available',
                        occ.availableRooms.toString(),
                        _P.blue,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _occStat(
                        'Total',
                        occ.totalRooms.toString(),
                        _P.primary,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _occStat(String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF666680),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRENDS — BAR CHART
  // ============================================================
  Widget _trendsSection(bool isDark, TrendsData trends) {
    final isUp = trends.growthPercent >= 0;
    final growthColor = isUp ? _P.success : _P.danger;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                    color: _P.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart_rounded,
                      color: _P.blue, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Weekly Bookings',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: growthColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUp ? Icons.trending_up : Icons.trending_down,
                        size: 11,
                        color: growthColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${trends.growthPercent.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: growthColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${trends.totalThisWeek}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'bookings this week',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 110,
              child: _buildBookingsBarChart(trends, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsBarChart(TrendsData trends, bool isDark) {
    final data = trends.bookingsTrend;
    if (data.isEmpty) return const SizedBox();

    final maxVal =
        data.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = maxVal > 0 ? maxVal * 1.3 : 5.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF0F0F8),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].day,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? _P.darkCard : const Color(0xFF1A1A2E),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = data[group.x];
              return BarTooltipItem(
                '${d.day}\n${d.value} bookings',
                GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          final d = data[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: d.value.toDouble(),
                gradient: const LinearGradient(
                  colors: [_P.primary, _P.primaryLight],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF7F8FC),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ============================================================
  // TODAY'S SCHEDULE
  // ============================================================
  Widget _todayScheduleSection(bool isDark, TodaySchedule schedule) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
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
                    color: _P.pink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: _P.pink, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Schedule",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _P.pink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${schedule.totalEvents}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _P.pink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...schedule.events.take(4).map((e) => _scheduleTile(isDark, e)),
          ],
        ),
      ),
    );
  }

  Widget _scheduleTile(bool isDark, ScheduleItem item) {
    final c = _hex(item.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_actionIcon(item.icon), color: c, size: 15),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.description,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.timeLabel,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP PROPERTY
  // ============================================================
  Widget _topPropertySection(bool isDark, TopProperty prop) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1F1B3D), const Color(0xFF1A1F33)]
                : [const Color(0xFFF5F3FF), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: _P.primary.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _P.primary.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_P.gold, _P.pink],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Top Performer',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_P.gold, _P.pink],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#1',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 76,
                      height: 76,
                      color: _P.primary.withOpacity(0.1),
                      child: prop.coverImage != null
                          ? CachedNetworkImage(
                              imageUrl: prop.coverImage!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.apartment_rounded,
                                color: _P.primary,
                                size: 32,
                              ),
                            )
                          : const Icon(
                              Icons.apartment_rounded,
                              color: _P.primary,
                              size: 32,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prop.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 10, color: _P.primary),
                            const SizedBox(width: 3),
                            Text(
                              prop.city,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF8A8FA3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _badge(
                              '₹${_formatNumber(prop.revenueThisMonth)}',
                              _P.success,
                            ),
                            const SizedBox(width: 6),
                            _badge(
                              '${prop.bookingsThisMonth} bookings',
                              _P.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _topMetric(
                        Icons.star_rounded,
                        prop.averageRating.toStringAsFixed(1),
                        'Rating',
                        _P.gold,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _topMetric(
                        Icons.visibility_rounded,
                        '${prop.viewCount}',
                        'Views',
                        _P.blue,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _topMetric(
                        Icons.trending_up_rounded,
                        '${prop.occupancyRate.toStringAsFixed(0)}%',
                        'Occupancy',
                        _P.success,
                        isDark,
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _topMetric(
      IconData icon, String value, String label, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 8.5,
            color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================
  Widget _activitySection(bool isDark, RecentActivity activity) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
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
                    color: _P.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded,
                      color: _P.teal, size: 14),
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
            const SizedBox(height: 10),
            ...activity.activities.take(5).map((a) => _activityTile(isDark, a)),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(bool isDark, ActivityItem item) {
    final c = _hex(item.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_actionIcon(item.icon), color: c, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.description,
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
            item.timeAgo,
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

  // ============================================================
  // PAYOUT SETUP CARD
  // ============================================================
  Widget _payoutCard(bool isDark) {
    final ownerProvider = Provider.of<OwnerProvider>(context);
    final hasUpi = ownerProvider.hasPayoutUpi;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: hasUpi // 👈 provider se
            ? const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (hasUpi ? _P.success : _P.primary).withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasUpi ? Icons.verified_rounded : Icons.payments_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUpi ? 'Payments Activated' : 'Set up Payments',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasUpi
                      ? 'You will receive rent automatically'
                      : 'Add UPI to receive rent payments',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!hasUpi)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showPayoutUpiDialog();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Add UPI',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _P.primary,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Active',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPayoutUpiDialog() {
    final upiController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? _P.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _P.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: _P.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Add UPI',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You will receive rent payments on this UPI ID',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: upiController,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'e.g. owner@okhdfcbank',
                  prefixIcon: const Icon(Icons.payments_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? _P.darkSurface : const Color(0xFFF8F9FC),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final upiId = upiController.text.trim();
                if (upiId.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid UPI ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                await _savePayoutUpi(upiId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _P.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePayoutUpi(String upiId) async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    final result = await provider.setPayoutUpi(upiId);

    if (!mounted) return;

    if (result['success'] == true) {
      // ✅ Provider se mark kar
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      await ownerProvider.setPayoutUpiSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'UPI saved!'),
          backgroundColor: _P.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await _loadAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed'),
          backgroundColor: _P.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ============================================================
  // STATS GRID
  // ============================================================
  Widget _statsGrid(bool isDark, dynamic stats) {
    final data = [
      {
        'label': 'Properties',
        'value': stats.totalProperties?.toString() ?? '0',
        'icon': Icons.apartment_rounded,
        'color': _P.blue,
      },
      {
        'label': 'Published',
        'value': stats.publishedProperties?.toString() ?? '0',
        'icon': Icons.check_circle_rounded,
        'color': _P.success,
      },
      {
        'label': 'Rooms',
        'value': stats.totalRooms?.toString() ?? '0',
        'icon': Icons.meeting_room_rounded,
        'color': _P.primary,
      },
      {
        'label': 'Available',
        'value': stats.availableRooms?.toString() ?? '0',
        'icon': Icons.bed_rounded,
        'color': _P.teal,
      },
      {
        'label': 'Bookings',
        'value': stats.totalBookingRequests?.toString() ?? '0',
        'icon': Icons.book_online_rounded,
        'color': _P.gold,
      },
      {
        'label': 'Pending',
        'value': stats.pendingRequests?.toString() ?? '0',
        'icon': Icons.schedule_rounded,
        'color': _P.pink,
      },
      {
        'label': 'Rating',
        'value': stats.averageRating != null
            ? stats.averageRating.toStringAsFixed(1)
            : '0.0',
        'icon': Icons.star_rounded,
        'color': _P.gold,
      },
      {
        'label': 'Views',
        'value': stats.totalViews?.toString() ?? '0',
        'icon': Icons.visibility_rounded,
        'color': _P.primaryLight,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
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
                    color: _P.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: _P.primary, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Stats',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, i) {
                final item = data[i];
                final color = item['color'] as Color;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: color, size: 13),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['value'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                              height: 1.1,
                            ),
                          ),
                          Text(
                            item['label'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF8A8FA3),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VERIFICATION CARD
  // ============================================================
  Widget _verificationCard(bool isDark, dynamic verification) {
    final isVerified = verification.isVerified;
    final isRejected = verification.isRejected;
    final color = isVerified
        ? _P.success
        : isRejected
            ? _P.danger
            : _P.gold;
    final icon = isVerified
        ? Icons.verified_rounded
        : isRejected
            ? Icons.error_outline_rounded
            : Icons.hourglass_top_rounded;
    final title = isVerified
        ? 'Verified Owner'
        : isRejected
            ? 'Verification Rejected'
            : 'Verification Pending';
    final subtitle = isVerified
        ? 'You can add properties & receive bookings'
        : isRejected
            ? (verification.rejectionReason ?? 'Please re-apply')
            : 'Admin reviews within 24-48 hours';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isRejected)
            GestureDetector(
              onTap: () => _navigateTo(const OwnerApplyPage()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  'Re-apply',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBSCRIPTIONS
  // ============================================================
  Widget _subscriptionSection(
      bool isDark, dynamic accessStatus, dynamic listingSub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
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
                    color: _P.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: _P.primary, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Subscriptions',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _subItem(
              title: 'Property Access',
              subtitle: accessStatus != null &&
                      accessStatus.hasActiveSubscription
                  ? '${accessStatus.plan} • ${accessStatus.daysRemaining} days left'
                  : 'No active plan — tap to buy',
              isActive:
                  accessStatus != null && accessStatus.hasActiveSubscription,
              color: _P.blue,
              icon: Icons.home_work_rounded,
              isDark: isDark,
              onTap: _navigateToPropertyAccess,
            ),
            const SizedBox(height: 8),
            _subItem(
              title: 'Listing Subscription',
              subtitle: listingSub != null && listingSub.isActive
                  ? '${listingSub.planDisplayName} • ${listingSub.daysRemaining} days left'
                  : 'Boost search rank — tap to buy',
              isActive: listingSub != null && listingSub.isActive,
              color: _P.primary,
              icon: Icons.trending_up_rounded,
              isDark: isDark,
              onTap: _navigateToListingSubscription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subItem({
    required String title,
    required String subtitle,
    required bool isActive,
    required Color color,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    subtitle,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? _P.success.withOpacity(0.15)
                    : _P.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isActive ? _P.success : _P.danger,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: isDark ? Colors.white38 : const Color(0xFFB0B3C0),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REELS
  // ============================================================
  Widget _reelsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
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
                    gradient: const LinearGradient(colors: [_P.gold, _P.pink]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.movie_creation_rounded,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Reels',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _reelCard(
                  icon: Icons.upload_rounded,
                  label: 'Upload',
                  color: _P.gold,
                  isDark: isDark,
                  onTap: () => _navigateTo(const OwnerReelsUploadScreen()),
                ),
                const SizedBox(width: 8),
                _reelCard(
                  icon: Icons.video_library_rounded,
                  label: 'My Reels',
                  color: _P.pink,
                  isDark: isDark,
                  onTap: () => _navigateTo(const OwnerMyReelsScreen()),
                ),
                const SizedBox(width: 8),
                _reelCard(
                  icon: Icons.analytics_rounded,
                  label: 'Stats',
                  color: _P.primary,
                  isDark: isDark,
                  onTap: () => _navigateTo(const OwnerMyReelsScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reelCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.75)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================
  Widget _quickActions(bool isDark) {
    final actions = [
      {
        'label': 'Properties',
        'icon': Icons.apartment_rounded,
        'color': _P.blue,
        'onTap': () => _navigateTo(const OwnerPropertyManagementPage()),
      },
      {
        'label': 'Bookings',
        'icon': Icons.book_online_rounded,
        'color': _P.gold,
        'onTap': () => _navigateTo(const OwnerBookingManagementPage()),
      },
      {
        'label': 'Chat',
        'icon': Icons.chat_bubble_rounded,
        'color': _P.success,
        'onTap': () => _navigateTo(const ChatListScreen()),
      },
      {
        'label': 'Alerts',
        'icon': Icons.notifications_rounded,
        'color': _P.primary,
        'onTap': () => _navigateTo(const NotificationScreen()),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
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
                    color: _P.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on_rounded,
                      color: _P.primary, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(actions.length, (i) {
                final a = actions[i];
                return Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: i == actions.length - 1 ? 0 : 8),
                    child: _quickAction(
                      label: a['label'] as String,
                      icon: a['icon'] as IconData,
                      color: a['color'] as Color,
                      isDark: isDark,
                      onTap: a['onTap'] as VoidCallback,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOOKING OVERVIEW
  // ============================================================
  Widget _bookingOverview(bool isDark, OwnerProvider p) {
    final bookings = p.bookingRequests;
    final pending =
        bookings.where((b) => (b.status ?? 'PENDING') == 'PENDING').length;
    final accepted =
        bookings.where((b) => (b.status ?? '') == 'ACCEPTED').length;
    final rejected =
        bookings.where((b) => (b.status ?? '') == 'REJECTED').length;

    final items = [
      {
        'label': 'Pending',
        'value': pending.toString(),
        'icon': Icons.schedule_rounded,
        'color': _P.gold,
      },
      {
        'label': 'Accepted',
        'value': accepted.toString(),
        'icon': Icons.check_circle_rounded,
        'color': _P.success,
      },
      {
        'label': 'Rejected',
        'value': rejected.toString(),
        'icon': Icons.cancel_rounded,
        'color': _P.danger,
      },
      {
        'label': 'Total',
        'value': bookings.length.toString(),
        'icon': Icons.book_online_rounded,
        'color': _P.primary,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _P.darkSurface : Colors.white,
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
                    color: _P.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.pending_actions_rounded,
                      color: _P.gold, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _navigateTo(const OwnerBookingManagementPage()),
                  child: Text(
                    'View all',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _P.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(items.length, (i) {
                final it = items[i];
                return Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
                    child: _bookingStat(
                      label: it['label'] as String,
                      value: it['value'] as String,
                      icon: it['icon'] as IconData,
                      color: it['color'] as Color,
                      isDark: isDark,
                      onTap: () =>
                          _navigateTo(const OwnerBookingManagementPage()),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================
  Widget _loading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_P.primary, _P.primaryLight],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _P.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading dashboard...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Color _hex(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return _P.primary;
    }
  }

  String _formatNumber(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return NumberFormat('#,##0').format(value);
    }
    return value.toStringAsFixed(0);
  }
}
