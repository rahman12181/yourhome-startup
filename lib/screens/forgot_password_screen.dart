// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/validators.dart';
import '../widgets/loading_widget.dart';
import 'verify_otp_screen.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleIn = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUIOverlay();
  }

  void _updateSystemUIOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark 
        ? const Color(0xFF0A0E1A)
        : const Color(0xFFF8F9FC);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: navBarColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: navBarColor,
        systemNavigationBarContrastEnforced: true,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.forgotPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            email: _emailController.text.trim(),
            type: 'FORGOT_PASSWORD',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to send OTP'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

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

    // Responsive values
    final cardWidth = _getResponsiveWidth(context);
    final buttonHeight = isDesktop ? 50.0 : (isTablet ? 48.0 : 46.0);
    final titleSize = _getResponsiveFontSize(context, 32);
    final subtitleSize = _getResponsiveFontSize(context, 16);

    return Scaffold(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Button + Theme Toggle - Top Position
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
                            // Theme toggle
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

                        // Title - Direct on screen (No Card)
                        Text(
                          'Forgot Password',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your registered email to receive OTP',
                          style: GoogleFonts.poppins(
                            fontSize: subtitleSize,
                            color: subtitleColor,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Form - Direct on screen (No Card) - FIXED
                        SlideTransition(
                          position: _slideUp,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ✅ Email - FIXED (No SizedBox)
                                TextFormField(
                                  controller: _emailController,
                                  style: GoogleFonts.poppins(
                                    fontSize: isDesktop ? 16 : 15,
                                    color: textColor,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    labelStyle: GoogleFonts.poppins(
                                      color: hintColor,
                                      fontSize: isDesktop ? 14 : 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: primaryBlue,
                                      size: isDesktop ? 24 : 22,
                                    ),
                                    filled: true,
                                    fillColor: fieldFillColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16.0,  // ✅ Fixed padding
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
                                    hintText: 'your@email.com',
                                    hintStyle: GoogleFonts.poppins(
                                      color: hintColor?.withOpacity(0.5),
                                      fontSize: isDesktop ? 15 : 14,
                                    ),
                                  ),
                                  validator: Validators.validateEmail,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                ),
                                const SizedBox(height: 28),

                                // Send OTP Button - Same as Login
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
                                        borderRadius:
                                            BorderRadius.circular(isDesktop ? 14 : 12),
                                        onTap: authProvider.isLoading
                                            ? null
                                            : _sendOtp,
                                        child: Center(
                                          child: authProvider.isLoading
                                              ? const LoadingWidget()
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Send OTP',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: isDesktop ? 16 : 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                        letterSpacing: 0.8,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.arrow_forward_rounded,
                                                      color: Colors.white,
                                                      size: isDesktop ? 20 : 18,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Back to Login Link
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
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: primaryBlue,
                                      ),
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Sign In',
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
    );
  }

  // Responsive helper methods
  double _getResponsiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return width - 56;
    } else if (width < 900) {
      return width * 0.75;
    } else {
      return width * 0.4;
    }
  }

  double _getResponsiveFontSize(BuildContext context, double size) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return size;
    } else if (width < 900) {
      return size * 1.1;
    } else {
      return size * 1.2;
    }
  }
}