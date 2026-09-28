import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/admin_model.dart';
import '../../providers/admin_provider.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isFirstLoad = true;
  String _searchQuery = '';
  String _selectedRole = 'All';

  final List<String> _roles = ['All', 'STUDENT', 'OWNER', 'ADMIN'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final p = Provider.of<AdminProvider>(context, listen: false);
    await p.getAllUsers();
    await p.getAllOwners();
    await p.getPendingOwners();
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
        title: Text('User Management',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(135),
          child: Column(
            children: [
              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF7C3AED)),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF141A2C) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Role Filter Chips ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _roles.map((role) {
                    final isSelected = _selectedRole == role;
                    final count = role == 'All'
                        ? p.allUsers.length
                        : p.allUsers.where((u) => u.role == role).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRole = role),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : (isDark
                                    ? const Color(0xFF141A2C)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7C3AED)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.06)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(role,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
                                  )),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.25)
                                      : const Color(0xFF7C3AED)
                                          .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$count',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF7C3AED),
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // ── Tabs ──
              Container(
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
                  tabs: [
                    Tab(text: 'All Users (${p.allUsers.length})'),
                    Tab(text: 'Pending (${p.pendingOwners.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: p.isLoading && p.allUsers.isEmpty && p.pendingOwners.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildUsersList(isDark, p),
                _buildPendingList(isDark, p),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════
  // USERS LIST
  // ═══════════════════════════════════════════
  Widget _buildUsersList(bool isDark, AdminProvider p) {
    var filtered = p.allUsers.where((u) {
      if (_selectedRole != 'All' && u.role != _selectedRole) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.displayId.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return _empty('No users found', isDark, Icons.people_outline_rounded);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _userCard(isDark, filtered[i], p),
      ),
    );
  }

  Widget _userCard(bool isDark, AdminUser u, AdminProvider p) {
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: u.isActive
              ? Colors.transparent
              : Colors.red.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            debugPrint('🔴 CARD TAPPED: ${u.name} (id: ${u.userId})');
            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminUserDetailScreen(
                    userId: u.userId,
                    user: u,
                  ),
                ),
              );
              debugPrint('🟢 Navigator.push called successfully');
            } catch (e, st) {
              debugPrint('❌ ERROR on navigation: $e');
              debugPrint('$st');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    // ── Avatar ──
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [roleColor, roleColor.withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: (u.profilePic != null &&
                                u.profilePic!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: u.profilePic!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _avatarFallback(u.name, roleColor),
                                errorWidget: (_, __, ___) =>
                                    _avatarFallback(u.name, roleColor),
                              )
                            : _avatarFallback(u.name, roleColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.badge_rounded,
                                  size: 11, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(u.displayId,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(u.email,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, size: 10, color: roleColor),
                              const SizedBox(width: 3),
                              Text(u.role,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: roleColor,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.grey[600]
                                : Colors.grey[400]),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Status Chips ──
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _chip(
                      u.isActive ? '✅ Active' : '⛔ Deactivated',
                      u.isActive ? const Color(0xFF10B981) : Colors.red,
                      isDark,
                    ),
                    if (u.isEmailVerified)
                      _chip('📧 Verified', const Color(0xFF3B82F6), isDark),
                    if (u.phone != null && u.phone!.isNotEmpty)
                      _chip('📱 ${u.phone}', const Color(0xFF8B5CF6), isDark),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Action Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmToggle(isDark, u, p),
                        icon: Icon(
                          u.isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_rounded,
                          size: 16,
                        ),
                        label: Text(
                          u.isActive ? 'Deactivate' : 'Activate',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: u.isActive
                              ? Colors.red
                              : const Color(0xFF10B981),
                          side: BorderSide(
                            color: u.isActive
                                ? Colors.red
                                : const Color(0xFF10B981),
                            width: 1.3,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          debugPrint('🔴 VIEW PROFILE BUTTON TAPPED: ${u.name}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(
                                userId: u.userId,
                                user: u,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: Text('View Profile',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PENDING OWNERS LIST
  // ═══════════════════════════════════════════
  Widget _buildPendingList(bool isDark, AdminProvider p) {
    if (p.pendingOwners.isEmpty) {
      return _empty('No pending owners', isDark,
          Icons.pending_actions_rounded);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: p.pendingOwners.length,
        itemBuilder: (context, i) =>
            _pendingCard(isDark, p.pendingOwners[i], p),
      ),
    );
  }

  Widget _pendingCard(bool isDark, PendingOwner o, AdminProvider p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: (o.profilePic != null &&
                          o.profilePic!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: o.profilePic!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _avatarFallbackOwner(o.name),
                          errorWidget: (_, __, ___) =>
                              _avatarFallbackOwner(o.name),
                        )
                      : _avatarFallbackOwner(o.name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A2E),
                        )),
                    const SizedBox(height: 2),
                    Text(o.businessName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(o.displayId,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[500],
                        )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('PENDING',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('📧 ${o.email}', const Color(0xFF3B82F6), isDark),
              _chip('📱 ${o.phone}', const Color(0xFF8B5CF6), isDark),
              _chip('💎 ${o.subscriptionPlan}', const Color(0xFF10B981),
                  isDark),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await p.verifyOwner(o.ownerId);
                    if (ok && mounted) {
                      _snack('Owner verified ✅', const Color(0xFF10B981));
                      _loadData();
                    } else if (mounted) {
                      _snack(p.error ?? 'Failed to verify', Colors.red);
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text('Verify',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(o, p, isDark),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text('Reject',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallbackOwner(String name) {
    return Container(
      color: const Color(0xFFF59E0B).withOpacity(0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'O',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF59E0B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════
  void _confirmToggle(bool isDark, AdminUser u, AdminProvider p) {
    showDialog(
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
              ? 'Are you sure you want to deactivate ${u.name}? They won\'t be able to login.'
              : 'Are you sure you want to activate ${u.name}?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = u.isActive
                  ? await p.deactivateUser(u.userId)
                  : await p.activateUser(u.userId);
              if (ok && mounted) {
                _snack(
                  u.isActive ? 'User deactivated' : 'User activated ✅',
                  u.isActive ? Colors.orange : const Color(0xFF10B981),
                );
              } else if (mounted) {
                _snack(p.error ?? 'Action failed', Colors.red);
              }
            },
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
  }

  void _showRejectDialog(PendingOwner o, AdminProvider p, bool isDark) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text('Reject Owner',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting: ${o.name}',
                style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: GoogleFonts.poppins(fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF7C3AED), width: 1.6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                _snack('Please enter a reason', Colors.orange);
                return;
              }
              Navigator.pop(context);
              final ok = await p.rejectOwner(
                  o.ownerId, reasonCtrl.text.trim());
              if (ok && mounted) {
                _snack('Owner rejected ❌', Colors.red);
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
  Widget _chip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            color: color,
            fontWeight: FontWeight.w600,
          )),
    );
  }

  Widget _empty(String msg, bool isDark, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 52,
                color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(msg,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              )),
        ],
      ),
    );
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