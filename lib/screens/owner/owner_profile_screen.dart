// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:yourhome/models/user_model.dart';
import 'package:yourhome/screens/help_support_screen.dart';
import 'package:yourhome/screens/login_screen.dart';
import 'package:yourhome/screens/privacy_policy_screen.dart';
import 'package:yourhome/screens/terms_conditions_screen.dart';
import 'package:yourhome/utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/profile_provider.dart';
import '../change_password_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;

  late AnimationController _staggerController;
  late List<Animation<double>> _staggerAnimations;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOutCubic),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _scaleIn = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _staggerAnimations = List.generate(15, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            index * 0.04,
            0.5 + (index * 0.025),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _mainController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _staggerController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);

    await Future.wait([
      profileProvider.getProfile(),
      ownerProvider.getOwnerProfile(),
      ownerProvider.getVerificationStatus(),
      ownerProvider.getDashboardStats(),
      ownerProvider.getPropertyAccessStatus(),
      ownerProvider.getListingSubscriptionDetails(),
    ]);
  }

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
        'file': await MultipartFile.fromFile(file.path),
      });

      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProvider.uploadProfilePicture(formData);

      setState(() => _isUploading = false);

      if (success && mounted) {
        _showSnackBar('Profile picture updated successfully!', Colors.green);
        _loadData();
      } else {
        _showSnackBar(
            profileProvider.error ?? 'Failed to update picture', Colors.red);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      final request = UpdateProfileRequest(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      final success = await profileProvider.updateProfile(request);

      if (_businessNameController.text.isNotEmpty) {
        await _updateBusinessName(_businessNameController.text.trim());
      }

      setState(() {
        _isLoading = false;
        if (success) {
          _isEditing = false;
        }
      });

      if (success && mounted) {
        _showSnackBar('Profile updated successfully!', Colors.green);
        _loadData();
      } else {
        _showSnackBar(
            profileProvider.error ?? 'Failed to update profile', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _updateBusinessName(String businessName) async {
    try {
      final response = await Dio().patch(
        '${AppConstants.baseUrl}/owner/business-name',
        data: {'businessName': businessName},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _getToken()}',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      // Business name update failed but profile updated
    }
  }

  Future<String> _getToken() async {
    return '';
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: const Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      ),
    );
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
    final accessStatus = ownerProvider.propertyAccessStatus;
    final listingSub = ownerProvider.listingSubscription;
    final user = authProvider.user;
    final profilePic = profile?.profilePic;

    if (_isEditing) {
      if (profile != null) {
        _nameController.text = profile.name;
        _phoneController.text = profile.phone ?? '';
      }
      if (ownerProfile != null) {
        _businessNameController.text = ownerProfile.businessName ?? '';
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        body: profileProvider.isLoading && profile == null
            ? _buildLoadingState(isDark)
            : Stack(
                children: [
                  SafeArea(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: ScaleTransition(
                          scale: _scaleIn,
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFF2563EB),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                children: [
                                  _buildPremiumAppBar(context, isDark),
                                  const SizedBox(height: 8),
                                  _buildPremiumProfileHeader(
                                    context,
                                    isDark,
                                    profile,
                                    ownerProfile,
                                    verification,
                                    profilePic,
                                    user,
                                    accessStatus,
                                    listingSub,
                                  ),
                                  const SizedBox(height: 16),
                                  if (verification != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: _buildPremiumVerificationCard(
                                          isDark, verification),
                                    ),
                                  const SizedBox(height: 16),
                                  if (stats != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child:
                                          _buildPremiumStatsCard(isDark, stats),
                                    ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: _buildPremiumSubscriptionCard(
                                        isDark, accessStatus, listingSub),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: _buildPremiumProfileDetails(
                                        isDark, profile, ownerProfile),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: _buildPremiumActionButtons(
                                        context, isDark),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Version 1.0.0',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isUploading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Uploading...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  // ========== PREMIUM APP BAR ==========
  Widget _buildPremiumAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F33) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : const Color(0xFF4B5563),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'My Profile',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isEditing ? 'Editing profile...' : 'Owner Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Edit/Save Button
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F33) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                color: isDark ? Colors.white : const Color(0xFF4B5563),
                size: 20,
              ),
              onPressed: () {
                if (_isEditing) {
                  setState(() {
                    _isEditing = false;
                    _nameController.clear();
                    _phoneController.clear();
                    _businessNameController.clear();
                  });
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
          ),
          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F33) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: isDark ? Colors.white : const Color(0xFF4B5563),
                size: 20,
              ),
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }

  // ========== LOADING STATE ==========
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading profile...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ========== PREMIUM PROFILE HEADER ==========
  Widget _buildPremiumProfileHeader(
    BuildContext context,
    bool isDark,
    dynamic profile,
    dynamic ownerProfile,
    dynamic verification,
    String? profilePic,
    dynamic user,
    dynamic accessStatus,
    dynamic listingSub,
  ) {
    final hasImage = profilePic != null && profilePic.isNotEmpty;
    final name = profile?.name ?? user?.name ?? 'Owner';
    final email = user?.email ?? '';
    final businessName = ownerProfile?.businessName;
    final displayId = profile?.displayId ?? user?.displayId ?? '';
    final isVerified = verification?.isVerified ?? false;
    final plan = listingSub?.plan ?? 'No Plan';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2563EB),
            const Color(0xFF3B82F6),
            const Color(0xFF60A5FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
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
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
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
                              color: Colors.grey[300],
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Colors.grey[600],
                            ),
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF2563EB),
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
              color: Colors.white,
            ),
          ),
          if (businessName != null && businessName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              businessName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
          if (displayId.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'ID: $displayId',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            email,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 8),
          // Status Badges Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              // Verification Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded,
                      size: 14,
                      color: isVerified ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isVerified ? 'Verified' : 'Pending',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Email Verification Badge
              if (profile != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        profile.isEmailVerified
                            ? Icons.email_rounded
                            : Icons.email_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.isEmailVerified
                            ? 'Email Verified'
                            : 'Email Not Verified',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              // Plan Badge
              if (plan != 'No Plan')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        plan,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== PREMIUM VERIFICATION CARD ==========
  Widget _buildPremiumVerificationCard(bool isDark, dynamic verification) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF2563EB),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Verification Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (verification.isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
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
          if (verification.businessName != null)
            _buildDetailRow(
              'Business',
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

  // ========== PREMIUM STATS CARD ==========
  Widget _buildPremiumStatsCard(bool isDark, dynamic stats) {
    final statsData = [
      {
        'label': 'Properties',
        'value': stats.totalProperties.toString(),
        'icon': Icons.apartment_rounded,
        'color': const Color(0xFF2563EB)
      },
      {
        'label': 'Rooms',
        'value': stats.totalRooms.toString(),
        'icon': Icons.bed_rounded,
        'color': const Color(0xFF8B5CF6)
      },
      {
        'label': 'Bookings',
        'value': stats.pendingRequests.toString(),
        'icon': Icons.book_online_rounded,
        'color': const Color(0xFFF59E0B)
      },
      {
        'label': 'Published',
        'value': stats.publishedProperties.toString(),
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF22C55E)
      },
      {
        'label': 'Available',
        'value': stats.availableRooms.toString(),
        'icon': Icons.meeting_room_rounded,
        'color': const Color(0xFF06B6D4)
      },
      {
        'label': 'Rating',
        'value': stats.averageRating.toStringAsFixed(1),
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFFD700)
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF2563EB),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Business Stats',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: statsData.length,
            itemBuilder: (context, index) {
              final stat = statsData[index];
              return _buildPremiumStatItem(
                isDark,
                stat['label'] as String,
                stat['value'] as String,
                stat['icon'] as IconData,
                stat['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatItem(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
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
              fontSize: 8,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ========== PREMIUM SUBSCRIPTION CARD ==========
  Widget _buildPremiumSubscriptionCard(
      bool isDark, dynamic accessStatus, dynamic listingSub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF2563EB),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Subscriptions',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Property Access
          _buildSubscriptionRow(
            isDark,
            icon: Icons.vpn_key_rounded,
            title: 'Property Access',
            status: accessStatus != null && accessStatus.hasActiveSubscription,
            daysLeft: accessStatus != null && accessStatus.hasActiveSubscription
                ? '${accessStatus.daysRemaining} days left'
                : 'No active plan',
            plan: accessStatus != null && accessStatus.hasActiveSubscription
                ? accessStatus.plan
                : null,
          ),
          const SizedBox(height: 10),
          // Listing Subscription
          _buildSubscriptionRow(
            isDark,
            icon: Icons.workspace_premium_rounded,
            title: 'Listing Subscription',
            status: listingSub != null && listingSub.isActive,
            daysLeft: listingSub != null && listingSub.isActive
                ? '${listingSub.daysRemaining} days left'
                : 'No active plan',
            plan: listingSub != null && listingSub.isActive
                ? listingSub.planDisplayName
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionRow(
    bool isDark, {
    required IconData icon,
    required String title,
    required bool status,
    required String daysLeft,
    String? plan,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: status
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(icon, color: status ? Colors.green : Colors.red, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  plan != null ? '$plan • $daysLeft' : daysLeft,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: status
                  ? Colors.green.withOpacity(0.12)
                  : Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status ? 'Active' : 'Inactive',
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: status ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== PREMIUM PROFILE DETAILS ==========
  Widget _buildPremiumProfileDetails(
      bool isDark, dynamic profile, dynamic ownerProfile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Color(0xFF2563EB),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
            _buildEditableField(
              'Business Name',
              _businessNameController,
              Icons.business_rounded,
              isDark,
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
              color: const Color(0xFF2563EB),
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

  // ========== EDITABLE FIELD ==========
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              width: 1,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  // ========== DETAIL ROW ==========
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
                color:
                    color ?? (isDark ? Colors.white : const Color(0xFF1A1A2E)),
              ),
              maxLines: isLong ? 3 : 1,
              overflow: isLong ? TextOverflow.ellipsis : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ========== PREMIUM ACTION BUTTONS ==========
  Widget _buildPremiumActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        if (_isEditing) ...[
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _isLoading ? null : _saveProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
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
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Change Password
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF2563EB).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        color: const Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Change Password',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Settings
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F33) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                'Privacy Policy',
                Icons.privacy_tip_rounded,
                isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              _buildSettingsTile(
                'Terms & Conditions',
                Icons.description_rounded,
                isDark,
               onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                ),
              ),
              _buildSettingsTile(
                'Help & Support',
                Icons.help_center_rounded,
                isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                ),
              ),
              _buildSettingsTile(
                'App Version',
                Icons.info_outline_rounded,
                isDark,
                trailing: Text(
                  '1.0.0',
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
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                )
              : null),
      onTap: onTap,
    );
  }

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
