// lib/screens/rental/my_rentals_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/rental_provider.dart';
import '../../models/rental_model.dart';
import 'rental_agreement_detail_screen.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RentalProvider>(context, listen: false).fetchMyAgreements();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF22C55E);
      case 'TERMINATED':
        return Colors.grey;
      case 'EXPIRED':
        return const Color(0xFFEF4444);
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final provider = Provider.of<RentalProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121E) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('My Rentals', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchMyAgreements(),
        child: provider.isLoading && provider.agreements.isEmpty
            ? Center(child: CircularProgressIndicator(color: primary))
            : provider.agreements.isEmpty
                ? _buildEmpty(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.agreements.length,
                    itemBuilder: (context, index) {
                      final agreement = provider.agreements[index];
                      return _agreementCard(agreement, isDark, primary);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_work_outlined, size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No active rentals yet',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Once your booking is accepted and paid, your\nrental agreement will show up here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _agreementCard(RentalAgreement agreement, bool isDark, Color primary) {
    final statusColor = _statusColor(agreement.status);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RentalAgreementDetailScreen(agreementId: agreement.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B2F) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    agreement.propertyTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    agreement.status,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (agreement.roomNumber != null)
              Text(
                'Room ${agreement.roomNumber} • ${agreement.agreementCode}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${agreement.monthlyRent.toStringAsFixed(0)}/mo',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'View details',
                      style: GoogleFonts.poppins(fontSize: 12, color: primary, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}