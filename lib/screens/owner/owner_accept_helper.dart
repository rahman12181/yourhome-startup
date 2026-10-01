import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/room_model.dart';
import '../../providers/owner_provider.dart';
import '../../services/owner_service.dart';
import '../../services/room_management_service.dart';

/// Accept flow for owner.
/// - Booking already has a room  -> normal accept (existing provider flow)
/// - Student asked "any room"    -> owner picks a room with a free bed first
class OwnerAcceptHelper {
  static final RoomManagementService _roomService = RoomManagementService();

  /// Returns true when the request was accepted.
  static Future<bool> accept(
    BuildContext context,
    BookingRequest booking,
    String responseMsg,
  ) async {
    final provider = Provider.of<OwnerProvider>(context, listen: false);

    // 1) Room already chosen by the student
    if (booking.roomId != null) {
      final ok =
          await provider.acceptBookingRequest(booking.requestId, responseMsg);
      if (!ok && context.mounted) {
        _snack(context, provider.error ?? 'Could not accept request',
            error: true);
      }
      return ok;
    }

    // 2) "Any available room" -> owner must assign one
    final roomId = await _pickRoom(context, booking);
    if (roomId == null) return false; // cancelled

    final res = await _roomService.acceptBooking(
      booking.requestId,
      responseMsg,
      roomId: roomId,
    );

    if (res.success) {
      provider.getIncomingBookingRequests(showLoader: false);
      provider.loadBookingStats();
      provider.loadUnreadBookingCount();
      return true;
    }

    if (context.mounted) _snack(context, res.message, error: true);
    return false;
  }

  static Future<int?> _pickRoom(
      BuildContext context, BookingRequest booking) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomPickerSheet(booking: booking),
    );
  }

  static void _snack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor:
            error ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _RoomPickerSheet extends StatefulWidget {
  final BookingRequest booking;
  const _RoomPickerSheet({required this.booking});

  @override
  State<_RoomPickerSheet> createState() => _RoomPickerSheetState();
}

class _RoomPickerSheetState extends State<_RoomPickerSheet> {
  late Future<List<Room>> _future;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Room>> _load() async {
    final res = await OwnerService().getOwnerRooms(widget.booking.propertyId);
    if (!res.success || res.data == null) return [];
    // only rooms that can really take one more student
    return res.data!
        .where((r) => !r.isUnderMaintenance && r.hasAvailableBeds)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const purple = Color(0xFF7C3AED);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE0E0E8),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Assign a room',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.booking.studentName ?? 'The student'} asked for any '
            'available room. Pick one with a free bed.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: FutureBuilder<List<Room>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                        child: CircularProgressIndicator(color: purple)),
                  );
                }
                final rooms = snap.data ?? [];
                if (rooms.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No room has a free bed right now.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : const Color(0xFF666680),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  itemBuilder: (_, i) {
                    final r = rooms[i];
                    final sel = _selected == r.roomId;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = r.roomId),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: sel
                              ? purple.withOpacity(0.08)
                              : (isDark
                                  ? const Color(0xFF1A1F33)
                                  : const Color(0xFFF8F9FC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel
                                ? purple
                                : (isDark
                                    ? Colors.white12
                                    : const Color(0xFFE8E8F0)),
                            width: sel ? 1.8 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sel
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: sel ? purple : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room ${r.roomNumber ?? r.roomId} • ${r.roomTypeDisplay}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    r.availabilityLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: const Color(0xFF22C55E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${r.monthlyRent.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Assign & Accept',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}