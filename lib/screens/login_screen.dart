// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/validators.dart';
import '../widgets/loading_widget.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
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
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      );
    }
  }

  // Responsive helper methods
  double _getResponsiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return width - 56; // Mobile
    } else if (width < 900) {
      return width * 0.75; // Tablet
    } else {
      return width * 0.4; // Desktop
    }
  }

  double _getResponsiveFontSize(BuildContext context, double size) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return size; // Mobile - no change
    } else if (width < 900) {
      return size * 1.1; // Tablet - slightly larger
    } else {
      return size * 1.2; // Desktop - larger
    }
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 28.0;
    } else if (width < 900) {
      return 40.0;
    } else {
      return 60.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    // Light mode - Premium White & Gold theme
    // Dark mode - Deep Luxury theme
    final List<Color> gradientColors = isDark
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

    // App Logo Blue Colors
    final primaryBlue = const Color(0xFF2563EB);  // Main blue
    final blueLight = const Color(0xFF3B82F6);   // Light blue
    final blueDark = const Color(0xFF1D4ED8);    // Dark blue

    // Responsive values
    final responsivePadding = _getResponsivePadding(context);
    final logoSize = isDesktop ? 130.0 : (isTablet ? 110.0 : 100.0);
    final titleSize = _getResponsiveFontSize(context, 34);
    final subtitleSize = _getResponsiveFontSize(context, 15);
    final cardWidth = _getResponsiveWidth(context);
    final buttonHeight = isDesktop ? 50.0 : (isTablet ? 48.0 : 46.0);
    final formSpacing = isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0);

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
              padding: EdgeInsets.symmetric(
                horizontal: responsivePadding,
                vertical: 20,
              ),
              child: FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: Container(
                    width: cardWidth,
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 550 : (isTablet ? 650 : double.infinity),
                      minHeight: screenHeight * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Theme Toggle - Responsive position
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
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
                                final themeProvider =
                                    Provider.of<ThemeProvider>(context, listen: false);
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
                                size: isDesktop ? 30 : 26,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isDesktop ? 30 : (isTablet ? 24 : 20)),

                        // Luxury Logo with Blue Accent
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      primaryBlue,
                                      blueDark,
                                    ]
                                  : [
                                      blueLight,
                                      primaryBlue,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(isDark ? 0.4 : 0.25),
                                blurRadius: isDark ? 40 : 30,
                                spreadRadius: isDark ? 8 : 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Container(
                              color: Colors.white,
                              padding: EdgeInsets.all(isDesktop ? 28 : 20),
                              child: Image.asset(
                                'assets/icons/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stack) => Icon(
                                  Icons.home_rounded,
                                  color: primaryBlue,
                                  size: isDesktop ? 50 : 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isDesktop ? 36 : (isTablet ? 32 : 28)),

                        // Welcome Text - Responsive
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isDesktop 
                              ? 'Sign in to continue your journey in luxury'
                              : 'Sign in to continue your journey',
                          style: GoogleFonts.poppins(
                            fontSize: subtitleSize,
                            color: subtitleColor,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isDesktop ? 48 : (isTablet ? 44 : 40)),

                        // Form - Direct on screen (No Card)
                        SlideTransition(
                          position: _slideUp,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ✅ Email Field - FIXED (No SizedBox, proper padding)
                                TextFormField(
                                  controller: _emailController,
                                  style: GoogleFonts.poppins(
                                    fontSize: isDesktop ? 16 : 15,
                                    color: textColor,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  validator: Validators.validateEmail,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
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
                                  scrollPhysics: const ClampingScrollPhysics(),
                                ),
                                SizedBox(height: formSpacing),

                                // ✅ Password Field - FIXED (No SizedBox, proper padding)
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.poppins(
                                    fontSize: isDesktop ? 16 : 15,
                                    color: textColor,
                                  ),
                                  validator: Validators.validatePassword,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
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
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: hintColor,
                                        size: isDesktop ? 22 : 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
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
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.poppins(
                                        fontSize: isDesktop ? 14 : 13,
                                        fontWeight: FontWeight.w500,
                                        color: primaryBlue,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isDesktop ? 28 : 24),

                                // Login Button - Matching Logo Blue Colors
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
                                            : _login,
                                        child: Center(
                                          child: authProvider.isLoading
                                              ? const LoadingWidget()
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Sign In',
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
                                SizedBox(height: isDesktop ? 28 : 24),

                                // Sign Up Section - Responsive
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: GoogleFonts.poppins(
                                        fontSize: isDesktop ? 15 : 14,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : const Color(0xFF6B7280),
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
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Sign Up',
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
                        
                        // Bottom spacing for responsive
                        SizedBox(height: isDesktop ? 30 : (isTablet ? 20 : 10)),
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
}