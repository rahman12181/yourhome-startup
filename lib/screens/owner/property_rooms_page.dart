import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/room_model.dart';
import '../../providers/owner_provider.dart';

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

  // ================= ADD/EDIT SHEET =================
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

  // ================= STATUS SHEET =================
  Future<void> _openStatusSheet(Room room) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121729) : Colors.white,
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
              'Change Room Status',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Room ${room.roomNumber ?? room.roomId}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
            ),
            const SizedBox(height: 20),
            ...[
              _statusOption(
                value: 'AVAILABLE',
                label: 'Available',
                subtitle: 'Room is ready for booking',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF22C55E),
                isSelected: room.status == 'AVAILABLE',
                isDark: isDark,
              ),
              _statusOption(
                value: 'OCCUPIED',
                label: 'Occupied',
                subtitle: 'Room is currently booked',
                icon: Icons.person_rounded,
                color: const Color(0xFFEF4444),
                isSelected: room.status == 'OCCUPIED',
                isDark: isDark,
              ),
              _statusOption(
                value: 'MAINTENANCE',
                label: 'Maintenance',
                subtitle: 'Room is under repair',
                icon: Icons.build_rounded,
                color: const Color(0xFFF59E0B),
                isSelected: room.status == 'MAINTENANCE',
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );

    if (selected != null && selected != room.status && mounted) {
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      final ok = await ownerProvider.updateRoomStatus(
        widget.property.propertyId,
        room.roomId,
        selected,
      );
      if (ok && mounted) {
        _showSnack('Status updated successfully');
        _loadRooms();
      }
    }
  }

  Widget _statusOption({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : (isDark ? const Color(0xFF1A1F33) : const Color(0xFFF8F9FC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  // ================= DELETE =================
  Future<void> _confirmDelete(Room room) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF121729) : Colors.white,
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
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Room?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Room ${room.roomNumber ?? room.roomId} will be permanently removed. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : const Color(0xFF8A8FA3),
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
                          side: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE8E8F0),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF666680),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
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
      if (ok && mounted) {
        _showSnack('Room deleted');
        _loadRooms();
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFF22C55E),
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
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
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

            return Column(
              children: [
                _buildHeader(isDark, total, available, occupied),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadRooms,
                    color: const Color(0xFF7C3AED),
                    backgroundColor:
                        isDark ? const Color(0xFF1A1F33) : Colors.white,
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
                                      16, 6, 16, 100),
                                  children: [
                                    _buildStatsRow(
                                      isDark,
                                      total,
                                      available,
                                      occupied,
                                      maintenance,
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Text(
                                          'All Rooms',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C3AED)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          child: Text(
                                            '${rooms.length}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...List.generate(rooms.length, (i) {
                                      final delay = i * 0.06;
                                      return AnimatedBuilder(
                                        animation: _staggerController,
                                        builder: (context, child) {
                                          final t = Curves.easeOutCubic.transform(
                                            ((_staggerController.value - delay)
                                                    .clamp(0.0, 1.0))
                                                .toDouble(),
                                          );
                                          return Transform.translate(
                                            offset: Offset(0, 20 * (1 - t)),
                                            child: Opacity(opacity: t, child: child),
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
  Widget _buildHeader(
      bool isDark, int total, int available, int occupied) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.property.title,
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

  // ================= FAB =================
  Widget _buildFab(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4ECDC4)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRoomSheet(),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Add Room',
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
        _statCard('Total', total, Icons.meeting_room_rounded,
            const Color(0xFF7C3AED), isDark),
        const SizedBox(width: 8),
        _statCard('Free', available, Icons.check_circle_rounded,
            const Color(0xFF22C55E), isDark),
        const SizedBox(width: 8),
        _statCard('Booked', occupied, Icons.person_rounded,
            const Color(0xFFEF4444), isDark),
        const SizedBox(width: 8),
        _statCard('Repair', maintenance, Icons.build_rounded,
            const Color(0xFFF59E0B), isDark),
      ],
    );
  }

  Widget _statCard(
      String label, int value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121729) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F0F8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
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
            const SizedBox(height: 6),
            Text(
              '$value',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ROOM CARD =================
  Widget _buildRoomCard(BuildContext context, Room room, bool isDark) {
    final statusConfig = {
      'AVAILABLE': {
        'color': const Color(0xFF22C55E),
        'label': 'Available',
        'icon': Icons.check_circle_rounded,
      },
      'OCCUPIED': {
        'color': const Color(0xFFEF4444),
        'label': 'Occupied',
        'icon': Icons.person_rounded,
      },
      'MAINTENANCE': {
        'color': const Color(0xFFF59E0B),
        'label': 'Maintenance',
        'icon': Icons.build_rounded,
      },
    };

    final cfg = statusConfig[room.status] ?? statusConfig['AVAILABLE']!;
    final color = cfg['color'] as Color;
    final label = cfg['label'] as String;
    final icon = cfg['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(14),
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
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              room.roomType,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7C3AED),
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
                          color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: color.withOpacity(0.3)),
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

            const SizedBox(height: 12),

            // Tags row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _miniTag(
                  '₹${room.monthlyRent.toStringAsFixed(0)}/mo',
                  Icons.currency_rupee_rounded,
                  const Color(0xFF7C3AED),
                  isDark,
                ),
                if (room.hasAc)
                  _miniTag(
                    'AC',
                    Icons.ac_unit_rounded,
                    const Color(0xFF3B82F6),
                    isDark,
                  ),
                if (room.hasAttachedBathroom)
                  _miniTag(
                    'Attached Bath',
                    Icons.bathtub_rounded,
                    const Color(0xFF8B5CF6),
                    isDark,
                  ),
              ],
            ),

            if (room.description != null && room.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                room.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action row
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                    onTap: () => _openRoomSheet(room: room),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Status',
                    color: const Color(0xFF7C3AED),
                    isDark: isDark,
                    onTap: () => _openStatusSheet(room),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                    onTap: () => _confirmDelete(room),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
            border: Border.all(color: color.withOpacity(0.2), width: 1.2),
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                height: 86,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121729) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 170,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121729) : Colors.white,
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
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.15),
                    const Color(0xFF4ECDC4).withOpacity(0.08),
                  ],
                ),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 56,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Rooms Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding rooms to this property\nso students can book them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => _openRoomSheet(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4ECDC4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.35),
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
                      'Add First Room',
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
          backgroundColor: const Color(0xFF22C55E),
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
          backgroundColor: const Color(0xFFEF4444),
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

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1320) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE0E0E8),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                      ),
                      borderRadius: BorderRadius.circular(14),
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
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'Fill room details below',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color:
                                isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF666680),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                            label: 'Capacity',
                            hint: '1',
                            icon: Icons.people_rounded,
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
                            color: const Color(0xFF3B82F6),
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
                            color: const Color(0xFF8B5CF6),
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
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE8E8F0),
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF666680),
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
                                      Color(0xFF7C3AED),
                                      Color(0xFF4ECDC4)
                                    ]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _loading
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED)
                                            .withOpacity(0.35),
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

  Widget _sectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.4,
        color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
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
            'Room Type',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF666680),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _roomTypes.map((t) {
            final isSel = _roomType == t;
            return GestureDetector(
              onTap: () => setState(() => _roomType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSel
                      ? const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                        )
                      : null,
                  color: isSel
                      ? null
                      : (isDark
                          ? const Color(0xFF1A1F33)
                          : const Color(0xFFF8F9FC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel
                        ? Colors.transparent
                        : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
                    width: 1.4,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF7C3AED).withOpacity(0.3),
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
                    color: isSel
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF666680)),
                  ),
                ),
              ),
            );
          }).toList(),
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
          color: value
              ? color.withOpacity(0.08)
              : (isDark ? const Color(0xFF1A1F33) : const Color(0xFFF8F9FC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? color
                : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
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
                  color: value
                      ? color
                      : (isDark ? Colors.white24 : const Color(0xFFCCCCDD)),
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
                size: 16,
                color: value ? color : (isDark ? Colors.white54 : Colors.grey)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: value
                      ? color
                      : (isDark ? Colors.white70 : const Color(0xFF666680)),
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
              color: isDark ? Colors.white70 : const Color(0xFF666680),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFFB0B3C0),
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1A1F33) : const Color(0xFFF8F9FC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE8E8F0),
                width: 1.4,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE8E8F0),
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}