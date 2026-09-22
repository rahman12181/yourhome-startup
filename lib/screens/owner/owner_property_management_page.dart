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

class OwnerPropertyManagementPage extends StatefulWidget {
  const OwnerPropertyManagementPage({super.key});

  @override
  State<OwnerPropertyManagementPage> createState() =>
      _OwnerPropertyManagementPageState();
}

class _OwnerPropertyManagementPageState
    extends State<OwnerPropertyManagementPage>
    with TickerProviderStateMixin {
  bool _isFirstLoad = true;
  late AnimationController _fadeController;
  late AnimationController _staggerController;

  // Filter state
  String _searchQuery = '';
  String _filter = 'ALL'; // ALL | PUBLISHED | DRAFT

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
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    await ownerProvider.loadAllOwnerData();
    if (mounted) _staggerController.forward(from: 0);
  }

  // ================= SUBSCRIPTION DIALOG =================
  void _showSubscriptionRequiredDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF121729) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.15),
                      const Color(0xFF4ECDC4).withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFF7C3AED),
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Subscription Required',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You need an active Property Access Subscription to add, edit, or manage properties.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : const Color(0xFF8A8FA3),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unlock unlimited property management with one subscription.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFFB45309),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE8E8F0),
                          ),
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF666680),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4ECDC4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToSubscription();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: Text(
                              'Buy Subscription',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
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

  void _navigateToSubscription() {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    int propertyId = 0;
    String propertyTitle = 'Property Access';
    if (ownerProvider.myProperties.isNotEmpty) {
      final firstProperty = ownerProvider.myProperties.first;
      propertyId = firstProperty.propertyId;
      propertyTitle = firstProperty.title;
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

  // ================= DELETE =================
  Future<void> _deleteProperty(Property property) async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);

    if (!ownerProvider.canAddProperty) {
      _showSubscriptionRequiredDialog();
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF121729) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Property?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${property.title}" will be permanently removed along with all its rooms and media.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : const Color(0xFF8A8FA3),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE8E8F0),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF666680),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
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

    if (confirm == true) {
      final success = await ownerProvider.deleteProperty(property.propertyId);
      if (success && mounted) {
        _showSnack('Property deleted');
        _loadAllData();
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ================= FILTER =================
  List<Property> _filtered(List<Property> all) {
    var list = all;
    if (_filter == 'PUBLISHED') {
      list = list.where((p) => p.isPublished).toList();
    } else if (_filter == 'DRAFT') {
      list = list.where((p) => !p.isPublished).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.city.toLowerCase().contains(q) ||
              p.state.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Consumer<OwnerProvider>(
          builder: (context, ownerProvider, _) {
            final allProperties = ownerProvider.myProperties;
            final properties = _filtered(allProperties);
            final hasAccess = ownerProvider.canAddProperty;
            final accessStatus = ownerProvider.propertyAccessStatus;
            final isLoading =
                ownerProvider.isLoading && allProperties.isEmpty;

            return Column(
              children: [
                _buildHeader(isDark, hasAccess, allProperties.length),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAllData,
                    color: const Color(0xFF7C3AED),
                    backgroundColor:
                        isDark ? const Color(0xFF1A1F33) : Colors.white,
                    child: isLoading
                        ? _buildSkeleton(isDark)
                        : FadeTransition(
                            opacity: _fadeController,
                            child: ListView(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                              children: [
                                _buildSubscriptionPill(
                                  isDark,
                                  hasAccess,
                                  accessStatus,
                                ),
                                const SizedBox(height: 14),
                                if (allProperties.isNotEmpty) ...[
                                  _buildStatsRow(isDark, allProperties),
                                  const SizedBox(height: 14),
                                  _buildSearchAndFilter(isDark),
                                  const SizedBox(height: 14),
                                ],
                                if (properties.isEmpty)
                                  allProperties.isEmpty
                                      ? _buildEmptyState(isDark, hasAccess)
                                      : _buildNoResults(isDark)
                                else
                                  ...List.generate(properties.length, (i) {
                                    final delay = i * 0.05;
                                    return AnimatedBuilder(
                                      animation: _staggerController,
                                      builder: (context, child) {
                                        final t =
                                            Curves.easeOutCubic.transform(
                                          ((_staggerController.value - delay)
                                                  .clamp(0.0, 1.0))
                                              .toDouble(),
                                        );
                                        return Transform.translate(
                                          offset: Offset(0, 24 * (1 - t)),
                                          child:
                                              Opacity(opacity: t, child: child),
                                        );
                                      },
                                      child: _buildPropertyCard(
                                        context,
                                        properties[i],
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
      floatingActionButton: Consumer<OwnerProvider>(
        builder: (context, ownerProvider, _) {
          final hasAccess = ownerProvider.canAddProperty;
          return _buildFab(isDark, hasAccess);
        },
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(bool isDark, bool hasAccess, int totalCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.apartment_rounded,
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
                  'My Properties',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  totalCount == 0
                      ? 'No properties yet'
                      : '$totalCount propert${totalCount == 1 ? 'y' : 'ies'} total',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ],
            ),
          ),
          _circleBtn(
            icon: Icons.refresh_rounded,
            onTap: _loadAllData,
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
        width: 42,
        height: 42,
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
          size: 19,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  // ================= FAB =================
  Widget _buildFab(bool isDark, bool hasAccess) {
    return Container(
      decoration: BoxDecoration(
        gradient: hasAccess
            ? const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4ECDC4)],
              )
            : const LinearGradient(
                colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (hasAccess
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF6B7280))
                .withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (hasAccess) {
              _openAddProperty();
            } else {
              _showSubscriptionRequiredDialog();
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasAccess ? Icons.add_rounded : Icons.lock_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  hasAccess ? 'Add Property' : 'Unlock',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddProperty() async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditPropertyPage()),
    );
    if (result == true) _loadAllData();
  }

  // ================= SUBSCRIPTION PILL =================
  Widget _buildSubscriptionPill(
    bool isDark,
    bool hasAccess,
    PropertyAccessStatus? status,
  ) {
    Color color;
    IconData icon;
    String title;
    String? subtitle;
    String buttonLabel;
    VoidCallback buttonTap;

    if (hasAccess) {
      final daysLeft = status?.daysRemaining ?? 0;
      final isExpiring = status?.isExpiringSoon ?? false;
      color = isExpiring ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
      icon = isExpiring ? Icons.warning_rounded : Icons.check_circle_rounded;
      title = isExpiring ? 'Expiring Soon' : 'Property Access Active';
      subtitle = daysLeft > 0 ? '$daysLeft days remaining' : null;
      buttonLabel = 'Renew';
      buttonTap = _navigateToSubscription;
    } else {
      final isExpired = (status?.status ?? 'EXPIRED') == 'EXPIRED';
      color = isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
      icon = isExpired ? Icons.cancel_rounded : Icons.lock_rounded;
      title = isExpired ? 'Subscription Expired' : 'No Active Subscription';
      subtitle = 'Buy to manage properties';
      buttonLabel = isExpired ? 'Renew' : 'Buy Now';
      buttonTap = _navigateToSubscription;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: buttonTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.75)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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

  // ================= STATS ROW =================
  Widget _buildStatsRow(bool isDark, List<Property> properties) {
    final total = properties.length;
    final published = properties.where((p) => p.isPublished).length;
    final draft = total - published;

    return Row(
      children: [
        _statCard(
          label: 'Total',
          value: total,
          icon: Icons.apartment_rounded,
          color: const Color(0xFF7C3AED),
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'Published',
          value: published,
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF22C55E),
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'Draft',
          value: draft,
          icon: Icons.drafts_rounded,
          color: const Color(0xFFF59E0B),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121729) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF0F0F8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SEARCH & FILTER =================
  Widget _buildSearchAndFilter(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121729) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFF0F0F8),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 18,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by title, city...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: isDark ? Colors.white38 : const Color(0xFFB0B3C0),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('ALL', 'All', isDark),
              const SizedBox(width: 8),
              _filterChip('PUBLISHED', 'Published', isDark),
              const SizedBox(width: 8),
              _filterChip('DRAFT', 'Draft', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label, bool isDark) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                )
              : null,
          color: selected
              ? null
              : (isDark ? const Color(0xFF121729) : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
            width: 1.3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF666680)),
          ),
        ),
      ),
    );
  }

  // ================= PROPERTY CARD =================
  Widget _buildPropertyCard(
    BuildContext context,
    Property property,
    bool isDark,
    bool hasAccess,
  ) {
    final isPublished = property.isPublished;
    final hasImage = property.coverImage.isNotEmpty;
    final statusColor =
        isPublished ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFF0F0F8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: hasAccess
              ? () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyRoomsPage(property: property),
                    ),
                  );
                }
              : _showSubscriptionRequiredDialog,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============ COVER IMAGE ============
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: property.coverImage,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: isDark
                                      ? Colors.grey[900]
                                      : Colors.grey[100],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.apartment_rounded,
                                  size: 46,
                                  color: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[400],
                                ),
                              )
                            : Icon(
                                Icons.apartment_rounded,
                                size: 46,
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[400],
                              ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Status pill top-left
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPublished
                                  ? Icons.check_circle_rounded
                                  : Icons.drafts_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPublished ? 'Published' : 'Draft',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Lock badge top-right (if no access)
                    if (!hasAccess)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Locked',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Bottom info on image
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '${property.city}, ${property.state}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ============ STATS + ACTIONS ============
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  children: [
                    // Stats
                    Row(
                      children: [
                        _propertyStat(
                          icon: Icons.meeting_room_rounded,
                          label: 'Rooms',
                          value: '${property.totalRooms}',
                          color: const Color(0xFF7C3AED),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _propertyStat(
                          icon: Icons.check_circle_rounded,
                          label: 'Available',
                          value: '${property.availableRooms}',
                          color: const Color(0xFF22C55E),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _propertyStat(
                          icon: Icons.category_rounded,
                          label: 'Type',
                          value: property.propertyType,
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.room_preferences_rounded,
                            label: 'Rooms',
                            color: const Color(0xFF7C3AED),
                            isDark: isDark,
                            onTap: hasAccess
                                ? () {
                                    HapticFeedback.selectionClick();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PropertyRoomsPage(property: property),
                                      ),
                                    );
                                  }
                                : _showSubscriptionRequiredDialog,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            color: const Color(0xFF3B82F6),
                            isDark: isDark,
                            onTap: hasAccess
                                ? () async {
                                    HapticFeedback.selectionClick();
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditPropertyPage(
                                            property: property),
                                      ),
                                    );
                                    if (result == true) _loadAllData();
                                  }
                                : _showSubscriptionRequiredDialog,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            color: const Color(0xFFEF4444),
                            isDark: isDark,
                            onTap: () => _deleteProperty(property),
                          ),
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

  Widget _propertyStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SKELETON =================
  Widget _buildSkeleton(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        Container(
          height: 62,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121729) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                height: 90,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121729) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(
          2,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 300,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121729) : Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ],
    );
  }

  // ================= NO RESULTS =================
  Widget _buildNoResults(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121729) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFF0F0F8),
              ),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 40,
              color: isDark ? Colors.white38 : const Color(0xFFB0B3C0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Results',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or filter',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
            ),
          ),
        ],
      ),
    );
  }

  // ================= EMPTY =================
  Widget _buildEmptyState(bool isDark, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.15),
                  const Color(0xFF4ECDC4).withOpacity(0.08),
                ],
              ),
            ),
            child: Icon(
              hasAccess ? Icons.apartment_outlined : Icons.lock_outlined,
              size: 56,
              color: const Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            hasAccess ? 'No Properties Yet' : 'Unlock Property Management',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hasAccess
                  ? 'Add your first property to start accepting bookings.'
                  : 'Buy a Property Access Subscription to add and manage properties.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: hasAccess ? _openAddProperty : _navigateToSubscription,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4ECDC4)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasAccess ? Icons.add_rounded : Icons.lock_open_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasAccess ? 'Add First Property' : 'Buy Subscription',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
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
}