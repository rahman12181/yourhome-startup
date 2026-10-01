import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/room_model.dart';
import '../../providers/owner_provider.dart';
import 'bulk_add_rooms_page.dart';
import 'room_detail_page.dart';

// ══════════════════════════════════════════════════════════════
// DESIGN TOKENS — Blue premium (matches other owner pages)
// ══════════════════════════════════════════════════════════════
class _C {
  static const accent = Color(0xFF2563EB);
  static const accentDark = Color(0xFF1D4ED8);
  static const accentLight = Color(0xFF3B82F6);
  static const accentSoft = Color(0xFFEBF1FF);
  static const ink = Color(0xFF0F172A);

  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const teal = Color(0xFF14B8A6);
  static const purple = Color(0xFF8B5CF6);

  // Dark (unchanged)
  static const darkBg = Color(0xFF0B1020);
  static const darkSurface = Color(0xFF131A2E);
  static const darkSurfaceAlt = Color(0xFF1C2540);

  // Light (blue-tinted)
  static const lightBg = Color(0xFFF6F8FC);
  static const lightBorder = Color(0xFFE5EAF3);
  static const lightText = Color(0xFF0F172A);
  static const lightTextSec = Color(0xFF64748B);
  static const lightTextTer = Color(0xFF94A3B8);

  static Color bg(bool d) => d ? darkBg : lightBg;
  static Color surface(bool d) => d ? darkSurface : Colors.white;
  static Color surfaceAlt(bool d) => d ? darkSurfaceAlt : const Color(0xFFF1F4FA);
  static Color border(bool d) => d ? Colors.white.withOpacity(0.07) : lightBorder;
  static Color text(bool d) => d ? Colors.white : lightText;
  static Color textSec(bool d) => d ? Colors.white60 : lightTextSec;
  static Color textTer(bool d) => d ? Colors.white38 : lightTextTer;

  static Color accentSoftBg(bool d) => d ? accent.withOpacity(0.15) : accentSoft;
}

class PropertyRoomsPage extends StatefulWidget {
  final Property property;
  const PropertyRoomsPage({super.key, required this.property});

  @override
  State<PropertyRoomsPage> createState() => _PropertyRoomsPageState();
}

class _PropertyRoomsPageState extends State<PropertyRoomsPage>
    with TickerProviderStateMixin {
  bool _isFirstLoad = true;
  late AnimationController _fadeController;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    )..forward();

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadRooms();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    await Provider.of<OwnerProvider>(context, listen: false)
        .getRooms(widget.property.propertyId);
    if (mounted) _staggerController.forward(from: 0);
  }

  double _bottomPad(BuildContext ctx) => MediaQuery.of(ctx).padding.bottom;

  // ================= ADD CHOOSER =================
  Future<void> _openAddChooser() async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + _bottomPad(ctx)),
        decoration: BoxDecoration(
          color: _C.surface(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE0E0E8),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Rooms',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: _C.text(isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.property.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _C.textSec(isDark),
              ),
            ),
            const SizedBox(height: 20),
            _chooserTile(
              value: 'bulk',
              label: 'Add rooms in bulk',
              subtitle: 'Create 10, 20 or 40 rooms in one go',
              icon: Icons.dynamic_feed_rounded,
              color: _C.accent,
              badge: 'Recommended',
              isDark: isDark,
            ),
            _chooserTile(
              value: 'single',
              label: 'Add a single room',
              subtitle: 'Add one room with custom details',
              icon: Icons.add_home_work_rounded,
              color: _C.teal,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (choice == 'single') {
      _openRoomSheet();
    } else if (choice == 'bulk') {
      _openBulkAdd();
    }
  }

  Widget _chooserTile({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    String? badge,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.30), width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _C.text(isDark),
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: _C.textSec(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _openBulkAdd() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BulkAddRoomsPage(property: widget.property),
      ),
    );
    if (created == true && mounted) _loadRooms();
  }

  Future<void> _openRoomDetail(Room room) async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(
          propertyId: widget.property.propertyId,
          roomId: room.roomId,
          roomLabel: 'Room ${room.roomNumber ?? room.roomId}',
        ),
      ),
    );
    if (mounted) _loadRooms();
  }

  void _openRoomSheet({Room? room}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomFormSheet(
        propertyId: widget.property.propertyId,
        room: room,
      ),
    ).then((success) {
      if (success == true) _loadRooms();
    });
  }

  Future<void> _confirmDelete(Room room) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _C.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _C.danger.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _C.danger,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Room?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: _C.text(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Room ${room.roomNumber ?? room.roomId} will be permanently removed. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: _C.textSec(isDark),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: _C.border(isDark)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _C.textSec(isDark),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      final ok = await ownerProvider.deleteRoom(
        widget.property.propertyId,
        room.roomId,
      );
      if (!mounted) return;
      if (ok) {
        _showSnack('Room deleted');
        _loadRooms();
      } else {
        _showSnack(ownerProvider.error ?? 'Could not delete room', error: true);
      }
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: error ? _C.danger : _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _C.bg(isDark),
      body: SafeArea(
        child: Consumer<OwnerProvider>(
          builder: (context, provider, _) {
            final rooms = provider.rooms;

            final total = rooms.length;
            final available =
                rooms.where((r) => r.status == 'AVAILABLE').length;
            final occupied = rooms.where((r) => r.status == 'OCCUPIED').length;
            final maintenance =
                rooms.where((r) => r.status == 'MAINTENANCE').length;
            final totalBeds = rooms.fold<int>(0, (s, r) => s + r.capacity);
            final filledBeds = rooms.fold<int>(0, (s, r) => s + r.occupiedCount);

            return Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadRooms,
                    color: _C.accent,
                    backgroundColor: _C.surface(isDark),
                    child: provider.isLoading && rooms.isEmpty
                        ? _buildSkeleton(isDark)
                        : rooms.isEmpty
                            ? _buildEmptyState(isDark)
                            : FadeTransition(
                                opacity: _fadeController,
                                child: ListView(
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 4, 14, 100),
                                  children: [
                                    _buildStatsRow(
                                      isDark,
                                      total,
                                      available,
                                      occupied,
                                      maintenance,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildBedSummary(
                                        isDark, filledBeds, totalBeds),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Text(
                                          'All Rooms',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            letterSpacing: -0.2,
                                            color: _C.text(isDark),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _C.accentSoftBg(isDark),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          child: Text(
                                            '${rooms.length}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _C.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...List.generate(rooms.length, (i) {
                                      final delay = (i * 0.06).clamp(0.0, 0.6);
                                      return AnimatedBuilder(
                                        animation: _staggerController,
                                        builder: (context, child) {
                                          final t = Curves.easeOutCubic
                                              .transform(((_staggerController
                                                          .value -
                                                      delay)
                                                  .clamp(0.0, 1.0))
                                              .toDouble());
                                          return Transform.translate(
                                            offset: Offset(0, 20 * (1 - t)),
                                            child: Opacity(
                                                opacity: t, child: child),
                                          );
                                        },
                                        child: _buildRoomCard(
                                            context, rooms[i], isDark),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(isDark),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          _circleIconBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
            isDark: isDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Management',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    letterSpacing: -0.3,
                    color: _C.text(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: _C.textSec(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _C.surface(isDark),
          shape: BoxShape.circle,
          border: Border.all(color: _C.border(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: _C.text(isDark)),
      ),
    );
  }

  // ================= FAB =================
  Widget _buildFab(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.accent, _C.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.accent.withOpacity(0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openAddChooser,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Add Rooms',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= STATS ROW =================
  Widget _buildStatsRow(bool isDark, int total, int available, int occupied,
      int maintenance) {
    return Row(
      children: [
        _statCard('Total', total, Icons.meeting_room_rounded, _C.accent, isDark),
        const SizedBox(width: 8),
        _statCard('Open', available, Icons.check_circle_rounded, _C.success,
            isDark),
        const SizedBox(width: 8),
        _statCard('Full', occupied, Icons.person_rounded, _C.danger, isDark),
        const SizedBox(width: 8),
        _statCard('Repair', maintenance, Icons.build_rounded, _C.warning,
            isDark),
      ],
    );
  }

  Widget _statCard(
      String label, int value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: _C.surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                height: 1,
                color: _C.text(isDark),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _C.textSec(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ BED SUMMARY
  Widget _buildBedSummary(bool isDark, int filled, int total) {
    final ratio = total == 0 ? 0.0 : filled / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                  color: _C.accentSoftBg(isDark),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bed_rounded,
                    size: 14, color: _C.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$filled of $total beds filled',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: _C.text(isDark),
                  ),
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _C.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor:
                  isDark ? Colors.white12 : const Color(0xFFE8E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_C.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ROOM CARD =================
  Widget _buildRoomCard(BuildContext context, Room room, bool isDark) {
    final Color color;
    final String label;
    final IconData icon;

    if (room.isUnderMaintenance) {
      color = _C.warning;
      label = 'Maintenance';
      icon = Icons.build_rounded;
    } else if (room.isFull) {
      color = _C.danger;
      label = 'Fully Booked';
      icon = Icons.person_rounded;
    } else if (room.isPartiallyOccupied) {
      color = _C.accent;
      label = room.availabilityLabel;
      icon = Icons.people_alt_rounded;
    } else {
      color = _C.success;
      label = room.availabilityLabel;
      icon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openRoomDetail(room),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.20)),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Room ${room.roomNumber ?? room.roomId}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                    color: _C.text(isDark),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _C.accentSoftBg(isDark),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  room.roomType,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: _C.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Floor ${room.floorNumber ?? 0} • Capacity ${room.capacity}',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: _C.textSec(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: color.withOpacity(0.30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bed bar
                _bedBar(room, color, isDark),

                const SizedBox(height: 14),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _miniTag(
                      '₹${room.monthlyRent.toStringAsFixed(0)}/mo',
                      Icons.currency_rupee_rounded,
                      _C.accent,
                      isDark,
                    ),
                    if (room.hasAc)
                      _miniTag('AC', Icons.ac_unit_rounded, _C.info, isDark),
                    if (room.hasAttachedBathroom)
                      _miniTag('Attached Bath', Icons.bathtub_rounded,
                          _C.purple, isDark),
                  ],
                ),

                if (room.description != null &&
                    room.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    room.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: _C.textSec(isDark),
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.groups_rounded,
                        label: 'Details',
                        color: _C.accent,
                        isDark: isDark,
                        onTap: () => _openRoomDetail(room),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: _C.info,
                        isDark: isDark,
                        onTap: () => _openRoomSheet(room: room),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        color: _C.danger,
                        isDark: isDark,
                        onTap: () => _confirmDelete(room),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Enhanced bed bar with rounded segments
  Widget _bedBar(Room room, Color color, bool isDark) {
    final segments = room.capacity.clamp(1, 12);
    final trackColor = isDark ? Colors.white12 : const Color(0xFFE8EDF5);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(segments, (i) {
              final filled = i < room.occupiedCount;
              return Expanded(
                child: Container(
                  height: 7,
                  margin: EdgeInsets.only(right: i < segments - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    gradient: filled
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.85)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: filled ? null : trackColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${room.occupiedCount}/${room.capacity}',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: _C.textSec(isDark),
          ),
        ),
      ],
    );
  }

  Widget _miniTag(String label, IconData icon, Color color, bool isDark) {
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

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.20), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SKELETON =================
  Widget _buildSkeleton(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      children: [
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                height: 86,
                decoration: BoxDecoration(
                  color: _C.surface(isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: _C.surface(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 170,
            decoration: BoxDecoration(
              color: _C.surface(isDark),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  // ================= EMPTY =================
  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.accent.withOpacity(0.10),
                border: Border.all(color: _C.accent.withOpacity(0.15), width: 2),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 56,
                color: _C.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Rooms Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: _C.text(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add all your rooms at once in bulk,\nor one by one, so students can book them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: _C.textSec(isDark),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _openAddChooser,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.accent, _C.accentLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _C.accent.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Add Rooms',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// ==================== ROOM FORM BOTTOM SHEET ======================
// ===================================================================
class _RoomFormSheet extends StatefulWidget {
  final int propertyId;
  final Room? room;
  const _RoomFormSheet({required this.propertyId, this.room});

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roomNumberCtrl;
  late TextEditingController _rentCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _floorCtrl;
  late TextEditingController _descCtrl;
  String _roomType = 'SINGLE';
  bool _hasAc = false;
  bool _hasBathroom = false;
  bool _loading = false;

  final List<String> _roomTypes = ['SINGLE', 'DOUBLE', 'TRIPLE', 'DORMITORY'];

  bool get _isEdit => widget.room != null;

  static const Map<String, int> _fixedBeds = {
    'SINGLE': 1,
    'DOUBLE': 2,
    'TRIPLE': 3,
  };

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _roomNumberCtrl = TextEditingController(text: r?.roomNumber ?? '');
    _rentCtrl = TextEditingController(
        text: r?.monthlyRent.toStringAsFixed(0) ?? '');
    _capacityCtrl =
        TextEditingController(text: r?.capacity.toString() ?? '1');
    _floorCtrl =
        TextEditingController(text: r?.floorNumber?.toString() ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    if (r != null) {
      _roomType = r.roomType;
      _hasAc = r.hasAc;
      _hasBathroom = r.hasAttachedBathroom;
    }
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _rentCtrl.dispose();
    _capacityCtrl.dispose();
    _floorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onTypeSelected(String type) {
    setState(() {
      _roomType = type;
      final beds = _fixedBeds[type];
      if (beds != null) {
        _capacityCtrl.text = '$beds';
      } else if ((int.tryParse(_capacityCtrl.text) ?? 0) < 4) {
        _capacityCtrl.text = '4';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final body = <String, dynamic>{
      'roomNumber': _roomNumberCtrl.text.trim(),
      'monthlyRent': double.tryParse(_rentCtrl.text) ?? 0,
      'capacity': int.tryParse(_capacityCtrl.text) ?? 1,
      'hasAc': _hasAc,
      'hasAttachedBathroom': _hasBathroom,
      if (_floorCtrl.text.isNotEmpty)
        'floorNumber': int.tryParse(_floorCtrl.text),
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text.trim(),
      'roomType': _roomType,
    };

    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);

    final success = _isEdit
        ? await ownerProvider.updateRoom(
            widget.propertyId, widget.room!.roomId, body)
        : await ownerProvider.addRoom(widget.propertyId, body);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Room updated successfully' : 'Room added successfully',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: _C.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ownerProvider.error ?? 'Something went wrong',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: _C.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final capacityLocked = !_isEdit && _roomType != 'DORMITORY';

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE0E0E8),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_C.accent, _C.accentLight],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _C.accent.withOpacity(0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isEdit ? Icons.edit_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Room' : 'Add New Room',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: _C.text(isDark),
                          ),
                        ),
                        Text(
                          'Fill room details below',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: _C.textSec(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(
                      Icons.close_rounded,
                      color: _C.textSec(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    24 + _bottomPad(context),
                  ),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _sectionTitle('Basic Details', isDark),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _roomNumberCtrl,
                      label: 'Room Number',
                      hint: 'e.g. 101',
                      icon: Icons.numbers_rounded,
                      isDark: isDark,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _roomTypeSelector(isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: _rentCtrl,
                            label: 'Monthly Rent (₹)',
                            hint: '6000',
                            icon: Icons.currency_rupee_rounded,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            controller: _capacityCtrl,
                            label: capacityLocked ? 'Beds (auto)' : 'Beds',
                            hint: '1',
                            icon: Icons.people_rounded,
                            isDark: isDark,
                            readOnly: capacityLocked,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null || n < 1) return 'Required';
                              if (!_isEdit && _roomType == 'DORMITORY' && n < 4) {
                                return 'Min 4';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _floorCtrl,
                      label: 'Floor Number',
                      hint: 'e.g. 0',
                      icon: Icons.stairs_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Features', isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _featureToggle(
                            icon: Icons.ac_unit_rounded,
                            label: 'AC',
                            value: _hasAc,
                            onChanged: (v) => setState(() => _hasAc = v),
                            color: _C.info,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _featureToggle(
                            icon: Icons.bathtub_rounded,
                            label: 'Attached Bath',
                            value: _hasBathroom,
                            onChanged: (v) => setState(() => _hasBathroom = v),
                            color: _C.purple,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Additional Info', isDark),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _descCtrl,
                      label: 'Description',
                      hint: 'e.g. Corner room with good ventilation',
                      icon: Icons.description_outlined,
                      isDark: isDark,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: _C.border(isDark)),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: _C.textSec(isDark),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _loading
                                  ? const LinearGradient(colors: [
                                      Color(0xFFBBBBBB),
                                      Color(0xFFCCCCCC)
                                    ])
                                  : const LinearGradient(colors: [
                                      _C.accent,
                                      _C.accentLight,
                                    ]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _loading
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: _C.accent.withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _loading ? null : _submit,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15),
                                  alignment: Alignment.center,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : Text(
                                          _isEdit ? 'Update Room' : 'Add Room',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _bottomPad(BuildContext ctx) => MediaQuery.of(ctx).padding.bottom;

  Widget _sectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.4,
        color: _C.textSec(isDark),
      ),
    );
  }

  Widget _roomTypeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _isEdit ? 'Room Type (cannot be changed)' : 'Room Type',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _C.textSec(isDark),
            ),
          ),
        ),
        Opacity(
          opacity: _isEdit ? 0.6 : 1,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _roomTypes.map((t) {
              final isSel = _roomType == t;
              return GestureDetector(
                onTap: _isEdit ? null : () => _onTypeSelected(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSel
                        ? const LinearGradient(
                            colors: [_C.accent, _C.accentLight],
                          )
                        : null,
                    color: isSel ? null : _C.surfaceAlt(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? Colors.transparent : _C.border(isDark),
                      width: 1.4,
                    ),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: _C.accent.withOpacity(0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    t,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : _C.textSec(isDark),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _featureToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.08) : _C.surfaceAlt(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? color : _C.border(isDark),
            width: value ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? color : _C.textTer(isDark),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Icon(icon,
                size: 16, color: value ? color : _C.textSec(isDark)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: value ? color : _C.textSec(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _C.textSec(isDark),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          cursorColor: _C.accent,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: _C.text(isDark),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: _C.textTer(isDark),
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: _C.textSec(isDark),
            ),
            filled: true,
            fillColor: readOnly
                ? (isDark
                    ? const Color(0xFF151A2B)
                    : const Color(0xFFF0F1F6))
                : _C.surfaceAlt(isDark),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _C.border(isDark), width: 1.4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _C.border(isDark), width: 1.4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _C.accent, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _C.danger, width: 1.8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _C.danger, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}