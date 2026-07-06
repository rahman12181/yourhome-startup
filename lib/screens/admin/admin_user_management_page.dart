// lib/screens/admin/admin_user_management_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFirstLoad = true;
  String _selectedRoleFilter = 'All';
  String _searchQuery = '';

  final List<String> _roleFilters = ['All', 'STUDENT', 'OWNER', 'ADMIN'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    await adminProvider.getAllUsers();
    await adminProvider.getPendingOwners();
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

    // ✅ Calculate counts for chips
    final totalUsers = adminProvider.allUsers.length;
    final studentCount = adminProvider.allUsers.where((u) => u.role == 'STUDENT').length;
    final ownerCount = adminProvider.allUsers.where((u) => u.role == 'OWNER').length;
    final adminCount = adminProvider.allUsers.where((u) => u.role == 'ADMIN').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'User Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // ✅ Filter Chips - Single Row (No Overflow)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'All',
                        totalUsers.toString(),
                        _selectedRoleFilter == 'All',
                        const Color(0xFF7C3AED),
                        isDark,
                        onTap: () {
                          setState(() {
                            _selectedRoleFilter = 'All';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '👤 Users',
                        studentCount.toString(),
                        _selectedRoleFilter == 'STUDENT',
                        const Color(0xFF2563EB),
                        isDark,
                        onTap: () {
                          setState(() {
                            _selectedRoleFilter = 'STUDENT';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '🏢 Owners',
                        ownerCount.toString(),
                        _selectedRoleFilter == 'OWNER',
                        const Color(0xFFF59E0B),
                        isDark,
                        onTap: () {
                          setState(() {
                            _selectedRoleFilter = 'OWNER';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '👑 Admin',
                        adminCount.toString(),
                        _selectedRoleFilter == 'ADMIN',
                        const Color(0xFF7C3AED),
                        isDark,
                        onTap: () {
                          setState(() {
                            _selectedRoleFilter = 'ADMIN';
                          });
                        },
                      ),
                      // ✅ Clear Filter Button
                      if (_selectedRoleFilter != 'All')
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRoleFilter = 'All';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ✅ Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF7C3AED),
                    unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'All Users'),
                      Tab(text: 'Pending Owners'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: adminProvider.isLoading && adminProvider.allUsers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF7C3AED),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllUsersList(context, isDark, adminProvider),
                  _buildPendingOwnersList(context, isDark, adminProvider),
                ],
              ),
            ),
    );
  }

  // ✅ Premium Filter Chip - No Overflow
  Widget _buildFilterChip(
    String label,
    String count,
    bool isSelected,
    Color color,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== ALL USERS LIST ==============
  Widget _buildAllUsersList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    // ✅ Apply role filter
    var filteredUsers = provider.allUsers.where((user) {
      if (_selectedRoleFilter == 'All') return true;
      return user.role == _selectedRoleFilter;
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_selectedRoleFilter == 'All' ? 'users' : _selectedRoleFilter.toLowerCase() + 's'} found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(context, user, isDark, provider);
      },
    );
  }

  // ============== PENDING OWNERS LIST ==============
  Widget _buildPendingOwnersList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    if (provider.pendingOwners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending owner requests',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: provider.pendingOwners.length,
      itemBuilder: (context, index) {
        final owner = provider.pendingOwners[index];
        return _buildPendingOwnerCard(context, owner, isDark, provider);
      },
    );
  }

  // ============== USER CARD ==============
  Widget _buildUserCard(
    BuildContext context,
    dynamic user,
    bool isDark,
    AdminProvider provider,
  ) {
    final isActive = user.isActive;
    final roleColor = _getRoleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isActive
            ? null
            : Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isActive ? roleColor : Colors.grey[600],
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    fontSize: 15,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildBadge(user.role, roleColor),
                    _buildBadge(
                      isActive ? 'Active' : 'Deactivated',
                      isActive ? Colors.green : Colors.red,
                    ),
                    if (user.isEmailVerified)
                      _buildBadge('Verified', Colors.green),
                  ],
                ),
              ],
            ),
          ),
          if (isActive)
            IconButton(
              icon: const Icon(Icons.block_rounded, color: Colors.red, size: 22),
              onPressed: () => _showDeactivateDialog(context, user, provider),
              tooltip: 'Deactivate',
            )
          else
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
              onPressed: () => _showActivateDialog(context, user, provider),
              tooltip: 'Activate',
            ),
        ],
      ),
    );
  }

  // ============== PENDING OWNER CARD ==============
  Widget _buildPendingOwnerCard(
    BuildContext context,
    dynamic owner,
    bool isDark,
    AdminProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.orange[400],
                child: Text(
                  owner.name.isNotEmpty ? owner.name[0].toUpperCase() : 'O',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      owner.businessName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pending',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildDetailChip(Icons.email_rounded, owner.email),
              _buildDetailChip(Icons.phone_rounded, owner.phone),
              _buildDetailChip(
                Icons.business_center_rounded,
                owner.subscriptionPlan,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final success = await provider.verifyOwner(owner.ownerId);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Owner verified successfully ✅'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showRejectDialog(context, owner, provider);
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============== HELPERS ==============
  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFF7C3AED);
      case 'OWNER':
        return const Color(0xFFF59E0B);
      case 'STUDENT':
        return const Color(0xFF2563EB);
      default:
        return Colors.grey;
    }
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============== DIALOGS ==============
  void _showDeactivateDialog(BuildContext context, dynamic user, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.red[400]),
            const SizedBox(width: 10),
            Text(
              'Deactivate User',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate ${user.name}?',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deactivateUser(user.userId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deactivated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showActivateDialog(BuildContext context, dynamic user, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green[400]),
            const SizedBox(width: 10),
            Text(
              'Activate User',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to activate ${user.name}?',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.activateUser(user.userId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User activated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, dynamic owner, AdminProvider provider) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red[400]),
            const SizedBox(width: 10),
            Text(
              'Reject Owner',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject ${owner.name}?',
              style: GoogleFonts.poppins(fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              final success = await provider.rejectOwner(
                owner.ownerId,
                reasonController.text.trim(),
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Owner rejected ❌'),
                    backgroundColor: Colors.red,
                  ),
                );
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}