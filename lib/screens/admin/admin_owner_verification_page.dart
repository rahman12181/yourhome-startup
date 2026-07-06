// lib/screens/admin/admin_owner_verification_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/admin_provider.dart';
import 'admin_owner_review_page.dart';

class AdminOwnerVerificationPage extends StatefulWidget {
  const AdminOwnerVerificationPage({super.key});

  @override
  State<AdminOwnerVerificationPage> createState() =>
      _AdminOwnerVerificationPageState();
}

class _AdminOwnerVerificationPageState
    extends State<AdminOwnerVerificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFirstLoad = true;
  String _searchQuery = '';

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
    await adminProvider.getPendingOwners();
    await adminProvider.getPendingOwners();
    adminProvider.getAllOwners();
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

    // Get counts
    final pendingCount = adminProvider.pendingOwners.length;
    final verifiedCount = adminProvider.allOwners
        .where((o) => o.verificationStatus == 'VERIFIED')
        .length;
    final rejectedCount = adminProvider.allOwners
        .where((o) => o.verificationStatus == 'REJECTED')
        .length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Owner Verification',
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
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF7C3AED),
              tabs: [
                _buildTab('Pending', Colors.orange, pendingCount),
                _buildTab('Verified', Colors.green, verifiedCount),
                _buildTab('Rejected', Colors.red, rejectedCount),
              ],
            ),
          ),
        ),
      ),
      body: adminProvider.isLoading && adminProvider.pendingOwners.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF7C3AED),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingList(context, isDark, adminProvider),
                  _buildVerifiedList(context, isDark, adminProvider),
                  _buildRejectedList(context, isDark, adminProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildTab(String label, Color color, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============== PENDING LIST ==============
  Widget _buildPendingList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    final pending = provider.pendingOwners
        .where((owner) =>
            owner.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            owner.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            owner.businessName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (pending.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No pending owner verifications',
        Icons.pending_actions_rounded,
      );
    }

    return Column(
      children: [
        _buildSearchBar(context, isDark),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: pending.length,
            itemBuilder: (context, index) {
              final owner = pending[index];
              return _buildOwnerCard(
                context,
                owner,
                isDark,
                provider,
                status: 'PENDING',
              );
            },
          ),
        ),
      ],
    );
  }

  // ============== VERIFIED LIST ==============
  Widget _buildVerifiedList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    final verified = provider.allOwners
        .where((owner) =>
            owner.verificationStatus == 'VERIFIED' &&
            (owner.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                owner.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                owner.businessName.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();

    if (verified.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No verified owners',
        Icons.verified_rounded,
      );
    }

    return Column(
      children: [
        _buildSearchBar(context, isDark),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: verified.length,
            itemBuilder: (context, index) {
              final owner = verified[index];
              return _buildOwnerCard(
                context,
                owner,
                isDark,
                provider,
                status: 'VERIFIED',
              );
            },
          ),
        ),
      ],
    );
  }

  // ============== REJECTED LIST ==============
  Widget _buildRejectedList(
    BuildContext context,
    bool isDark,
    AdminProvider provider,
  ) {
    final rejected = provider.allOwners
        .where((owner) =>
            owner.verificationStatus == 'REJECTED' &&
            (owner.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                owner.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                owner.businessName.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();

    if (rejected.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No rejected owners',
        Icons.cancel_rounded,
      );
    }

    return Column(
      children: [
        _buildSearchBar(context, isDark),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: rejected.length,
            itemBuilder: (context, index) {
              final owner = rejected[index];
              return _buildOwnerCard(
                context,
                owner,
                isDark,
                provider,
                status: 'REJECTED',
              );
            },
          ),
        ),
      ],
    );
  }

  // ============== SEARCH BAR ==============
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search owners...',
          hintStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1A1F33) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  // ============== OWNER CARD (For ALL Statuses) ==============
  Widget _buildOwnerCard(
    BuildContext context,
    dynamic owner,
    bool isDark,
    AdminProvider provider, {
    required String status,
  }) {
    final isPending = status == 'PENDING';
    final isVerified = status == 'VERIFIED';
    final isRejected = status == 'REJECTED';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPending) {
      statusColor = Colors.orange;
      statusText = 'PENDING';
      statusIcon = Icons.pending_actions_rounded;
    } else if (isVerified) {
      statusColor = Colors.green;
      statusText = 'VERIFIED ✅';
      statusIcon = Icons.verified_rounded;
    } else {
      statusColor = Colors.red;
      statusText = 'REJECTED ❌';
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPending
            ? Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ========== HEADER ==========
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      owner.name.isNotEmpty ? owner.name[0].toUpperCase() : 'O',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
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
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        owner.displayId,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_rounded,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              owner.email,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (owner.businessName != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.business_center_rounded,
                              size: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                owner.businessName,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ========== DIVIDER ==========
          Divider(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),

          // ========== DOCUMENTS PREVIEW (Only for Pending) ==========
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildDocChip(
                    'Aadhar',
                    Icons.assignment_ind_rounded,
                    owner.aadharDocUrl != null,
                    isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildDocChip(
                    'PAN',
                    Icons.assignment_rounded,
                    owner.panDocUrl != null,
                    isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildDocChip(
                    'Address',
                    Icons.home_work_rounded,
                    owner.addressProofUrl != null,
                    isDark,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      owner.subscriptionPlan,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ========== VERIFIED/REJECTED DETAILS ==========
          if (!isPending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isVerified ? Icons.verified_rounded : Icons.cancel_rounded,
                        size: 16,
                        color: isVerified ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isVerified
                            ? owner.verifiedAt != null
                                ? 'Verified on ${_formatDate(owner.verifiedAt)}'
                                : 'Verified'
                            : 'Rejected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (owner.rejectionReason != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reason: ${owner.rejectionReason}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.red[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ========== ACTION BUTTONS - FOR ALL STATUSES ==========
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ✅ REVIEW BUTTON - FOR ALL STATUSES
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminOwnerReviewPage(
                            ownerId: owner.ownerId,
                            ownerName: owner.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Review'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                // ✅ VERIFY BUTTON - ONLY FOR PENDING
                if (isPending) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await provider.verifyOwner(owner.ownerId);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Owner verified successfully ✅'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                ],
                // ✅ REJECT BUTTON - ONLY FOR PENDING
                if (isPending) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showRejectDialog(context, owner, provider);
                      },
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                ],
                // ✅ VIEW DETAILS - FOR VERIFIED/REJECTED
                if (!isPending) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to Owner Review Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminOwnerReviewPage(
                              ownerId: owner.ownerId,
                              ownerName: owner.name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============== DOC CHIP HELPER ==============
  Widget _buildDocChip(String label, IconData icon, bool isUploaded, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isUploaded
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isUploaded
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isUploaded ? Colors.green : Colors.grey[500],
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: isUploaded ? Colors.green : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            isUploaded ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 10,
            color: isUploaded ? Colors.green : Colors.grey[500],
          ),
        ],
      ),
    );
  }

  // ============== REJECT DIALOG ==============
  void _showRejectDialog(
    BuildContext context,
    dynamic owner,
    AdminProvider provider,
  ) {
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
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject ${owner.name}?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reason for rejection:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
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
                    content: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Owner rejected ❌'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
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

  // ============== EMPTY STATE ==============
  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== HELPERS ==============
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}