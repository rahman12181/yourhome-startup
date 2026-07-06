import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:yourhome/utils/constants.dart';
import '../../widgets/custom_loading_widget.dart';

class ListingSubscriptionPage extends StatefulWidget {
  final int listingId;
  final String listingTitle;

  const ListingSubscriptionPage({
    super.key,
    required this.listingId,
    required this.listingTitle,
  });

  @override
  State<ListingSubscriptionPage> createState() =>
      _ListingSubscriptionPageState();
}

class _ListingSubscriptionPageState extends State<ListingSubscriptionPage> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  String _selectedPlan = 'basic';

  final Map<String, Map<String, dynamic>> _plans = {
    'basic': {
      'label': 'Basic',
      'price': 199,
      'duration': '30 days',
      'listings': 1,
      'color': const Color(0xFF7C3AED),
      'icon': Icons.assignment_rounded,
      'savings': 0,
    },
    'standard': {
      'label': 'Standard',
      'price': 499,
      'duration': '30 days',
      'listings': 5,
      'color': const Color(0xFF2563EB),
      'icon': Icons.assignment_turned_in_rounded,
      'savings': 496,
    },
    'premium': {
      'label': 'Premium',
      'price': 999,
      'duration': '30 days',
      'listings': 20,
      'color': const Color(0xFF16A34A),
      'icon': Icons.star_rounded, // FIXED: Changed from assignment_special_rounded
      'savings': 2981,
    },
  };

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() => _isLoading = false);
    _showSnackBar('✅ Payment Successful!', 'Your listing subscription is now active.', Colors.green);
    Navigator.pop(context, true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    _showSnackBar('❌ Payment Failed', 'Please try again later.', Colors.red);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isLoading = false);
    _showSnackBar('💳 External Wallet', 'Payment through external wallet selected.', Colors.blue);
  }

  void _startPayment() async {
    setState(() => _isLoading = true);

    try {
      final plan = _plans[_selectedPlan]!;
      final amount = (plan['price'] as int) * 100;

      final options = {
        'key': AppConstants.razorpayKeyId,
        'amount': amount,
        'name': 'YourHome',
        'description': 'Listing Subscription - ${widget.listingTitle}',
        'prefill': {
          'contact': '9876543210',
          'email': 'user@example.com',
        },
        'theme': {
          'color': '#7C3AED',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('⚠️ Error', 'Something went wrong. Please try again.', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        title: Text(
          'Listing Subscription',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListingInfo(isDark),
                const SizedBox(height: 20),
                Text(
                  'Choose Subscription Plan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                ..._plans.entries.map((entry) {
                  return _buildPlanCard(entry.key, entry.value, isDark);
                }).toList(),
                const SizedBox(height: 20),
                _buildFeatures(isDark),
                const SizedBox(height: 24),
                _buildPaymentButton(isDark),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isLoading) const CustomLoadingWidget(message: 'Processing payment...'),
        ],
      ),
    );
  }

  Widget _buildListingInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listingTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Listing ID: #${widget.listingId}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.2)),
            ),
            child: Text(
              'Promote',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String key, Map<String, dynamic> plan, bool isDark) {
    final isSelected = _selectedPlan == key;
    final price = plan['price'] as int;
    final savings = plan['savings'] as int;
    final listings = plan['listings'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF7C3AED).withOpacity(0.05)
            : (isDark ? const Color(0xFF141A2C) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: RadioListTile<String>(
        value: key,
        groupValue: _selectedPlan,
        onChanged: (value) {
          setState(() {
            _selectedPlan = value!;
          });
        },
        activeColor: const Color(0xFF7C3AED),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (plan['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(plan['icon'] as IconData, color: plan['color'] as Color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['label'] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    '$listings listing${listings > 1 ? 's' : ''} • ${plan['duration']}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$price',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                if (savings > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Save ₹$savings',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        subtitle: isSelected
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: const Color(0xFF7C3AED), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Selected plan',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF7C3AED),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildFeatures(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem('Boost listing visibility', isDark),
          _buildFeatureItem('Appear at top of search results', isDark),
          _buildFeatureItem('Get featured badge on listing', isDark),
          _buildFeatureItem('Priority customer support', isDark),
          _buildFeatureItem('Detailed analytics dashboard', isDark),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(bool isDark) {
    final price = _plans[_selectedPlan]!['price'] as int;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Pay ₹$price & Subscribe',
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

  void _showSnackBar(String title, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
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
}