import 'package:flutter/material.dart';
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

class _PropertyRoomsPageState extends State<PropertyRoomsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRooms());
  }

  Future<void> _loadRooms() async {
    await Provider.of<OwnerProvider>(context, listen: false).getRooms(widget.property.propertyId);
  }

  void _showAddEditRoomDialog({Room? room}) {
    showDialog(
      context: context,
      builder: (_) => _RoomFormDialog(propertyId: widget.property.propertyId, room: room),
    ).then((success) {
      if (success == true) _loadRooms();
    });
  }

  Future<void> _handleDeleteRoom(int roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      await ownerProvider.deleteRoom(widget.property.propertyId, roomId);
    }
  }

  Future<void> _handleStatusChange(int roomId, String status) async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    await ownerProvider.updateRoomStatus(widget.property.propertyId, roomId, status);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ownerProvider = Provider.of<OwnerProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Rooms — ${widget.property.title}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEditRoomDialog()),
        ],
      ),
      body: ownerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ownerProvider.rooms.isEmpty
              ? Center(
                  child: Text('No rooms added yet',
                      style: GoogleFonts.poppins(color: Colors.grey[600])))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ownerProvider.rooms.length,
                  itemBuilder: (context, index) {
                    final room = ownerProvider.rooms[index];
                    return _buildRoomCard(room, isDark);
                  },
                ),
    );
  }

  Widget _buildRoomCard(Room room, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Room ${room.roomNumber ?? room.roomId}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _showAddEditRoomDialog(room: room);
                  if (value == 'delete') _handleDeleteRoom(room.roomId);
                  if (value == 'available') _handleStatusChange(room.roomId, 'AVAILABLE');
                  if (value == 'occupied') _handleStatusChange(room.roomId, 'OCCUPIED');
                  if (value == 'maintenance') _handleStatusChange(room.roomId, 'MAINTENANCE');
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'available', child: Text('Mark Available')),
                  const PopupMenuItem(value: 'occupied', child: Text('Mark Occupied')),
                  const PopupMenuItem(value: 'maintenance', child: Text('Mark Maintenance')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(room.roomTypeDisplay, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('₹${room.monthlyRent.toStringAsFixed(0)}/month',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.blue)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration:
                    BoxDecoration(color: room.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(room.statusDisplay, style: GoogleFonts.poppins(fontSize: 10, color: room.statusColor)),
              ),
              if (room.hasAc) _tag('AC'),
              if (room.hasAttachedBathroom) _tag('Attached Bath'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue)),
    );
  }
}

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
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Room' : 'Add Room'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: _roomNumberCtrl,
                  decoration: const InputDecoration(labelText: 'Room Number')),
              if (!_isEdit) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _roomType,
                  decoration: const InputDecoration(labelText: 'Room Type'),
                  items: ['SINGLE', 'DOUBLE', 'TRIPLE', 'DORMITORY']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _roomType = v!),
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _rentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly Rent *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _floorCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Floor Number')),
              const SizedBox(height: 8),
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              SwitchListTile(
                  title: const Text('Has AC'), value: _hasAc, onChanged: (v) => setState(() => _hasAc = v)),
              SwitchListTile(
                  title: const Text('Attached Bathroom'),
                  value: _hasBathroom,
                  onChanged: (v) => setState(() => _hasBathroom = v)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: Text(_isEdit ? 'Update' : 'Add')),
      ],
    );
  }
}