// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main entrance animations
  late final AnimationController _entranceController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _loaderFade;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  // Breathing pulse for logo
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  // Background floating elements
  late final AnimationController _bgController;
  late final Animation<double> _bgFloat1;
  late final Animation<double> _bgFloat2;
  late final Animation<double> _bgFloat3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call this every time dependencies change to update navigation bar
    _updateSystemUIOverlay();
  }

  void _updateSystemUIOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final navBarColor = isDark 
        ? const Color(0xFF0A0E1A)  // Dark mode - matches gradient
        : const Color(0xFFF8F9FC); // Light mode - matches gradient

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

  void _setupAnimations() {
    // Main entrance controller
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _loaderFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _taglineFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();

    // Logo breathing pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Background floating animation
    _bgController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _bgFloat1 = Tween<double>(begin: 0.0, end: 25.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    _bgFloat2 = Tween<double>(begin: 0.0, end: -20.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    _bgFloat3 = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
  }

  void _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 2600));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.isLoggedIn();

    if (isLoggedIn) {
      await authProvider.checkAuthStatus();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Same blue gradient as login screen
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

    final blobColor = isDark
        ? const Color(0xFF2563EB).withOpacity(0.08)
        : const Color(0xFF2563EB).withOpacity(0.06);

    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark 
        ? Colors.white.withOpacity(0.7) 
        : const Color(0xFF6B7280);

    final primaryBlue = const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: gradientColors.first,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final t = _bgController.value;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 0.2, -1),
                end: Alignment(1, 1 - t * 0.2),
                colors: gradientColors,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Floating background blobs - Blue themed like login
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  return Positioned(
                    top: -80 + _bgFloat1.value,
                    right: -60 - _bgFloat2.value,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blobColor,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  return Positioned(
                    bottom: -40 + _bgFloat2.value,
                    left: -50 + _bgFloat3.value,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blobColor.withOpacity(0.7),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  return Positioned(
                    top: MediaQuery.of(context).size.height * 0.3,
                    right: -30 + _bgFloat3.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blobColor.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              ),

              // Theme toggle - Matching login screen style
              Positioned(
                top: 16,
                right: 16,
                child: FadeTransition(
                  opacity: _logoFade,
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
                      icon: Icon(
                        isDark
                            ? Icons.wb_sunny_outlined
                            : Icons.nightlight_round_outlined,
                        color: isDark
                            ? primaryBlue
                            : const Color(0xFF4B5563),
                        size: 26,
                      ),
                      tooltip: 'Toggle theme',
                      onPressed: () {
                        final themeProvider = Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        );
                        final current = themeProvider.themeMode;
                        final next = current == ThemeMode.light
                            ? ThemeMode.dark
                            : current == ThemeMode.dark
                                ? ThemeMode.system
                                : ThemeMode.light;
                        themeProvider.setThemeMode(next);
                      },
                    ),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with blue theme
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseScale.value,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.03),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(isDark ? 0.3 : 0.15),
                                      blurRadius: 50,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1B2436)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/icons/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stack) {
                                        return Icon(
                                          Icons.home_rounded,
                                          size: 56,
                                          color: primaryBlue,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Brand name - Same as login screen style
                    FadeTransition(
                      opacity: _logoFade,
                      child: Text(
                        'yourhome',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Tagline with blue accent - Like login screen
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
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
                          child: Text(
                            'FIND YOUR PERFECT STAY',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle - Same style as login
                    SlideTransition(
                      position: _subtitleSlide,
                      child: FadeTransition(
                        opacity: _subtitleFade,
                        child: Text(
                          'PG  •  HOSTEL  •  HOTEL  •  VILLA  •  FLAT',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 56),

                    // Elegant loader - Blue themed
                    FadeTransition(
                      opacity: _loaderFade,
                      child: const _ElegantLoader(),
                    ),
                  ],
                ),
              ),

              // Bottom tagline
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Center(
                      child: Text(
                        '✨ Made with care, for your next home ✨',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: subtitleColor.withOpacity(0.5),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Elegant animated loader matching login screen style
class _ElegantLoader extends StatefulWidget {
  const _ElegantLoader();

  @override
  State<_ElegantLoader> createState() => _ElegantLoaderState();
}

class _ElegantLoaderState extends State<_ElegantLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF2563EB);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            // Animated dots with blue theme
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final t = (_controller.value - delay) % 1.0;
                final scale = t < 0.5
                    ? 1.0 + (t / 0.5) * 0.8
                    : 1.8 - ((t - 0.5) / 0.5) * 0.8;
                final opacity = t < 0.5
                    ? 0.3 + (t / 0.5) * 0.7
                    : 1.0 - ((t - 0.5) / 0.5) * 0.7;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Transform.scale(
                    scale: scale.clamp(0.5, 1.8),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withOpacity(opacity.clamp(0.3, 1.0))
                            : primaryBlue.withOpacity(opacity.clamp(0.3, 1.0)),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.white : primaryBlue)
                                .withOpacity(opacity * 0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Loading text
            Text(
              'Loading',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFF6B7280).withOpacity(0.7),
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }
}