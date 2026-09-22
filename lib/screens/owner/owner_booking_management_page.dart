// lib/pages/owner/OwnerBookingManagementPage.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/owner_provider.dart';
import '../../models/booking_model.dart';
import '../../models/booking_stats_model.dart';

class OwnerBookingManagementPage extends StatefulWidget {
  const OwnerBookingManagementPage({super.key});

  @override
  State<OwnerBookingManagementPage> createState() =>
      _OwnerBookingManagementPageState();
}

class _OwnerBookingManagementPageState extends State<OwnerBookingManagementPage>
    with TickerProviderStateMixin {
  bool _isFirstLoad = true;
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _staggerController;

  int _selectedSegment = 0;
  bool _disposed = false;
  Timer? _autoRefreshTimer;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      _fadeController.forward();
      if (_isFirstLoad) {
        _isFirstLoad = false;
        _loadAll();
        _startAutoRefresh();
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _disposed) return;
      final p = Provider.of<OwnerProvider>(context, listen: false);
      p.getIncomingBookingRequests(showLoader: false);
      p.loadUnreadBookingCount();
    });
  }

  void _onTabChanged() {
    if (_disposed || !mounted) return;
    if (_tabController.indexIsChanging) return;
    if (_selectedSegment != _tabController.index) {
      setState(() => _selectedSegment = _tabController.index);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _autoRefreshTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _fadeController.dispose();
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted || _disposed) return;
    try {
      final p = Provider.of<OwnerProvider>(context, listen: false);
      await Future.wait([
        p.getIncomingBookingRequests(),
        p.loadBookingStats(),
        p.loadUnreadBookingCount(),
      ]);
      if (!mounted || _disposed) return;
      _staggerController.forward(from: 0);
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to load bookings', const Color(0xFFEF4444));
      }
    }
  }

  Future<void> _handleAccept(int requestId, {String? template}) async {
    HapticFeedback.mediumImpact();
    final response = template ?? 'Booking accepted!';
    try {
      final p = Provider.of<OwnerProvider>(context, listen: false);
      final ok = await p.acceptBookingRequest(requestId, response);
      if (!mounted || _disposed) return;
      if (ok) {
        _showSnackWithUndo(
            'Booking accepted', const Color(0xFF22C55E), requestId);
      } else {
        _showSnack(p.error ?? 'Failed to accept', const Color(0xFFEF4444));
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Something went wrong', const Color(0xFFEF4444));
      }
    }
  }

  Future<void> _handleReject(int requestId, {String? template}) async {
    HapticFeedback.mediumImpact();
    final response = template ?? 'Booking rejected.';
    try {
      final p = Provider.of<OwnerProvider>(context, listen: false);
      final ok = await p.rejectBookingRequest(requestId, response);
      if (!mounted || _disposed) return;
      if (ok) {
        _showSnackWithUndo(
            'Booking rejected', const Color(0xFFEF4444), requestId);
      } else {
        _showSnack(p.error ?? 'Failed to reject', const Color(0xFFEF4444));
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Something went wrong', const Color(0xFFEF4444));
      }
    }
  }

  Future<void> _handleUndo(int requestId) async {
    HapticFeedback.mediumImpact();
    try {
      final p = Provider.of<OwnerProvider>(context, listen: false);
      final ok = await p.undoBookingResponse(requestId);
      if (!mounted || _disposed) return;
      if (ok) {
        _showSnack('Response undone', const Color(0xFF7C3AED));
      } else {
        _showSnack(p.error ?? 'Failed to undo', const Color(0xFFEF4444));
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Something went wrong', const Color(0xFFEF4444));
      }
    }
  }

  void _showSnackWithUndo(String msg, Color color, int requestId) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _handleUndo(requestId),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============ SAFE HELPERS ============
  String _safeTitle(BookingRequest b) {
    final t = b.propertyTitle;
    return (t == null || t.trim().isEmpty) ? 'Property' : t;
  }

  String _safeCity(BookingRequest b) {
    final c = b.propertyCity;
    return (c == null || c.trim().isEmpty) ? 'N/A' : c;
  }

  String _safeStatus(BookingRequest b) {
    final s = b.status;
    return (s == null || s.trim().isEmpty) ? 'PENDING' : s.toUpperCase();
  }

  String _safeStudentName(BookingRequest b) {
    final n = b.studentName;
    return (n == null || n.trim().isEmpty) ? 'Unknown User' : n;
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
        return 'Accepted';
      case 'REJECTED':
        return 'Rejected';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'ACCEPTED':
        return const Color(0xFF22C55E);
      case 'REJECTED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return Icons.schedule_rounded;
      case 'ACCEPTED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      default:
        return Icons.book_online_rounded;
    }
  }

  String _formatDate(dynamic d) {
    if (d == null) return 'N/A';
    try {
      if (d is DateTime) return DateFormat('dd MMM yyyy').format(d);
      if (d is String) {
        if (d.trim().isEmpty) return 'N/A';
        return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
      }
      return d.toString();
    } catch (_) {
      return 'N/A';
    }
  }

  String _timeAgo(DateTime? d) {
    if (d == null) return 'Just now';
    try {
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Just now';
    }
  }

  Color _hexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF8A8FA3);
    }
  }

  // ============ CONTACT ACTIONS ============
  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack('Phone number not available', const Color(0xFFEF4444));
      return;
    }
    try {
      final uri = Uri.parse('tel:${phone.trim()}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack('Cannot open dialer', const Color(0xFFEF4444));
      }
    } catch (_) {
      _showSnack('Cannot open dialer', const Color(0xFFEF4444));
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack('Phone number not available', const Color(0xFFEF4444));
      return;
    }
    try {
      final cleaned = phone.trim().replaceAll(RegExp(r'[^\d]'), '');
      final number = cleaned.length == 10 ? '91$cleaned' : cleaned;
      final uri = Uri.parse('https://wa.me/$number');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack('Cannot open WhatsApp', const Color(0xFFEF4444));
      }
    } catch (_) {
      _showSnack('Cannot open WhatsApp', const Color(0xFFEF4444));
    }
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      _showSnack('Email not available', const Color(0xFFEF4444));
      return;
    }
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: email.trim(),
        query: 'subject=Nestora Booking Enquiry',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack('Cannot open email app', const Color(0xFFEF4444));
      }
    } catch (_) {
      _showSnack('Cannot open email app', const Color(0xFFEF4444));
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('$label copied', const Color(0xFF22C55E));
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
        body: SafeArea(
          child: Consumer<OwnerProvider>(
            builder: (context, p, _) {
              final all = List<BookingRequest>.from(p.bookingRequests);
              final pending = all
                  .where((b) => _safeStatus(b) == 'PENDING')
                  .toList(growable: false);
              final accepted = all
                  .where((b) => _safeStatus(b) == 'ACCEPTED')
                  .toList(growable: false);
              final rejected = all
                  .where((b) => _safeStatus(b) == 'REJECTED')
                  .toList(growable: false);

              final lists = [pending, accepted, rejected];
              final isLoading = p.isLoading && all.isEmpty;

              return Column(
                children: [
                  _buildHeader(isDark, all.length, pending.length,
                      p.unreadBookingCount),
                  if (_showSearch) _buildSearchBar(isDark, p),
                  _buildStatsSection(isDark, p.bookingStats, p.isStatsLoading),
                  _buildQuickFilters(isDark, p),
                  _buildSegmentChips(
                    isDark,
                    pending.length,
                    accepted.length,
                    rejected.length,
                  ),
                  Expanded(
                    child: isLoading
                        ? _buildSkeleton(isDark)
                        : FadeTransition(
                            opacity: _fadeController,
                            child: TabBarView(
                              controller: _tabController,
                              physics: const BouncingScrollPhysics(),
                              children: List.generate(3, (i) {
                                final status =
                                    ['PENDING', 'ACCEPTED', 'REJECTED'][i];
                                return RefreshIndicator(
                                  onRefresh: _loadAll,
                                  color: const Color(0xFF7C3AED),
                                  backgroundColor: isDark
                                      ? const Color(0xFF1A1F33)
                                      : Colors.white,
                                  child: _buildBookingList(
                                    context,
                                    lists[i],
                                    status,
                                    isDark,
                                  ),
                                );
                              }),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader(
      bool isDark, int total, int pending, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Requests',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  pending > 0
                      ? '$pending pending · $total total'
                      : 'You\'re all caught up',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: pending > 0
                        ? const Color(0xFFF59E0B)
                        : (isDark ? Colors.white54 : const Color(0xFF8A8FA3)),
                  ),
                ),
              ],
            ),
          ),
          _circleBtn(
            icon: _showSearch ? Icons.close_rounded : Icons.search_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                final p = Provider.of<OwnerProvider>(context, listen: false);
                p.updateBookingFilters(clearSearch: true);
              }
            },
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _circleBtn(
            icon: Icons.refresh_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              _loadAll();
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE8E8F0),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================
  Widget _buildSearchBar(bool isDark, OwnerProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE8E8F0),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          decoration: InputDecoration(
            icon: Icon(
              Icons.search_rounded,
              size: 18,
              color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
            ),
            hintText: 'Search by name, ID, or email...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFFB0B3C0),
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      p.updateBookingFilters(clearSearch: true);
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {});
          },
          onSubmitted: (val) {
            p.updateBookingFilters(
              searchQuery: val.trim().isEmpty ? null : val.trim(),
              clearSearch: val.trim().isEmpty,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // STATS SECTION (ANALYTICS)
  // ============================================================
  Widget _buildStatsSection(
      bool isDark, BookingStats? stats, bool isLoading) {
    if (isLoading && stats == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121729) : Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }

    if (stats == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        children: [
          // Row 1: Mini stat cards
          Row(
            children: [
              Expanded(
                child: _miniStatCard(
                  label: 'Today',
                  value: '${stats.todayNew}',
                  subtitle: 'new',
                  icon: Icons.today_rounded,
                  color: const Color(0xFF7C3AED),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStatCard(
                  label: 'Pending',
                  value: '${stats.totalPending}',
                  subtitle: stats.urgentPending > 0
                      ? '${stats.urgentPending} urgent'
                      : 'all fresh',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStatCard(
                  label: 'This Week',
                  value: '${stats.thisWeekBookings}',
                  subtitle: _growthText(stats.weeklyGrowthPercent),
                  icon: Icons.trending_up_rounded,
                  color: stats.weeklyGrowthPercent >= 0
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Performance card with graph
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121729) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFF0F0F8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 16,
                      color: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Performance',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Last 7 days',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFFB0B3C0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Custom mini bar chart
                SizedBox(
                  height: 70,
                  child: _buildMiniChart(stats, isDark),
                ),
                const SizedBox(height: 12),
                // Bottom metrics row
                Row(
                  children: [
                    Expanded(
                      child: _metricTile(
                        label: 'Acceptance',
                        value: '${stats.acceptanceRate.toStringAsFixed(1)}%',
                        color: const Color(0xFF22C55E),
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF0F0F8),
                    ),
                    Expanded(
                      child: _metricTile(
                        label: 'Avg Response',
                        value: _formatResponseTime(stats.avgResponseHours),
                        color: const Color(0xFF4ECDC4),
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF0F0F8),
                    ),
                    Expanded(
                      child: _metricTile(
                        label: 'This Month',
                        value: '${stats.thisMonthBookings}',
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
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
  }

  Widget _miniStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFF0F0F8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 8.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(BookingStats stats, bool isDark) {
    // Last 7 days mock data (real data aane par replace kar sakte ho)
    final now = DateTime.now();
    final List<double> values = [
      (stats.thisWeekBookings * 0.15).clamp(0, 100).toDouble(),
      (stats.thisWeekBookings * 0.35).clamp(0, 100).toDouble(),
      (stats.thisWeekBookings * 0.25).clamp(0, 100).toDouble(),
      (stats.thisWeekBookings * 0.45).clamp(0, 100).toDouble(),
      (stats.thisWeekBookings * 0.55).clamp(0, 100).toDouble(),
      (stats.thisWeekBookings * 0.70).clamp(0, 100).toDouble(),
      (stats.thisWeekBookings * 0.85).clamp(0, 100).toDouble(),
    ];
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxV <= 0 ? 1.0 : maxV;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final dayLabel = DateFormat('E').format(day).substring(0, 1);
        final heightRatio = values[i] / safeMax;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    width: double.infinity,
                    height: (50 * heightRatio).clamp(4.0, 50.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabel,
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

  Widget _metricTile({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
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

  String _growthText(double percent) {
    if (percent > 0) return '+${percent.toStringAsFixed(0)}%';
    if (percent < 0) return '${percent.toStringAsFixed(0)}%';
    return '0%';
  }

  String _formatResponseTime(double hours) {
    if (hours <= 0) return 'N/A';
    if (hours < 1) return '${(hours * 60).round()}m';
    if (hours < 24) return '${hours.toStringAsFixed(1)}h';
    return '${(hours / 24).toStringAsFixed(1)}d';
  }

  // ============================================================
  // QUICK FILTERS
  // ============================================================
  Widget _buildQuickFilters(bool isDark, OwnerProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _quickFilterChip(
              label: 'All',
              selected: !p.bookingOnlyNew &&
                  !p.bookingOnlyUrgent &&
                  p.bookingSortBy == 'newest',
              color: const Color(0xFF7C3AED),
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                p.resetBookingFilters();
              },
            ),
            const SizedBox(width: 6),
            _quickFilterChip(
              label: 'New',
              selected: p.bookingOnlyNew,
              color: const Color(0xFF22C55E),
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                p.updateBookingFilters(
                  onlyNew: !p.bookingOnlyNew,
                  onlyUrgent: false,
                );
              },
            ),
            const SizedBox(width: 6),
            _quickFilterChip(
              label: 'Urgent',
              selected: p.bookingOnlyUrgent,
              color: const Color(0xFFEF4444),
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                p.updateBookingFilters(
                  onlyUrgent: !p.bookingOnlyUrgent,
                  onlyNew: false,
                );
              },
            ),
            const SizedBox(width: 6),
            _quickFilterChip(
              label: 'Newest',
              selected: p.bookingSortBy == 'newest',
              color: const Color(0xFF4ECDC4),
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                p.updateBookingFilters(sortBy: 'newest');
              },
            ),
            const SizedBox(width: 6),
            _quickFilterChip(
              label: 'Move-in Date',
              selected: p.bookingSortBy == 'moveindate',
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                p.updateBookingFilters(sortBy: 'moveindate');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickFilterChip({
    required String label,
    required bool selected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [color, color.withOpacity(0.75)])
              : null,
          color: selected
              ? null
              : (isDark ? const Color(0xFF1A1F33) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8E8F0)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF666680)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEGMENT CHIPS
  // ============================================================
  Widget _buildSegmentChips(
      bool isDark, int pending, int accepted, int rejected) {
    final items = [
      {'label': 'Pending', 'count': pending, 'color': const Color(0xFFF59E0B)},
      {'label': 'Accepted', 'count': accepted, 'color': const Color(0xFF22C55E)},
      {'label': 'Rejected', 'count': rejected, 'color': const Color(0xFFEF4444)},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121729) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF0F0F8),
          ),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final item = items[i];
            final selected = _selectedSegment == i;
            final color = item['color'] as Color;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_selectedSegment != i) {
                    setState(() => _selectedSegment = i);
                  }
                  if (_tabController.index != i) {
                    _tabController.animateTo(i);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              color.withOpacity(0.15),
                              color.withOpacity(0.08),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: color.withOpacity(0.35), width: 1.2)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          item['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? color
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF666680)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? color
                              : (isDark
                                  ? Colors.white10
                                  : const Color(0xFFF0F0F8)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${item['count']}',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white54
                                    : const Color(0xFF8A8FA3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================
  Widget _buildSkeleton(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      children: [
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121729) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOOKING LIST
  // ============================================================
  Widget _buildBookingList(
    BuildContext context,
    List<BookingRequest> bookings,
    String status,
    bool isDark,
  ) {
    if (bookings.isEmpty) return _buildEmptyState(isDark, status);

    return ListView.builder(
      key: PageStorageKey('booking_list_$status'),
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final delay = index * 0.05;
        return AnimatedBuilder(
          animation: _staggerController,
          builder: (context, child) {
            final raw = (_staggerController.value - delay);
            final t = Curves.easeOutCubic
                .transform(raw.clamp(0.0, 1.0).toDouble());
            return Transform.translate(
              offset: Offset(0, 18 * (1 - t)),
              child: Opacity(opacity: t, child: child),
            );
          },
          child: _buildCard(context, booking, isDark),
        );
      },
    );
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================
  Widget _buildCard(
    BuildContext context,
    BookingRequest booking,
    bool isDark,
  ) {
    final status = _safeStatus(booking);
    final color = _statusColor(status);
    final isPending = status == 'PENDING';
    final studentName = _safeStudentName(booking);
    final studentInitial =
        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'U';
    final hasPhone =
        booking.studentPhone != null && booking.studentPhone!.trim().isNotEmpty;
    final hasEmail =
        booking.studentEmail != null && booking.studentEmail!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFF0F0F8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            _showDetailsSheet(context, booking, isDark);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============ STUDENT HEADER ============
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4ECDC4).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: booking.studentProfilePic != null &&
                              booking.studentProfilePic!.trim().isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                booking.studentProfilePic!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  studentInitial,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              studentInitial,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  studentName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (booking.isNew) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                              if (booking.isUrgent) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'URGENT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (booking.studentDisplayId != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    booking.studentDisplayId!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF7C3AED),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Flexible(
                                child: Text(
                                  '· ${_timeAgo(booking.requestedAt)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF8A8FA3),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.08),
                        ]),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(status),
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ============ DIVIDER ============
                Container(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF0F0F8),
                ),

                const SizedBox(height: 10),

                // ============ PROPERTY INFO ============
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _safeTitle(booking),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_safeCity(booking)} · Room ${booking.roomNumber ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF8A8FA3),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ============ INFO CHIPS ============
                Row(
                  children: [
                    Expanded(
                      child: _infoChip(
                        Icons.calendar_today_rounded,
                        _formatDate(booking.moveInDate),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _infoChip(
                        Icons.access_time_rounded,
                        '${booking.durationMonths ?? 1} mo',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _infoChip(
                        booking.isPaid
                            ? Icons.check_circle_rounded
                            : Icons.payment_rounded,
                        booking.isPaid ? 'Paid' : 'Not Paid',
                        isDark,
                        color: booking.isPaid
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),

                // ============ MESSAGE ============
                if (booking.message != null &&
                    booking.message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 13,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFFB0B3C0),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking.message!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF8A8FA3),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ============ CONTACT ROW ============
                Row(
                  children: [
                    _iconActionBtn(
                      icon: Icons.call_rounded,
                      color: const Color(0xFF22C55E),
                      isDark: isDark,
                      enabled: hasPhone,
                      onTap: () => _callPhone(booking.studentPhone),
                    ),
                    const SizedBox(width: 6),
                    _iconActionBtn(
                      icon: Icons.chat_rounded,
                      color: const Color(0xFF25D366),
                      isDark: isDark,
                      enabled: hasPhone,
                      onTap: () => _openWhatsApp(booking.studentPhone),
                    ),
                    const SizedBox(width: 6),
                    _iconActionBtn(
                      icon: Icons.email_rounded,
                      color: const Color(0xFF4ECDC4),
                      isDark: isDark,
                      enabled: hasEmail,
                      onTap: () => _sendEmail(booking.studentEmail),
                    ),
                    const Spacer(),
                    if (hasPhone)
                      _iconActionBtn(
                        icon: Icons.copy_rounded,
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                        enabled: true,
                        onTap: () => _copyToClipboard(
                            booking.studentPhone!, 'Phone'),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // ============ ACTIONS ============
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          label: 'Accept',
                          icon: Icons.check_rounded,
                          filled: true,
                          color: const Color(0xFF22C55E),
                          onTap: () => _showAcceptDialog(
                              context, booking.requestId, isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionBtn(
                          label: 'Reject',
                          icon: Icons.close_rounded,
                          filled: false,
                          color: const Color(0xFFEF4444),
                          onTap: () => _showRejectDialog(
                              context, booking.requestId, isDark),
                        ),
                      ),
                    ],
                  )
                else
                  _actionBtn(
                    label: 'View Details',
                    icon: Icons.arrow_forward_rounded,
                    filled: false,
                    color: const Color(0xFF7C3AED),
                    fullWidth: true,
                    onTap: () => _showDetailsSheet(context, booking, isDark),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconActionBtn({
    required IconData icon,
    required Color color,
    required bool isDark,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8F9FC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? color.withOpacity(0.2)
                : (isDark ? Colors.white10 : const Color(0xFFE8E8F0)),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? color
              : (isDark ? Colors.white24 : const Color(0xFFB0B3C0)),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, bool isDark,
      {Color? color}) {
    final c = color ?? (isDark ? Colors.white54 : const Color(0xFF8A8FA3));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: c,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required bool filled,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final child = Material(
      color: filled ? Colors.transparent : color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: filled
              ? BoxDecoration(
                  gradient:
                      LinearGradient(colors: [color, color.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: color.withOpacity(0.25), width: 1.2),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: filled ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: child) : child;
  }

  // ============================================================
  // ACCEPT DIALOG WITH TEMPLATES
  // ============================================================
  void _showAcceptDialog(
      BuildContext context, int requestId, bool isDark) {
    final controller = TextEditingController(text: 'Booking accepted!');
    final templates = [
      'Welcome! Please visit between 10am-6pm.',
      'Room available. Call to confirm visit time.',
      'Approved! Bring Aadhar card for verification.',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121729) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE0E0E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 16),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Color(0xFF22C55E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Accept Booking',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Quick Templates',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: templates.map((t) {
                  return GestureDetector(
                    onTap: () {
                      controller.text = t;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        t.length > 30 ? '${t.substring(0, 30)}...' : t,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 3,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write your response...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color:
                          isDark ? Colors.white38 : const Color(0xFFB0B3C0),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      filled: false,
                      color: const Color(0xFF8A8FA3),
                      onTap: () => Navigator.pop(sheetContext),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _actionBtn(
                      label: 'Accept Booking',
                      icon: Icons.check_rounded,
                      filled: true,
                      color: const Color(0xFF22C55E),
                      onTap: () {
                        final text = controller.text.trim();
                        Navigator.pop(sheetContext);
                        _handleAccept(
                          requestId,
                          template: text.isEmpty ? 'Booking accepted!' : text,
                        );
                      },
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

  // ============================================================
  // REJECT DIALOG WITH TEMPLATES
  // ============================================================
  void _showRejectDialog(
      BuildContext context, int requestId, bool isDark) {
    final controller = TextEditingController(text: 'Booking rejected.');
    final templates = [
      'Room already booked. Try another room.',
      'Currently under maintenance.',
      'Not available for these dates.',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121729) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE0E0E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 16),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Reject Booking',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Quick Templates',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: templates.map((t) {
                  return GestureDetector(
                    onTap: () => controller.text = t,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        t.length > 30 ? '${t.substring(0, 30)}...' : t,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 3,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Reason for rejection...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color:
                          isDark ? Colors.white38 : const Color(0xFFB0B3C0),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      label: 'Cancel',
                      icon: Icons.arrow_back_rounded,
                      filled: false,
                      color: const Color(0xFF8A8FA3),
                      onTap: () => Navigator.pop(sheetContext),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _actionBtn(
                      label: 'Reject Booking',
                      icon: Icons.close_rounded,
                      filled: true,
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        final text = controller.text.trim();
                        Navigator.pop(sheetContext);
                        _handleReject(
                          requestId,
                          template:
                              text.isEmpty ? 'Booking rejected.' : text,
                        );
                      },
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

  // ============================================================
  // DETAILS SHEET
  // ============================================================
  void _showDetailsSheet(
    BuildContext context,
    BookingRequest booking,
    bool isDark,
  ) {
    final status = _safeStatus(booking);
    final color = _statusColor(status);
    final studentName = _safeStudentName(booking);
    final studentInitial =
        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'U';
    final hasPhone =
        booking.studentPhone != null && booking.studentPhone!.trim().isNotEmpty;
    final hasEmail =
        booking.studentEmail != null && booking.studentEmail!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121729) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE0E0E8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.75)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _statusIcon(status),
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
                                  'Booking Details',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  _statusLabel(status),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // STUDENT CARD
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            const Color(0xFF4ECDC4).withOpacity(0.08),
                            const Color(0xFF7C3AED).withOpacity(0.05),
                          ]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF4ECDC4).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    size: 14, color: Color(0xFF4ECDC4)),
                                const SizedBox(width: 6),
                                Text(
                                  'Requested By',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF4ECDC4),
                                  ),
                                ),
                                const Spacer(),
                                if (booking.isRepeatStudent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'REPEAT',
                                      style: GoogleFonts.poppins(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF22C55E),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4ECDC4),
                                        Color(0xFF7C3AED)
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: booking.studentProfilePic != null &&
                                          booking
                                              .studentProfilePic!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            booking.studentProfilePic!,
                                            width: 46,
                                            height: 46,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Text(
                                              studentInitial,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          studentInitial,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      if (booking.studentDisplayId != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          booking.studentDisplayId!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF7C3AED),
                                          ),
                                        ),
                                      ],
                                      if (booking.studentTotalBookings !=
                                          null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          '${booking.studentAcceptedBookings ?? 0} accepted · ${booking.studentTotalBookings} total bookings',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9.5,
                                            color: isDark
                                                ? Colors.white54
                                                : const Color(0xFF8A8FA3),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (hasPhone)
                              _contactRow(
                                Icons.phone_rounded,
                                'Phone',
                                booking.studentPhone!,
                                isDark,
                                onTap: () =>
                                    _callPhone(booking.studentPhone),
                                onCopy: () => _copyToClipboard(
                                    booking.studentPhone!, 'Phone'),
                              ),
                            if (hasEmail)
                              _contactRow(
                                Icons.email_rounded,
                                'Email',
                                booking.studentEmail!,
                                isDark,
                                onTap: () =>
                                    _sendEmail(booking.studentEmail),
                                onCopy: () => _copyToClipboard(
                                    booking.studentEmail!, 'Email'),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // BOOKING INFO
                      Text(
                        'Booking Info',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF8A8FA3),
                        ),
                      ),
                      const SizedBox(height: 8),

                      _sheetRow(Icons.apartment_rounded, 'Property',
                          _safeTitle(booking), isDark),
                      _sheetRow(Icons.location_on_rounded, 'City',
                          _safeCity(booking), isDark),
                      if (booking.propertyAddress != null)
                        _sheetRow(Icons.home_rounded, 'Address',
                            booking.propertyAddress!, isDark),
                      _sheetRow(Icons.meeting_room_rounded, 'Room',
                          booking.roomNumber ?? 'N/A', isDark),
                      if (booking.monthlyRent != null)
                        _sheetRow(Icons.currency_rupee_rounded, 'Rent',
                            '₹${booking.monthlyRent!.toStringAsFixed(0)}',
                            isDark),
                      _sheetRow(Icons.calendar_today_rounded, 'Move-in Date',
                          _formatDate(booking.moveInDate), isDark),
                      _sheetRow(Icons.access_time_rounded, 'Duration',
                          '${booking.durationMonths ?? 1} months', isDark),
                      if (booking.message != null &&
                          booking.message!.trim().isNotEmpty)
                        _sheetRow(Icons.format_quote_rounded, 'Message',
                            booking.message!, isDark),
                      if (booking.ownerResponse != null &&
                          booking.ownerResponse!.trim().isNotEmpty)
                        _sheetRow(Icons.reply_rounded, 'Your Response',
                            booking.ownerResponse!, isDark,
                            valueColor: const Color(0xFF22C55E)),
                      _sheetRow(Icons.upload_rounded, 'Requested',
                          _formatDate(booking.requestedAt), isDark),
                      if (booking.respondedAt != null)
                        _sheetRow(Icons.done_all_rounded, 'Responded',
                            _formatDate(booking.respondedAt), isDark),

                      // PAYMENT INFO
                      if (booking.isPaid) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Payment',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF8A8FA3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _sheetRow(Icons.check_circle_rounded, 'Status',
                            'Paid', isDark,
                            valueColor: const Color(0xFF22C55E)),
                        if (booking.paidAmount != null)
                          _sheetRow(Icons.currency_rupee_rounded, 'Amount',
                              '₹${booking.paidAmount!.toStringAsFixed(0)}',
                              isDark),
                        if (booking.payoutStatus != null)
                          _sheetRow(Icons.arrow_upward_rounded, 'Payout',
                              booking.payoutStatus!, isDark),
                      ],

                      const SizedBox(height: 16),

                      // ACTIONS
                      if (status == 'PENDING')
                        Row(
                          children: [
                            Expanded(
                              child: _actionBtn(
                                label: 'Accept',
                                icon: Icons.check_rounded,
                                filled: true,
                                color: const Color(0xFF22C55E),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _showAcceptDialog(
                                      context, booking.requestId, isDark);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _actionBtn(
                                label: 'Reject',
                                icon: Icons.close_rounded,
                                filled: false,
                                color: const Color(0xFFEF4444),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _showRejectDialog(
                                      context, booking.requestId, isDark);
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        _actionBtn(
                          label: 'Close',
                          icon: Icons.close_rounded,
                          filled: false,
                          color: const Color(0xFF7C3AED),
                          fullWidth: true,
                          onTap: () => Navigator.pop(sheetContext),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactRow(
    IconData icon,
    String label,
    String value,
    bool isDark, {
    VoidCallback? onTap,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFF0F0F8),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              if (onCopy != null)
                GestureDetector(
                  onTap: onCopy,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color:
                          isDark ? Colors.white38 : const Color(0xFFB0B3C0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetRow(
    IconData icon,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor ??
                        (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(bool isDark, String status) {
    final icon = _statusIcon(status);
    final color = _statusColor(status);
    final message = {
          'PENDING': 'No pending bookings',
          'ACCEPTED': 'No accepted bookings',
          'REJECTED': 'No rejected bookings',
        }[status] ??
        'No bookings yet';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      children: [
        Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                ),
              ),
              child: Icon(icon, size: 42, color: color),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}