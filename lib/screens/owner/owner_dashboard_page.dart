// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:yourhome/screens/owner/owner_profile_screen.dart';
import 'package:yourhome/screens/owner/owner_my_reels_screen.dart'; // 👈 ADD THIS IMPORT
import 'package:yourhome/screens/owner/owner_reels_upload_screen.dart'; // 👈 ADD THIS IMPORT
import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/api_service.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notification_screen.dart';
import 'owner_property_management_page.dart';
import 'owner_booking_management_page.dart';
import 'property_access_subscription_page.dart';
import 'listing_subscription_page.dart';
import 'owner_apply_page.dart';

class _OwnerPalette {
  static const primary = Color(0xFFF59E0B);
  static const primaryLight = Color(0xFFFBBF24);
  static const gold = Color(0xFFD4AF37);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const purple = Color(0xFF8B5CF6);
  static const blue = Color(0xFF3B82F6);
  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const lightBg = Color(0xFFF7F8FC);
  static const teal = Color(0xFF14B8A6);
  static const pink = Color(0xFFEC4899);
  static const reelColor = Color(0xFFF59E0B); // 👈 ADD THIS
}

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _isFirstLoad = true;
  int _unreadNotifications = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _selectedPropertyId = 0;
  String _selectedPropertyTitle = 'Property Access';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadAll();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    await ownerProvider.loadAllOwnerData();
    _loadPropertyData(ownerProvider);
    _loadUnreadNotifications();
  }

  void _loadPropertyData(OwnerProvider provider) {
    if (provider.myProperties.isNotEmpty) {
      final firstProperty = provider.myProperties.first;
      setState(() {
        _selectedPropertyId = firstProperty.propertyId ?? 0;
        _selectedPropertyTitle = firstProperty.title ?? 'Property';
      });
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final res = await ApiService().get('/notifications/unread-count');
      if (mounted && res.data['success'] == true) {
        setState(
            () => _unreadNotifications = res.data['data']['unreadCount'] ?? 0);
      }
    } catch (_) {}
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  void _navigateTo(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
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
    String listingTitle = 'Listing Subscription';
    int listingId = 0;
    if (ownerProvider.myProperties.isNotEmpty) {
      final firstProperty = ownerProvider.myProperties.first;
      listingId = firstProperty.propertyId ?? 0;
      listingTitle = firstProperty.title ?? 'Listing';
    }
    _navigateTo(
      ListingSubscriptionPage(
        listingId: listingId,
        listingTitle: listingTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final ownerProvider = Provider.of<OwnerProvider>(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final user = authProvider.user;
    final profileImage = profileProvider.profile?.profilePic;
    final stats = ownerProvider.dashboardStats;
    final verification = ownerProvider.verificationStatus;
    final accessStatus = ownerProvider.propertyAccessStatus;
    final listingSub = ownerProvider.listingSubscription;
    final ownerProfile = ownerProvider.ownerProfile;

    _loadPropertyData(ownerProvider);

    return Scaffold(
      backgroundColor: isDark ? _OwnerPalette.darkBg : _OwnerPalette.lightBg,
      appBar: _buildAppBar(context, isDark),
      body: ownerProvider.isLoading && stats == null
          ? _buildLoadingState(isDark)
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: _OwnerPalette.primary,
              backgroundColor:
                  isDark ? _OwnerPalette.darkSurface : Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      _buildProfileHeader(
                        context,
                        isDark,
                        user,
                        profileImage,
                        verification,
                        ownerProfile,
                      ),
                      const SizedBox(height: 16),
                      // Verification Status Card
                      if (verification != null)
                        _buildVerificationStatusCard(isDark, verification),
                      const SizedBox(height: 14),
                      // Stats Grid
                      if (stats != null) _buildStatsGrid(isDark, stats),
                      const SizedBox(height: 18),
                      // ========== 🎬 REELS SECTION ==========
                      _buildReelsSection(context, isDark), // 👈 ADD THIS
                      const SizedBox(height: 18),
                      // Subscription Section
                      _buildSubscriptionSection(
                        context,
                        isDark,
                        accessStatus,
                        listingSub,
                      ),
                      const SizedBox(height: 18),
                      // Quick Actions
                      _buildQuickActions(context, isDark, verification),
                      const SizedBox(height: 18),
                      // Pending Items
                      _buildPendingItems(context, isDark, ownerProvider),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ========== 🎬 REELS SECTION (NEW) ==========
  Widget _buildReelsSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.movie_creation_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '🎬 Reels',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Promote properties',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Upload Reel Card
              _buildReelsCard(
                context: context, // 👈 FIXED: Added named parameter
                icon: Icons.upload_rounded,
                label: 'Upload\nReel',
                subtitle: '20-30s video',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => _navigateTo(const OwnerReelsUploadScreen()),
              ),
              const SizedBox(width: 8),
              // My Reels Card
              _buildReelsCard(
                context: context, // 👈 FIXED: Added named parameter
                icon: Icons.video_library_rounded,
                label: 'My\nReels',
                subtitle: 'Manage all',
                color: const Color(0xFFD4AF37),
                isDark: isDark,
                onTap: () => _navigateTo(const OwnerMyReelsScreen()),
              ),
              const SizedBox(width: 8),
              // Stats Card
              _buildReelsCard(
                context: context, // 👈 FIXED: Added named parameter
                icon: Icons.analytics_rounded,
                label: 'Reel\nStats',
                subtitle: 'Performance',
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () {
                  _navigateTo(const OwnerMyReelsScreen());
                },
              ),
              const SizedBox(width: 8),
              // Tips Card
              _buildReelsCard(
                context: context, // 👈 FIXED: Added named parameter
                icon: Icons.tips_and_updates_rounded,
                label: 'Tips\n& Tricks',
                subtitle: 'Grow more',
                color: const Color(0xFF14B8A6),
                isDark: isDark,
                onTap: () {
                  _showReelsTipsDialog(context, isDark);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReelsCard({
    required BuildContext context, // 👈 Make sure this is here
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReelsTipsDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF141A2C) : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '🎬 Reels Tips',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              _buildTipItem('🎥', 'Keep videos 20-30 seconds', isDark),
              _buildTipItem('🏠', 'Showcase best property features', isDark),
              _buildTipItem('📝', 'Add engaging captions', isDark),
              _buildTipItem('📈', 'Post regularly for more views', isDark),
              _buildTipItem('⭐', 'Verified owners get more reach', isDark),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Got it! ✨',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
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

  Widget _buildTipItem(String emoji, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== APP BAR ==============
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _OwnerPalette.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: _OwnerPalette.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Dashboard',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.white : const Color(0xFF4B5563),
            size: 22,
          ),
          onPressed: _loadAll,
        ),
      ],
    );
  }

  // ============== LOADING STATE ==============
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_OwnerPalette.primary, _OwnerPalette.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _OwnerPalette.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============== PROFILE HEADER ==============
  Widget _buildProfileHeader(
    BuildContext context,
    bool isDark,
    dynamic user,
    String? profileImage,
    dynamic verification,
    dynamic ownerProfile,
  ) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;
    final isVerified = verification?.isVerified ?? false;
    final businessName = ownerProfile?.businessName;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () => _navigateTo(const OwnerProfileScreen()),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasImage
                    ? null
                    : const LinearGradient(
                        colors: [
                          _OwnerPalette.primary,
                          _OwnerPalette.primaryLight
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: _OwnerPalette.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.transparent,
                backgroundImage:
                    hasImage ? CachedNetworkImageProvider(profileImage) : null,
                child: hasImage
                    ? null
                    : Text(
                        user?.name?.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'O',
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
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  user?.name?.isNotEmpty == true ? user!.name : 'Owner',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (businessName != null && businessName.isNotEmpty)
                  Text(
                    businessName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                // Verification Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isVerified ? Colors.green : Colors.orange)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified_rounded
                            : Icons.hourglass_top_rounded,
                        size: 10,
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isVerified
                            ? 'Verified Owner'
                            : verification?.isRejected == true
                                ? 'Rejected'
                                : 'Pending',
                        style: GoogleFonts.poppins(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: isVerified ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Notification Button
          _buildNotificationButton(isDark),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              size: 22,
            ),
            if (_unreadNotifications > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: _OwnerPalette.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    _unreadNotifications > 9
                        ? '9+'
                        : _unreadNotifications.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 8,
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
          HapticFeedback.selectionClick();
          _navigateTo(const NotificationScreen());
        },
      ),
    );
  }

  // ============== VERIFICATION STATUS CARD ==============
  Widget _buildVerificationStatusCard(bool isDark, dynamic verification) {
    final isVerified = verification.isVerified;
    final isRejected = verification.isRejected;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVerified
              ? [Colors.green.withOpacity(0.10), Colors.teal.withOpacity(0.04)]
              : isRejected
                  ? [Colors.red.withOpacity(0.10), Colors.red.withOpacity(0.04)]
                  : [
                      Colors.orange.withOpacity(0.10),
                      Colors.orange.withOpacity(0.04)
                    ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified
              ? Colors.green.withOpacity(0.25)
              : isRejected
                  ? Colors.red.withOpacity(0.25)
                  : Colors.orange.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isVerified
                  ? Colors.green.withOpacity(0.15)
                  : isRejected
                      ? Colors.red.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_rounded
                  : isRejected
                      ? Icons.error_outline_rounded
                      : Icons.hourglass_top_rounded,
              color: isVerified
                  ? Colors.green
                  : isRejected
                      ? Colors.red
                      : Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? '✔ Verified Owner'
                      : isRejected
                          ? '✖ Verification Rejected'
                          : '⏳ Verification Pending',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  isVerified
                      ? 'You can add properties & receive bookings'
                      : isRejected
                          ? '${verification.rejectionReason ?? "Please re-apply"}'
                          : 'Admin reviews within 24-48 hours',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isRejected)
            TextButton(
              onPressed: () => _navigateTo(const OwnerApplyPage()),
              style: TextButton.styleFrom(
                foregroundColor: _OwnerPalette.primary,
                minimumSize: const Size(50, 28),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side:
                      BorderSide(color: _OwnerPalette.primary.withOpacity(0.3)),
                ),
              ),
              child: Text(
                'Re-apply',
                style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  // ============== STATS GRID ==============
  Widget _buildStatsGrid(bool isDark, dynamic stats) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Properties', stats.totalProperties.toString(),
                Icons.apartment_rounded, const Color(0xFF3B82F6), isDark),
            const SizedBox(width: 8),
            _buildStatCard('Published', stats.publishedProperties.toString(),
                Icons.check_circle_rounded, const Color(0xFF22C55E), isDark),
            const SizedBox(width: 8),
            _buildStatCard('Rooms', stats.totalRooms.toString(),
                Icons.bed_rounded, const Color(0xFF8B5CF6), isDark),
            const SizedBox(width: 8),
            _buildStatCard('Available', stats.availableRooms.toString(),
                Icons.meeting_room_rounded, const Color(0xFF06B6D4), isDark),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatCard('Bookings', stats.pendingRequests.toString(),
                Icons.book_online_rounded, const Color(0xFFF59E0B), isDark),
            const SizedBox(width: 8),
            _buildStatCard(
                'Accepted',
                stats.acceptedRequests?.toString() ?? '0',
                Icons.check_rounded,
                const Color(0xFF22C55E),
                isDark),
            const SizedBox(width: 8),
            _buildStatCard('Rating', stats.averageRating.toStringAsFixed(1),
                Icons.star_rounded, const Color(0xFFF59E0B), isDark),
            const SizedBox(width: 8),
            _buildStatCard('Views', stats.totalViews?.toString() ?? '0',
                Icons.visibility_rounded, const Color(0xFF8B5CF6), isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============== SUBSCRIPTION SECTION ==============
  Widget _buildSubscriptionSection(
    BuildContext context,
    bool isDark,
    dynamic accessStatus,
    dynamic listingSub,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _OwnerPalette.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: _OwnerPalette.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Subscriptions',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSubscriptionItem(
            context,
            '🏠 Property Access',
            accessStatus != null && accessStatus.hasActiveSubscription
                ? '${accessStatus.plan} • ${accessStatus.daysRemaining} days'
                : 'No active plan — tap to buy',
            accessStatus != null && accessStatus.hasActiveSubscription,
            const Color(0xFF3B82F6),
            isDark,
            onTap: _navigateToPropertyAccess,
          ),
          const SizedBox(height: 10),
          _buildSubscriptionItem(
            context,
            '📋 Listing Subscription',
            listingSub != null && listingSub.isActive
                ? '${listingSub.planDisplayName} • ${listingSub.daysRemaining} days'
                : 'Boost search — tap to buy',
            listingSub != null && listingSub.isActive,
            const Color(0xFF8B5CF6),
            isDark,
            onTap: _navigateToListingSubscription,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem(
    BuildContext context,
    String title,
    String subtitle,
    bool isActive,
    Color color,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isActive ? Colors.green : Colors.grey,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============== QUICK ACTIONS ==============
  Widget _buildQuickActions(
      BuildContext context, bool isDark, dynamic verification) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _OwnerPalette.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: _OwnerPalette.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildQuickActionItem(context, '🏢 Properties',
                  Icons.apartment_rounded, Colors.blue, isDark,
                  onTap: () =>
                      _navigateTo(const OwnerPropertyManagementPage())),
              const SizedBox(width: 8),
              _buildQuickActionItem(context, '📅 Bookings',
                  Icons.book_online_rounded, Colors.orange, isDark,
                  onTap: () => _navigateTo(const OwnerBookingManagementPage())),
              const SizedBox(width: 8),
              _buildQuickActionItem(context, '💬 Chat',
                  Icons.chat_bubble_rounded, Colors.green, isDark,
                  onTap: () => _navigateTo(const ChatListScreen())),
              const SizedBox(width: 8),
              _buildQuickActionItem(context, '🔔 Notifications',
                  Icons.notifications_rounded, Colors.purple, isDark,
                  onTap: () => _navigateTo(const NotificationScreen())),
            ],
          ),
          if (verification == null || verification.isRejected) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildQuickActionItem(context, '📝 Apply',
                    Icons.assignment_ind_rounded, _OwnerPalette.success, isDark,
                    onTap: () => _navigateTo(const OwnerApplyPage())),
                const SizedBox(width: 8),
                _buildQuickActionItem(context, '⭐ Profile',
                    Icons.person_rounded, _OwnerPalette.primary, isDark,
                    onTap: () => _navigateTo(const OwnerProfileScreen())),
                const SizedBox(width: 8),
                _buildQuickActionItem(context, '📊 Stats',
                    Icons.analytics_rounded, _OwnerPalette.teal, isDark,
                    onTap: () {}),
                const SizedBox(width: 8),
                _buildQuickActionItem(context, '❓ Help',
                    Icons.help_center_rounded, Colors.grey, isDark,
                    onTap: () {}),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== PENDING ITEMS ==============
  Widget _buildPendingItems(
      BuildContext context, bool isDark, OwnerProvider provider) {
    final bookings = provider.bookingRequests;
    final pendingBookings =
        bookings.where((b) => b.status == 'PENDING').toList();
    final acceptedBookings =
        bookings.where((b) => b.status == 'ACCEPTED').toList();
    final rejectedBookings =
        bookings.where((b) => b.status == 'REJECTED').toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Booking Overview',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPendingItem(
                  context,
                  '📌 Pending',
                  pendingBookings.length.toString(),
                  const Color(0xFFF59E0B),
                  isDark,
                  onTap: () => _navigateTo(const OwnerBookingManagementPage())),
              const SizedBox(width: 8),
              _buildPendingItem(
                  context,
                  '✅ Accepted',
                  acceptedBookings.length.toString(),
                  const Color(0xFF22C55E),
                  isDark,
                  onTap: () => _navigateTo(const OwnerBookingManagementPage())),
              const SizedBox(width: 8),
              _buildPendingItem(
                  context,
                  '❌ Rejected',
                  rejectedBookings.length.toString(),
                  const Color(0xFFEF4444),
                  isDark,
                  onTap: () => _navigateTo(const OwnerBookingManagementPage())),
              const SizedBox(width: 8),
              _buildPendingItem(
                  context,
                  '🏠 Properties',
                  provider.myProperties.length.toString(),
                  const Color(0xFF3B82F6),
                  isDark,
                  onTap: () =>
                      _navigateTo(const OwnerPropertyManagementPage())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingItem(
    BuildContext context,
    String label,
    String count,
    Color color,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
