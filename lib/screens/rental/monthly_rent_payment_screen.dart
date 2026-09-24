// lib/screens/payment/monthly_rent_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../providers/rental_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class MonthlyRentPaymentScreen extends StatefulWidget {
  final int invoiceId;
  final String invoiceMonth;
  final double amount;

  const MonthlyRentPaymentScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceMonth,
    required this.amount,
  });

  @override
  State<MonthlyRentPaymentScreen> createState() =>
      _MonthlyRentPaymentScreenState();
}

class _MonthlyRentPaymentScreenState extends State<MonthlyRentPaymentScreen>
    with TickerProviderStateMixin {
  Razorpay? _razorpay;
  bool _isPaying = false;
  bool _paymentSuccess = false;
  String? _utr;

  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initRazorpay();
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
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _scaleIn = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _mainController.forward();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _mainController.dispose();
    super.dispose();
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF22C55E)
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
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
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  Future<void> _payNow() async {
    HapticFeedback.mediumImpact();
    setState(() => _isPaying = true);

    final rentalProvider = Provider.of<RentalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final initiateResult =
        await rentalProvider.initiateMonthlyRent(widget.invoiceId);

    if (!mounted) return;

    if (initiateResult['success'] != true) {
      setState(() => _isPaying = false);
      _showSnack(
        initiateResult['message'] ?? 'Failed to start payment',
        Colors.red[700]!,
      );
      return;
    }

    final data = initiateResult['data'];

    debugPrint('════════════════════════════════════════');
    debugPrint('💰 RAZORPAY INITIATE RESPONSE');
    debugPrint('amount (raw)     : ${data.amount}');
    debugPrint('razorpayOrderId  : ${data.razorpayOrderId}');
    debugPrint('════════════════════════════════════════');

    final double rawAmount = (data.amount as num).toDouble();
    final int amountInPaise = (rawAmount * 100).round();

    debugPrint('Amount in paise  : $amountInPaise');
    debugPrint('Razorpay key     : ${AppConstants.razorpayKeyId}');

    final options = {
      'key': AppConstants.razorpayKeyId,
      'amount': amountInPaise,
      'currency': 'INR',
      'order_id': data.razorpayOrderId,
      'name': AppConstants.appName,
      'description': 'Rent for ${widget.invoiceMonth}',
      'prefill': {
        'contact': authProvider.user?.phone ?? '',
        'email': authProvider.user?.email ?? '',
      },
      'theme': {'color': '#2563EB'},
      'retry': {
        'enabled': true,
        'max_count': 2,
      },
      'timeout': 300,
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('❌ Razorpay.open() exception: $e');
      if (mounted) {
        setState(() => _isPaying = false);
        _showSnack('Unable to open payment checkout.', Colors.red[700]!);
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ RAZORPAY PAYMENT SUCCESS: ${response.paymentId}');

    final rentalProvider = Provider.of<RentalProvider>(context, listen: false);

    final result = await rentalProvider.confirmMonthlyRent(
      razorpayOrderId: response.orderId!,
      razorpayPaymentId: response.paymentId!,
      razorpaySignature: response.signature!,
    );

    if (!mounted) return;
    setState(() => _isPaying = false);

    if (result['success'] == true) {
      HapticFeedback.heavyImpact();
      setState(() {
        _paymentSuccess = true;
        _utr = result['data']?.payoutTransactionRef;
      });
    } else {
      _showSnack(
        result['message'] ?? 'Payment confirmation failed',
        Colors.red[700]!,
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    debugPrint('❌ RAZORPAY PAYMENT FAILED: code=${response.code}');

    if (!mounted) return;
    setState(() => _isPaying = false);

    String errorMsg;
    Color bgColor;

    switch (response.code) {
      case Razorpay.NETWORK_ERROR:
        errorMsg = 'Network error. Check internet and try again.';
        bgColor = Colors.orange[700]!;
        break;
      case Razorpay.INVALID_OPTIONS:
        errorMsg = 'Payment configuration error. Please contact support.';
        bgColor = Colors.red[700]!;
        break;
      case Razorpay.PAYMENT_CANCELLED:
        errorMsg = 'Payment cancelled. Tap "Pay" to try again.';
        bgColor = Colors.orange[700]!;
        break;
      case Razorpay.TLS_ERROR:
        errorMsg = 'Security error. Please check your device settings.';
        bgColor = Colors.red[700]!;
        break;
      default:
        errorMsg = response.message?.isNotEmpty == true
            ? response.message!
            : 'Payment failed. Please try again.';
        bgColor = Colors.red[700]!;
    }

    _showSnack(errorMsg, bgColor);
  }

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
        backgroundColor:
            isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        appBar: _paymentSuccess ? null : _buildPremiumAppBar(context, isDark),
        body: _paymentSuccess
            ? _buildSuccessView(isDark)
            : FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: ScaleTransition(
                    scale: _scaleIn,
                    child: _buildPaymentView(context, isDark),
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // PREMIUM APP BAR
  // ============================================================
  PreferredSizeWidget _buildPremiumAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
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
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Text(
            'Pay Rent',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 21,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 12,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 5),
              Text(
                'Secure',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN PAYMENT VIEW
  // ============================================================
  Widget _buildPaymentView(BuildContext context, bool isDark) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountHeroCard(isDark),
                  const SizedBox(height: 20),
                  _buildInvoiceDetailsCard(isDark),
                  const SizedBox(height: 16),
                  _buildWhatYouPayCard(isDark),
                  const SizedBox(height: 16),
                  _buildTrustBadges(isDark),
                ],
              ),
            ),
          ),
          _buildBottomPayButton(isDark),
        ],
      ),
    );
  }

  // ============================================================
  // HERO AMOUNT CARD
  // ============================================================
  Widget _buildAmountHeroCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.38),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            top: -20,
            right: 30,
            child: Icon(
              Icons.home_work_rounded,
              size: 90,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent for',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      Text(
                        widget.invoiceMonth,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Amount Payable',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '₹',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.amount.toStringAsFixed(0),
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Zero platform fees on this payment',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
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

  // ============================================================
  // INVOICE DETAILS CARD
  // ============================================================
  Widget _buildInvoiceDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF2563EB),
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Details',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Billing Month',
            value: widget.invoiceMonth,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _detailRow(
            icon: Icons.tag_rounded,
            label: 'Invoice ID',
            value: '#${widget.invoiceId}',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _detailRow(
            icon: Icons.currency_rupee_rounded,
            label: 'Amount',
            value: '₹${widget.amount.toStringAsFixed(0)}',
            isDark: isDark,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WHAT YOU PAY CARD (breakdown)
  // ============================================================
  Widget _buildWhatYouPayCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22C55E).withOpacity(isDark ? 0.12 : 0.07),
            const Color(0xFF16A34A).withOpacity(isDark ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF16A34A),
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'What you pay',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'INSTANT',
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _priceBreakdownRow(
            'Rent Amount',
            '₹${widget.amount.toStringAsFixed(0)}',
            isDark,
          ),
          const SizedBox(height: 8),
          _priceBreakdownRow(
            'Platform Fee',
            '₹0',
            isDark,
            isFree: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _priceBreakdownRow(
            'Total Payable',
            '₹${widget.amount.toStringAsFixed(0)}',
            isDark,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _priceBreakdownRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    bool isFree = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 13.5 : 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isFree
                ? const Color(0xFF16A34A)
                : (isBold
                    ? const Color(0xFF2563EB)
                    : (isDark ? Colors.white : const Color(0xFF1A1A2E))),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRUST BADGES ROW
  // ============================================================
  Widget _buildTrustBadges(bool isDark) {
    final badges = [
      {
        'icon': Icons.lock_rounded,
        'title': '256-bit SSL',
        'color': const Color(0xFF2563EB),
      },
      {
        'icon': Icons.shield_rounded,
        'title': 'RBI Compliant',
        'color': const Color(0xFF16A34A),
      },
      {
        'icon': Icons.flash_on_rounded,
        'title': 'Instant Payout',
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: badges.map((b) {
          final color = b['color'] as Color;
          return Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    b['icon'] as IconData,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  b['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // BOTTOM PAY BUTTON
  // ============================================================
  Widget _buildBottomPayButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _isPaying
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _isPaying
                      ? (isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFE5E7EB))
                      : null,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isPaying
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.4),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _isPaying ? null : _payNow,
                    child: Center(
                      child: _isPaying
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Processing...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Pay ₹${widget.amount.toStringAsFixed(0)} Securely',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 13,
                  color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  'Powered by Razorpay  •  PCI-DSS Compliant',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS VIEW
  // ============================================================
  Widget _buildSuccessView(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            // Success animation container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value.clamp(0.0, 1.2),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '🎉 Rent Paid!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your ${widget.invoiceMonth} rent has been paid successfully.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            // Receipt card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F33) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _receiptRow(
                    'Property',
                    'Your Rental',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _receiptRow(
                    'Billing Month',
                    widget.invoiceMonth,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _receiptRow(
                    'Amount Paid',
                    '₹${widget.amount.toStringAsFixed(0)}',
                    isDark,
                    isBold: true,
                  ),
                  if (_utr != null) ...[
                    const SizedBox(height: 12),
                    _receiptRow(
                      'Transaction Ref',
                      _utr!,
                      isDark,
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            // Done button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context, true);
                    },
                    child: Center(
                      child: Text(
                        'Done',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold
                  ? const Color(0xFF2563EB)
                  : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
            ),
          ),
        ),
      ],
    );
  }
}