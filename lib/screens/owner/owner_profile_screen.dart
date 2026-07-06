import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:yourhome/models/user_model.dart';
import 'package:yourhome/screens/login_screen.dart';
import 'package:yourhome/utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/profile_provider.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploading = false;

  // Controllers for edit mode
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    
    await Future.wait([
      profileProvider.getProfile(),
      ownerProvider.getOwnerProfile(),
      ownerProvider.getVerificationStatus(),
      ownerProvider.getDashboardStats(),
    ]);
  }

  // ============== UPDATE PROFILE PICTURE ==============
  Future<void> _updateProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final File file = File(image.path);
      
      final formData = FormData.fromMap({
        'profilePic': await MultipartFile.fromFile(file.path),
      });

      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProvider.uploadProfilePicture(formData);

      setState(() => _isUploading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error ?? 'Failed to update picture'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============== SAVE PROFILE ==============
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      
      // Using UpdateProfileRequest class (only name & phone)
      final request = UpdateProfileRequest(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      final success = await profileProvider.updateProfile(request);

      setState(() {
        _isLoading = false;
        if (success) {
          _isEditing = false;
        }
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============== LOGOUT ==============
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final ownerProvider = Provider.of<OwnerProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final profile = profileProvider.profile;
    final ownerProfile = ownerProvider.ownerProfile;
    final verification = ownerProvider.verificationStatus;
    final stats = ownerProvider.dashboardStats;
    final user = authProvider.user;
    final profilePic = profile?.profilePic;

    // Set controllers when editing
    if (_isEditing && profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone ?? '';
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: _buildAppBar(isDark),
      body: Stack(
        children: [
          profileProvider.isLoading && profile == null
              ? _buildLoadingState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF7C3AED),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          _buildProfileHeader(
                            context,
                            isDark,
                            profile,
                            ownerProfile,
                            verification,
                            profilePic,
                            user,
                          ),
                          const SizedBox(height: 16),
                          if (verification != null)
                            _buildVerificationCard(isDark, verification),
                          const SizedBox(height: 16),
                          if (stats != null) _buildStatsCard(isDark, stats),
                          const SizedBox(height: 16),
                          _buildProfileDetails(isDark, profile, ownerProfile),
                          const SizedBox(height: 24),
                          _buildActionButtons(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= APP BAR =================
  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      title: Text(
        'My Profile',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isEditing ? Icons.close_rounded : Icons.edit_rounded,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          onPressed: () {
            if (_isEditing) {
              setState(() {
                _isEditing = false;
                _nameController.clear();
                _phoneController.clear();
              });
            } else {
              setState(() => _isEditing = true);
            }
          },
        ),
        IconButton(
          icon: Icon(
            Icons.logout_rounded,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          onPressed: _logout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= LOADING STATE =================
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF7C3AED)),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ================= PROFILE HEADER =================
  Widget _buildProfileHeader(
    BuildContext context,
    bool isDark,
    dynamic profile,
    dynamic ownerProfile,
    dynamic verification,
    String? profilePic,
    dynamic user,
  ) {
    final hasImage = profilePic != null && profilePic.isNotEmpty;
    final name = profile?.name ?? user?.name ?? 'Owner';
    final email = user?.email ?? '';
    final businessName = ownerProfile?.businessName;
    final displayId = profile?.displayId ?? user?.displayId ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              GestureDetector(
                onTap: _updateProfilePicture,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasImage
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: profilePic,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          if (businessName != null && businessName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              businessName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
          ],
          if (displayId.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'ID: $displayId',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            email,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          // Verification Status
          if (verification != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (verification.isVerified ? Colors.green : Colors.orange)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    verification.isVerified
                        ? Icons.verified_rounded
                        : Icons.hourglass_top_rounded,
                    size: 14,
                    color: verification.isVerified ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    verification.isVerified
                        ? 'Verified Owner'
                        : verification.isRejected
                            ? 'Rejected'
                            : 'Pending Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: verification.isVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          // Email Verification
          if (profile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (profile.isEmailVerified ? Colors.green : Colors.red)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    profile.isEmailVerified
                        ? Icons.email_rounded
                        : Icons.email_outlined,
                    size: 14,
                    color: profile.isEmailVerified ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    profile.isEmailVerified
                        ? 'Email Verified'
                        : 'Email Not Verified',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: profile.isEmailVerified ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ================= VERIFICATION CARD =================
  Widget _buildVerificationCard(bool isDark, dynamic verification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner Verification',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Status',
            verification.isVerified
                ? 'Verified ✅'
                : verification.isRejected
                    ? 'Rejected ❌'
                    : 'Pending ⏳',
            isDark,
            color: verification.isVerified
                ? Colors.green
                : verification.isRejected
                    ? Colors.red
                    : Colors.orange,
          ),
          if (verification.submittedAt != null)
            _buildDetailRow(
              'Submitted',
              _formatDate(verification.submittedAt),
              isDark,
            ),
          if (verification.verifiedAt != null)
            _buildDetailRow(
              'Verified On',
              _formatDate(verification.verifiedAt),
              isDark,
            ),
          if (verification.rejectionReason != null && verification.isRejected)
            _buildDetailRow(
              'Rejection Reason',
              verification.rejectionReason,
              isDark,
              isLong: true,
              color: Colors.red,
            ),
          if (verification.businessName != null)
            _buildDetailRow(
              'Business Name',
              verification.businessName,
              isDark,
            ),
          if (verification.aadharNumber != null)
            _buildDetailRow(
              'Aadhar',
              '****${verification.aadharNumber.substring(verification.aadharNumber.length - 4)}',
              isDark,
            ),
          if (verification.panNumber != null)
            _buildDetailRow(
              'PAN',
              '****${verification.panNumber.substring(verification.panNumber.length - 4)}',
              isDark,
            ),
        ],
      ),
    );
  }

  // ================= STATS CARD =================
  Widget _buildStatsCard(bool isDark, dynamic stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stats',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                'Properties',
                stats.totalProperties.toString(),
                Icons.apartment_rounded,
                const Color(0xFF7C3AED),
                isDark,
              ),
              _buildStatItem(
                'Rooms',
                stats.totalRooms.toString(),
                Icons.bed_rounded,
                const Color(0xFF3B82F6),
                isDark,
              ),
              _buildStatItem(
                'Bookings',
                stats.pendingRequests.toString(),
                Icons.book_online_rounded,
                Colors.orange,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatItem(
                'Published',
                stats.publishedProperties.toString(),
                Icons.check_circle_rounded,
                Colors.green,
                isDark,
              ),
              _buildStatItem(
                'Available',
                stats.availableRooms.toString(),
                Icons.meeting_room_rounded,
                const Color(0xFF06B6D4),
                isDark,
              ),
              _buildStatItem(
                'Rating',
                stats.averageRating.toStringAsFixed(1),
                Icons.star_rounded,
                Colors.amber,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ================= PROFILE DETAILS =================
  Widget _buildProfileDetails(bool isDark, dynamic profile, dynamic ownerProfile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Profile Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (_isEditing)
                GestureDetector(
                  onTap: _isLoading ? null : _saveProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing) ...[
            _buildEditableField(
              'Full Name',
              _nameController,
              Icons.person_rounded,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              'Phone',
              _phoneController,
              Icons.phone_rounded,
              isDark,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
          ] else ...[
            _buildDetailRow(
              'Full Name',
              profile?.name ?? 'N/A',
              isDark,
            ),
            _buildDetailRow(
              'Email',
              profile?.email ?? 'N/A',
              isDark,
            ),
            _buildDetailRow(
              'Phone',
              profile?.phone ?? 'Not provided',
              isDark,
            ),
            _buildDetailRow(
              'User ID',
              profile?.displayId ?? 'N/A',
              isDark,
            ),
            _buildDetailRow(
              'Role',
              profile?.role ?? 'N/A',
              isDark,
              color: const Color(0xFF7C3AED),
            ),
            if (ownerProfile?.businessName != null)
              _buildDetailRow(
                'Business',
                ownerProfile!.businessName!,
                isDark,
              ),
            if (profile?.createdAt != null)
              _buildDetailRow(
                'Member Since',
                _formatDate(profile!.createdAt.toString()),
                isDark,
              ),
          ],
        ],
      ),
    );
  }

  // ================= EDITABLE FIELD =================
  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade300,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  // ================= DETAIL ROW =================
  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isLong = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color ?? (isDark ? Colors.white : const Color(0xFF1A1A2E)),
              ),
              maxLines: isLong ? 3 : 1,
              overflow: isLong ? TextOverflow.ellipsis : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _buildActionButtons(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_isEditing) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141A2C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  'Privacy Policy',
                  Icons.privacy_tip_rounded,
                  isDark,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  'Terms & Conditions',
                  Icons.description_rounded,
                  isDark,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  'Help & Support',
                  Icons.help_center_rounded,
                  isDark,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  'App Version',
                  Icons.info_outline_rounded,
                  isDark,
                  trailing: Text(
                    AppConstants.appVersion,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon,
    bool isDark, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600]),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                )
              : null),
      onTap: onTap,
    );
  }

  // ================= HELPERS =================
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}