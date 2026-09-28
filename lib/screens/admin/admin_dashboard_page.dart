import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:yourhome/screens/admin/admin_analytics_screen.dart';
import 'package:yourhome/screens/admin/charts/admin_charts.dart';
import 'package:yourhome/widgets/action_card.dart';
import 'package:yourhome/widgets/section_header.dart';
import 'package:yourhome/widgets/stat_card.dart';
import '../../models/admin_analytics_models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/referral_provider.dart';
import 'admin_owner_verification_page.dart';
import 'admin_payment_history_screen.dart';
import 'admin_report_management_page.dart';
import 'admin_subscription_screen.dart';
import 'admin_withdrawals_screen.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _isFirstLoad = true;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _ctrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadData();
      }
    });
  }

  void _loadData() {
    try {
      final adminP = Provider.of<AdminProvider>(context, listen: false);
      adminP.loadAllAdminData();
      final refP = Provider.of<ReferralProvider>(context, listen: false);
      refP.fetchPendingWithdrawals();
      refP.fetchWithdrawals();
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminP = Provider.of<AdminProvider>(context);
    final refP = Provider.of<ReferralProvider>(context);
    final authP = Provider.of<AuthProvider>(context);
    final summary = adminP.dashboardSummary;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      body: adminP.isLoading && summary == null
          ? _buildLoading(isDark)
          : RefreshIndicator(
              onRefresh: () async {
                await adminP.loadAllAdminData();
                await refP.fetchPendingWithdrawals();
                await refP.fetchWithdrawals();
              },
              color: const Color(0xFF7C3AED),
              child: FadeTransition(
                opacity: _fade,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(context, isDark, authP.user),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (summary != null) ...[
                            _buildWelcomeBanner(isDark, summary),
                            const SizedBox(height: 20),
                            _buildKpiGrid(isDark, summary),
                            const SizedBox(height: 24),
                            _buildActionsRequired(isDark, summary),
                            const SizedBox(height: 24),
                            _buildChartsTabs(isDark, summary),
                            const SizedBox(height: 24),
                            _buildRevenueTrend(isDark, summary),
                            const SizedBox(height: 24),
                            _buildUserOwnerTrends(isDark, summary),
                            const SizedBox(height: 24),
                            _buildBookingChart(isDark, summary),
                            const SizedBox(height: 24),
                            _buildBreakdowns(isDark, summary),
                            const SizedBox(height: 24),
                            _buildWithdrawalOverview(isDark, refP),
                            const SizedBox(height: 24),
                            _buildTopCities(isDark, summary),
                            const SizedBox(height: 24),
                            _buildPendingItems(isDark, adminP, refP),
                            const SizedBox(height: 24),
                            _buildQuickActions(isDark),
                          ] else
                            _buildError(isDark, adminP.error),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════
  // LOADING / ERROR
  // ═══════════════════════════════════════════
  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Loading dashboard...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              )),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(error ?? 'Failed to load',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════
  Widget _buildAppBar(BuildContext context, bool isDark, dynamic user) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      expandedHeight: 0,
      toolbarHeight: 70,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Dashboard',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  )),
              Text('Welcome, ${user?.name ?? 'Admin'}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  )),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AdminAnalyticsScreen()),
          ),
          tooltip: 'Full Analytics',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadData,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // WELCOME BANNER
  // ═══════════════════════════════════════════
  Widget _buildWelcomeBanner(bool isDark, AdminDashboardSummary s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67F5), Color(0xFFB794F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👋 Welcome Admin!',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 4),
                    Text('Here\'s your daily overview.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _welcomeStat(
                  'Revenue Today',
                  '₹${_fmtMoney(s.revenueToday)}',
                  Icons.currency_rupee_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _welcomeStat(
                  'Users Today',
                  '+${s.newUsersToday}',
                  Icons.person_add_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _welcomeStat(
                  'Bookings',
                  '+${s.newBookingsToday}',
                  Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _welcomeStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.white70,
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // KPI GRID — 6 Cards
  // ═══════════════════════════════════════════
  Widget _buildKpiGrid(bool isDark, AdminDashboardSummary s) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Total Users',
              value: _fmt(s.totalUsers),
              icon: Icons.people_rounded,
              color: const Color(0xFF3B82F6),
              growthPercent: s.userGrowthPercent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Total Owners',
              value: _fmt(s.totalOwners),
              icon: Icons.business_center_rounded,
              color: const Color(0xFF8B5CF6),
              growthPercent: s.ownerGrowthPercent,
              isDark: isDark,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AdminOwnerVerificationPage())),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Properties',
              value: _fmt(s.totalProperties),
              icon: Icons.apartment_rounded,
              color: const Color(0xFF06B6D4),
              growthPercent: s.propertyGrowthPercent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Bookings',
              value: _fmt(s.totalBookings),
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFFF59E0B),
              growthPercent: s.bookingGrowthPercent,
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Total Revenue',
              value: '₹${_fmtMoney(s.totalRevenue)}',
              icon: Icons.currency_rupee_rounded,
              color: const Color(0xFF10B981),
              growthPercent: s.revenueGrowthPercent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Active Subs',
              value: _fmt(s.activeSubscriptions),
              icon: Icons.workspace_premium_rounded,
              color: const Color(0xFFEC4899),
              isDark: isDark,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminSubscriptionScreen())),
            ),
          ),
        ]),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ACTIONS REQUIRED
  // ═══════════════════════════════════════════
  Widget _buildActionsRequired(bool isDark, AdminDashboardSummary s) {
    if (s.actionsRequired.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Actions Required',
          icon: Icons.priority_high_rounded,
          color: const Color(0xFFF59E0B),
          isDark: isDark,
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${s.actionsRequired.length}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                )),
          ),
        ),
        const SizedBox(height: 12),
        ...s.actionsRequired.map((item) => AdminActionCard(
              item: item,
              isDark: isDark,
              onTap: () => _handleActionTap(item),
            )),
      ],
    );
  }

  void _handleActionTap(AdminActionItem item) {
    switch (item.type) {
      case 'PENDING_OWNER':
      case 'VERIFICATION_PENDING':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AdminOwnerVerificationPage()));
        break;
      case 'PENDING_WITHDRAWAL':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminWithdrawalsScreen()));
        break;
      case 'PENDING_REPORT':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AdminReportManagementPage()));
        break;
      default:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()));
    }
  }

  // ═══════════════════════════════════════════
  // CHARTS TABS — 4 tabs
  // ═══════════════════════════════════════════
  Widget _buildChartsTabs(bool isDark, AdminDashboardSummary s) {
    final tabs = ['📈 Revenue', '👥 Users', '📊 Bookings', '🏢 Properties'];

    return _card(
      isDark,
      Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.asMap().entries.map((e) {
                final isSelected = _activeTab == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e.value,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _activeTab == 0
                ? AdminLineChart(
                    data: s.revenueTrend,
                    lineColor: const Color(0xFF10B981),
                    yAxisSuffix: '₹',
                    isDark: isDark,
                  )
                : _activeTab == 1
                    ? AdminLineChart(
                        data: s.userTrend,
                        lineColor: const Color(0xFF3B82F6),
                        isDark: isDark,
                      )
                    : _activeTab == 2
                        ? AdminBarChart(
                            data: s.bookingTrend,
                            barColor: const Color(0xFFF59E0B),
                            isDark: isDark,
                            height: 180,
                          )
                        : AdminLineChart(
                            data: s.propertyTrend,
                            lineColor: const Color(0xFF06B6D4),
                            isDark: isDark,
                          ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // REVENUE TREND (Full)
  // ═══════════════════════════════════════════
  Widget _buildRevenueTrend(bool isDark, AdminDashboardSummary s) {
    return _card(
      isDark,
      AdminLineChart(
        data: s.revenueTrend,
        lineColor: const Color(0xFF10B981),
        title: '📈 Revenue Trend (7 days)',
        yAxisSuffix: '₹',
        isDark: isDark,
        height: 200,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // USER + OWNER TRENDS
  // ═══════════════════════════════════════════
  Widget _buildUserOwnerTrends(bool isDark, AdminDashboardSummary s) {
    return Row(
      children: [
        Expanded(
          child: _card(
            isDark,
            AdminLineChart(
              data: s.userTrend,
              lineColor: const Color(0xFF3B82F6),
              title: '👥 Users',
              isDark: isDark,
              height: 140,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _card(
            isDark,
            AdminLineChart(
              data: s.ownerTrend,
              lineColor: const Color(0xFF8B5CF6),
              title: '🏢 Owners',
              isDark: isDark,
              height: 140,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // BOOKING BAR CHART
  // ═══════════════════════════════════════════
  Widget _buildBookingChart(bool isDark, AdminDashboardSummary s) {
    return _card(
      isDark,
      AdminBarChart(
        data: s.bookingTrend,
        barColor: const Color(0xFFF59E0B),
        title: '📊 Bookings (7 days)',
        isDark: isDark,
        height: 200,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // BREAKDOWNS — 3 donut charts
  // ═══════════════════════════════════════════
  Widget _buildBreakdowns(bool isDark, AdminDashboardSummary s) {
    return Column(
      children: [
        _card(
          isDark,
          AdminDonutChart(
            data: s.userRoleBreakdown,
            colors: const [
              Color(0xFF3B82F6),
              Color(0xFF8B5CF6),
              Color(0xFF7C3AED),
            ],
            title: '👤 User Roles',
            centerLabel: 'Total',
            centerValue: _fmt(s.totalUsers),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        _card(
          isDark,
          AdminDonutChart(
            data: s.ownerVerificationBreakdown,
            colors: const [
              Color(0xFF22C55E),
              Color(0xFFF59E0B),
              Color(0xFFEF4444),
            ],
            title: '✅ Owner Verification',
            centerLabel: 'Owners',
            centerValue: _fmt(s.totalOwners),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        _card(
          isDark,
          AdminDonutChart(
            data: s.bookingStatusBreakdown,
            colors: const [
              Color(0xFFF59E0B),
              Color(0xFF22C55E),
              Color(0xFFEF4444),
              Color(0xFF8A8FA3),
              Color(0xFF3B82F6),
            ],
            title: '📋 Booking Status',
            centerLabel: 'Bookings',
            centerValue: _fmt(s.totalBookings),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // WITHDRAWAL OVERVIEW
  // ═══════════════════════════════════════════
  Widget _buildWithdrawalOverview(bool isDark, ReferralProvider refP) {
    final pending = refP.pendingWithdrawals.length;
    final totalAmount = refP.pendingWithdrawals.fold<double>(
        0.0, (sum, item) => sum + item.amount);
    final approved = refP.withdrawals
        .where((w) => w.status == 'APPROVED')
        .length;
    final failed =
        refP.withdrawals.where((w) => w.status == 'FAILED').length;

    return _card(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Withdrawals Overview',
            icon: Icons.payments_rounded,
            color: const Color(0xFF7C3AED),
            isDark: isDark,
            trailing: pending > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$pending Pending',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        )),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _smallStat(
                  isDark,
                  'Pending ₹',
                  '₹${totalAmount.toStringAsFixed(0)}',
                  const Color(0xFFF59E0B),
                  Icons.pending_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallStat(
                  isDark,
                  'Total',
                  '${refP.withdrawals.length}',
                  const Color(0xFF7C3AED),
                  Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallStat(
                  isDark,
                  'Approved',
                  '$approved',
                  const Color(0xFF10B981),
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallStat(
                  isDark,
                  'Failed',
                  '$failed',
                  const Color(0xFFEF4444),
                  Icons.cancel_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminWithdrawalsScreen())),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7C3AED),
                    side: const BorderSide(
                        color: Color(0xFF7C3AED), width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AdminPaymentHistoryScreen())),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(
                        color: Color(0xFF8B5CF6), width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallStat(bool isDark, String label, String value, Color color,
      IconData icon) {
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
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              )),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TOP CITIES
  // ═══════════════════════════════════════════
  Widget _buildTopCities(bool isDark, AdminDashboardSummary s) {
    if (s.topCities.isEmpty) return const SizedBox.shrink();
    return _card(
      isDark,
      AdminBarChart(
        data: s.topCities.take(6).toList(),
        barColor: const Color(0xFF7C3AED),
        title: '🏙️ Top Cities',
        isDark: isDark,
        height: 200,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PENDING ITEMS
  // ═══════════════════════════════════════════
  Widget _buildPendingItems(
      bool isDark, AdminProvider p, ReferralProvider refP) {
    return _card(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Pending Items',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pendingItem(
                isDark,
                'Withdrawals',
                '${refP.pendingWithdrawals.length}',
                const Color(0xFF7C3AED),
                Icons.payments_rounded,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminWithdrawalsScreen())),
              ),
              const SizedBox(width: 8),
              _pendingItem(
                isDark,
                'Owners',
                '${p.pendingOwners.length}',
                const Color(0xFFF59E0B),
                Icons.people_rounded,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AdminOwnerVerificationPage())),
              ),
              const SizedBox(width: 8),
              _pendingItem(
                isDark,
                'Properties',
                '${p.pendingProperties.length}',
                const Color(0xFF3B82F6),
                Icons.apartment_rounded,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pendingItem(
                isDark,
                'Reports',
                '${p.pendingReports.length}',
                const Color(0xFFEF4444),
                Icons.flag_rounded,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AdminReportManagementPage())),
              ),
              const SizedBox(width: 8),
              _pendingItem(
                isDark,
                'Subscriptions',
                '${p.subscriptions.where((s) => s.status == "ACTIVE").length}',
                const Color(0xFF8B5CF6),
                Icons.workspace_premium_rounded,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminSubscriptionScreen())),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pendingItem(bool isDark, String label, String count, Color color,
      IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(count,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════
  Widget _buildQuickActions(bool isDark) {
    return _card(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Quick Actions',
            icon: Icons.flash_on_rounded,
            color: const Color(0xFF7C3AED),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _quickItem(isDark, 'Withdrawals', Icons.payments_rounded,
                  const Color(0xFF7C3AED), () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminWithdrawalsScreen()));
              }),
              const SizedBox(width: 8),
              _quickItem(isDark, 'History', Icons.history_rounded,
                  const Color(0xFF8B5CF6), () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminPaymentHistoryScreen()));
              }),
              const SizedBox(width: 8),
              _quickItem(isDark, 'Verify', Icons.verified_rounded,
                  const Color(0xFF3B82F6), () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminOwnerVerificationPage()));
              }),
              const SizedBox(width: 8),
              _quickItem(isDark, 'Reports', Icons.flag_rounded,
                  const Color(0xFFEF4444), () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminReportManagementPage()));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickItem(bool isDark, String label, IconData icon, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
  Widget _card(bool isDark, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _fmtMoney(double n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(2)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}