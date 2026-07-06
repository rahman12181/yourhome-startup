// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleIn = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    final request = ChangePasswordRequest(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    final success = await profileProvider.changePassword(request);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Password changed successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error ?? 'Failed to change password'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Same gradient as login screen
    final gradientColors = isDark
        ? [
            const Color(0xFF0A0E1A),
            const Color(0xFF121828),
            const Color(0xFF1A2340),
          ]
        : [
            const Color(0xFFF8F9FC),
            const Color(0xFFF0F2F8),
            const Color(0xFFE8EBF3),
          ];

    final cardColor = isDark 
        ? const Color(0xFF1A1F33).withOpacity(0.92)
        : Colors.white.withOpacity(0.98);
    
    final fieldFillColor = isDark 
        ? const Color(0xFF262D44) 
        : const Color(0xFFF5F7FA);
    
    final hintColor = isDark 
        ? Colors.grey[400] 
        : const Color(0xFF9CA3AF);
    
    final textColor = isDark 
        ? Colors.white 
        : const Color(0xFF1F2937);
    
    final subtitleColor = isDark 
        ? Colors.white.withOpacity(0.7) 
        : const Color(0xFF6B7280);

    final primaryBlue = const Color(0xFF2563EB);
    final blueLight = const Color(0xFF3B82F6);
    final blueDark = const Color(0xFF1D4ED8);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    final cardWidth = isDesktop ? screenWidth * 0.4 : (isTablet ? screenWidth * 0.75 : screenWidth - 56);
    final buttonHeight = isDesktop ? 50.0 : (isTablet ? 48.0 : 46.0);
    final titleSize = isDesktop ? 34.0 : (isTablet ? 30.0 : 28.0);
    final fieldHeight = isDesktop ? 60.0 : (isTablet ? 56.0 : 52.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark 
            ? const Color(0xFF0A0E1A) 
            : const Color(0xFFF8F9FC),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: true,
      ),
      child: Scaffold(
        backgroundColor: gradientColors.first,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: ScaleTransition(
                    scale: _scaleIn,
                    child: Container(
                      width: cardWidth,
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 550 : (isTablet ? 650 : double.infinity),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Back Button + Theme Toggle
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.06),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.arrow_back_rounded,
                                    color: isDark ? Colors.white : const Color(0xFF4B5563),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.06),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    final themeProvider = Provider.of<ThemeProvider>(
                                      context,
                                      listen: false,
                                    );
                                    themeProvider.setThemeMode(
                                      isDark ? ThemeMode.light : ThemeMode.dark,
                                    );
                                  },
                                  icon: Icon(
                                    isDark
                                        ? Icons.wb_sunny_outlined
                                        : Icons.nightlight_round_outlined,
                                    color: isDark
                                        ? primaryBlue
                                        : const Color(0xFF4B5563),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Icon + Title
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: primaryBlue,
                              size: isDesktop ? 50 : 40,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Change Password',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your current password and set a new one',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: subtitleColor,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Form - Direct on screen (No Card)
                          SlideTransition(
                            position: _slideUp,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Current Password
                                  TextFormField(
                                    controller: _currentPasswordController,
                                    obscureText: !_showCurrentPassword,
                                    style: GoogleFonts.poppins(
                                      fontSize: isDesktop ? 16 : 15,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Current Password',
                                      labelStyle: GoogleFonts.poppins(
                                        color: hintColor,
                                        fontSize: isDesktop ? 14 : 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: primaryBlue,
                                        size: isDesktop ? 24 : 22,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _showCurrentPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: hintColor,
                                          size: isDesktop ? 22 : 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showCurrentPassword = !_showCurrentPassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: fieldFillColor,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0,
                                        horizontal: 16.0,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide(
                                          color: primaryBlue,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFEF4444),
                                          width: 2,
                                        ),
                                      ),
                                      hintText: 'Enter current password',
                                      hintStyle: GoogleFonts.poppins(
                                        color: hintColor?.withOpacity(0.5),
                                        fontSize: isDesktop ? 15 : 14,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your current password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // New Password
                                  TextFormField(
                                    controller: _newPasswordController,
                                    obscureText: !_showNewPassword,
                                    style: GoogleFonts.poppins(
                                      fontSize: isDesktop ? 16 : 15,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'New Password',
                                      labelStyle: GoogleFonts.poppins(
                                        color: hintColor,
                                        fontSize: isDesktop ? 14 : 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: primaryBlue,
                                        size: isDesktop ? 24 : 22,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _showNewPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: hintColor,
                                          size: isDesktop ? 22 : 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showNewPassword = !_showNewPassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: fieldFillColor,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0,
                                        horizontal: 16.0,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide(
                                          color: primaryBlue,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFEF4444),
                                          width: 2,
                                        ),
                                      ),
                                      hintText: 'Enter new password',
                                      hintStyle: GoogleFonts.poppins(
                                        color: hintColor?.withOpacity(0.5),
                                        fontSize: isDesktop ? 15 : 14,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a new password';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm Password
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: !_showConfirmPassword,
                                    style: GoogleFonts.poppins(
                                      fontSize: isDesktop ? 16 : 15,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm New Password',
                                      labelStyle: GoogleFonts.poppins(
                                        color: hintColor,
                                        fontSize: isDesktop ? 14 : 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: primaryBlue,
                                        size: isDesktop ? 24 : 22,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _showConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: hintColor,
                                          size: isDesktop ? 22 : 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showConfirmPassword = !_showConfirmPassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: fieldFillColor,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0,
                                        horizontal: 16.0,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: BorderSide(
                                          color: primaryBlue,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFEF4444),
                                          width: 2,
                                        ),
                                      ),
                                      hintText: 'Confirm new password',
                                      hintStyle: GoogleFonts.poppins(
                                        color: hintColor?.withOpacity(0.5),
                                        fontSize: isDesktop ? 15 : 14,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _newPasswordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),

                                  // Change Password Button
                                  SizedBox(
                                    height: buttonHeight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                                  const Color(0xFF3B82F6),
                                                  const Color(0xFF2563EB),
                                                  const Color(0xFF1D4ED8),
                                                ]
                                              : [
                                                  const Color(0xFF60A5FA),
                                                  const Color(0xFF3B82F6),
                                                  const Color(0xFF2563EB),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryBlue.withOpacity(isDark ? 0.4 : 0.3),
                                            blurRadius: isDesktop ? 20 : 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
                                          onTap: _isLoading ? null : _changePassword,
                                          child: Center(
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(
                                                        Icons.check_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        'Update Password',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: isDesktop ? 16 : 15,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.white,
                                                          letterSpacing: 0.8,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Back to Profile
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Remember your password?',
                                        style: GoogleFonts.poppins(
                                          fontSize: isDesktop ? 15 : 14,
                                          color: hintColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          foregroundColor: primaryBlue,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Go Back',
                                          style: GoogleFonts.poppins(
                                            fontSize: isDesktop ? 16 : 15,
                                            color: primaryBlue,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
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
        ),
      ),
    );
  }
}