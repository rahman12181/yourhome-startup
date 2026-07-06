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
    with SingleTickerProviderStateMixin {
  bool _isFirstLoad = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

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
    super.dispose();
  }

  Future<void> _loadRooms() async {
    await Provider.of<OwnerProvider>(context, listen: false)
        .getRooms(widget.property.propertyId);
  }

  void _showAddEditRoomDialog({Room? room}) {
    showDialog(
      context: context,
      builder: (_) => _RoomFormDialog(
        propertyId: widget.property.propertyId,
        room: room,
      ),
    ).then((success) {
      if (success == true) _loadRooms();
    });
  }

  Future<void> _handleDeleteRoom(int roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Room'),
        content: const Text('Are you sure you want to delete this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      await ownerProvider.deleteRoom(widget.property.propertyId, roomId);
      if (mounted) _loadRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ownerProvider = Provider.of<OwnerProvider>(context);
    final rooms = ownerProvider.rooms;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final totalRooms = rooms.length;
    final available = rooms.where((r) => r.status == 'AVAILABLE').length;
    final occupied = rooms.where((r) => r.status == 'OCCUPIED').length;
    final maintenance = rooms.where((r) => r.status == 'MAINTENANCE').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.property.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${rooms.length} rooms • $available available • $occupied occupied',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF7C3AED),
                size: 24,
              ),
            ),
            onPressed: () => _showAddEditRoomDialog(),
          ),
        ],
      ),
      body: ownerProvider.isLoading && rooms.isEmpty
          ? _buildLoadingState(isDark)
          : RefreshIndicator(
              onRefresh: _loadRooms,
              color: const Color(0xFF7C3AED),
              backgroundColor: isDark ? const Color(0xFF1A1F33) : Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: rooms.isEmpty
                    ? _buildEmptyState(isDark)
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 16 + bottomPadding,
                        ),
                        child: Column(
                          children: [
                            // Stats Row
                            _buildStatsRow(isDark, totalRooms, available, occupied, maintenance),
                            const SizedBox(height: 14),
                            ...rooms.map((room) =>
                                _buildRoomCard(context, room, isDark)),
                          ],
                        ),
                      ),
              ),
            ),
    );
  }

  // ============== LOADING STATE ==============
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading rooms...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============== STATS ROW ==============
  Widget _buildStatsRow(bool isDark, int total, int available, int occupied, int maintenance) {
    return Row(
      children: [
        _statBox('Total Rooms', total.toString(), Icons.meeting_room_rounded, const Color(0xFF7C3AED), isDark),
        const SizedBox(width: 8),
        _statBox('Available', available.toString(), Icons.check_circle_rounded, Colors.green, isDark),
        const SizedBox(width: 8),
        _statBox('Occupied', occupied.toString(), Icons.person_rounded, Colors.blue, isDark),
        const SizedBox(width: 8),
        _statBox('Maintenance', maintenance.toString(), Icons.build_rounded, Colors.orange, isDark),
      ],
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 7,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============== ROOM CARD ==============
  Widget _buildRoomCard(BuildContext context, Room room, bool isDark) {
    final statusColors = {
      'AVAILABLE': Colors.green,
      'OCCUPIED': Colors.blue,
      'MAINTENANCE': Colors.orange,
    };
    final statusIcons = {
      'AVAILABLE': Icons.check_circle_rounded,
      'OCCUPIED': Icons.person_rounded,
      'MAINTENANCE': Icons.build_rounded,
    };
    final color = statusColors[room.status] ?? Colors.grey;
    final icon = statusIcons[room.status] ?? Icons.help_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.roomNumber!.isNotEmpty ? 'Room ${room.roomNumber}' : 'Room ${room.roomId}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${room.roomTypeDisplay} • ${room.floorNumber != null ? 'Floor ${room.floorNumber}' : 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  room.statusDisplay,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _roomInfoItem('₹${room.monthlyRent.toStringAsFixed(0)}/mo', Icons.currency_rupee_rounded, isDark),
              const SizedBox(width: 14),
              _roomInfoItem('Cap: ${room.capacity}', Icons.people_rounded, isDark),
              const SizedBox(width: 14),
              if (room.hasAc) _roomInfoItem('AC', Icons.ac_unit_rounded, isDark),
              if (room.hasAttachedBathroom) _roomInfoItem('Bath', Icons.bathtub_rounded, isDark),
            ],
          ),
          const SizedBox(height: 10),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _roomActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  onTap: () => _showAddEditRoomDialog(room: room),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _roomStatusButton(
                  room: room,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _roomActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  color: Colors.red,
                  isDark: isDark,
                  onTap: () => _handleDeleteRoom(room.roomId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roomInfoItem(String label, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 12, color: isDark ? Colors.grey[400] : Colors.grey[500]),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _roomActionButton({
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
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

  Widget _roomStatusButton({
    required Room room,
    required bool isDark,
  }) {
    final statuses = [
      {'value': 'AVAILABLE', 'label': 'Available', 'color': Colors.green},
      {'value': 'OCCUPIED', 'label': 'Occupied', 'color': Colors.blue},
      {'value': 'MAINTENANCE', 'label': 'Maintenance', 'color': Colors.orange},
    ];

    return PopupMenuButton<String>(
      onSelected: (value) async {
        final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
        await ownerProvider.updateRoomStatus(widget.property.propertyId, room.roomId, value);
        if (mounted) _loadRooms();
      },
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              color: const Color(0xFF7C3AED),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Status',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFF7C3AED),
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => statuses.map((status) {
        final statusValue = status['value'] as String;
        final isSelected = room.status == statusValue;
        return PopupMenuItem<String>(
          value: statusValue,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: (status['color'] as Color).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: status['color'] as Color,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                status['label'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF7C3AED),
                  size: 16,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============== EMPTY STATE ==============
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Rooms Added',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add rooms to this property',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditRoomDialog(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== ROOM FORM DIALOG =====================
class _RoomFormDialog extends StatefulWidget {
  final int propertyId;
  final Room? room;
  const _RoomFormDialog({required this.propertyId, this.room});

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roomNumberCtrl;
  late TextEditingController _rentCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _floorCtrl;
  late TextEditingController _descCtrl;
  String _roomType = 'SINGLE';
  bool _hasAc = false;
  bool _hasBathroom = false;

  bool get _isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _roomNumberCtrl = TextEditingController(text: r?.roomNumber ?? '');
    _rentCtrl = TextEditingController(text: r?.monthlyRent.toStringAsFixed(0) ?? '');
    _capacityCtrl = TextEditingController(text: r?.capacity.toString() ?? '1');
    _floorCtrl = TextEditingController(text: r?.floorNumber?.toString() ?? '');
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

    final body = <String, dynamic>{
      if (_roomNumberCtrl.text.isNotEmpty) 'roomNumber': _roomNumberCtrl.text.trim(),
      'monthlyRent': double.tryParse(_rentCtrl.text) ?? 0,
      'capacity': int.tryParse(_capacityCtrl.text) ?? 1,
      if (_floorCtrl.text.isNotEmpty) 'floorNumber': int.tryParse(_floorCtrl.text),
      'hasAc': _hasAc,
      'hasAttachedBathroom': _hasBathroom,
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text.trim(),
    };
    if (!_isEdit) body['roomType'] = _roomType;

    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    final success = _isEdit
        ? await ownerProvider.updateRoom(widget.propertyId, widget.room!.roomId, body)
        : await ownerProvider.addRoom(widget.propertyId, body);

    if (mounted) Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1A1F33) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEdit ? Icons.edit_rounded : Icons.add_rounded,
                      color: const Color(0xFF7C3AED),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Room' : 'Add Room',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _formField(
                _roomNumberCtrl,
                'Room Number',
                Icons.numbers_rounded,
                isDark,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (!_isEdit)
                _dropdownField(
                  'Room Type',
                  _roomType,
                  ['SINGLE', 'DOUBLE', 'TRIPLE', 'DORMITORY'],
                  (v) => setState(() => _roomType = v!),
                  isDark,
                ),
              if (!_isEdit) const SizedBox(height: 12),
              _formField(
                _rentCtrl,
                'Monthly Rent *',
                Icons.currency_rupee_rounded,
                isDark,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _formField(
                _capacityCtrl,
                'Capacity *',
                Icons.people_rounded,
                isDark,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _formField(
                _floorCtrl,
                'Floor Number',
                Icons.air_rounded,
                isDark,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _formField(
                _descCtrl,
                'Description',
                Icons.description_rounded,
                isDark,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _switchTile('Has AC', _hasAc, (v) => setState(() => _hasAc = v), isDark),
                  ),
                  Expanded(
                    child: _switchTile('Attached Bath', _hasBathroom, (v) => setState(() => _hasBathroom = v), isDark),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEdit ? 'Update' : 'Add',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
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
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isDark, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _dropdownField(String label, String value, List<String> items, Function(String?) onChanged, bool isDark) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.category_rounded, size: 18, color: Colors.grey),
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _switchTile(String label, bool value, Function(bool) onChanged, bool isDark) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}