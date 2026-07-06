// lib/screens/admin/admin_owner_review_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/admin_provider.dart';

class AdminOwnerReviewPage extends StatefulWidget {
  final int ownerId;
  final String ownerName;

  const AdminOwnerReviewPage({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<AdminOwnerReviewPage> createState() => _AdminOwnerReviewPageState();
}

class _AdminOwnerReviewPageState extends State<AdminOwnerReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFirstLoad = true;

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

  void _loadData() {
    final adminProvider = Provider.of<AdminProvider>(
      context,
      listen: false,
    );
    adminProvider.getOwnerDetail(widget.ownerId);
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
    final owner = adminProvider.selectedOwnerDetail;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Review Owner',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (owner != null && owner.isPending) ...[
            _buildActionButtons(context, owner, adminProvider),
          ],
        ],
      ),
      body: adminProvider.isLoading || owner == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Profile Header
                      _buildProfileHeader(context, owner, isDark),
                      const SizedBox(height: 16),
                      // Stats Row
                      _buildStatsRow(context, owner, isDark),
                      const SizedBox(height: 16),
                      // Tab Bar
                      _buildTabBar(isDark),
                      // Tab Content
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(context, owner, isDark),
                            _buildDocumentsTab(context, owner, isDark),
                            _buildPropertiesTab(context, owner, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ============== ACTION BUTTONS ==============
  Widget _buildActionButtons(
    BuildContext context,
    owner,
    AdminProvider provider,
  ) {
    return Row(
      children: [
        if (owner.isPending) ...[
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.green),
            onPressed: () => _showVerifyDialog(context, owner, provider),
            tooltip: 'Verify',
            style: IconButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.1),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.red),
            onPressed: () => _showRejectDialog(context, owner, provider),
            tooltip: 'Reject',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ============== PROFILE HEADER ==============
  Widget _buildProfileHeader(
    BuildContext context,
    owner,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED),
            const Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Text(
                    owner.name.isNotEmpty ? owner.name[0].toUpperCase() : 'O',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      owner.displayId,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(owner.verificationStatus)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(owner.verificationStatus),
                                size: 14,
                                color: _getStatusColor(owner.verificationStatus),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusText(owner.verificationStatus),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: _getStatusColor(owner.verificationStatus),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Contact Info
          Row(
            children: [
              Expanded(
                child: _buildContactChip(
                  Icons.email_rounded,
                  owner.email,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContactChip(
                  Icons.phone_rounded,
                  owner.phone,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============== STATS ROW ==============
  Widget _buildStatsRow(
    BuildContext context,
    owner,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  owner.totalProperties.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Properties',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  owner.totalRooms.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Rooms',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '₹${owner.totalRevenue.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Revenue',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============== TAB BAR ==============
  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF7C3AED),
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: '📋 Overview'),
          Tab(text: '📄 Documents'),
          Tab(text: '🏢 Properties'),
        ],
      ),
    );
  }

  // ============== OVERVIEW TAB ==============
  Widget _buildOverviewTab(
    BuildContext context,
    owner,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Info
            _buildDetailSection(
              'Business Information',
              Icons.business_center_rounded,
              [
                {'label': 'Business Name', 'value': owner.businessName},
                {'label': 'Aadhar Number', 'value': owner.aadharNumber},
                {'label': 'PAN Number', 'value': owner.panNumber},
                {'label': 'Subscription Plan', 'value': owner.subscriptionPlan},
              ],
              isDark,
            ),
            const SizedBox(height: 16),

            // Personal Info
            _buildDetailSection(
              'Personal Information',
              Icons.person_rounded,
              [
                {'label': 'Full Name', 'value': owner.name},
                {'label': 'Email', 'value': owner.email},
                {'label': 'Phone', 'value': owner.phone},
                {'label': 'User ID', 'value': owner.displayId},
              ],
              isDark,
            ),
            const SizedBox(height: 16),

            // Verification Info
            _buildDetailSection(
              'Verification Information',
              Icons.verified_rounded,
              [
                {
                  'label': 'Status',
                  'value': _getStatusText(owner.verificationStatus),
                  'color': _getStatusColor(owner.verificationStatus),
                },
                if (owner.verifiedAt != null)
                  {
                    'label': 'Verified At',
                    'value': _formatDate(owner.verifiedAt!),
                  },
                if (owner.rejectionReason != null)
                  {
                    'label': 'Rejection Reason',
                    'value': owner.rejectionReason!,
                    'color': Colors.red,
                  },
                {'label': 'Joined', 'value': _formatDate(owner.createdAt)},
              ],
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Map<String, dynamic>> items,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    item['label'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item['value'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: item['color'] ?? 
                        (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // ============== DOCUMENTS TAB ==============
  Widget _buildDocumentsTab(
    BuildContext context,
    owner,
    bool isDark,
  ) {
    final documents = [
      {
        'title': 'Aadhar Card',
        'icon': Icons.assignment_ind_rounded,
        'url': owner.aadharDocUrl,
        'isUploaded': owner.aadharDocUrl != null,
      },
      {
        'title': 'PAN Card',
        'icon': Icons.assignment_rounded,
        'url': owner.panDocUrl,
        'isUploaded': owner.panDocUrl != null,
      },
      {
        'title': 'Address Proof',
        'icon': Icons.home_work_rounded,
        'url': owner.addressProofUrl,
        'isUploaded': owner.addressProofUrl != null,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          ...documents.map((doc) => _buildDocumentCard(
            context,
            doc['title'] as String,
            doc['icon'] as IconData,
            doc['url'] as String?,
            doc['isUploaded'] as bool,
            isDark,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    String title,
    IconData icon,
    String? url,
    bool isUploaded,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUploaded
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isUploaded ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  isUploaded ? 'Uploaded ✅' : 'Not Uploaded ❌',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isUploaded ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          if (isUploaded && url != null)
            OutlinedButton.icon(
              onPressed: () => _viewDocument(url),
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('View'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C3AED)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _viewDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot open document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============== PROPERTIES TAB ==============
  Widget _buildPropertiesTab(
    BuildContext context,
    owner,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_rounded,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '${owner.totalProperties} Properties',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total Rooms: ${owner.totalRooms}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revenue: ₹${owner.totalRevenue.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to owner's properties
              },
              icon: const Icon(Icons.apartment_rounded),
              label: const Text('View All Properties'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C3AED)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== VERIFY DIALOG ==============
  void _showVerifyDialog(
    BuildContext context,
    owner,
    AdminProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.verified_rounded, color: Colors.green[400]),
            const SizedBox(width: 10),
            Text(
              'Verify Owner',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to verify ${owner.name}?',
              style: GoogleFonts.poppins(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Owner will receive a verification notification.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
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
              Navigator.pop(context);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  // ============== REJECT DIALOG ==============
  void _showRejectDialog(
    BuildContext context,
    owner,
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
            child: const Text('Cancel'),
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

  // ============== HELPERS ==============
  Color _getStatusColor(String status) {
    switch (status) {
      case 'VERIFIED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'VERIFIED':
        return Icons.verified_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'VERIFIED':
        return 'VERIFIED ✅';
      case 'REJECTED':
        return 'REJECTED ❌';
      default:
        return 'PENDING ⏳';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}