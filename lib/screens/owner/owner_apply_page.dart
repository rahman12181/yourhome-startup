// lib/pages/owner/owner_apply_page.dart

// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class OwnerApplyPage extends StatefulWidget {
  const OwnerApplyPage({super.key});

  @override
  State<OwnerApplyPage> createState() => _OwnerApplyPageState();
}

class _OwnerApplyPageState extends State<OwnerApplyPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _businessCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  File? _aadharDoc;
  File? _panDoc;
  File? _addressProof;

  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _businessCtrl.dispose();
    _aadharCtrl.dispose();
    _panCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(void Function(File) onPicked) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        onPicked(File(picked.path));
      });
    }
  }

  void _formatAadhar(String value) {
    final text = value.replaceAll(RegExp(r'\s'), '');
    if (text.length > 12) return;

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 4 || i == 8) {
        formatted += ' ';
      }
      formatted += text[i];
    }
    _aadharCtrl.text = formatted;
    _aadharCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: formatted.length),
    );
  }

  // ============== SHOW TERMS DIALOG ==============
  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TermsBottomSheet(
        onAgree: () {
          setState(() {
            _agreeTerms = true;
          });
        },
      ),
    );
  }

  // ============== SHOW PRIVACY DIALOG ==============
  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PrivacyBottomSheet(
        onAgree: () {
          setState(() {
            _agreePrivacy = true;
          });
        },
      ),
    );
  }

  // ============== SUBMIT ==============
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please fill all required fields', Colors.orange);
      return;
    }

    if (_aadharDoc == null || _panDoc == null || _addressProof == null) {
      _showSnackbar('All documents are required', Colors.orange);
      return;
    }

    if (!_agreeTerms) {
      _showSnackbar('Please agree to Terms & Conditions', Colors.orange);
      return;
    }

    if (!_agreePrivacy) {
      _showSnackbar('Please agree to Privacy Policy', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    final result = await ownerProvider.applyAsOwner(
      businessName: _businessCtrl.text.trim(),
      aadharNumber: _aadharCtrl.text.trim(),
      panNumber: _panCtrl.text.trim().toUpperCase(),
      aadharDoc: _aadharDoc,
      panDoc: _panDoc,
      addressProof: _addressProof,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result.success) {
        _showSnackbar('Application submitted successfully! ✅', Colors.green);
        Navigator.pop(context, true);
      } else {
        _showSnackbar(result.message, Colors.red);
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : Icons.warning_amber_rounded,
              color: Colors.white,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        appBar: _buildAppBar(isDark),
        body: _isLoading
            ? _buildLoadingState(isDark)
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildBody(isDark, user),
                ),
              ),
      ),
    );
  }

  // ============== APP BAR ==============
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Text(
        'Become an Owner',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF4B5563),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: const Color(0xFF2563EB),
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

  // ============== LOADING STATE ==============
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
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
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Submitting Application...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============== BODY ==============
  Widget _buildBody(bool isDark, dynamic user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeaderCard(isDark, user),
            const SizedBox(height: 16),

            // ─── Important Warning Banner ───
            _buildWarningBanner(isDark),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F33) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildBusinessNameField(isDark),
                  const SizedBox(height: 16),
                  _buildAadharField(isDark),
                  const SizedBox(height: 16),
                  _buildPanField(isDark),
                  const SizedBox(height: 20),
                  Divider(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentSection(isDark),
                  const SizedBox(height: 12),
                  _buildFileUploadWidget(
                    'Aadhar Card *',
                    _aadharDoc,
                    (f) => setState(() => _aadharDoc = f),
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFileUploadWidget(
                    'PAN Card *',
                    _panDoc,
                    (f) => setState(() => _panDoc = f),
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFileUploadWidget(
                    'Address Proof *',
                    _addressProof,
                    (f) => setState(() => _addressProof = f),
                    isDark,
                  ),
                  const SizedBox(height: 20),
                  Divider(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // ─── Legal Warning ───
                  _buildLegalWarning(isDark),
                  const SizedBox(height: 16),

                  // ─── Security Section ───
                  _buildSecuritySection(isDark),
                  const SizedBox(height: 16),

                  // ─── Terms & Conditions ───
                  _buildTermsCheckbox(isDark),
                  const SizedBox(height: 12),

                  // ─── Privacy Policy ───
                  _buildPrivacyCheckbox(isDark),
                  const SizedBox(height: 20),

                  _buildSubmitButton(isDark),
                  const SizedBox(height: 12),
                  _buildInfoNote(isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============== HEADER CARD ==============
  Widget _buildHeaderCard(bool isDark, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Become an Owner',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start listing your properties and earn',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Strictly Verified',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============== WARNING BANNER ==============
  Widget _buildWarningBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important — Strict Verification',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only ORIGINAL documents in YOUR name will be accepted. '
                  'Fake or duplicate documents will lead to account ban, '
                  '₹50,000 penalty, and FIR. All data is shared with Police.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============== LEGAL WARNING ==============
  Widget _buildLegalWarning(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(isDark ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Legal Consequences',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLegalItem('Account permanently banned', isDark),
          _buildLegalItem('₹50,000 penalty charged', isDark),
          _buildLegalItem('FIR under IT Act 2000 Section 66C & 66D', isDark),
          _buildLegalItem('Jail up to 3 years + ₹1 lakh fine', isDark),
          _buildLegalItem('Aadhaar blacklisted with UIDAI', isDark),
          _buildLegalItem('All data shared with Police', isDark),
        ],
      ),
    );
  }

  Widget _buildLegalItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.close_rounded,
            size: 12,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== SECURITY SECTION ==============
  Widget _buildSecuritySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2563EB).withOpacity(0.08),
            const Color(0xFF2563EB).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '🔒 Secure Application Process',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSecurityItem(
            '✅ Your data is encrypted and secure',
            isDark,
          ),
          _buildSecurityItem(
            '✅ Documents are verified by our team',
            isDark,
          ),
          _buildSecurityItem(
            '✅ Application reviewed within 24-48 hours',
            isDark,
          ),
          _buildSecurityItem(
            '✅ You will receive email confirmation',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const Icon(
            Icons.circle_rounded,
            size: 5,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== BUSINESS NAME ==============
  Widget _buildBusinessNameField(bool isDark) {
    return TextFormField(
      controller: _businessCtrl,
      style: GoogleFonts.poppins(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: 'Business Name *',
        labelStyle: GoogleFonts.poppins(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 13,
        ),
        hintText: 'e.g., Rahman PG Services',
        hintStyle: GoogleFonts.poppins(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.business_center_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 22,
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Business name is required';
        }
        if (value.length < 2) {
          return 'At least 2 characters';
        }
        return null;
      },
    );
  }

  // ============== AADHAR FIELD ==============
  Widget _buildAadharField(bool isDark) {
    return TextFormField(
      controller: _aadharCtrl,
      style: GoogleFonts.poppins(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 15,
      ),
      keyboardType: TextInputType.number,
      maxLength: 14,
      buildCounter: (context,
              {required currentLength,
              required isFocused,
              maxLength}) =>
          null,
      onChanged: _formatAadhar,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: 'Aadhar Number *',
        labelStyle: GoogleFonts.poppins(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 13,
        ),
        hintText: '1234 5678 9012',
        hintStyle: GoogleFonts.poppins(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.assignment_ind_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 22,
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Aadhar number is required';
        }
        final digits = value.replaceAll(RegExp(r'\s'), '');
        if (digits.length != 12) {
          return 'Enter 12 digits';
        }
        if (!RegExp(r'^\d{12}$').hasMatch(digits)) {
          return 'Only digits allowed';
        }
        return null;
      },
    );
  }

  // ============== PAN FIELD ==============
  Widget _buildPanField(bool isDark) {
    return TextFormField(
      controller: _panCtrl,
      style: GoogleFonts.poppins(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 15,
      ),
      textCapitalization: TextCapitalization.characters,
      maxLength: 10,
      buildCounter: (context,
              {required currentLength,
              required isFocused,
              maxLength}) =>
          null,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
      ],
      decoration: InputDecoration(
        labelText: 'PAN Number *',
        labelStyle: GoogleFonts.poppins(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 13,
        ),
        hintText: 'ABCDE1234F',
        hintStyle: GoogleFonts.poppins(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.assignment_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 22,
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'PAN number is required';
        }
        final pan = value.toUpperCase();
        if (pan.length != 10) {
          return 'PAN must be 10 characters';
        }
        if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
          return 'Invalid PAN format (e.g., ABCDE1234F)';
        }
        return null;
      },
    );
  }

  // ============== DOCUMENT SECTION ==============
  Widget _buildDocumentSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.upload_file_rounded,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              'Required Documents',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Camera only — gallery uploads will be rejected',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ============== FILE UPLOAD WIDGET ==============
  Widget _buildFileUploadWidget(
    String label,
    File? file,
    void Function(File) onPicked,
    bool isDark,
  ) {
    final bool isUploaded = file != null;

    return GestureDetector(
      onTap: () => _pickFile(onPicked),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            width: isUploaded ? 1.5 : 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUploaded
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isUploaded
                    ? Icons.file_present_rounded
                    : Icons.camera_alt_rounded,
                color: isUploaded ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploaded
                        ? '✅ Uploaded (Tap to retake)'
                        : '📷 Required — Tap to capture',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isUploaded ? Colors.green : Colors.red,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isUploaded
                    ? Colors.green.withOpacity(0.1)
                    : const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUploaded
                        ? Icons.change_circle_rounded
                        : Icons.camera_alt_rounded,
                    size: 14,
                    color:
                        isUploaded ? Colors.green : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUploaded ? 'Retake' : 'Capture',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isUploaded
                          ? Colors.green
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== TERMS CHECKBOX ==============
  Widget _buildTermsCheckbox(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: _agreeTerms,
            onChanged: (value) {
              setState(() {
                _agreeTerms = value ?? false;
              });
            },
            activeColor: const Color(0xFF2563EB),
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(
              color: isDark ? Colors.grey[500]! : Colors.grey[400]!,
              width: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _agreeTerms = !_agreeTerms;
                    });
                  },
                  child: Text(
                    'I agree to the ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showTermsAndConditions,
                  child: Text(
                    'Terms & Conditions',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' including Anti-Fraud rules',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============== PRIVACY CHECKBOX ==============
  Widget _buildPrivacyCheckbox(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: _agreePrivacy,
            onChanged: (value) {
              setState(() {
                _agreePrivacy = value ?? false;
              });
            },
            activeColor: const Color(0xFF2563EB),
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(
              color: isDark ? Colors.grey[500]! : Colors.grey[400]!,
              width: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _agreePrivacy = !_agreePrivacy;
                    });
                  },
                  child: Text(
                    'I agree to the ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showPrivacyPolicy,
                  child: Text(
                    'Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' and data sharing rules',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============== SUBMIT BUTTON ==============
  Widget _buildSubmitButton(bool isDark) {
    final ownerProvider = Provider.of<OwnerProvider>(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (ownerProvider.isSubmitting || _isLoading) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: (ownerProvider.isSubmitting || _isLoading)
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Submit Application',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============== INFO NOTE ==============
  Widget _buildInfoNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue[400],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Application reviewed within 24-48 hours. By submitting, you confirm all documents are original and belong to you.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.5,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TERMS BOTTOM SHEET — with STRONG anti-fraud legal text
// ══════════════════════════════════════════════════════════════
class _TermsBottomSheet extends StatelessWidget {
  final VoidCallback onAgree;

  const _TermsBottomSheet({required this.onAgree});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms & Conditions',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'Please read carefully before agreeing',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color:
                              isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── RED ALERT at top ───
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'WARNING: Fake documents or fake listings will result in '
                            'permanent ban, ₹50,000 penalty, and FIR with Police. '
                            'All your data will be shared with authorities.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: isDark
                                  ? Colors.red[300]
                                  : Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '📌 1. Acceptance of Terms',
                    'By using the YourHome app, you agree to these Terms & Conditions. '
                        'If you do not agree, please do not use our services. '
                        'Continuing to use the app means you accept all rules below.',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '👤 2. User Accounts',
                    '• You must be 18+ years old to use this app\n'
                        '• Provide accurate and complete information only\n'
                        '• You are responsible for your account security\n'
                        '• Notify us immediately of any unauthorized use\n'
                        '• One person = One owner account (strictly enforced)\n\n'
                        '🎥 VIDEO VERIFICATION CONSENT:\n'
                        '• You agree to record a 5–20 second verification video\n'
                        '• Video is stored securely for 2 years as legal record\n'
                        '• Video is used for identity verification ONLY\n'
                        '• Video will NOT be shared publicly\n'
                        '• Video will be shared with Police ONLY if fraud is detected',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '🏠 3. Property Listings & Owner Verification — STRICT RULES',
                    'VIOLATION WILL LEAD TO LEGAL ACTION:\n\n'
                        '✅ Owners must provide ORIGINAL and GENUINE documents\n'
                        '✅ Aadhaar/PAN must belong to the SAME person applying\n'
                        '✅ Property photos must be REAL (not copied from internet)\n'
                        '✅ One person can register ONLY ONE owner account\n'
                        '✅ Aadhaar/PAN cannot be reused for another account\n\n'
                        '🚨 IF FOUND FAKE / DUPLICATE / STOLEN:\n'
                        '❌ Account permanently banned — no refund of subscription\n'
                        '❌ ₹50,000 penalty will be charged\n'
                        '❌ FIR will be lodged under IT Act 2000 Section 66C & 66D\n'
                        '❌ Legal action under IPC Section 420, 468, 471\n'
                        '❌ Jail up to 3 years + fine up to ₹1 lakh\n'
                        '❌ All documents will be shared with Police & UIDAI\n'
                        '❌ Your identity will be blacklisted across all platforms\n\n'
                        '📌 Every document is verified against Government records. '
                        'Every video is recorded as legal evidence. '
                        'Fraud will NOT be tolerated.',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '📅 4. Bookings',
                    '• Booking requests are sent to property owners\n'
                        '• Owners have 24-48 hours to respond\n'
                        '• Cancellation policies apply as per owner discretion\n'
                        '• Tenants must honor booking commitments\n'
                        '• Owners must NOT accept booking then cancel without reason',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '💳 5. Payments & Fraud Consequences',
                    '✅ Payments processed via Razorpay (bank-grade security)\n'
                        '✅ Subscription fees auto-charged monthly\n'
                        '✅ Refunds subject to cancellation policy\n'
                        '✅ All prices in INR\n\n'
                        '🚨 PAYMENT FRAUD WILL RESULT IN:\n'
                        '❌ Immediate bank account freeze request to your bank\n'
                        '❌ Payouts permanently stopped\n'
                        '❌ Full refund to affected tenants (deducted from your account)\n'
                        '❌ FIR under IPC Section 420 (Cheating)\n'
                        '❌ Report to RBI Cyber Cell\n'
                        '❌ Your UPI ID / bank account flagged as fraudulent\n\n'
                        '⚠️ If you collect rent from tenants and disappear, '
                        'this is a CRIMINAL OFFENCE. Police will arrest you. '
                        'Your Aadhaar, PAN, photo, and video will be published '
                        'in the FIR and may be circulated to other platforms.',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '🚫 6. User Conduct',
                    '• No false or misleading information\n'
                        '• No harassment or discrimination\n'
                        '• No spamming or unsolicited messages\n'
                        '• No illegal activities\n'
                        '• No scraping or data mining\n'
                        '• No impersonation of others\n'
                        '• No sharing of other users\' data',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '©️ 7. Intellectual Property',
                    '• All content on YourHome is owned by us\n'
                        '• Users retain rights to their uploaded content\n'
                        '• Using our logo or brand requires written permission',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '⚠️ 8. Disclaimer',
                    '• We provide the service "as is"\n'
                        '• We are not responsible for property quality\n'
                        '• We do not guarantee bookings\n'
                        '• Use of the app is at your own risk',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '⛔ 9. Termination',
                    '• We may suspend or terminate accounts without notice\n'
                        '• Violation of terms leads to permanent account removal\n'
                        '• No refund will be given on termination for fraud\n'
                        '• Users may delete their account anytime',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '⚖️ 10. Governing Law',
                    '• These terms are governed by Indian law\n'
                        '• Disputes will be resolved in Indian courts\n'
                        '• Exclusive jurisdiction: Delhi, India\n'
                        '• You agree to cooperate with legal proceedings',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '📧 11. Contact',
                    'For any questions, contact us at:\n'
                        'Email: lutfur1218@gmail.com\n'
                        'Phone: +91-7643845067\n'
                        'Address: Delhi, Abulfazal Street-4, India',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  // ─── BIG ANTI-FRAUD DECLARATION ───
                  _buildTermsSection(
                    '🚨 12. Anti-Fraud Declaration',
                    'BY ACCEPTING THESE TERMS, YOU DECLARE THAT:\n\n'
                        '1. All documents uploaded are ORIGINAL and belong to YOU\n'
                        '2. Your Aadhaar is NOT registered on any other YourHome account\n'
                        '3. Your PAN is NOT registered on any other YourHome account\n'
                        '4. Your phone number is NOT used on any other account\n'
                        '5. Your bank account is in YOUR OWN name\n'
                        '6. You will NOT create fake property listings\n'
                        '7. You will NOT collect rent and disappear\n'
                        '8. You will NOT misuse tenant information\n'
                        '9. You will NOT upload photoshopped documents\n'
                        '10. You understand that VIDEO is recorded as evidence\n\n'
                        '⚠️ IF ANY DECLARATION IS FALSE:\n\n'
                        '🛑 Immediate account termination (no refund)\n'
                        '🛑 Police complaint (FIR)\n'
                        '🛑 IT Act 2000 Section 66C — Identity theft (up to 3 years jail)\n'
                        '🛑 IT Act 2000 Section 66D — Cheating by personation (up to 3 years + ₹1L fine)\n'
                        '🛑 IPC Section 420 — Cheating (up to 7 years jail)\n'
                        '🛑 IPC Section 468 — Forgery (up to 7 years jail)\n'
                        '🛑 IPC Section 471 — Using forged document (up to 7 years jail)\n'
                        '🛑 Aadhaar Act 2016 Section 38 — Illegal use of Aadhaar\n'
                        '🛑 DPDP Act 2023 — Data misuse penalty (up to ₹250 Cr)\n\n'
                        '📌 LEGAL NOTICE:\n'
                        'All your uploaded documents, video recordings, IP address, '
                        'device ID, bank account details, and chat records are preserved '
                        'for 2 years. In case of fraud, this data will be submitted to '
                        'Police as evidence without any prior notice to you.',
                    isDark,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Last updated: October 2026',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Agree Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    onAgree();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'I Agree to Terms & Anti-Fraud Rules',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            height: 1.65,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PRIVACY BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _PrivacyBottomSheet extends StatelessWidget {
  final VoidCallback onAgree;

  const _PrivacyBottomSheet({required this.onAgree});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'How we protect and use your data',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color:
                              isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacySection(
                    '📋 Introduction',
                    'YourHome is a property listing and booking platform that connects property owners with tenants. '
                        'We are committed to protecting your privacy and ensuring the security of your personal information.',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    '📊 Information We Collect',
                    '• Personal Information: Name, email, phone number, address\n'
                        '• Property Information: Property details, photos, videos\n'
                        '• Payment Information: Transaction details (processed via Razorpay)\n'
                        '• Device Information: Device type, OS, IP address, device ID\n'
                        '• Usage Data: App interactions, search history, preferences\n'
                        '• Verification Data: Aadhaar/PAN documents, selfie video',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    '🔧 How We Use Your Data',
                    '• To provide and maintain our services\n'
                        '• To process bookings and payments\n'
                        '• To verify property owners and tenants\n'
                        '• To send notifications and updates\n'
                        '• To improve app performance and user experience\n'
                        '• To prevent fraud and ensure security\n'
                        '• To comply with legal requirements',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    '🤝 Data Sharing',
                    'We share your data ONLY with:\n'
                        '• Razorpay: For payment processing\n'
                        '• Firebase: For push notifications\n'
                        '• Cloudinary: For secure media storage\n'
                        '• Government Authorities: When legally required\n'
                        '• Police: In case of fraud investigation (without prior notice)\n'
                        '• UIDAI: For Aadhaar verification if applicable\n\n'
                        'We NEVER sell your personal data to third parties.',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    '🔒 Data Security',
                    '• All data is encrypted in transit (SSL/TLS)\n'
                        '• Passwords are hashed using BCrypt\n'
                        '• Access to data is restricted to authorized personnel\n'
                        '• Regular security audits are conducted\n'
                        '• Data is stored in secure databases\n'
                        '• Video recordings are stored with encryption',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    '📅 Data Retention',
                    '• Verification documents: 2 years (as per UIDAI guidelines)\n'
                        '• Video recordings: 2 years (legal evidence)\n'
                        '• Transaction records: 7 years (as per RBI rules)\n'
                        '• Chat messages: 6 months after account closure\n\n'
                        'After retention period, data is securely deleted.',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    '👤 Your Rights',
                    '• Access your personal data anytime\n'
                        '• Update or correct your information\n'
                        '• Delete your account and associated data\n'
                        '• Opt-out of marketing communications\n'
                        '• Request data export\n'
                        '• File complaint with Data Protection Board (DPDP Act 2023)',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    '🚨 Fraud Data Sharing Notice',
                    'IF FRAUD IS DETECTED:\n'
                        '• All your data will be shared with Police\n'
                        '• Your Aadhaar/PAN will be reported to UIDAI\n'
                        '• Your bank account details will be shared with RBI Cyber Cell\n'
                        '• Your identity will be flagged on our platform\n'
                        '• No prior notice will be given to you',
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    '📞 Contact Us',
                    'Email: lutfur1218@gmail.com\n'
                        'Phone: +91-7643845067\n'
                        'Address: Delhi, Abulfazal Street-4, India\n'
                        'Response Time: Within 12-24 hours',
                    isDark,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Last updated: October 2026',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Agree Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    onAgree();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'I Agree to Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            height: 1.65,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}