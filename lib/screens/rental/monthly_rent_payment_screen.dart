// lib/screens/payment/monthly_rent_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../providers/rental_provider.dart';
import '../../providers/auth_provider.dart';

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

class _MonthlyRentPaymentScreenState extends State<MonthlyRentPaymentScreen> {
  Razorpay? _razorpay;
  bool _isPaying = false;
  bool _paymentSuccess = false;
  String? _utr;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _payNow() async {
    setState(() => _isPaying = true);

    final rentalProvider = Provider.of<RentalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final initiateResult = await rentalProvider.initiateMonthlyRent(widget.invoiceId);

    if (initiateResult['success'] != true) {
      setState(() => _isPaying = false);
      _showSnack(initiateResult['message'] ?? 'Failed to start payment', Colors.red);
      return;
    }

    final data = initiateResult['data'];
    // ⚠️ NOTE: the backend doc for 17.5 shows `amount` as the same rupee
    // value as the invoice (e.g. 6000.00), unlike the other Razorpay
    // order-creation endpoints (3.4 / 11.1 / 14.2) which explicitly return
    // amount in *paise*. Razorpay Checkout always needs paise. Confirm
    // with your backend team which one /user/monthly-rent/initiate/{id}
    // actually returns — this assumes paise (consistent with every other
    // payment endpoint in the docs). If the backend truly returns rupees,
    // remove the `* 100` below.
    final amountInPaise = (data.amount * 100).round();

    var options = {
      'key': 'rzp_live_YOUR_KEY_HERE', // same Razorpay key used elsewhere
      'amount': amountInPaise,
      'currency': 'INR',
      'order_id': data.razorpayOrderId,
      'name': 'Nestora',
      'description': 'Rent for ${widget.invoiceMonth}',
      'prefill': {
        'contact': authProvider.user?.phone ?? '',
        'email': authProvider.user?.email ?? '',
      },
      'theme': {'color': '#2563EB'},
    };

    _razorpay!.open(options);
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final rentalProvider = Provider.of<RentalProvider>(context, listen: false);

    final result = await rentalProvider.confirmMonthlyRent(
      razorpayOrderId: response.orderId!,
      razorpayPaymentId: response.paymentId!,
      razorpaySignature: response.signature!,
    );

    if (!mounted) return;
    setState(() => _isPaying = false);

    if (result['success'] == true) {
      setState(() {
        _paymentSuccess = true;
        _utr = result['data']?.payoutTransactionRef;
      });
    } else {
      _showSnack(result['message'] ?? 'Payment confirmation failed', Colors.red);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isPaying = false);
    _showSnack('Payment failed: ${response.message}', Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    if (_paymentSuccess) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 56, color: Color(0xFF22C55E)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Rent Paid!',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.invoiceMonth} rent of ₹${widget.amount.toStringAsFixed(0)} has been paid.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                  ),
                  if (_utr != null) ...[
                    const SizedBox(height: 4),
                    Text('Ref: $_utr', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Done', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Pay Rent', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F33) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rent for', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[500])),
                  const SizedBox(height: 2),
                  Text(
                    widget.invoiceMonth,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black),
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount Payable',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
                      Text(
                        '₹${widget.amount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isPaying ? null : _payNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isPaying
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(
                        'Pay ₹${widget.amount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '🔒 Secure payment via Razorpay',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}