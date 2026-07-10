import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:yourhome/providers/owner_provider.dart';
import 'package:yourhome/utils/constants.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../models/owner_model.dart';

class PropertyAccessSubscriptionPage extends StatefulWidget {
  final int propertyId;
  final String propertyTitle;

  const PropertyAccessSubscriptionPage({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  State<PropertyAccessSubscriptionPage> createState() =>
      _PropertyAccessSubscriptionPageState();
}

class _PropertyAccessSubscriptionPageState
    extends State<PropertyAccessSubscriptionPage> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  String? _selectedPlanCode;
  List<PropertyAccessPlan> _plans = [];
  bool _isFetching = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() {
      _isFetching = true;
      _error = null;
    });

    try {
      final provider = Provider.of<OwnerProvider>(context, listen: false);

      if (provider.propertyAccessPlans.isNotEmpty) {
        setState(() {
          _plans = provider.propertyAccessPlans;
          if (_plans.isNotEmpty) {
            _selectedPlanCode = _plans.first.code;
          }
          _isFetching = false;
        });
        return;
      }

      await provider.getPropertyAccessPlans();

      if (mounted) {
        setState(() {
          _plans = provider.propertyAccessPlans;
          if (_plans.isNotEmpty) {
            _selectedPlanCode = _plans.first.code;
          }
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load plans. Please try again.';
          _isFetching = false;
        });
      }
    }
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = false);

    try {
      final provider = Provider.of<OwnerProvider>(context, listen: false);

      final success = await provider.confirmPropertyAccessSubscription(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        plan: _selectedPlanCode!,
      );

      if (success && mounted) {
        _showSnackBar(
          'Subscription Activated!',
          'Your property access subscription is now active.',
          Colors.green,
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        _showSnackBar(
          'Payment Confirmation Failed',
          provider.error ?? 'Please contact support.',
          Colors.orange,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error',
          'Failed to confirm payment. Please contact support.',
          Colors.red,
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    _showSnackBar(
      'Payment Failed',
      response.message ?? 'Please try again later.',
      Colors.red,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isLoading = false);
    _showSnackBar(
      'External Wallet',
      'Payment through external wallet selected.',
      Colors.blue,
    );
  }

  void _startPayment() async {
    if (_selectedPlanCode == null) {
      _showSnackBar('Error', 'Please select a plan first.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<OwnerProvider>(context, listen: false);

      final selectedPlan = _plans.firstWhere(
        (plan) => plan.code == _selectedPlanCode,
      );

      final order = await provider.buyPropertyAccessSubscription(
        selectedPlan.code,
      );

      if (order == null) {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed',
          provider.error ?? 'Could not create order. Please try again.',
          Colors.red,
        );
        return;
      }

      final options = {
        'key': AppConstants.razorpayKeyId,
        'amount': order.amount,
        'currency': order.currency,
        'order_id': order.razorpayOrderId,
        'name': AppConstants.appName,
        'description': 'Property Access Subscription - ${widget.propertyTitle}',
        'prefill': {
          'contact': provider.ownerProfile?.phone ?? '9876543210',
          'email': provider.ownerProfile?.email ?? 'user@example.com',
        },
        'theme': {
          'color': '#7C3AED',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        'Error',
        'Something went wrong. Please try again.',
        Colors.red,
      );
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
          'Property Access',
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
      body: SafeArea(
        child:_isFetching
          ? const Center(child: CustomLoadingWidget(message: 'Loading plans...'))
          : _error != null
              ? _buildErrorWidget(isDark)
              : _plans.isEmpty
                  ? _buildEmptyWidget(isDark)
                  : _buildBody(isDark),
    ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPlans,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Plans Available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyInfo(isDark),
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
              ..._plans.map((plan) => _buildPlanCard(plan, isDark)),
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
    );
  }

  Widget _buildPropertyInfo(bool isDark) {
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
            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.propertyTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Property ID: #${widget.propertyId}',
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
              'Access',
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

  Widget _buildPlanCard(PropertyAccessPlan plan, bool isDark) {
    final isSelected = _selectedPlanCode == plan.code;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? plan.color.withOpacity(0.05)
            : (isDark ? const Color(0xFF141A2C) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? plan.color
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: plan.color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: RadioListTile<String>(
        value: plan.code,
        groupValue: _selectedPlanCode,
        onChanged: (value) {
          setState(() {
            _selectedPlanCode = value!;
          });
        },
        activeColor: plan.color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: plan.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(plan.icon, color: plan.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    plan.displayDuration,
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
                  plan.displayPrice,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                if (plan.isBestValue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Best Value',
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
                    Icon(Icons.check_circle_rounded, color: plan.color, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Selected plan',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: plan.color,
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
            'What you get:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem('Full access to property details', isDark),
          _buildFeatureItem('View all room information', isDark),
          _buildFeatureItem('Contact owner directly', isDark),
          _buildFeatureItem('Schedule property visits', isDark),
          _buildFeatureItem('Get notified about updates', isDark),
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
    final selectedPlan = _plans.firstWhere(
      (plan) => plan.code == _selectedPlanCode,
      orElse: () => _plans.first,
    );

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
              'Pay ${selectedPlan.displayPrice} & Subscribe',
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