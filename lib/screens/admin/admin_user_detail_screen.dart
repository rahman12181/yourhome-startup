import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/admin_model.dart';
import '../../providers/admin_provider.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;
  final AdminUser user;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    required this.user,
  });

  @override
  State<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  AdminUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _currentUser = widget.user;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = _currentUser ?? widget.user;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor:
                isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
            expandedHeight: 0,
            toolbarHeight: 64,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('User Profile',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                )),
          ),

          // ── Profile Header ──
          SliverToBoxAdapter(
            child: _buildProfileHeader(isDark, u),
          ),

          // ── Tabs ──
          SliverToBoxAdapter(
            child: _buildTabs(isDark),
          ),

          // ── Tab Content ──
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildDetailsTab(isDark, u),
                _buildActionsTab(isDark, u),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PROFILE HEADER
  // ═══════════════════════════════════════════
  Widget _buildProfileHeader(bool isDark, AdminUser u) {
    Color roleColor;
    IconData roleIcon;
    switch (u.role) {
      case 'ADMIN':
        roleColor = const Color(0xFF7C3AED);
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
      case 'OWNER':
        roleColor = const Color(0xFFF59E0B);
        roleIcon = Icons.business_center_rounded;
        break;
      default:
        roleColor = const Color(0xFF3B82F6);
        roleIcon = Icons.person_rounded;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [roleColor, roleColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ── Avatar ──
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(
                  child: (u.profilePic != null &&
                          u.profilePic!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: u.profilePic!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _avatarFallback(u.name),
                          errorWidget: (_, __, ___) =>
                              _avatarFallback(u.name),
                        )
                      : _avatarFallback(u.name),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.badge_rounded,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(u.displayId,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(u.role,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (u.isActive
                                    ? const Color(0xFF10B981)
                                    : Colors.red)
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            u.isActive ? '✅ Active' : '⛔ Inactive',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _contactChip(Icons.email_rounded, u.email),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _contactChip(
                    Icons.phone_rounded, u.phone ?? 'Not provided'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Color(0xFF7C3AED),
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        ),
      ),
    );
  }

  Widget _contactChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TABS
  // ═══════════════════════════════════════════
  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: const Color(0xFF7C3AED),
        unselectedLabelColor:
            isDark ? Colors.grey[500] : Colors.grey[600],
        indicator: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: '📋 Details'),
          Tab(text: '⚙️ Actions'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DETAILS TAB
  // ═══════════════════════════════════════════
  Widget _buildDetailsTab(bool isDark, AdminUser u) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _infoCard(isDark, 'Personal Information', [
          _infoRow('Full Name', u.name, isDark),
          _infoRow('Display ID', u.displayId, isDark),
          _infoRow('Email', u.email, isDark),
          _infoRow('Phone', u.phone ?? 'Not provided', isDark),
        ]),
        const SizedBox(height: 16),
        _infoCard(isDark, 'Account Information', [
          _infoRow('Role', u.role, isDark),
          _infoRow(
              'Account Status', u.isActive ? 'Active' : 'Deactivated', isDark),
          _infoRow('Email Verified', u.isEmailVerified ? 'Yes' : 'No', isDark),
          _infoRow(
              'Joined On',
              DateFormat('dd MMM yyyy, hh:mm a').format(u.createdAt),
              isDark),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _infoCard(bool isDark, String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              )),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                )),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                )),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ACTIONS TAB
  // ═══════════════════════════════════════════
  Widget _buildActionsTab(bool isDark, AdminUser u) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _actionCard(
          isDark,
          title: u.isActive ? 'Deactivate Account' : 'Activate Account',
          description: u.isActive
              ? 'User won\'t be able to login'
              : 'User will be able to login again',
          icon: u.isActive
              ? Icons.block_rounded
              : Icons.check_circle_rounded,
          color: u.isActive ? Colors.red : const Color(0xFF10B981),
          onTap: () => _handleToggle(context, u),
        ),
        const SizedBox(height: 12),
        _actionCard(
          isDark,
          title: 'Send Notification',
          description: 'Send a push notification to this user',
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () => _snack('Coming soon', const Color(0xFF3B82F6)),
        ),
        const SizedBox(height: 12),
        _actionCard(
          isDark,
          title: 'View Bookings',
          description: 'See all bookings made by this user',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () => _snack('Coming soon', const Color(0xFFF59E0B)),
        ),
      ],
    );
  }

  Widget _actionCard(
    bool isDark, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
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
                  Text(title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : const Color(0xFF1A1A2E),
                      )),
                  const SizedBox(height: 2),
                  Text(description,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: color),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════
  Future<void> _handleToggle(BuildContext context, AdminUser u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              u.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
              color: u.isActive ? Colors.red : const Color(0xFF10B981),
            ),
            const SizedBox(width: 10),
            Text(
              u.isActive ? 'Deactivate User?' : 'Activate User?',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          u.isActive
              ? 'Are you sure? ${u.name} won\'t be able to login.'
              : 'Are you sure you want to activate ${u.name}?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  u.isActive ? Colors.red : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(u.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final p = Provider.of<AdminProvider>(context, listen: false);
      final ok = u.isActive
          ? await p.deactivateUser(u.userId)
          : await p.activateUser(u.userId);
      if (ok && mounted) {
        setState(() {
          _currentUser = AdminUser(
            userId: u.userId,
            displayId: u.displayId,
            name: u.name,
            email: u.email,
            phone: u.phone,
            profilePic: u.profilePic,
            role: u.role,
            isActive: !u.isActive,
            isEmailVerified: u.isEmailVerified,
            createdAt: u.createdAt,
          );
        });
        _snack(
          u.isActive ? 'User deactivated' : 'User activated ✅',
          u.isActive ? Colors.orange : const Color(0xFF10B981),
        );
      }
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}