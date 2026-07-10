// lib/screens/terms_conditions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        appBar: _buildPremiumAppBar(context, isDark),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPremiumHeader(isDark),
                const SizedBox(height: 24),
                _buildSearchSection(isDark),
                const SizedBox(height: 20),
                ..._buildSections(isDark),
                const SizedBox(height: 20),
                _buildLastUpdated(isDark),
                const SizedBox(height: 20),
                _buildAcceptButton(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== PREMIUM APP BAR ==========
  PreferredSizeWidget _buildPremiumAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
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
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF4B5563),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Terms & Condi...',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
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
              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
              color: isDark ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
              size: 22,
            ),
            onPressed: () {
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
  Widget _buildPremiumHeader(bool isDark) {
    return Container(
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legal Agreement',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Terms & Conditions',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'By using YourHome, you agree to our terms. Please read carefully.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ========== SEARCH SECTION ==========
  Widget _buildSearchSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search terms...',
                hintStyle: GoogleFonts.poppins(
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                fontSize: 14,
              ),
              onChanged: (value) {
                // Search functionality
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Search',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTIONS ==========
  List<Widget> _buildSections(bool isDark) {
    final sections = [
      {
        'emoji': '📌',
        'title': 'Acceptance of Terms',
        'content': 'By using the YourHome app, you agree to these Terms & Conditions. If you do not agree, please do not use our services.',
        'color': const Color(0xFF2563EB),
      },
      {
        'emoji': '👤',
        'title': 'User Accounts',
        'content': '• You must be 18+ years old to use this app\n• Provide accurate and complete information\n• You are responsible for your account security\n• Notify us immediately of any unauthorized use\n• Owners must verify their identity and property',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'emoji': '🏠',
        'title': 'Property Listings',
        'content': '• Owners must provide accurate property information\n• Photos must represent the actual property\n• False or misleading listings will be removed\n• Owners must have legal rights to list the property\n• Properties undergo admin verification before publication',
        'color': const Color(0xFFF59E0B),
      },
      {
        'emoji': '📅',
        'title': 'Bookings',
        'content': '• Booking requests are sent to property owners\n• Owners have 24-48 hours to respond\n• Cancellation policies apply as per owner discretion\n• Tenants must honor booking commitments',
        'color': const Color(0xFF22C55E),
      },
      {
        'emoji': '💳',
        'title': 'Payments',
        'content': '• Payments are processed securely via Razorpay\n• Subscription fees are charged monthly\n• Refunds are subject to cancellation policies\n• All prices are in INR',
        'color': const Color(0xFFEC4899),
      },
      {
        'emoji': '🚫',
        'title': 'User Conduct',
        'content': '• No false or misleading information\n• No harassment or discrimination\n• No spamming or unsolicited messages\n• No illegal activities\n• No scraping or data mining\n• No impersonation of others',
        'color': const Color(0xFFEF4444),
      },
      {
        'emoji': '©️',
        'title': 'Intellectual Property',
        'content': '• All content on YourHome is owned by us\n• Users retain rights to their uploaded content\n• Using our logo or brand requires permission',
        'color': const Color(0xFF7C3AED),
      },
      {
        'emoji': '⚠️',
        'title': 'Disclaimer',
        'content': '• We provide the service "as is"\n• We are not responsible for property quality\n• We do not guarantee bookings\n• Use of the app is at your own risk',
        'color': const Color(0xFFF59E0B),
      },
      {
        'emoji': '⛔',
        'title': 'Termination',
        'content': '• We may suspend or terminate accounts\n• Violation of terms leads to account removal\n• Users may delete their account anytime',
        'color': const Color(0xFFEF4444),
      },
      {
        'emoji': '⚖️',
        'title': 'Governing Law',
        'content': '• These terms are governed by Indian law\n• Disputes will be resolved in Indian courts\n• Exclusive jurisdiction: Delhi, India',
        'color': const Color(0xFF2563EB),
      },
      {
        'emoji': '📧',
        'title': 'Contact',
        'content': 'For any questions, contact us at support@yourhome.in',
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return sections.map((section) {
      return _buildPremiumSection(
        isDark,
        section['emoji']! as String,
        section['title']! as String,
        section['content']! as String,
        section['color']! as Color,
      );
    }).toList();
  }

  Widget _buildPremiumSection(
    bool isDark,
    String emoji,
    String title,
    String content,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${title.split(' ').last}',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.8,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== LAST UPDATED ==========
  Widget _buildLastUpdated(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.update_rounded,
            size: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Text(
            'Last updated: July 2026',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ========== ACCEPT BUTTON ==========
  Widget _buildAcceptButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'I Agree & Accept',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}