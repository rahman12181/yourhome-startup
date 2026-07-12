import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:yourhome/models/admin_model.dart';
import 'package:yourhome/screens/admin/admin_owner_verification_page.dart';
import 'package:yourhome/screens/admin/admin_report_management_page.dart';
import 'package:yourhome/screens/admin/admin_subscription_screen.dart';
import 'package:yourhome/screens/admin/admin_withdrawals_screen.dart'; // ✅ NEW IMPORT
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/referral_provider.dart'; // ✅ NEW IMPORT

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _isFirstLoad = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
        _loadData();
      }
    });
  }

  void _loadData() {
    try {
      final adminProvider = Provider.of<AdminProvider>(
        context,
        listen: false,
      );
      adminProvider.loadAllAdminData();
      
      // ✅ NEW: Load referral data too
      final referralProvider = Provider.of<ReferralProvider>(
        context,
        listen: false,
      );
      referralProvider.fetchPendingWithdrawals();
      referralProvider.fetchWithdrawals();
    } catch (e) {
      print('❌ Error loading admin data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminProvider = Provider.of<AdminProvider>(context);
    final referralProvider = Provider.of<ReferralProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final stats = adminProvider.dashboardStats;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
      appBar: _buildAppBar(context, isDark, user),
      body: adminProvider.isLoading && stats == null
          ? _buildLoadingState(isDark)
          : RefreshIndicator(
              onRefresh: () async {
                await adminProvider.loadAllAdminData();
                await referralProvider.fetchPendingWithdrawals();
                await referralProvider.fetchWithdrawals();
              },
              color: const Color(0xFF7C3AED),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ✅ NEW: Withdrawal Stats Card
                      _buildWithdrawalStats(context, isDark, referralProvider),
                      const SizedBox(height: 16),
                      // Stats Grid
                      _buildStatsGrid(context, isDark, stats),
                      const SizedBox(height: 24),
                      // Revenue Breakdown
                      _buildRevenueBreakdown(context, isDark, stats),
                      const SizedBox(height: 24),
                      // Quick Actions
                      _buildQuickActions(context, isDark, referralProvider),
                      const SizedBox(height: 24),
                      // Pending Items
                      _buildPendingItems(context, isDark, adminProvider, referralProvider),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ============== APP BAR ==============
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    dynamic user,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFF7C3AED),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Admin Dashboard',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
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
          ),
          onPressed: _loadData,
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading dashboard...',
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

  // ============== ✅ PREMIUM WITHDRAWAL STATS CARD ==============
Widget _buildWithdrawalStats(
  BuildContext context,
  bool isDark,
  ReferralProvider provider,
) {
  final pendingCount = provider.pendingWithdrawals.length;
  final pendingAmount = provider.pendingWithdrawals.fold(
    0.0,
    (sum, item) => sum + item.amount,
  );
  final totalWithdrawals = provider.withdrawals.length;
  final approvedWithdrawals = provider.withdrawals.where((w) => w.status == 'APPROVED').length;
  final rejectedWithdrawals = provider.withdrawals.where((w) => w.status == 'REJECTED').length;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A1F33) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
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
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: Color(0xFF7C3AED),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Withdrawals Overview',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            if (pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$pendingCount Pending',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Manage all withdrawal requests from users',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 20),

        // Stats Grid - 4 cards in a row
        Row(
          children: [
            _buildWithdrawalStatItem(
              context,
              'Pending Amount',
              '₹${pendingAmount.toStringAsFixed(0)}',
              Icons.pending_rounded,
              Colors.orange,
              isDark,
            ),
            const SizedBox(width: 10),
            _buildWithdrawalStatItem(
              context,
              'Total Requests',
              totalWithdrawals.toString(),
              Icons.receipt_long_rounded,
              const Color(0xFF7C3AED),
              isDark,
            ),
            const SizedBox(width: 10),
            _buildWithdrawalStatItem(
              context,
              'Approved',
              approvedWithdrawals.toString(),
              Icons.check_circle_rounded,
              Colors.green,
              isDark,
            ),
            const SizedBox(width: 10),
            _buildWithdrawalStatItem(
              context,
              'Rejected',
              rejectedWithdrawals.toString(),
              Icons.cancel_rounded,
              Colors.red,
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // View All Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminWithdrawalsScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.arrow_forward_rounded,
              color: const Color(0xFF7C3AED),
              size: 18,
            ),
            label: Text(
              'View All Withdrawals',
              style: GoogleFonts.poppins(
                color: const Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ============== ✅ WITHDRAWAL STAT ITEM ==============
Widget _buildWithdrawalStatItem(
  BuildContext context,
  String label,
  String value,
  IconData icon,
  Color color,
  bool isDark,
) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
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
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

  // ============== STATS GRID ==============
  Widget _buildStatsGrid(
    BuildContext context,
    bool isDark,
    AdminDashboardStats? stats,
  ) {
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Row 1: Users, Owners, Verified Owners, Pending
        Row(
          children: [
            _buildStatCard(
              context,
              'Total Users',
              stats.totalUsers.toString(),
              Icons.people_rounded,
              const Color(0xFF3B82F6),
              isDark,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              context,
              'Total Owners',
              stats.totalOwners.toString(),
              Icons.business_center_rounded,
              const Color(0xFF8B5CF6),
              isDark,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              context,
              'Verified Owners',
              stats.verifiedOwners.toString(),
              Icons.verified_rounded,
              const Color(0xFF22C55E),
              isDark,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              context,
              'Pending Verif.',
              stats.pendingVerifications.toString(),
              Icons.pending_actions_rounded,
              const Color(0xFFF59E0B),
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Properties, Published, Pending Props, Revenue
        Row(
          children: [
            _buildStatCard(
              context,
              'Total Properties',
              stats.totalProperties.toString(),
              Icons.apartment_rounded,
              const Color(0xFF06B6D4),
              isDark,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              context,
              'Published',
              stats.publishedProperties.toString(),
              Icons.check_circle_rounded,
              const Color(0xFF22C55E),
              isDark,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              context,
              'Pending Props',
              stats.pendingProperties.toString(),
              Icons.pending_rounded,
              const Color(0xFFF59E0B),
              isDark,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              context,
              'Total Revenue',
              '₹${stats.totalRevenue.toStringAsFixed(0)}',
              Icons.currency_rupee_rounded,
              const Color(0xFF10B981),
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============== REVENUE BREAKDOWN ==============
  Widget _buildRevenueBreakdown(
    BuildContext context,
    bool isDark,
    AdminDashboardStats? stats,
  ) {
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Revenue Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dono subscription types ka combined revenue',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          // Listing Subscription
          _buildRevenueItem(
            context,
            '📋 Listing Subscription',
            '₹${stats.listingSubscriptionRevenue.toStringAsFixed(0)}',
            'BASIC / STANDARD / PREMIUM / ENTERPRISE',
            const Color(0xFF3B82F6),
            isDark,
          ),
          const SizedBox(height: 12),
          // Property Access
          _buildRevenueItem(
            context,
            '🏠 Property Access',
            '₹${stats.propertyAccessRevenue.toStringAsFixed(0)}',
            '1M / 2M / 3M / 4M / 5M plans',
            const Color(0xFF8B5CF6),
            isDark,
          ),
          const Divider(height: 24),
          // Total Revenue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_money_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Revenue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              Text(
                '₹${stats.totalRevenue.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Listing + Property Access combined',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(
    BuildContext context,
    String title,
    String amount,
    String subtitle,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.attach_money_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============== UPDATED: QUICK ACTIONS ==============
  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
    ReferralProvider referralProvider,
  ) {
    final pendingCount = referralProvider.pendingWithdrawals.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionItem(
                  context,
                  '💳 Withdrawals',
                  Icons.payments_rounded,
                  const Color(0xFF7C3AED),
                  isDark,
                  badge: pendingCount > 0 ? pendingCount.toString() : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminWithdrawalsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionItem(
                  context,
                  '👥 Verify\nOwners',
                  Icons.verified_rounded,
                  Colors.blue,
                  isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminOwnerVerificationPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionItem(
                  context,
                  '🏢 Publish\nProperties',
                  Icons.publish_rounded,
                  Colors.green,
                  isDark,
                  onTap: () {
                    // Navigate to Property Management -> Pending
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionItem(
                  context,
                  '🚨 Pending\nReports',
                  Icons.flag_rounded,
                  Colors.red,
                  isDark,
                  onTap: () {
                    // Navigate to Reports
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    bool isDark, {
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
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

  // ============== UPDATED: PENDING ITEMS ==============
  Widget _buildPendingItems(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
    ReferralProvider referralProvider,
  ) {
    final pendingWithdrawals = referralProvider.pendingWithdrawals.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Pending Items',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // ✅ NEW: Withdrawals Pending
              _buildPendingItem(
                context,
                '💳 Withdrawals',
                pendingWithdrawals.toString(),
                const Color(0xFF7C3AED),
                isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminWithdrawalsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _buildPendingItem(
                context,
                '👥 Owners',
                provider.pendingOwners.length.toString(),
                const Color(0xFFF59E0B),
                isDark,
                onTap: () {
                  // Navigate to Pending Owners
                },
              ),
              const SizedBox(width: 10),
              _buildPendingItem(
                context,
                '🏢 Properties',
                provider.pendingProperties.length.toString(),
                const Color(0xFF3B82F6),
                isDark,
                onTap: () {
                  // Navigate to Pending Properties
                },
              ),
              const SizedBox(width: 10),
              _buildPendingItem(
                context,
                '🚨 Reports',
                provider.pendingReports.length.toString(),
                const Color(0xFFEF4444),
                isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminReportManagementPage(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _buildPendingItem(
                context,
                '📋 Subs',
                provider.subscriptions
                    .where((s) => s.status == 'ACTIVE')
                    .length
                    .toString(),
                const Color(0xFF8B5CF6),
                isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminSubscriptionScreen(),
                    ),
                  );
                },
              ),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
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