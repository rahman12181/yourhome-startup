// lib/screens/admin/admin_subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_model.dart';

// ==================== DESIGN TOKENS ====================
class _AdminPalette {
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF9F67F5);
  static const gold = Color(0xFFD4AF37);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF2563EB);

  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const lightBg = Color(0xFFF5F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
}

class AdminSubscriptionScreen extends StatefulWidget {
  const AdminSubscriptionScreen({super.key});

  @override
  State<AdminSubscriptionScreen> createState() =>
      _AdminSubscriptionScreenState();
}

class _AdminSubscriptionScreenState extends State<AdminSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFirstLoad = true;
  String _searchQuery = '';

  // Counts
  int _totalSubscriptions = 0;
  int _activeCount = 0;
  int _expiredCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(
      context,
      listen: false,
    );
    await adminProvider.getPropertyAccessSubscriptions();

    setState(() {
      _totalSubscriptions = adminProvider.subscriptions.length;
      _activeCount =
          adminProvider.subscriptions.where((s) => s.status == 'ACTIVE').length;
      _expiredCount =
          adminProvider.subscriptions.where((s) => s.status == 'EXPIRED').length;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? _AdminPalette.darkBg : _AdminPalette.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            elevation: 0,
            backgroundColor: isDark ? _AdminPalette.darkBg : _AdminPalette.lightBg,
            expandedHeight: 0,
            toolbarHeight: 64,
            title: Text(
              'Property Access',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                fontSize: 21,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? _AdminPalette.darkSurface : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: _AdminPalette.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _loadData();
                    },
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(160),
              child: _buildStatsBar(context, isDark),
            ),
          ),
        ],
        body: adminProvider.isLoading && adminProvider.subscriptions.isEmpty
            ? _buildLoadingState(isDark)
            : Column(
                children: [
                  _buildSearchBar(context, isDark),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      color: _AdminPalette.primary,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSubscriptionList(context, isDark, adminProvider, 'ALL'),
                          _buildSubscriptionList(context, isDark, adminProvider, 'ACTIVE'),
                          _buildSubscriptionList(context, isDark, adminProvider, 'EXPIRED'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _AdminPalette.primary),
          const SizedBox(height: 16),
          Text(
            'Loading subscriptions...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============== STATS BAR ==============
  Widget _buildStatsBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  _totalSubscriptions.toString(),
                  Icons.subscriptions_rounded,
                  [const Color(0xFF7C3AED), const Color(0xFF9F67F5)],
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  _activeCount.toString(),
                  Icons.check_circle_rounded,
                  [const Color(0xFF16A34A), const Color(0xFF22C55E)],
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Expired',
                  _expiredCount.toString(),
                  Icons.cancel_rounded,
                  [const Color(0xFFDC2626), const Color(0xFFF87171)],
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? _AdminPalette.darkSurface : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_AdminPalette.primary, _AdminPalette.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _AdminPalette.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(12),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Expired'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    List<Color> gradientColors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 15),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============== SEARCH BAR ==============
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? _AdminPalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search by owner name, plan...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _AdminPalette.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: _AdminPalette.primary,
                size: 18,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ============== SUBSCRIPTION LIST ==============
  Widget _buildSubscriptionList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
    String filter,
  ) {
    List<AdminPropertyAccessSubscription> filteredSubscriptions;

    switch (filter) {
      case 'ACTIVE':
        filteredSubscriptions =
            provider.subscriptions.where((s) => s.status == 'ACTIVE').toList();
        break;
      case 'EXPIRED':
        filteredSubscriptions =
            provider.subscriptions.where((s) => s.status == 'EXPIRED').toList();
        break;
      default:
        filteredSubscriptions = provider.subscriptions;
    }

    if (_searchQuery.isNotEmpty) {
      filteredSubscriptions = filteredSubscriptions.where((sub) {
        final plan = sub.plan.toLowerCase();
        final status = sub.status.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return plan.contains(query) || status.contains(query);
      }).toList();
    }

    if (filteredSubscriptions.isEmpty) {
      return _buildEmptyState(isDark, 'No subscriptions found');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredSubscriptions.length,
      itemBuilder: (context, index) {
        final subscription = filteredSubscriptions[index];
        return _buildSubscriptionCard(context, subscription, isDark, provider);
      },
    );
  }

  // ============== SUBSCRIPTION CARD ==============
  Widget _buildSubscriptionCard(
    BuildContext context,
    AdminPropertyAccessSubscription subscription,
    bool isDark,
    AdminProvider provider,
  ) {
    final isActive = subscription.status == 'ACTIVE';
    final isExpired = subscription.status == 'EXPIRED';

    Color statusColor;
    String statusText;
    IconData statusIcon;
    List<Color> iconGradient;

    if (isActive) {
      statusColor = _AdminPalette.success;
      statusText = 'Active';
      statusIcon = Icons.check_circle_rounded;
      iconGradient = [const Color(0xFF16A34A), const Color(0xFF22C55E)];
    } else if (isExpired) {
      statusColor = _AdminPalette.danger;
      statusText = 'Expired';
      statusIcon = Icons.cancel_rounded;
      iconGradient = [const Color(0xFFDC2626), const Color(0xFFF87171)];
    } else {
      statusColor = Colors.grey;
      statusText = 'Cancelled';
      statusIcon = Icons.remove_circle_rounded;
      iconGradient = [Colors.grey[500]!, Colors.grey[400]!];
    }

    String planName = subscription.plan;
    switch (planName) {
      case 'MONTHLY_1':
        planName = '1 Month';
        break;
      case 'MONTHLY_2':
        planName = '2 Months';
        break;
      case 'MONTHLY_3':
        planName = '3 Months';
        break;
      case 'MONTHLY_4':
        planName = '4 Months';
        break;
      case 'MONTHLY_5':
        planName = '5 Months';
        break;
      default:
        planName = subscription.plan;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? _AdminPalette.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? _AdminPalette.success.withOpacity(0.3)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04)),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? _AdminPalette.success.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: iconGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: iconGradient.first.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.subscriptions_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subscription #${subscription.subscriptionId}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                size: 12,
                                color: isDark ? Colors.grey[500] : Colors.grey[500]),
                            const SizedBox(width: 3),
                            Text(
                              planName,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
              height: 1,
            ),

            // Details Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.black.withOpacity(0.015),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today_rounded,
                      'Duration',
                      '${subscription.durationMonths}M',
                      isDark,
                    ),
                  ),
                  _buildDetailDivider(isDark),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.play_arrow_rounded,
                      'Start',
                      DateFormat('dd MMM yy').format(subscription.startDate),
                      isDark,
                    ),
                  ),
                  _buildDetailDivider(isDark),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.stop_rounded,
                      'End',
                      DateFormat('dd MMM yy').format(subscription.endDate),
                      isDark,
                    ),
                  ),
                  _buildDetailDivider(isDark),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.currency_rupee_rounded,
                      'Amount',
                      '₹${subscription.amountPaid.toStringAsFixed(0)}',
                      isDark,
                      color: _AdminPalette.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            if (isActive)
              Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showForceExpireDialog(context, subscription, provider);
                    },
                    icon: const Icon(Icons.cancel_rounded, size: 17),
                    label: Text('Force Expire',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _AdminPalette.danger,
                      side: BorderSide(color: _AdminPalette.danger.withOpacity(0.5), width: 1.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailDivider(bool isDark) {
    return Container(
      height: 32,
      width: 1,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, bool isDark, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 15,
          color: color ?? (isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color ?? (isDark ? Colors.white : const Color(0xFF1A1A2E)),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ============== FORCE EXPIRE DIALOG ==============
  void _showForceExpireDialog(
    BuildContext context,
    AdminPropertyAccessSubscription subscription,
    AdminProvider provider,
  ) {
    final TextEditingController reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? _AdminPalette.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _AdminPalette.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.warning_amber_rounded,
                        color: _AdminPalette.danger, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Force Expire Subscription',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Are you sure you want to force expire this subscription?',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _AdminPalette.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _AdminPalette.warning.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: _AdminPalette.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Owner will lose property access immediately.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? _AdminPalette.warning : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 2,
                autofocus: true,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter reason for force expiry...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _AdminPalette.primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_AdminPalette.danger, Color(0xFFF87171)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _AdminPalette.danger.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final success = await provider.forceExpireSubscription(
                            subscription.subscriptionId,
                            reasonController.text.trim().isNotEmpty
                                ? reasonController.text.trim()
                                : 'Force expired by admin',
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text('Subscription force expired successfully',
                                        style: GoogleFonts.poppins()),
                                  ],
                                ),
                                backgroundColor: _AdminPalette.danger,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            _loadData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Force Expire',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== EMPTY STATE ==============
  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _AdminPalette.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.subscriptions_outlined,
              size: 52,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}