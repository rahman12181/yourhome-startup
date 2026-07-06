import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/owner_provider.dart';

class OwnerBookingManagementPage extends StatefulWidget {
  const OwnerBookingManagementPage({super.key});

  @override
  State<OwnerBookingManagementPage> createState() => _OwnerBookingManagementPageState();
}

class _OwnerBookingManagementPageState extends State<OwnerBookingManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await Provider.of<OwnerProvider>(context, listen: false).getIncomingBookingRequests();
  }

  Future<void> _handleAccept(int requestId) async {
    final ctrl = TextEditingController();
    final response = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accept Request'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write a response message...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (response != null && response.isNotEmpty) {
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      final success = await ownerProvider.acceptBookingRequest(requestId, response);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success ? 'Request accepted' : (ownerProvider.error ?? 'Failed'))));
      }
    }
  }

  Future<void> _handleReject(int requestId) async {
    final ctrl = TextEditingController();
    final response = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write a reason...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (response != null && response.isNotEmpty) {
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      final success = await ownerProvider.rejectBookingRequest(requestId, response);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success ? 'Request rejected' : (ownerProvider.error ?? 'Failed'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Booking Requests', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF1A1F33) : Colors.white,
              child: TabBar(
                tabs: [
                  Tab(child: Text('Pending', style: GoogleFonts.poppins())),
                  Tab(child: Text('Accepted', style: GoogleFonts.poppins())),
                  Tab(child: Text('Rejected', style: GoogleFonts.poppins())),
                ],
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF2563EB),
              ),
            ),
            Expanded(
              child: Consumer<OwnerProvider>(
                builder: (context, ownerProvider, _) {
                  if (ownerProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return TabBarView(
                    children: [
                      _buildBookingList(ownerProvider.pendingRequests, isDark, showActions: true),
                      _buildBookingList(ownerProvider.acceptedRequests, isDark),
                      _buildBookingList(ownerProvider.rejectedRequests, isDark),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingRequest> requests, bool isDark, {bool showActions = false}) {
    if (requests.isEmpty) {
      return Center(child: Text('No requests found', style: GoogleFonts.poppins(color: Colors.grey[600])));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return _buildBookingCard(req, isDark, showActions: showActions);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingRequest req, bool isDark, {bool showActions = false}) {
    Color statusColor;
    switch (req.status) {
      case 'PENDING':
        statusColor = Colors.orange;
        break;
      case 'ACCEPTED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Booking #${req.requestId}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(req.status,
                    style: GoogleFonts.poppins(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Property: ${req.propertyTitle}',
              style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          if (req.roomNumber != null)
            Text('Room: ${req.roomNumber}',
                style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Move-in: ${DateFormat('dd MMM yyyy').format(req.moveInDate)}',
              style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          if (req.durationMonths != null)
            Text('Duration: ${req.durationMonths} months',
                style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          if (req.message != null && req.message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('"${req.message}"',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ],
          if (req.ownerResponse != null && req.ownerResponse!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Text('Your response: ${req.ownerResponse}',
                  style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAccept(req.requestId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(req.requestId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}