// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/api_service.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile_screen.dart';
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
  int _unreadChats = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Property data for navigation
  int _selectedPropertyId = 0;
  String _selectedPropertyTitle = 'Property Access';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadAll();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    await ownerProvider.loadAllOwnerData();
    
    // Property data load karo
    _loadPropertyData(ownerProvider);
    
    _loadUnreadNotifications();
    _loadUnreadChats();
  }

  // ============== PROPERTY DATA LOAD ==============
  void _loadPropertyData(OwnerProvider provider) {
    // FIXED: 'myProperties' use karo - yeh tumhare provider mein hai
    if (provider.myProperties.isNotEmpty) {
      final firstProperty = provider.myProperties.first;
      setState(() {
        _selectedPropertyId = firstProperty.propertyId ?? 0;
        _selectedPropertyTitle = firstProperty.title ?? 'Property';
      });
    } else {
      setState(() {
        _selectedPropertyId = 0;
        _selectedPropertyTitle = 'Property Access';
      });
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final res = await ApiService().get('/notifications/unread-count');
      if (mounted && res.data['success'] == true) {
        setState(() => _unreadNotifications = res.data['data']['unreadCount'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadChats() async {
    try {
      final res = await ApiService().get('/chat/conversations');
      if (mounted && res.data['success'] == true) {
        final list = res.data['data'] as List;
        final total = list.fold<int>(0, (sum, c) => sum + ((c['unreadCount'] ?? 0) as int));
        setState(() => _unreadChats = total);
      }
    } catch (_) {}
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _navigateTo(Widget screen) {
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

  // ============== NAVIGATION WITH ACTUAL DATA ==============
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
    
    // FIXED: 'myProperties' use karo
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

    final user = authProvider.user;
    final profileImage = profileProvider.profile?.profilePic;
    final stats = ownerProvider.dashboardStats;
    final verification = ownerProvider.verificationStatus;
    final accessStatus = ownerProvider.propertyAccessStatus;
    final listingSub = ownerProvider.listingSubscription;

    // Har build pe property data update karo
    _loadPropertyData(ownerProvider);

    return Scaffold(
      backgroundColor: isDark ? _OwnerPalette.darkBg : _OwnerPalette.lightBg,
      body: SafeArea(
        child: ownerProvider.isLoading && stats == null
            ? const Center(child: CircularProgressIndicator(color: _OwnerPalette.primary))
            : RefreshIndicator(
                onRefresh: _loadAll,
                color: _OwnerPalette.primary,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, isDark, user, profileImage, verification),
                        const SizedBox(height: 16),
                        if (verification != null && !verification.isVerified)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildVerificationBanner(context, verification, isDark),
                          ),
                        if (accessStatus != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildAccessBanner(context, accessStatus, isDark),
                          ),
                        const SizedBox(height: 8),
                        if (stats != null) _buildStatsGrid(isDark, stats),
                        const SizedBox(height: 20),
                        _buildSubscriptionCards(context, isDark, accessStatus, listingSub),
                        const SizedBox(height: 24),
                        _buildQuickActions(context, isDark, verification),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context, bool isDark, dynamic user, String? profileImage,
      dynamic verification) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateTo(const ProfileScreen()),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasImage
                    ? null
                    : const LinearGradient(
                        colors: [_OwnerPalette.primary, _OwnerPalette.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: _OwnerPalette.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.transparent,
                backgroundImage: hasImage ? CachedNetworkImageProvider(profileImage) : null,
                child: hasImage
                    ? null
                    : Text(
                        user?.name?.isNotEmpty == true ? user!.name[0].toUpperCase() : 'O',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[500])),
                const SizedBox(height: 2),
                Text(
                  user?.name?.isNotEmpty == true ? user!.name : 'Owner',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (verification != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (verification.isVerified ? _OwnerPalette.success : Colors.orange)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          verification.isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                          size: 11,
                          color: verification.isVerified ? _OwnerPalette.success : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          verification.isVerified
                              ? 'Verified Owner'
                              : verification.isRejected
                                  ? 'Rejected'
                                  : 'Pending Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: verification.isVerified ? _OwnerPalette.success : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _buildIconButton(
            isDark,
            Icons.chat_bubble_outline_rounded,
            _unreadChats,
            () => _navigateTo(const ChatListScreen()),
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            isDark,
            Icons.notifications_outlined,
            _unreadNotifications,
            () => _navigateTo(const NotificationScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(bool isDark, IconData icon, int badgeCount, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _OwnerPalette.darkSurface : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF4B5563), size: 24),
            if (badgeCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: _OwnerPalette.danger, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    badgeCount > 9 ? '9+' : badgeCount.toString(),
                    style: GoogleFonts.poppins(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onPressed: onTap,
      ),
    );
  }

  // ================= BANNERS =================
  Widget _buildVerificationBanner(BuildContext context, dynamic verification, bool isDark) {
    final isRejected = verification.isRejected;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isRejected ? _OwnerPalette.danger : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isRejected ? _OwnerPalette.danger : Colors.orange).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isRejected ? Icons.error_outline_rounded : Icons.hourglass_empty_rounded,
              color: isRejected ? _OwnerPalette.danger : Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRejected
                  ? 'Rejected: ${verification.rejectionReason ?? "Please re-apply"}'
                  : 'Verification pending — Admin reviews within 24-48 hrs',
              style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          if (isRejected)
            TextButton(
              onPressed: () => _navigateTo(const OwnerApplyPage()),
              child: const Text('Re-apply'),
            ),
        ],
      ),
    );
  }

  Widget _buildAccessBanner(BuildContext context, dynamic accessStatus, bool isDark) {
    if (!accessStatus.hasActiveSubscription) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _OwnerPalette.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _OwnerPalette.danger.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: _OwnerPalette.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text('No active Property Access — buy to add properties',
                  style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
            ),
            TextButton(
              onPressed: _navigateToPropertyAccess,
              child: const Text('Buy'),
            ),
          ],
        ),
      );
    }
    if (accessStatus.isExpiringSoon) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${accessStatus.daysRemaining} din mein Property Access expire hoga',
                  style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
            ),
            TextButton(
              onPressed: _navigateToPropertyAccess,
              child: const Text('Renew'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ================= STATS =================
  Widget _buildStatsGrid(bool isDark, dynamic stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _statCard('Properties', stats.totalProperties.toString(), Icons.apartment_rounded,
                  _OwnerPalette.blue, isDark),
              const SizedBox(width: 10),
              _statCard('Published', stats.publishedProperties.toString(), Icons.check_circle_rounded,
                  _OwnerPalette.success, isDark),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statCard('Total Rooms', stats.totalRooms.toString(), Icons.bed_rounded,
                  _OwnerPalette.purple, isDark),
              const SizedBox(width: 10),
              _statCard('Available', stats.availableRooms.toString(), Icons.meeting_room_rounded,
                  const Color(0xFF06B6D4), isDark),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statCard('Pending Req.', stats.pendingRequests.toString(), Icons.pending_actions_rounded,
                  Colors.orange, isDark),
              const SizedBox(width: 10),
              _statCard('Avg Rating', stats.averageRating.toStringAsFixed(1), Icons.star_rounded,
                  Colors.amber, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _OwnerPalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ================= SUBSCRIPTION CARDS =================
  Widget _buildSubscriptionCards(
      BuildContext context, bool isDark, dynamic accessStatus, dynamic listingSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscriptions',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _navigateToPropertyAccess,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_OwnerPalette.primary, _OwnerPalette.gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: _OwnerPalette.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Property Access',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          accessStatus != null && accessStatus.hasActiveSubscription
                              ? '${accessStatus.plan} • ${accessStatus.daysRemaining} days left'
                              : 'No active plan — tap to buy',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _navigateToListingSubscription,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_OwnerPalette.purple, Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: _OwnerPalette.purple.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Listing Subscription',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          listingSub != null && listingSub.isActive
                              ? '${listingSub.planDisplayName} • ${listingSub.daysRemaining} days left'
                              : 'Boost search ranking — tap to buy',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _buildQuickActions(BuildContext context, bool isDark, dynamic verification) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? _OwnerPalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            const SizedBox(height: 12),
            _actionTile(context, '🏢 Manage Properties', Icons.apartment_rounded, _OwnerPalette.blue, isDark,
                onTap: () => _navigateTo(const OwnerPropertyManagementPage())),
            _actionTile(context, '📅 Booking Requests', Icons.book_online_rounded, Colors.orange, isDark,
                onTap: () => _navigateTo(const OwnerBookingManagementPage())),
            _actionTile(context, '💬 Chat with Users', Icons.chat_bubble_rounded, _OwnerPalette.success, isDark,
                onTap: () => _navigateTo(const ChatListScreen())),
            _actionTile(context, '🔔 Notifications', Icons.notifications_rounded, _OwnerPalette.purple, isDark,
                onTap: () => _navigateTo(const NotificationScreen())),
            if (verification == null || verification.isRejected)
              _actionTile(context, '📝 Apply / Re-apply as Owner', Icons.assignment_ind_rounded,
                  _OwnerPalette.success, isDark,
                  onTap: () => _navigateTo(const OwnerApplyPage())),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext context, String title, IconData icon, Color color, bool isDark,
      {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      ),
    );
  }
}