// lib/screens/rental/rental_agreement_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:yourhome/screens/rental/monthly_rent_payment_screen.dart';
import '../../providers/rental_provider.dart';
import '../../models/rental_model.dart';

class RentalAgreementDetailScreen extends StatefulWidget {
  final int agreementId;

  const RentalAgreementDetailScreen({super.key, required this.agreementId});

  @override
  State<RentalAgreementDetailScreen> createState() =>
      _RentalAgreementDetailScreenState();
}

class _RentalAgreementDetailScreenState
    extends State<RentalAgreementDetailScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await Provider.of<RentalProvider>(context, listen: false)
        .fetchAgreementWithInvoices(widget.agreementId);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _confirmTerminate() async {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B1B2F) : Colors.white,
        title: Text('Terminate agreement?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will end your rental agreement. This action cannot be undone.',
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[500]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason (e.g. moving to another city)',
                hintStyle: GoogleFonts.poppins(fontSize: 12.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason')),
      );
      return;
    }

    final provider = Provider.of<RentalProvider>(context, listen: false);
    final result = await provider.terminateAgreement(
      widget.agreementId,
      reasonController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Color _invoiceStatusColor(RentInvoice invoice) {
    if (invoice.isPaid) return const Color(0xFF22C55E);
    if (invoice.isOverdue) return const Color(0xFFEF4444);
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final provider = Provider.of<RentalProvider>(context);
    final agreement = provider.selectedAgreement;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121E) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Rental Agreement', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (agreement != null && agreement.isActive)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              tooltip: 'Terminate',
              onPressed: _confirmTerminate,
            ),
        ],
      ),
      body: _isLoading || agreement == null
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _agreementInfoCard(agreement, isDark, primary),
                  const SizedBox(height: 20),
                  Text(
                    'Monthly Invoices',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (provider.invoices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No invoices generated yet',
                          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12.5),
                        ),
                      ),
                    )
                  else
                    ...provider.invoices.map((inv) => _invoiceCard(inv, isDark, primary)),
                ],
              ),
            ),
    );
  }

  Widget _agreementInfoCard(RentalAgreement agreement, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, primary.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            agreement.propertyTitle,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          if (agreement.roomNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Room ${agreement.roomNumber} • ${agreement.agreementCode}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoChip('Monthly Rent', '₹${agreement.monthlyRent.toStringAsFixed(0)}'),
              const SizedBox(width: 10),
              _infoChip('Deposit', '₹${agreement.securityDeposit.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _infoChip('Start Date', agreement.startDate),
              const SizedBox(width: 10),
              _infoChip('Due Day', '${agreement.rentDueDay}th'),
            ],
          ),
          if (agreement.ownerName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  agreement.ownerName!,
                  style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _invoiceCard(RentInvoice invoice, bool isDark, Color primary) {
    final statusColor = _invoiceStatusColor(invoice);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B2F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.22 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      invoice.invoiceMonth,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        invoice.isPaid ? 'PAID' : (invoice.isOverdue ? 'OVERDUE' : 'DUE'),
                        style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Due: ${invoice.dueDate}',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${invoice.totalPayable.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: primary),
              ),
              const SizedBox(height: 6),
              if (!invoice.isPaid)
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MonthlyRentPaymentScreen(
                            invoiceId: invoice.id,
                            invoiceMonth: invoice.invoiceMonth,
                            amount: invoice.totalPayable,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        Provider.of<RentalProvider>(context, listen: false)
                            .refreshInvoices();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Pay Now', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}