import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/owner_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/booking_model.dart';

// ==================== DESIGN TOKENS ====================
class _BookPalette {
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF60A5FA);
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFF22C55E);
  static const danger = Color(0xFFDC2626);
  static const dangerLight = Color(0xFFF87171);
  static const warning = Color(0xFFF59E0B);

  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const darkSurfaceAlt = Color(0xFF1A1F33);
  static const lightBg = Color(0xFFF5F7FA);
}

class OwnerBookingManagementPage extends StatefulWidget {
  const OwnerBookingManagementPage({super.key});

  @override
  State<OwnerBookingManagementPage> createState() =>
      _OwnerBookingManagementPageState();
}

class _OwnerBookingManagementPageState
    extends State<OwnerBookingManagementPage>
    with TickerProviderStateMixin {
  bool _isFirstLoad = true;
  late TabController _tabController;

  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  int _selectedSegment = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() => _selectedSegment = _tabController.index);
    });

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadBookings();
      }
      _headerController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    await ownerProvider.getIncomingBookingRequests();
  }

  Future<void> _handleAccept(int requestId) async {
    HapticFeedback.mediumImpact();
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    final success = await ownerProvider.acceptBookingRequest(requestId, 'Booking accepted!');
    if (success && mounted) {
      _showSnackBar('Booking accepted successfully', _BookPalette.success, Icons.check_circle_rounded);
      _loadBookings();
    }
  }

  Future<void> _handleReject(int requestId) async {
    HapticFeedback.mediumImpact();
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    final success = await ownerProvider.rejectBookingRequest(requestId, 'Booking rejected.');
    if (success && mounted) {
      _showSnackBar('Booking rejected', _BookPalette.danger, Icons.cancel_rounded);
      _loadBookings();
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  String _getStatusDisplay(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
        return 'Accepted';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is DateTime) return DateFormat('dd MMM yyyy').format(date);
      if (date is String) return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
      return date.toString();
    } catch (_) {
      return date.toString();
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ownerProvider = Provider.of<OwnerProvider>(context);

    final allBookings = ownerProvider.bookingRequests;
    final pending = allBookings.where((b) => b.status == 'PENDING').toList();
    final accepted = allBookings.where((b) => b.status == 'ACCEPTED').toList();
    final rejected = allBookings.where((b) => b.status == 'REJECTED').toList();
    final lists = [pending, accepted, rejected];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? _BookPalette.darkBg : _BookPalette.lightBg,
        body: SafeArea(
          child: Column(
            children: [
              FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: _buildHeroHeader(context, isDark, allBookings.length, pending.length),
                ),
              ),
              _buildSegmentedControl(isDark, pending.length, accepted.length, rejected.length),
              Expanded(
                child: ownerProvider.isLoading && allBookings.isEmpty
                    ? _buildLoadingState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        color: _BookPalette.primary,
                        backgroundColor: isDark ? _BookPalette.darkSurfaceAlt : Colors.white,
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: List.generate(3, (i) {
                            final status = ['PENDING', 'ACCEPTED', 'REJECTED'][i];
                            return _buildBookingList(context, lists[i], status, isDark);
                          }),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HERO HEADER ====================
  Widget _buildHeroHeader(BuildContext context, bool isDark, int total, int pending) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Requests',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pending > 0
                      ? '$pending waiting for your response'
                      : 'You\'re all caught up',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: pending > 0
                        ? _BookPalette.warning
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          _buildIconButton(
            icon: Icons.refresh_rounded,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              _loadBookings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required bool isDark, required VoidCallback onTap}) {
    return Material(
      color: isDark ? _BookPalette.darkSurfaceAlt : Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: _BookPalette.primary),
        ),
      ),
    );
  }

  // ==================== SEGMENTED CONTROL ====================
  Widget _buildSegmentedControl(bool isDark, int pending, int accepted, int rejected) {
    final segments = [
      {'label': 'Pending', 'count': pending, 'color': _BookPalette.warning},
      {'label': 'Accepted', 'count': accepted, 'color': _BookPalette.success},
      {'label': 'Rejected', 'count': rejected, 'color': _BookPalette.danger},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isDark ? _BookPalette.darkSurfaceAlt : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(3, (i) {
            final seg = segments[i];
            final isSelected = _selectedSegment == i;
            final color = seg['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSegment = i);
                  _tabController.animateTo(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(isDark ? 0.18 : 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    border: isSelected ? Border.all(color: color.withOpacity(0.35)) : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        seg['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? color : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (seg['count'] as int).toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? color : (isDark ? Colors.grey[300] : Colors.grey[500]),
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

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _BookPalette.primary, strokeWidth: 2.6),
          const SizedBox(height: 16),
          Text(
            'Loading bookings...',
            style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ==================== BOOKING LIST ====================
  Widget _buildBookingList(BuildContext context, List<BookingRequest> bookings, String status, bool isDark) {
    if (bookings.isEmpty) return _buildEmptyState(isDark, status);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 320 + (index * 40).clamp(0, 300)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
            );
          },
          child: _buildTicketCard(context, bookings[index], isDark),
        );
      },
    );
  }

  // ==================== TICKET-STYLE CARD ====================
  Widget _buildTicketCard(BuildContext context, BookingRequest booking, bool isDark) {
    final statusColors = {
      'PENDING': _BookPalette.warning,
      'ACCEPTED': _BookPalette.success,
      'REJECTED': _BookPalette.danger,
    };
    final color = statusColors[booking.status] ?? Colors.grey;
    final isPending = booking.status == 'PENDING';
    final initial = booking.propertyTitle.isNotEmpty ? booking.propertyTitle[0].toUpperCase() : 'P';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? _BookPalette.darkSurfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _showBookingDetailsSheet(context, booking, isDark);
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent strip
                  Container(width: 5, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: avatar + title + status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  initial,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.propertyTitle,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded,
                                            size: 12, color: isDark ? Colors.grey[500] : Colors.grey[500]),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            '${booking.propertyCity} · Room ${booking.roomNumber ?? 'N/A'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.5,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusDisplay(booking.status),
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Dashed-style divider
                          _buildDashedDivider(isDark),

                          const SizedBox(height: 12),

                          // Details row
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStat(Icons.calendar_today_rounded,
                                    _formatDate(booking.moveInDate), isDark),
                              ),
                              Expanded(
                                child: _buildMiniStat(Icons.access_time_rounded,
                                    '${booking.durationMonths ?? 1} mo', isDark),
                              ),
                              Expanded(
                                child: _buildMiniStat(Icons.history_rounded,
                                    _getTimeAgo(booking.requestedAt), isDark),
                              ),
                            ],
                          ),

                          if (booking.message != null && booking.message!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.format_quote_rounded,
                                      size: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      booking.message!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          if (isPending)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    label: 'Accept',
                                    icon: Icons.check_rounded,
                                    filled: true,
                                    color: _BookPalette.success,
                                    onTap: () => _handleAccept(booking.requestId),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildActionButton(
                                    label: 'Reject',
                                    icon: Icons.close_rounded,
                                    filled: false,
                                    color: _BookPalette.danger,
                                    onTap: () => _handleReject(booking.requestId),
                                  ),
                                ),
                              ],
                            )
                          else
                            _buildActionButton(
                              label: 'View Details',
                              icon: Icons.arrow_forward_rounded,
                              filled: false,
                              color: _BookPalette.primary,
                              fullWidth: true,
                              onTap: () => _showBookingDetailsSheet(context, booking, isDark),
                            ),
                        ],
                      ),
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

  Widget _buildDashedDivider(bool isDark) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 5.0;
          final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
          return Flex(
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 13, color: isDark ? Colors.grey[500] : Colors.grey[500]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final child = Material(
      color: filled ? Colors.transparent : color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: filled
              ? BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: filled ? Colors.white : color),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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

  // ==================== BOOKING DETAILS BOTTOM SHEET ====================
  void _showBookingDetailsSheet(BuildContext context, BookingRequest booking, bool isDark) {
    final statusColors = {
      'PENDING': _BookPalette.warning,
      'ACCEPTED': _BookPalette.success,
      'REJECTED': _BookPalette.danger,
    };
    final color = statusColors[booking.status] ?? Colors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? _BookPalette.darkSurfaceAlt : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.book_online_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking Details',
                                  style: GoogleFonts.playfairDisplay(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  _getStatusDisplay(booking.status),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildSheetRow(Icons.apartment_rounded, 'Property', booking.propertyTitle, isDark),
                      _buildSheetRow(Icons.location_on_rounded, 'City', booking.propertyCity, isDark),
                      _buildSheetRow(Icons.meeting_room_rounded, 'Room', booking.roomNumber ?? 'N/A', isDark),
                      _buildSheetRow(Icons.calendar_today_rounded, 'Move-in Date',
                          _formatDate(booking.moveInDate), isDark),
                      _buildSheetRow(Icons.access_time_rounded, 'Duration',
                          '${booking.durationMonths ?? 1} months', isDark),
                      if (booking.message != null && booking.message!.isNotEmpty)
                        _buildSheetRow(Icons.format_quote_rounded, 'Message', booking.message!, isDark),
                      if (booking.ownerResponse != null && booking.ownerResponse!.isNotEmpty)
                        _buildSheetRow(Icons.reply_rounded, 'Your Response', booking.ownerResponse!, isDark,
                            valueColor: _BookPalette.success),
                      _buildSheetRow(Icons.upload_rounded, 'Requested',
                          _formatDate(booking.requestedAt), isDark),
                      if (booking.respondedAt != null)
                        _buildSheetRow(Icons.done_all_rounded, 'Responded',
                            _formatDate(booking.respondedAt), isDark),
                      const SizedBox(height: 20),
                      if (booking.status == 'PENDING')
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: 'Accept',
                                icon: Icons.check_rounded,
                                filled: true,
                                color: _BookPalette.success,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _handleAccept(booking.requestId);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionButton(
                                label: 'Reject',
                                icon: Icons.close_rounded,
                                filled: false,
                                color: _BookPalette.danger,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _handleReject(booking.requestId);
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        _buildActionButton(
                          label: 'Close',
                          icon: Icons.close_rounded,
                          filled: false,
                          color: _BookPalette.primary,
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

  Widget _buildSheetRow(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _BookPalette.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _BookPalette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState(bool isDark, String status) {
    final icons = {
      'PENDING': Icons.pending_actions_rounded,
      'ACCEPTED': Icons.check_circle_rounded,
      'REJECTED': Icons.cancel_rounded,
    };
    final messages = {
      'PENDING': 'No pending bookings',
      'ACCEPTED': 'No accepted bookings',
      'REJECTED': 'No rejected bookings',
    };
    final colors = {
      'PENDING': _BookPalette.warning,
      'ACCEPTED': _BookPalette.success,
      'REJECTED': _BookPalette.danger,
    };
    final icon = icons[status] ?? Icons.book_online_rounded;
    final message = messages[status] ?? 'No bookings found';
    final color = colors[status] ?? _BookPalette.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 52, color: color.withOpacity(0.6)),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}