// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/owner_model.dart';
import '../../providers/owner_provider.dart';
import '../../models/property_model.dart';
import 'add_edit_property_page.dart';
import 'property_rooms_page.dart';
import 'property_access_subscription_page.dart';

// ══════════════════════════════════════════════════════════════
// DESIGN TOKENS — Blue premium theme
// ══════════════════════════════════════════════════════════════
class _C {
  // ── Brand: professional blue ──
  static const accent = Color(0xFF2563EB);        // primary blue
  static const accentDark = Color(0xFF1D4ED8);    // blue on light bg text
  static const accentLight = Color(0xFF3B82F6);   // lighter blue
  static const accentSoft = Color(0xFFEBF1FF);    // very light blue tint
  static const ink = Color(0xFF0F172A);           // deep ink for contrast

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ── Dark theme (unchanged) ──
  static const darkBg = Color(0xFF0B1020);
  static const darkSurface = Color(0xFF131A2E);
  static const darkSurfaceAlt = Color(0xFF1C2540);

  // ── Light theme (clean, blue-tinted) ──
  static const lightBg = Color(0xFFF6F8FC);
  static const lightBorder = Color(0xFFE5EAF3);
  static const lightText = Color(0xFF0F172A);
  static const lightTextSec = Color(0xFF64748B);
  static const lightTextTer = Color(0xFF94A3B8);

  static Color bg(bool d) => d ? darkBg : lightBg;
  static Color surface(bool d) => d ? darkSurface : Colors.white;
  static Color surfaceAlt(bool d) => d ? darkSurfaceAlt : const Color(0xFFF1F4FA);
  static Color border(bool d) => d ? Colors.white.withOpacity(0.07) : lightBorder;
  static Color text(bool d) => d ? Colors.white : lightText;
  static Color textSec(bool d) => d ? Colors.white60 : lightTextSec;
  static Color textTer(bool d) => d ? Colors.white38 : lightTextTer;

  // Primary buttons: solid blue in BOTH modes (consistent, professional)
  static Color btnBg(bool d) => accent;
  static Color btnFg(bool d) => Colors.white;

  // Blue tinted soft backgrounds for chips/badges
  static Color accentSoftBg(bool d) =>
      d ? accent.withOpacity(0.15) : accentSoft;
}

class OwnerPropertyManagementPage extends StatefulWidget {
  const OwnerPropertyManagementPage({super.key});

  @override
  State<OwnerPropertyManagementPage> createState() =>
      _OwnerPropertyManagementPageState();
}

class _OwnerPropertyManagementPageState
    extends State<OwnerPropertyManagementPage> with TickerProviderStateMixin {
  static const double _hPad = 8.0;

  bool _isFirstLoad = true;
  late final AnimationController _fadeController;
  late final AnimationController _staggerController;
  late final AnimationController _pulseController;

  String _searchQuery = '';
  String _filter = 'ALL';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    )..forward();

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadAllData();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _pulseController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    await ownerProvider.loadAllOwnerData();
    if (mounted) _staggerController.forward(from: 0);
  }

  // ══════════════════════════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════════════════════════
  Future<bool?> _showActionDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
    Color? confirmColor,
    Widget? extra,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _C.surface(isDark),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: _C.text(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.55,
                  color: _C.textSec(isDark),
                ),
              ),
              if (extra != null) ...[
                const SizedBox(height: 16),
                extra,
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _C.border(isDark)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        cancelLabel,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _C.textSec(isDark),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor ?? color,
                        foregroundColor: confirmColor == null
                            ? Colors.white
                            : _C.btnFg(isDark),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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

  Future<void> _showSubscriptionRequiredDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await _showActionDialog(
      icon: Icons.lock_rounded,
      color: _C.accent,
      title: 'Subscription Required',
      message:
          'You need an active Property Access Subscription to add, edit or manage properties.',
      cancelLabel: 'Not Now',
      confirmLabel: 'Subscribe',
      confirmColor: _C.btnBg(isDark),
      extra: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.accentSoftBg(isDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: _C.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'One subscription unlocks unlimited property management.',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  height: 1.4,
                  color: _C.accentDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) _navigateToSubscription();
  }

  void _navigateToSubscription() {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    int propertyId = 0;
    String propertyTitle = 'Property Access';
    if (ownerProvider.myProperties.isNotEmpty) {
      final first = ownerProvider.myProperties.first;
      propertyId = first.propertyId;
      propertyTitle = first.title;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyAccessSubscriptionPage(
          propertyId: propertyId,
          propertyTitle: propertyTitle,
        ),
      ),
    ).then((_) => _loadAllData());
  }

  // ══════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════
  Future<void> _deleteProperty(Property property) async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);

    if (!ownerProvider.canAddProperty) {
      _showSubscriptionRequiredDialog();
      return;
    }

    final confirm = await _showActionDialog(
      icon: Icons.delete_outline_rounded,
      color: _C.danger,
      title: 'Delete Property?',
      message:
          '"${property.title}" will be permanently removed along with all its rooms and media.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
    );

    if (confirm != true) return;

    final success = await ownerProvider.deleteProperty(property.propertyId);
    if (!mounted) return;
    if (success) {
      _showSnack('Property deleted');
      _loadAllData();
    } else {
      _showSnack('Could not delete property. Please try again.',
          isError: true);
    }
  }

  void _openRooms(Property property) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PropertyRoomsPage(property: property)),
    );
  }

  Future<void> _openEdit(Property property) async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditPropertyPage(property: property)),
    );
    if (result == true) _loadAllData();
  }

  Future<void> _openAddProperty() async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditPropertyPage()),
    );
    if (result == true) _loadAllData();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ],
          ),
          backgroundColor: isError ? _C.danger : _C.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ══════════════════════════════════════════════════════════
  // FILTER
  // ══════════════════════════════════════════════════════════
  List<Property> _filtered(List<Property> all) {
    var list = all;
    if (_filter == 'PUBLISHED') {
      list = list.where((p) => p.isPublished).toList();
    } else if (_filter == 'DRAFT') {
      list = list.where((p) => !p.isPublished).toList();
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.city.toLowerCase().contains(q) ||
              p.state.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _C.bg(isDark),
      body: SafeArea(
        child: Consumer<OwnerProvider>(
          builder: (context, ownerProvider, _) {
            final all = ownerProvider.myProperties;
            final visible = _filtered(all);
            final hasAccess = ownerProvider.canAddProperty;
            final accessStatus = ownerProvider.propertyAccessStatus;
            final isLoading = ownerProvider.isLoading && all.isEmpty;

            return Column(
              children: [
                _buildHeader(isDark, all.length, hasAccess),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAllData,
                    color: _C.accent,
                    backgroundColor: _C.surface(isDark),
                    child: isLoading
                        ? _buildSkeleton(isDark)
                        : FadeTransition(
                            opacity: _fadeController,
                            child: ListView(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                  _hPad, 8, _hPad, 100),
                              children: [
                                _buildSubscriptionBanner(
                                    isDark, hasAccess, accessStatus),
                                if (all.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  _buildStatsCard(isDark, all),
                                  const SizedBox(height: 18),
                                  _buildSearchField(isDark),
                                  const SizedBox(height: 12),
                                  _buildSegmentedFilter(isDark, all),
                                ],
                                const SizedBox(height: 18),
                                if (visible.isEmpty)
                                  all.isEmpty
                                      ? _buildEmptyState(isDark, hasAccess)
                                      : _buildNoResults(isDark)
                                else
                                  ...List.generate(visible.length, (i) {
                                    final delay = i * 0.05;
                                    return AnimatedBuilder(
                                      animation: _staggerController,
                                      builder: (context, child) {
                                        final t = Curves.easeOutCubic
                                            .transform((_staggerController
                                                        .value -
                                                    delay)
                                                .clamp(0.0, 1.0)
                                                .toDouble());
                                        return Transform.translate(
                                          offset: Offset(0, 24 * (1 - t)),
                                          child: Opacity(
                                              opacity: t, child: child),
                                        );
                                      },
                                      child: _buildPropertyCard(
                                        visible[i],
                                        isDark,
                                        hasAccess,
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(bool isDark, int totalCount, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad + 4, 14, _hPad, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Properties',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    letterSpacing: -0.5,
                    height: 1.15,
                    color: _C.text(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalCount == 0
                      ? 'Add your first listing to get started'
                      : 'Manage your $totalCount listing${totalCount == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _C.textSec(isDark),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _loadAllData();
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.surface(isDark),
                shape: BoxShape.circle,
                border: Border.all(color: _C.border(isDark)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.refresh_rounded,
                  size: 20, color: _C.text(isDark)),
            ),
          ),
          const SizedBox(width: 8),
          // Always-visible Add button
          GestureDetector(
            onTap: hasAccess
                ? _openAddProperty
                : _showSubscriptionRequiredDialog,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: hasAccess ? _C.btnBg(isDark) : _C.surfaceAlt(isDark),
                borderRadius: BorderRadius.circular(22),
                boxShadow: hasAccess
                    ? [
                        BoxShadow(
                          color: _C.accent.withOpacity(0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasAccess ? Icons.add_rounded : Icons.lock_rounded,
                    size: 19,
                    color: hasAccess ? _C.btnFg(isDark) : _C.textSec(isDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasAccess ? 'Add' : 'Unlock',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasAccess ? _C.btnFg(isDark) : _C.textSec(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SUBSCRIPTION BANNER
  // ══════════════════════════════════════════════════════════
  Widget _buildSubscriptionBanner(
    bool isDark,
    bool hasAccess,
    PropertyAccessStatus? status,
  ) {
    final Color color;
    final IconData icon;
    final String title;
    final String? subtitle;
    final String buttonLabel;

    if (hasAccess) {
      final daysLeft = status?.daysRemaining ?? 0;
      final isExpiring = status?.isExpiringSoon ?? false;
      color = isExpiring ? _C.warning : _C.success;
      icon = isExpiring ? Icons.schedule_rounded : Icons.verified_rounded;
      title = isExpiring ? 'Expiring Soon' : 'Property Access Active';
      subtitle = daysLeft > 0 ? '$daysLeft days remaining' : null;
      buttonLabel = 'Renew';
    } else {
      final isExpired = (status?.status ?? 'EXPIRED') == 'EXPIRED';
      color = isExpired ? _C.danger : _C.warning;
      icon = isExpired ? Icons.error_outline_rounded : Icons.lock_outline_rounded;
      title = isExpired ? 'Subscription Expired' : 'No Active Subscription';
      subtitle = 'Subscribe to add and manage properties';
      buttonLabel = isExpired ? 'Renew' : 'Subscribe';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.10 : 0.08),
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
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
                    color: _C.text(isDark),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _C.textSec(isDark),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _navigateToSubscription,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STATS
  // ══════════════════════════════════════════════════════════
  Widget _buildStatsCard(bool isDark, List<Property> properties) {
    final total = properties.length;
    final published = properties.where((p) => p.isPublished).length;
    final draft = total - published;

    Widget divider() => Container(
          width: 1,
          height: 36,
          color: _C.border(isDark),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _cardDeco(isDark, radius: 18),
      child: Row(
        children: [
          _statItem('Total', total, _C.accent, isDark),
          divider(),
          _statItem('Published', published, _C.success, isDark),
          divider(),
          _statItem('Draft', draft, _C.warning, isDark),
        ],
      ),
    );
  }

  Widget _statItem(String label, int value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              height: 1.1,
              letterSpacing: -0.5,
              color: _C.text(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _C.textSec(isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SEARCH + FILTER
  // ══════════════════════════════════════════════════════════
  Widget _buildSearchField(bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border(isDark)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: _C.textTer(isDark)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _C.text(isDark),
              ),
              cursorColor: _C.accent,
              decoration: InputDecoration(
                hintText: 'Search by title, city or state',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: _C.textTer(isDark),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(Icons.close_rounded,
                  size: 18, color: _C.textTer(isDark)),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilter(bool isDark, List<Property> all) {
    final publishedCount = all.where((p) => p.isPublished).length;
    final items = <List<dynamic>>[
      ['ALL', 'All', all.length],
      ['PUBLISHED', 'Published', publishedCount],
      ['DRAFT', 'Draft', all.length - publishedCount],
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surfaceAlt(isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((it) {
          final value = it[0] as String;
          final label = it[1] as String;
          final count = it[2] as int;
          final selected = _filter == value;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _filter = value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _C.surface(isDark) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? (isDark ? Colors.white : _C.accentDark)
                            : _C.textSec(isDark),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected
                            ? _C.accent.withOpacity(0.15)
                            : _C.textTer(isDark).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? _C.accent
                              : _C.textSec(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PROPERTY CARD
  // ══════════════════════════════════════════════════════════
  BoxDecoration _cardDeco(bool isDark, {double radius = 20}) {
    return BoxDecoration(
      color: _C.surface(isDark),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _C.border(isDark)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(Property property, bool isDark, bool hasAccess) {
    final isPublished = property.isPublished;
    final hasImage = property.coverImage.isNotEmpty;
    final statusColor = isPublished ? _C.success : _C.warning;

    final int total = (property.totalRooms as num?)?.toInt() ?? 0;
    final int available = (property.availableRooms as num?)?.toInt() ?? 0;
    final int occupied = (total - available).clamp(0, total).toInt();
    final double occupancy = total > 0 ? occupied / total : 0.0;

    final placeholder = Container(
      color: _C.surfaceAlt(isDark),
      child: Icon(Icons.apartment_rounded,
          size: 44, color: _C.textTer(isDark)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDeco(isDark, radius: 22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: hasAccess
              ? () => _openRooms(property)
              : _showSubscriptionRequiredDialog,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: property.coverImage,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: _C.surfaceAlt(isDark),
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _C.accent,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => placeholder,
                            )
                          : placeholder,
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 70,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _imageChip(
                        icon: isPublished
                            ? Icons.check_circle_rounded
                            : Icons.edit_note_rounded,
                        label: isPublished ? 'Published' : 'Draft',
                        color: statusColor,
                      ),
                    ),
                    if (!hasAccess)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _imageChip(
                          icon: Icons.lock_rounded,
                          label: 'Locked',
                          color: _C.danger,
                        ),
                      ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                  color: _C.text(isDark),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 14, color: _C.textSec(isDark)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      '${property.city}, ${property.state}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: _C.textSec(isDark),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _C.accentSoftBg(isDark),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${property.propertyType}',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _C.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Room facts
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt(isDark),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _fact(Icons.meeting_room_outlined, '$total',
                              'Rooms', isDark),
                          _factDivider(isDark),
                          _fact(Icons.check_circle_outline_rounded,
                              '$available', 'Available', isDark,
                              valueColor: _C.success),
                          _factDivider(isDark),
                          _fact(Icons.person_outline_rounded, '$occupied',
                              'Occupied', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Occupancy bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Occupancy',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _C.textSec(isDark),
                          ),
                        ),
                        Text(
                          '${(occupancy * 100).round()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _C.text(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: occupancy,
                        minHeight: 6,
                        backgroundColor: _C.surfaceAlt(isDark),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_C.accent),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: hasAccess
                                  ? () => _openRooms(property)
                                  : _showSubscriptionRequiredDialog,
                              icon: const Icon(Icons.meeting_room_rounded,
                                  size: 18),
                              label: Text(
                                'Manage Rooms',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.btnBg(isDark),
                                foregroundColor: _C.btnFg(isDark),
                                elevation: 0,
                                shadowColor: _C.accent.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _squareAction(
                          icon: Icons.edit_outlined,
                          color: _C.info,
                          isDark: isDark,
                          tooltip: 'Edit',
                          onTap: hasAccess
                              ? () => _openEdit(property)
                              : _showSubscriptionRequiredDialog,
                        ),
                        const SizedBox(width: 8),
                        _squareAction(
                          icon: Icons.delete_outline_rounded,
                          color: _C.danger,
                          isDark: isDark,
                          tooltip: 'Delete',
                          onTap: () => _deleteProperty(property),
                        ),
                      ],
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

  Widget _imageChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fact(
    IconData icon,
    String value,
    String label,
    bool isDark, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: _C.textSec(isDark)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.1,
              color: valueColor ?? _C.text(isDark),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: _C.textSec(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _factDivider(bool isDark) => Container(
        width: 1,
        height: 38,
        color: _C.border(isDark),
      );

  Widget _squareAction({
    required IconData icon,
    required Color color,
    required bool isDark,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SKELETON
  // ══════════════════════════════════════════════════════════
  Widget _skelBox(bool isDark, {double? height, double radius = 16}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _C.border(isDark)),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
        children: [
          _skelBox(isDark, height: 70, radius: 18),
          const SizedBox(height: 14),
          _skelBox(isDark, height: 78, radius: 18),
          const SizedBox(height: 18),
          _skelBox(isDark, height: 50),
          const SizedBox(height: 12),
          _skelBox(isDark, height: 44, radius: 14),
          const SizedBox(height: 18),
          _skelBox(isDark, height: 380, radius: 22),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // EMPTY / NO RESULTS
  // ══════════════════════════════════════════════════════════
  Widget _buildNoResults(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _C.surface(isDark),
              shape: BoxShape.circle,
              border: Border.all(color: _C.border(isDark)),
            ),
            child: Icon(Icons.search_off_rounded,
                size: 38, color: _C.textTer(isDark)),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching properties',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.text(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different keyword or filter',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: _C.textSec(isDark),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() {
                _searchQuery = '';
                _filter = 'ALL';
              });
            },
            child: Text(
              'Clear filters',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _C.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: _C.accent.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasAccess ? Icons.apartment_rounded : Icons.lock_outline_rounded,
              size: 52,
              color: _C.accent,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            hasAccess ? 'No properties yet' : 'Unlock property management',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: _C.text(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              hasAccess
                  ? 'Add your first property to start accepting bookings from students.'
                  : 'Subscribe to Property Access to add and manage your listings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                height: 1.55,
                color: _C.textSec(isDark),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: hasAccess ? _openAddProperty : _navigateToSubscription,
              icon: Icon(
                hasAccess ? Icons.add_rounded : Icons.lock_open_rounded,
                size: 18,
              ),
              label: Text(
                hasAccess ? 'Add First Property' : 'Subscribe Now',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.btnBg(isDark),
                foregroundColor: _C.btnFg(isDark),
                elevation: 0,
                shadowColor: _C.accent.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}