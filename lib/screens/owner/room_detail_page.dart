import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/room_detail_model.dart';
import '../../models/bulk_room_model.dart';
import '../../services/room_management_service.dart';

class RoomDetailPage extends StatefulWidget {
  final int propertyId;
  final int roomId;
  final String roomLabel;

  const RoomDetailPage({
    super.key,
    required this.propertyId,
    required this.roomId,
    required this.roomLabel,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final RoomManagementService _service = RoomManagementService();

  RoomDetail? _detail;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  static const _purple = Color(0xFF7C3AED);
  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);
  static const _blue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ================= DATA =================
  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await _service.getRoomDetail(widget.propertyId, widget.roomId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _detail = res.data;
        _error = null;
      } else {
        _error = res.message;
      }
    });
  }

  Future<void> _toggleMaintenance() async {
    final d = _detail;
    if (d == null) return;
    final enable = !d.isMaintenance;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          enable ? 'Put under maintenance?' : 'Resume bookings?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          enable
              ? 'Students will not be able to book ${d.title} until you resume it.'
              : '${d.title} will be open for bookings again.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              enable ? 'Yes, pause' : 'Yes, resume',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: enable ? _amber : _green,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    final res =
        await _service.setMaintenance(widget.propertyId, widget.roomId, enable);
    if (!mounted) return;
    setState(() => _busy = false);

    if (res.success) {
      _snack(enable ? 'Room moved to maintenance' : 'Room is available again');
      _load(silent: true);
    } else {
      _snack(res.message, error: true);
    }
  }

  // ================= HELPERS =================
  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: error ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _date(DateTime? d) =>
      d == null ? '-' : '${d.day} ${_months[d.month - 1]} ${d.year}';

  String _dateTime(DateTime? d) {
    if (d == null) return '-';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '${_date(d)}, $h:$m $ap';
  }

  Color _statusColor(RoomDetail d) {
    if (d.isMaintenance) return _amber;
    if (d.isFull) return _red;
    if (d.occupiedCount > 0) return _blue;
    return _green;
  }

  Future<void> _call(String phone) async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (_) {
      _snack('Could not open dialer', error: true);
    }
  }

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('$what copied');
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildBody(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context), isDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detail?.title ?? widget.roomLabel,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  _detail?.propertyTitle ?? 'Room details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ],
            ),
          ),
          _circleBtn(Icons.refresh_rounded, () => _load(), isDark),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE8E8F0),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading && _detail == null) {
      return const Center(
        child: CircularProgressIndicator(color: _purple),
      );
    }

    if (_detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Could not load room',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : const Color(0xFF666680),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Retry', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

    final d = _detail!;

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: _purple,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
        children: [
          _buildSummaryCard(d, isDark),
          const SizedBox(height: 18),
          _sectionTitle('Beds', '${d.occupiedCount}/${d.capacity} filled', isDark),
          const SizedBox(height: 10),
          _buildBeds(d, isDark),
          const SizedBox(height: 18),
          _sectionTitle('Current Tenants', '${d.occupants.length}', isDark),
          const SizedBox(height: 10),
          if (d.occupants.isEmpty)
            _emptyNote('No tenants yet. A tenant appears here automatically '
                'after they book and pay.', isDark)
          else
            ...d.occupants.map((o) => _tenantCard(o, isDark)),
          if (d.pendingHolds.isNotEmpty) ...[
            const SizedBox(height: 18),
            _sectionTitle('Awaiting Payment', '${d.pendingHolds.length}', isDark),
            const SizedBox(height: 10),
            ...d.pendingHolds.map((h) => _holdCard(h, isDark)),
          ],
          if (d.pastOccupants.isNotEmpty) ...[
            const SizedBox(height: 18),
            _sectionTitle('Past Tenants', '${d.pastOccupants.length}', isDark),
            const SizedBox(height: 10),
            ...d.pastOccupants.map((o) => _pastCard(o, isDark)),
          ],
          const SizedBox(height: 22),
          _buildMaintenanceCard(d, isDark),
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _buildSummaryCard(RoomDetail d, bool isDark) {
    final color = _statusColor(d);
    final typeColor = RoomTypeInfo.color(d.roomType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F0F8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  RoomTypeInfo.label(d.roomType),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  d.availabilityLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₹${d.monthlyRent.toStringAsFixed(0)} / month',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.layers_rounded, 'Floor ${d.floorNumber ?? 0}', _purple),
              _chip(Icons.bed_rounded, '${d.capacity} bed${d.capacity == 1 ? '' : 's'}', _blue),
              if (d.hasAc) _chip(Icons.ac_unit_rounded, 'AC', _blue),
              if (d.hasAttachedBathroom)
                _chip(Icons.bathtub_rounded, 'Attached Bath', const Color(0xFF8B5CF6)),
            ],
          ),
          if (d.description != null && d.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              d.description!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.5,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String trailing, bool isDark) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            trailing,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _purple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyNote(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F0F8),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          height: 1.5,
          color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
        ),
      ),
    );
  }

  // ================= BEDS =================
  Widget _buildBeds(RoomDetail d, bool isDark) {
    final tileWidth = (MediaQuery.of(context).size.width - 32 - 10) / 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: d.beds.map((bed) {
        late Color c;
        late IconData icon;
        late String subtitle;
        switch (bed.state) {
          case 'OCCUPIED':
            c = _purple;
            icon = Icons.person_rounded;
            subtitle = bed.occupantName ?? 'Occupied';
            break;
          case 'HELD':
            c = _amber;
            icon = Icons.hourglass_top_rounded;
            subtitle = '${bed.occupantName ?? 'Student'} • pay pending';
            break;
          case 'UNAVAILABLE':
            c = Colors.grey;
            icon = Icons.block_rounded;
            subtitle = 'Maintenance';
            break;
          default:
            c = _green;
            icon = Icons.bed_outlined;
            subtitle = 'Empty';
        }

        return SizedBox(
          width: tileWidth,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.withOpacity(isDark ? 0.14 : 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: c, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bed ${bed.bedNumber}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: c,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= TENANTS =================
  Widget _tenantCard(RoomOccupantInfo o, bool isDark) {
    final paid = (o.paymentStatus ?? '').toUpperCase() == 'PAID';
    final hasPic = o.profilePic != null && o.profilePic!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F0F8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _purple.withOpacity(0.15),
                backgroundImage: hasPic ? NetworkImage(o.profilePic!) : null,
                child: hasPic
                    ? null
                    : Text(
                        o.name.isNotEmpty ? o.name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: _purple,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    if (o.displayId != null)
                      Text(
                        o.displayId!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (paid ? _green : _amber).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  paid ? 'PAID' : (o.paymentStatus ?? 'PENDING'),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: paid ? _green : _amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (o.phone != null && o.phone!.isNotEmpty)
            _infoRow(
              Icons.phone_rounded,
              o.phone!,
              isDark,
              onTap: () => _call(o.phone!),
              onLongPress: () => _copy(o.phone!, 'Phone number'),
              accent: _green,
            ),
          if (o.email != null && o.email!.isNotEmpty)
            _infoRow(
              Icons.email_outlined,
              o.email!,
              isDark,
              onLongPress: () => _copy(o.email!, 'Email'),
            ),
          _infoRow(Icons.event_available_rounded,
              'Move-in: ${_date(o.moveInDate)}', isDark),
          if (o.durationMonths != null)
            _infoRow(Icons.timelapse_rounded,
                'Stay: ${o.durationMonths} month${o.durationMonths == 1 ? '' : 's'}', isDark),
          if (o.amountPaid != null)
            _infoRow(
              Icons.currency_rupee_rounded,
              'Paid ₹${o.amountPaid!.toStringAsFixed(0)} • ${_dateTime(o.paidAt)}',
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
    bool isDark, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? accent,
  }) {
    final c = accent ?? (isDark ? Colors.white60 : const Color(0xFF666680));
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accent ?? const Color(0xFF8A8FA3)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: onTap != null ? FontWeight.w600 : FontWeight.w500,
                  color: c,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _holdCard(RoomHoldInfo h, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: _amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.studentName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Accepted ${_dateTime(h.acceptedAt)}\n'
                  'Bed reserved until ${_dateTime(h.holdExpiresAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.5,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ],
            ),
          ),
          if (h.studentPhone != null && h.studentPhone!.isNotEmpty)
            IconButton(
              onPressed: () => _call(h.studentPhone!),
              icon: const Icon(Icons.phone_rounded, color: _green, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _pastCard(RoomOccupantInfo o, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F0F8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 18, color: Color(0xFF8A8FA3)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  '${_date(o.movedInAt)}  →  ${_date(o.vacatedAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MAINTENANCE =================
  Widget _buildMaintenanceCard(RoomDetail d, bool isDark) {
    final enabled = d.isMaintenance;
    final color = enabled ? _green : _amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                'Maintenance',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            enabled
                ? 'This room is paused. Students cannot book it.'
                : 'Occupancy updates automatically. This is the only thing you '
                    'need to set manually, and only when the room is empty.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.5,
              color: isDark ? Colors.white60 : const Color(0xFF666680),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _toggleMaintenance,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(enabled ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 18),
              label: Text(
                enabled ? 'Resume bookings' : 'Put under maintenance',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}