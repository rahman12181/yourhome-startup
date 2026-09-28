import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:yourhome/screens/admin/charts/admin_charts.dart';
import 'package:yourhome/widgets/period_selector.dart';
import 'package:yourhome/widgets/stat_card.dart';
import '../../models/admin_analytics_models.dart';
import '../../providers/admin_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadAll();
      }
    });
  }

  Future<void> _loadAll() async {
    final p = Provider.of<AdminProvider>(context, listen: false);
    await p.loadAllAnalytics();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        title: Text('Analytics',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PeriodSelector(
              selected: p.analyticsPeriod,
              onChanged: (period) async {
                p.setAnalyticsPeriod(period);
                await p.loadAllAnalytics(period: period);
              },
              isDark: isDark,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor:
              isDark ? Colors.grey[500] : Colors.grey[600],
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '👥 Users'),
            Tab(text: '🏢 Owners'),
            Tab(text: '💰 Revenue'),
            Tab(text: '📋 Bookings'),
            Tab(text: '🏠 Properties'),
            Tab(text: '📊 Engagement'),
          ],
        ),
      ),
      body: p.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _userTab(isDark, p),
                _ownerTab(isDark, p),
                _revenueTab(isDark, p),
                _bookingTab(isDark, p),
                _propertyTab(isDark, p),
                _engagementTab(isDark, p),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════
  // USER TAB
  // ═══════════════════════════════════════════
  Widget _userTab(bool isDark, AdminProvider p) {
    final u = p.userAnalytics;
    if (u == null) return _empty('User analytics not available');

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Total Users',
              value: _fmt(u.totalUsers),
              icon: Icons.people_rounded,
              color: const Color(0xFF3B82F6),
              growthPercent: u.growthPercent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Active',
              value: _fmt(u.activeUsers),
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Verified',
              value: _fmt(u.verifiedUsers),
              icon: Icons.verified_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Retention',
              value: '${u.retentionRate.toStringAsFixed(0)}%',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'New Today',
              value: '+${u.newUsersToday}',
              icon: Icons.person_add_rounded,
              color: const Color(0xFF06B6D4),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Churn Rate',
              value: '${u.churnRate.toStringAsFixed(1)}%',
              icon: Icons.trending_down_rounded,
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 20),

        _card(isDark, AdminLineChart(
          data: u.growthTrend,
          lineColor: const Color(0xFF3B82F6),
          title: '📈 Growth Trend (${p.analyticsPeriod})',
          isDark: isDark,
          height: 200,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: u.roleBreakdown,
          colors: const [
            Color(0xFF3B82F6),
            Color(0xFF8B5CF6),
            Color(0xFF7C3AED),
          ],
          title: '👤 Role Breakdown',
          centerLabel: 'Total',
          centerValue: _fmt(u.totalUsers),
          isDark: isDark,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: u.cityBreakdown.take(8).toList(),
          barColor: const Color(0xFF3B82F6),
          title: '🏙️ Top Cities',
          isDark: isDark,
          height: 200,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: u.signupByDayOfWeek,
          barColor: const Color(0xFF8B5CF6),
          title: '📊 Signups by Day of Week',
          isDark: isDark,
          height: 180,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: u.activeVsInactive,
          colors: const [Color(0xFF10B981), Color(0xFFEF4444)],
          title: '⚡ Active vs Inactive',
          centerLabel: 'Users',
          centerValue: _fmt(u.totalUsers),
          isDark: isDark,
        )),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // OWNER TAB
  // ═══════════════════════════════════════════
  Widget _ownerTab(bool isDark, AdminProvider p) {
    final o = p.ownerAnalytics;
    if (o == null) return _empty('Owner analytics not available');

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Total Owners',
              value: _fmt(o.totalOwners),
              icon: Icons.business_center_rounded,
              color: const Color(0xFF8B5CF6),
              growthPercent: o.growthPercent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Verified',
              value: _fmt(o.verifiedOwners),
              icon: Icons.verified_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Pending',
              value: _fmt(o.pendingVerifications),
              icon: Icons.pending_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Rejected',
              value: _fmt(o.rejectedOwners),
              icon: Icons.cancel_rounded,
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Avg Properties',
              value: o.averagePropertiesPerOwner.toStringAsFixed(1),
              icon: Icons.apartment_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Avg Revenue',
              value: '₹${_fmtMoney(o.averageRevenuePerOwner)}',
              icon: Icons.currency_rupee_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 20),

        _card(isDark, AdminLineChart(
          data: o.growthTrend,
          lineColor: const Color(0xFF8B5CF6),
          title: '📈 Growth Trend (${p.analyticsPeriod})',
          isDark: isDark,
          height: 200,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: o.verificationBreakdown,
          colors: const [
            Color(0xFF10B981),
            Color(0xFFF59E0B),
            Color(0xFFEF4444),
          ],
          title: '✅ Verification Status',
          centerLabel: 'Owners',
          centerValue: _fmt(o.totalOwners),
          isDark: isDark,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: o.subscriptionPlanBreakdown,
          barColor: const Color(0xFF8B5CF6),
          title: '💎 Subscription Plans',
          isDark: isDark,
          height: 180,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: o.propertyAccessPlanBreakdown,
          barColor: const Color(0xFF7C3AED),
          title: '🏠 Property Access Plans',
          isDark: isDark,
          height: 180,
        )),
        const SizedBox(height: 16),

        if (o.topOwnersByRevenue.isNotEmpty)
          _card(
            isDark,
            _topList(
              o.topOwnersByRevenue,
              '💰 Top Owners by Revenue',
              const Color(0xFF10B981),
              isDark,
            ),
          ),
        const SizedBox(height: 16),

        if (o.topOwnersByProperties.isNotEmpty)
          _card(
            isDark,
            _topList(
              o.topOwnersByProperties,
              '🏢 Top Owners by Properties',
              const Color(0xFF3B82F6),
              isDark,
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // REVENUE TAB
  // ═══════════════════════════════════════════
  Widget _revenueTab(bool isDark, AdminProvider p) {
    final r = p.revenueAnalytics;
    if (r == null) return _empty('Revenue analytics not available');

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        AdminStatCard(
          label: 'Total Revenue',
          value: '₹${_fmtMoney(r.totalRevenue)}',
          icon: Icons.currency_rupee_rounded,
          color: const Color(0xFF10B981),
          growthPercent: r.growthPercent,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'This Month',
              value: '₹${_fmtMoney(r.thisMonthRevenue)}',
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'This Year',
              value: '₹${_fmtMoney(r.thisYearRevenue)}',
              icon: Icons.event_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Payouts Done',
              value: '₹${_fmtMoney(r.totalPayoutsCompleted)}',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Payouts Pending',
              value: '₹${_fmtMoney(r.totalPayoutsPending)}',
              icon: Icons.schedule_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 20),

        _card(isDark, AdminLineChart(
          data: r.monthlyTrend,
          lineColor: const Color(0xFF10B981),
          title: '📈 Monthly Revenue',
          yAxisSuffix: '₹',
          isDark: isDark,
          height: 200,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminLineChart(
          data: r.dailyTrend,
          lineColor: const Color(0xFF06B6D4),
          title: '📊 Daily Revenue',
          yAxisSuffix: '₹',
          isDark: isDark,
          height: 180,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: r.revenueBySource,
          colors: const [
            Color(0xFF10B981),
            Color(0xFF8B5CF6),
            Color(0xFF3B82F6),
            Color(0xFFF59E0B),
          ],
          title: '💰 Revenue Sources',
          centerLabel: 'Total',
          centerValue: '₹${_fmtMoney(r.totalRevenue)}',
          isDark: isDark,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: r.revenueByPlan,
          barColor: const Color(0xFF10B981),
          title: '💎 Revenue by Plan',
          isDark: isDark,
          height: 180,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: r.revenueByCity,
          barColor: const Color(0xFF7C3AED),
          title: '🏙️ Revenue by City',
          isDark: isDark,
          height: 180,
        )),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // BOOKING TAB
  // ═══════════════════════════════════════════
  Widget _bookingTab(bool isDark, AdminProvider p) {
    final b = p.bookingAnalytics;
    if (b == null) return _empty('Booking analytics not available');

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Total Bookings',
              value: _fmt(b.totalBookings),
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFFF59E0B),
              growthPercent: b.growthPercent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Acceptance',
              value: '${b.acceptanceRate.toStringAsFixed(1)}%',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Accepted',
              value: _fmt(b.acceptedBookings),
              icon: Icons.thumb_up_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Pending',
              value: _fmt(b.pendingBookings),
              icon: Icons.pending_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Rejected',
              value: _fmt(b.rejectedBookings),
              icon: Icons.cancel_rounded,
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Avg Response',
              value: '${b.averageResponseTimeHours.toStringAsFixed(1)}h',
              icon: Icons.timer_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 20),

        _card(isDark, AdminBarChart(
          data: b.monthlyTrend,
          barColor: const Color(0xFFF59E0B),
          title: '📊 Monthly Bookings',
          isDark: isDark,
          height: 200,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminLineChart(
          data: b.dailyTrend,
          lineColor: const Color(0xFFF59E0B),
          title: '📈 Daily Bookings',
          isDark: isDark,
          height: 180,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: b.statusBreakdown,
          colors: const [
            Color(0xFFF59E0B),
            Color(0xFF10B981),
            Color(0xFFEF4444),
            Color(0xFF8A8FA3),
            Color(0xFF3B82F6),
          ],
          title: '📋 Status Breakdown',
          centerLabel: 'Total',
          centerValue: _fmt(b.totalBookings),
          isDark: isDark,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: b.byPropertyType,
          barColor: const Color(0xFFF59E0B),
          title: '🏠 By Property Type',
          isDark: isDark,
          height: 180,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: b.byGender,
          colors: const [
            Color(0xFF3B82F6),
            Color(0xFFEC4899),
            Color(0xFF8B5CF6),
          ],
          title: '⚧ By Gender',
          isDark: isDark,
        )),
        const SizedBox(height: 16),

        if (b.topPropertiesByBookings.isNotEmpty)
          _card(
            isDark,
            _topList(
              b.topPropertiesByBookings,
              '🏆 Top Properties by Bookings',
              const Color(0xFFF59E0B),
              isDark,
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // PROPERTY TAB
  // ═══════════════════════════════════════════
  Widget _propertyTab(bool isDark, AdminProvider p) {
    final pr = p.propertyAnalytics;
    if (pr == null) return _empty('Property analytics not available');

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Total Properties',
              value: _fmt(pr.totalProperties),
              icon: Icons.apartment_rounded,
              color: const Color(0xFF06B6D4),
              growthPercent: pr.growthPercent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Occupancy',
              value: '${pr.averageOccupancyRate.toStringAsFixed(1)}%',
              icon: Icons.pie_chart_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Published',
              value: _fmt(pr.publishedProperties),
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Pending',
              value: _fmt(pr.pendingProperties),
              icon: Icons.pending_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Total Rooms',
              value: _fmt(pr.totalRooms),
              icon: Icons.meeting_room_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Total Views',
              value: _fmt(pr.totalViews),
              icon: Icons.visibility_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 20),

        _card(isDark, AdminLineChart(
          data: pr.monthlyTrend,
          lineColor: const Color(0xFF06B6D4),
          title: '📈 Monthly Properties Added',
          isDark: isDark,
          height: 200,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: pr.typeBreakdown,
          colors: const [
            Color(0xFF06B6D4),
            Color(0xFF8B5CF6),
            Color(0xFF3B82F6),
            Color(0xFFF59E0B),
            Color(0xFF10B981),
          ],
          title: '🏠 Property Types',
          centerLabel: 'Total',
          centerValue: _fmt(pr.totalProperties),
          isDark: isDark,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: pr.occupancyBreakdown,
          colors: const [
            Color(0xFF10B981),
            Color(0xFFF59E0B),
            Color(0xFFEF4444),
          ],
          title: '📊 Occupancy Status',
          isDark: isDark,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminDonutChart(
          data: pr.genderBreakdown,
          colors: const [
            Color(0xFF3B82F6),
            Color(0xFFEC4899),
            Color(0xFF8B5CF6),
          ],
          title: '⚧ Gender Distribution',
          isDark: isDark,
        )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: pr.cityBreakdown.take(8).toList(),
          barColor: const Color(0xFF7C3AED),
          title: '🏙️ Top Cities',
          isDark: isDark,
          height: 200,
        )),
        const SizedBox(height: 16),

        if (pr.topPropertiesByViews.isNotEmpty)
          _card(
            isDark,
            _topList(
              pr.topPropertiesByViews,
              '👁️ Top Properties by Views',
              const Color(0xFF06B6D4),
              isDark,
            ),
          ),
        const SizedBox(height: 16),

        if (pr.topPropertiesByRevenue.isNotEmpty)
          _card(
            isDark,
            _topList(
              pr.topPropertiesByRevenue,
              '💰 Top Properties by Revenue',
              const Color(0xFF10B981),
              isDark,
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ENGAGEMENT TAB
  // ═══════════════════════════════════════════
  Widget _engagementTab(bool isDark, AdminProvider p) {
    final e = p.engagementAnalytics;
    if (e == null) return _empty('Engagement analytics not available');

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Daily Active',
              value: _fmt(e.dailyActiveUsers),
              icon: Icons.person_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Weekly Active',
              value: _fmt(e.weeklyActiveUsers),
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Monthly Active',
              value: _fmt(e.monthlyActiveUsers),
              icon: Icons.groups_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'DAU/MAU',
              value: '${e.dauMauRatio.toStringAsFixed(1)}%',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminStatCard(
              label: 'Property Views',
              value: _fmt(e.totalPropertyViews),
              icon: Icons.visibility_rounded,
              color: const Color(0xFF06B6D4),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminStatCard(
              label: 'Avg Rating',
              value: e.averageRating.toStringAsFixed(1),
              icon: Icons.star_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: 20),

        _card(isDark, AdminLineChart(
          data: e.dauTrend,
          lineColor: const Color(0xFF3B82F6),
          title: '📈 Daily Active Users',
          isDark: isDark,
          height: 200,
        )),
        const SizedBox(height: 16),

        if (e.searchesTrend.isNotEmpty)
          _card(isDark, AdminLineChart(
            data: e.searchesTrend,
            lineColor: const Color(0xFF8B5CF6),
            title: '🔍 Searches Trend',
            isDark: isDark,
            height: 180,
          )),
        const SizedBox(height: 16),

        if (e.viewsTrend.isNotEmpty)
          _card(isDark, AdminLineChart(
            data: e.viewsTrend,
            lineColor: const Color(0xFF06B6D4),
            title: '👁️ Property Views Trend',
            isDark: isDark,
            height: 180,
          )),
        const SizedBox(height: 16),

        if (e.chatMessagesTrend.isNotEmpty)
          _card(isDark, AdminLineChart(
            data: e.chatMessagesTrend,
            lineColor: const Color(0xFF10B981),
            title: '💬 Chat Messages Trend',
            isDark: isDark,
            height: 180,
          )),
        const SizedBox(height: 16),

        _card(isDark, AdminBarChart(
          data: e.ratingDistribution,
          barColor: const Color(0xFFF59E0B),
          title: '⭐ Rating Distribution',
          isDark: isDark,
          height: 180,
        )),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // TOP LIST WIDGET
  // ═══════════════════════════════════════════
  Widget _topList(List<ChartPoint> data, String title, Color color,
      bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            )),
        const SizedBox(height: 12),
        ...data.take(8).toList().asMap().entries.map((e) {
          final maxVal = data.first.value == 0 ? 1.0 : data.first.value;
          final pct = (e.value.value / maxVal).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: e.key < 3
                        ? color.withOpacity(0.2)
                        : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + Progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Value
                Text(_fmt(e.value.value as int),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ],
            ),
          );
        }).toList(),
      ],
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

  Widget _empty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined,
                size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(msg,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
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