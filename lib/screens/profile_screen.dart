// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yourhome/screens/help_support_screen.dart';
import 'package:yourhome/screens/owner/owner_apply_page.dart';
import 'package:yourhome/screens/privacy_policy_screen.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notifications/notification_screen.dart';
import 'bookings/booking_list_screen.dart';
import 'home_screen.dart';

// ============================================================
// DESIGN TOKENS
// ============================================================
class _Palette {
  static const primary = Color(0xFF2563EB);
  static const primaryDeep = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFF60A5FA);
  static const accent = Color(0xFF7C3AED);
  static const gold = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);

  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2E);
  static const darkSurfaceAlt = Color(0xFF1A2138);
  static const lightBg = Color(0xFFF3F5FA);
  static const lightSurface = Colors.white;
}

class ProfileScreen extends StatefulWidget {
  final int? userId;
  final bool isOwner;

  const ProfileScreen({
    super.key,
    this.userId,
    this.isOwner = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late AnimationController _staggerController;
  late List<Animation<double>> _staggerAnimations;
  late AnimationController _glowController;

  UserProfile? _otherUserProfile;
  bool _isLoadingOtherUser = false;
  String? _otherUserError;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfileData();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOutCubic),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _scaleIn = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _staggerAnimations = List.generate(16, (index) {
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

    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _mainController.forward();
    _staggerController.forward();
  }

  void _loadProfileData() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    if (widget.isOwner && widget.userId != null) {
      _loadOtherUserProfile(widget.userId!);
    } else {
      profileProvider.loadAllData();
    }
  }

  Future<void> _loadOtherUserProfile(int userId) async {
    setState(() {
      _isLoadingOtherUser = true;
      _otherUserError = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getAccessToken();

      if (token == null) {
        _otherUserError = 'Please login again';
        setState(() => _isLoadingOtherUser = false);
        return;
      }

      final dio = Dio();
      final response = await dio.get(
        '${_getBaseUrl()}/user/profile/$userId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        _otherUserProfile = UserProfile(
          userId: data['userId'] ?? userId,
          displayId:
              data['displayId'] ?? 'NST-${userId.toString().padLeft(6, '0')}',
          name: data['name'] ?? 'User',
          email: data['email'] ?? 'user@email.com',
          phone: data['phone'],
          profilePic: data['profilePic'],
          role: data['role'] ?? 'USER',
          isEmailVerified: data['isEmailVerified'] ?? false,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
        );
      } else {
        _fallbackUserProfile(userId);
      }
    } catch (e) {
      _fallbackUserProfile(userId);
    }

    setState(() {
      _isLoadingOtherUser = false;
    });
  }

  void _fallbackUserProfile(int userId) {
    _otherUserProfile = UserProfile(
      userId: userId,
      displayId: 'NST-${userId.toString().padLeft(6, '0')}',
      name: userId == 15 ? 'Riza Sheaikh' : 'Lutfur Rahman',
      email: userId == 15 ? 'riza@email.com' : 'lutfur@email.com',
      phone: '9876543210',
      profilePic: userId == 15
          ? 'https://res.cloudinary.com/dhw16mrqc/image/upload/v1781066809/nestora/profile-pics/p3zmqrxp3q1zvr0vlbxy.jpg'
          : 'https://res.cloudinary.com/dhw16mrqc/image/upload/v1778790707/nestora/profile-pics/hvayp0xihizoya1xamyc.jpg',
      role: 'OWNER',
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
  }

  String _getBaseUrl() {
    return 'https://api.nestora.in';
  }

  @override
  void dispose() {
    _mainController.dispose();
    _staggerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.isOwner) return;

    HapticFeedback.lightImpact();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null && mounted) {
      final file = File(pickedFile.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final success = await profileProvider.uploadProfilePicture(formData);

      if (mounted && success) {
        _showSnackBar('Profile picture updated successfully!', isError: false);
      } else if (mounted) {
        _showSnackBar(profileProvider.error ?? 'Failed to upload image',
            isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isOwner) {
      return _buildOwnerProfileView(context, isDark);
    }

    return _buildUserProfileView(
        context, isDark, user, profileProvider, authProvider);
  }

  // ========== BACKGROUND DECORATION ==========
  Widget _buildBackgroundDecor(bool isDark) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            final t = _glowController.value;
            return Stack(
              children: [
                Positioned(
                  top: -120 + (t * 20),
                  right: -80,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _Palette.primary.withOpacity(isDark ? 0.18 : 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -100 + (t * 15),
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _Palette.accent.withOpacity(isDark ? 0.14 : 0.07),
                          Colors.transparent,
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

  // ========== OWNER PROFILE VIEW ==========
  Widget _buildOwnerProfileView(BuildContext context, bool isDark) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? _Palette.darkBg : _Palette.lightBg,
        extendBodyBehindAppBar: false,
        appBar: _buildPremiumAppBar(context, isDark, isOwner: true),
        body: Stack(
          children: [
            _buildBackgroundDecor(isDark),
            _isLoadingOtherUser
                ? _buildLoadingState(isDark)
                : _otherUserError != null
                    ? _buildErrorState(isDark, _otherUserError!)
                    : _otherUserProfile != null
                        ? FadeTransition(
                            opacity: _fadeIn,
                            child: SlideTransition(
                              position: _slideUp,
                              child: ScaleTransition(
                                scale: _scaleIn,
                                child: _buildOtherUserContent(context, isDark),
                              ),
                            ),
                          )
                        : _buildEmptyState(isDark),
          ],
        ),
      ),
    );
  }

  // ========== USER PROFILE VIEW ==========
  Widget _buildUserProfileView(
    BuildContext context,
    bool isDark,
    dynamic user,
    ProfileProvider provider,
    AuthProvider authProvider,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? _Palette.darkBg : _Palette.lightBg,
        appBar: _buildPremiumAppBar(context, isDark),
        body: Stack(
          children: [
            _buildBackgroundDecor(isDark),
            provider.isLoading && provider.profile == null
                ? _buildLoadingState(isDark)
                : provider.hasError
                    ? _buildErrorState(isDark, provider.error!)
                    : RefreshIndicator(
                        onRefresh: () async {
                          await provider.loadAllData();
                        },
                        color: _Palette.primary,
                        backgroundColor:
                            isDark ? _Palette.darkSurface : Colors.white,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp,
                            child: ScaleTransition(
                              scale: _scaleIn,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                child: Column(
                                  children: [
                                    _buildPremiumHeader(
                                        context, user, provider, isDark),
                                    const SizedBox(height: 18),
                                    _buildPremiumStats(
                                        context, provider, isDark),
                                    const SizedBox(height: 22),
                                    _sectionLabel('Account', isDark, 12),
                                    _buildPremiumMenu(context, isDark),
                                    const SizedBox(height: 22),
                                    _buildPremiumLogout(
                                        context, authProvider, isDark),
                                    const SizedBox(height: 18),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shield_moon_rounded,
                                          size: 13,
                                          color: isDark
                                              ? Colors.grey[700]
                                              : Colors.grey[400],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Nestora  •  Version 1.0.0',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[700]
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark, double bottomPad) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: bottomPad, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  // ========== PREMIUM APP BAR ==========
  PreferredSizeWidget _buildPremiumAppBar(
    BuildContext context,
    bool isDark, {
    bool isOwner = false,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: isOwner
          ? Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: isDark ? _Palette.darkSurfaceAlt : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF4B5563),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      title: Text(
        isOwner ? 'Owner Profile' : 'My Profile',
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDark ? _Palette.darkSurfaceAlt : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? _Palette.gold : const Color(0xFF4B5563),
              size: 21,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              themeProvider.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== PREMIUM HEADER ==========
  Widget _buildPremiumHeader(
    BuildContext context,
    dynamic user,
    ProfileProvider provider,
    bool isDark,
  ) {
    final profile = provider.profile;
    final imageUrl = profile?.profilePic ?? '';
    final name = profile?.name ?? user?.name ?? 'User';
    final email = profile?.email ?? user?.email ?? 'user@email.com';
    final role = profile?.role ?? user?.role ?? 'STUDENT';
    final isVerified = profile?.isEmailVerified ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _Palette.primaryDeep,
            _Palette.primary,
            _Palette.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _Palette.primary.withOpacity(0.35),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative ring pattern
          Positioned(
            top: -30,
            right: -30,
            child: Icon(
              Icons.diamond_rounded,
              size: 130,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.25),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          backgroundImage: imageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    color: _Palette.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_Palette.gold, Color(0xFFFBBF24)],
                              ),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.email_rounded,
                              size: 12,
                              color: Colors.white.withOpacity(0.75),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                email,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _glassChip(
                              icon: Icons.workspace_premium_rounded,
                              label: role,
                            ),
                            if (isVerified)
                              _glassChip(
                                icon: Icons.verified_rounded,
                                label: 'Verified',
                                iconColor: const Color(0xFF86EFAC),
                                background:
                                    const Color(0xFF16A34A).withOpacity(0.25),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassChip({
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: iconColor ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ========== PREMIUM STATS ==========
  Widget _buildPremiumStats(
      BuildContext context, ProfileProvider provider, bool isDark) {
    final stats = [
      {
        'label': 'Bookings',
        'value': provider.bookings.length.toString(),
        'icon': Icons.book_online_rounded,
        'color': _Palette.primary,
      },
      {
        'label': 'Alerts',
        'value': provider.unreadCount.toString(),
        'icon': Icons.notifications_rounded,
        'color': _Palette.gold,
      },
      {
        'label': 'Favorites',
        'value': '0',
        'icon': Icons.favorite_rounded,
        'color': _Palette.danger,
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        final animation = _staggerAnimations[index];
        final color = stat['color'] as Color;

        return Expanded(
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: Container(
                margin:
                    EdgeInsets.only(right: index < stats.length - 1 ? 10 : 0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? _Palette.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.18),
                            color.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(stat['icon'] as IconData,
                          color: color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stat['value'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stat['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ========== PREMIUM MENU ==========
  Widget _buildPremiumMenu(BuildContext context, bool isDark) {
    final bookingsCount =
        Provider.of<ProfileProvider>(context).bookings.length.toString();
    final unreadCount =
        Provider.of<ProfileProvider>(context).unreadCount.toString();

    final menuItems = [
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Edit Profile',
        'subtitle': 'Update your personal information',
        'screen': const EditProfileScreen(),
        'color': _Palette.primary,
      },
      {
        'icon': Icons.business_center_rounded,
        'title': 'Become an Owner',
        'subtitle': 'Apply to list your properties',
        'screen': const OwnerApplyPage(),
        'badge': 'NEW',
        'badgeColor': const Color.fromARGB(255, 37, 99, 235),
        'color': const Color.fromARGB(255, 37, 99, 235),
      },
      {
        'icon': Icons.book_online_rounded,
        'title': 'My Bookings',
        'subtitle': 'View all your booking requests',
        'screen': const BookingListScreen(),
        'badge': bookingsCount,
        'color': _Palette.accent,
      },
      {
        'icon': Icons.notifications_rounded,
        'title': 'Notifications',
        'subtitle': 'View all notifications',
        'screen': const NotificationScreen(),
        'badge': unreadCount,
        'badgeColor': _Palette.danger,
        'color': _Palette.gold,
      },
      {
        'icon': Icons.lock_outline_rounded,
        'title': 'Change Password',
        'subtitle': 'Update your password',
        'screen': const ChangePasswordScreen(),
        'color': const Color(0xFF0EA5E9),
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Privacy & Security',
        'subtitle': 'Manage your privacy settings',
        'screen': const PrivacyPolicyScreen(),
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'subtitle': 'Get help and support',
        'screen': const HelpSupportScreen(),
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? _Palette.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: menuItems.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == menuItems.length - 1;
          final animation =
              _staggerAnimations[(index + 3) % _staggerAnimations.length];
          final itemColor = item['color'] as Color;

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(20) : Radius.zero,
                    bottom: isLast ? const Radius.circular(20) : Radius.zero,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final screen = item['screen'] as Widget?;
                    if (screen != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => screen),
                      ).then((_) {
                        final provider = Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        );
                        provider.loadAllData();
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                itemColor.withOpacity(0.16),
                                itemColor.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(item['icon'] as IconData,
                              color: itemColor, size: 20),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item['subtitle'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item['badge'] != null &&
                            (item['badge'] as String) != '0')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  (item['badgeColor'] as Color?) ??
                                      _Palette.primary,
                                  ((item['badgeColor'] as Color?) ??
                                          _Palette.primary)
                                      .withOpacity(0.75),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['badge'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  //PREMIUM LOGOUT 
  Widget _buildPremiumLogout(
    BuildContext context,
    AuthProvider authProvider,
    bool isDark,
  ) {
    return FadeTransition(
      opacity: _staggerAnimations[10],
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: authProvider.isLoading
                ? null
                : () => _showLogoutDialog(context),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark
                    ? _Palette.danger.withOpacity(0.12)
                    : _Palette.danger.withOpacity(0.06),
                border: Border.all(
                  color: _Palette.danger.withOpacity(0.4),
                  width: 1.4,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 19, color: _Palette.danger),
                    const SizedBox(width: 9),
                    Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _Palette.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== OTHER USER CONTENT ==========
  static const List<String> _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  void _copyToClipboard(String value, String label) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: value));
    _showSnackBar('$label copied to clipboard', isError: false);
  }

  Widget _buildOtherUserContent(BuildContext context, bool isDark) {
    final profile = _otherUserProfile!;
    final joinedYear = profile.createdAt.year;
    final joinedLabel =
        '${_monthShort[profile.createdAt.month - 1]} $joinedYear';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        children: [
          // ---------- COVER + AVATAR ----------
          FadeTransition(
            opacity: _staggerAnimations[0],
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  height: 128,
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _Palette.primaryDeep,
                        _Palette.primary,
                        _Palette.accent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _Palette.primary.withOpacity(0.32),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -20,
                        right: -10,
                        child: Icon(Icons.villa_rounded,
                            size: 100, color: Colors.white.withOpacity(0.08)),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -20,
                        child: Icon(Icons.apartment_rounded,
                            size: 90, color: Colors.white.withOpacity(0.06)),
                      ),
                      Positioned(
                        top: 12,
                        left: 16,
                        child: _glassChip(
                          icon: Icons.workspace_premium_rounded,
                          label: profile.role,
                        ),
                      ),
                      if (profile.isEmailVerified)
                        Positioned(
                          top: 12,
                          right: 16,
                          child: _glassChip(
                            icon: Icons.verified_rounded,
                            label: 'Verified',
                            iconColor: const Color(0xFF86EFAC),
                            background:
                                const Color(0xFF16A34A).withOpacity(0.28),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 74,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? _Palette.darkBg : _Palette.lightBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor:
                          isDark ? _Palette.darkSurfaceAlt : Colors.white,
                      backgroundImage: profile.profilePic != null &&
                              profile.profilePic!.isNotEmpty
                          ? CachedNetworkImageProvider(profile.profilePic!)
                          : null,
                      child: profile.profilePic == null ||
                              profile.profilePic!.isEmpty
                          ? Text(
                              profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : 'O',
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                color: _Palette.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 58),

          // ---------- NAME + META ----------
          FadeTransition(
            opacity: _staggerAnimations[1],
            child: Column(
              children: [
                Text(
                  profile.name,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.displayId,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _Palette.primary.withOpacity(isDark ? 0.14 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 14, color: _Palette.primary),
                      const SizedBox(width: 6),
                      Text(
                        'On Nestora since $joinedLabel',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _Palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ---------- QUICK CONTACT ACTIONS ----------
          FadeTransition(
            opacity: _staggerAnimations[2],
            child: Row(
              children: [
                Expanded(
                  child: _contactAction(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: const Color(0xFF16A34A),
                    isDark: isDark,
                    onTap: () => _copyToClipboard(
                        profile.phone ?? 'Not provided', 'Phone number'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _contactAction(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Message',
                    color: _Palette.primary,
                    isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _contactAction(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    color: _Palette.accent,
                    isDark: isDark,
                    onTap: () =>
                        _copyToClipboard(profile.email, 'Email address'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------- TRUST BADGES ----------
          FadeTransition(
            opacity: _staggerAnimations[3],
            child: Row(
              children: [
                Expanded(
                  child: _trustBadge(
                    icon: Icons.verified_user_rounded,
                    label:
                        profile.isEmailVerified ? 'ID Verified' : 'Unverified',
                    color: profile.isEmailVerified
                        ? const Color(0xFF16A34A)
                        : Colors.grey,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _trustBadge(
                    icon: Icons.house_rounded,
                    label: 'Listing Owner',
                    color: _Palette.gold,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _trustBadge(
                    icon: Icons.bolt_rounded,
                    label: 'Quick Replies',
                    color: _Palette.accent,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          _sectionLabel('Contact details', isDark, 10),

          // ---------- DETAIL CARD ----------
          FadeTransition(
            opacity: _staggerAnimations[4],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? _Palette.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.email_rounded,
                    'Email',
                    profile.email,
                    isDark,
                    onTap: () =>
                        _copyToClipboard(profile.email, 'Email address'),
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05)),
                  _buildDetailRow(
                    Icons.phone_rounded,
                    'Phone',
                    profile.phone ?? 'Not provided',
                    isDark,
                    onTap: profile.phone != null
                        ? () => _copyToClipboard(profile.phone!, 'Phone number')
                        : null,
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05)),
                  _buildDetailRow(
                    Icons.badge_rounded,
                    'User ID',
                    profile.displayId,
                    isDark,
                    onTap: () => _copyToClipboard(profile.displayId, 'User ID'),
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05)),
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    'Member Since',
                    '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year}',
                    isDark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ---------- BACK BUTTON ----------
          FadeTransition(
            opacity: _staggerAnimations[5],
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: Text(
                  'Back to Chat',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? _Palette.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 6),
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

  Widget _trustBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDark ? 0.16 : 0.10),
            color.withOpacity(isDark ? 0.06 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark,
      {VoidCallback? onTap}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _Palette.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: _Palette.primary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.copy_rounded,
              size: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: row,
      ),
    );
  }

  // ========== COMMON STATES ==========
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Palette.primaryDeep, _Palette.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _Palette.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your profile...',
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

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _Palette.danger.withOpacity(0.15),
                    _Palette.danger.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: _Palette.danger,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _loadProfileData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (isDark ? Colors.grey[800] : Colors.grey[200]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_rounded,
              size: 44,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'User not found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ========== LOGOUT DIALOG ==========
  Future<void> _showLogoutDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? _Palette.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _Palette.danger.withOpacity(0.18),
                        _Palette.danger.withOpacity(0.06),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: _Palette.danger, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to logout of your account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: _Palette.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
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
      ),
    );

    if (confirm == true && mounted) {
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
}
