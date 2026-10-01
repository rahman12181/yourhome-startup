import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/property_model.dart';
import '../../models/bulk_room_model.dart';
import '../../services/room_management_service.dart';

class BulkAddRoomsPage extends StatefulWidget {
  final Property property;
  const BulkAddRoomsPage({super.key, required this.property});

  @override
  State<BulkAddRoomsPage> createState() => _BulkAddRoomsPageState();
}

class _BatchDraft {
  String roomType;
  bool hasAc = false;
  bool hasBath = false;
  final TextEditingController count = TextEditingController(text: '10');
  final TextEditingController rent = TextEditingController();
  final TextEditingController floor = TextEditingController();
  final TextEditingController start = TextEditingController();
  final TextEditingController prefix = TextEditingController();
  final TextEditingController capacity = TextEditingController(text: '4');

  _BatchDraft(this.roomType);

  int get rooms => int.tryParse(count.text.trim()) ?? 0;

  int get bedsPerRoom {
    final fixed = RoomTypeInfo.fixedBeds(roomType);
    if (fixed != null) return fixed;
    return int.tryParse(capacity.text.trim()) ?? 0;
  }

  void dispose() {
    count.dispose();
    rent.dispose();
    floor.dispose();
    start.dispose();
    prefix.dispose();
    capacity.dispose();
  }
}

class _BulkAddRoomsPageState extends State<BulkAddRoomsPage> {
  static const int _maxRoomsPerRequest = 200;

  final RoomManagementService _service = RoomManagementService();
  final List<_BatchDraft> _batches = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _batches.add(_BatchDraft('DOUBLE'));
  }

  @override
  void dispose() {
    for (final b in _batches) {
      b.dispose();
    }
    super.dispose();
  }

  // ================= HELPERS =================
  int get _totalRooms => _batches.fold(0, (s, b) => s + b.rooms);
  int get _totalBeds => _batches.fold(0, (s, b) => s + b.rooms * b.bedsPerRoom);

  void _snack(String msg, {bool error = false}) {
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

  String? _validate() {
    if (_batches.isEmpty) return 'Add at least one room type';
    int total = 0;
    for (int i = 0; i < _batches.length; i++) {
      final b = _batches[i];
      final n = i + 1;
      final count = int.tryParse(b.count.text.trim());
      if (count == null || count < 1 || count > _maxRoomsPerRequest) {
        return 'Room type #$n: number of rooms must be 1 to $_maxRoomsPerRequest';
      }
      total += count;
      final rent = double.tryParse(b.rent.text.trim());
      if (rent == null || rent <= 0) {
        return 'Room type #$n: enter a valid monthly rent';
      }
      if (b.roomType == 'DORMITORY') {
        final cap = int.tryParse(b.capacity.text.trim());
        if (cap == null || cap < 4 || cap > 50) {
          return 'Room type #$n: dormitory needs 4 to 50 beds';
        }
      }
    }
    if (total > _maxRoomsPerRequest) {
      return 'You can create at most $_maxRoomsPerRequest rooms at a time';
    }
    return null;
  }

  List<RoomBatchInput> _buildRequest() {
    return _batches.map((b) {
      return RoomBatchInput(
        roomType: b.roomType,
        count: int.parse(b.count.text.trim()),
        monthlyRent: double.parse(b.rent.text.trim()),
        floorNumber: int.tryParse(b.floor.text.trim()),
        capacity: b.roomType == 'DORMITORY'
            ? int.tryParse(b.capacity.text.trim())
            : null,
        hasAc: b.hasAc,
        hasAttachedBathroom: b.hasBath,
        roomNumberPrefix: b.prefix.text.trim().isEmpty ? null : b.prefix.text.trim(),
        startNumber: int.tryParse(b.start.text.trim()),
      );
    }).toList();
  }

  // ================= ACTIONS =================
  Future<void> _reviewAndCreate() async {
    FocusScope.of(context).unfocus();
    final err = _validate();
    if (err != null) {
      _snack(err, error: true);
      return;
    }

    final request = _buildRequest();
    setState(() => _busy = true);
    final previewRes =
        await _service.previewBulk(widget.property.propertyId, request);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!previewRes.success || previewRes.data == null) {
      _snack(previewRes.message, error: true);
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreviewSheet(preview: previewRes.data!),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final res = await _service.createBulk(widget.property.propertyId, request);
    if (!mounted) return;
    setState(() => _busy = false);

    if (res.success && res.data != null) {
      _snack('${res.data!.createdRooms} rooms created (${res.data!.totalBeds} beds)');
      Navigator.pop(context, true);
    } else {
      _snack(res.message, error: true);
    }
  }

  void _addBatch() {
    HapticFeedback.selectionClick();
    // suggest a type not used yet
    final used = _batches.map((b) => b.roomType).toSet();
    final next = RoomTypeInfo.all.firstWhere(
      (t) => !used.contains(t),
      orElse: () => 'SINGLE',
    );
    setState(() => _batches.add(_BatchDraft(next)));
  }

  void _removeBatch(int index) {
    setState(() {
      _batches[index].dispose();
      _batches.removeAt(index);
    });
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
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                children: [
                  _buildInfoCard(isDark),
                  const SizedBox(height: 14),
                  ...List.generate(
                    _batches.length,
                    (i) => _buildBatchCard(i, _batches[i], isDark),
                  ),
                  _buildAddBatchButton(isDark),
                ],
              ),
            ),
            _buildBottomBar(isDark),
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
          InkWell(
            onTap: () => Navigator.pop(context),
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
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Rooms in Bulk',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
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

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFF7C3AED), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Create many rooms in one go. Pick a room type, enter how many, '
              'and the rent. Room numbers are generated automatically and you '
              'can review everything before saving.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.5,
                color: isDark ? Colors.white70 : const Color(0xFF5B21B6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BATCH CARD =================
  Widget _buildBatchCard(int index, _BatchDraft b, bool isDark) {
    final color = RoomTypeInfo.color(b.roomType);
    final isDorm = b.roomType == 'DORMITORY';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Room type #${index + 1}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              if (_batches.length > 1)
                IconButton(
                  onPressed: () => _removeBatch(index),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444), size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RoomTypeInfo.all.map((t) {
              final sel = b.roomType == t;
              final c = RoomTypeInfo.color(t);
              return GestureDetector(
                onTap: () => setState(() => b.roomType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel
                        ? c
                        : (isDark ? const Color(0xFF1A1F33) : const Color(0xFFF8F9FC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? c
                          : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
                    ),
                  ),
                  child: Text(
                    RoomTypeInfo.label(t),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF666680)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: b.count,
                  label: 'How many rooms',
                  hint: '10',
                  isDark: isDark,
                  digitsOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  controller: b.rent,
                  label: 'Rent / month (₹)',
                  hint: '6000',
                  isDark: isDark,
                  digitsOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: b.floor,
                  label: 'Floor (optional)',
                  hint: '1',
                  isDark: isDark,
                  digitsOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  controller: b.start,
                  label: 'Start number',
                  hint: 'Auto',
                  isDark: isDark,
                  digitsOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: b.prefix,
                  label: 'Prefix (optional)',
                  hint: 'A-',
                  isDark: isDark,
                  prefixFormat: true,
                ),
              ),
              if (isDorm) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: b.capacity,
                    label: 'Beds per room',
                    hint: '6',
                    isDark: isDark,
                    digitsOnly: true,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _toggle(
                  icon: Icons.ac_unit_rounded,
                  label: 'AC',
                  value: b.hasAc,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  onTap: () => setState(() => b.hasAc = !b.hasAc),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _toggle(
                  icon: Icons.bathtub_rounded,
                  label: 'Attached Bath',
                  value: b.hasBath,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  onTap: () => setState(() => b.hasBath = !b.hasBath),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${b.rooms} × ${RoomTypeInfo.label(b.roomType)} '
              '(${b.bedsPerRoom} bed${b.bedsPerRoom == 1 ? '' : 's'} each) '
              '= ${b.rooms * b.bedsPerRoom} beds',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    bool digitsOnly = false,
    bool prefixFormat = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF666680),
            ),
          ),
        ),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          keyboardType:
              digitsOnly ? TextInputType.number : TextInputType.text,
          inputFormatters: [
            if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
            if (prefixFormat) ...[
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]')),
              LengthLimitingTextInputFormatter(8),
            ],
          ],
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
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1A1F33) : const Color(0xFFF8F9FC),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE8E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE8E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggle({
    required IconData icon,
    required String label,
    required bool value,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? color.withOpacity(0.08)
              : (isDark ? const Color(0xFF1A1F33) : const Color(0xFFF8F9FC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? color
                : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
            width: value ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: value ? color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 15, color: value ? color : Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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

  Widget _buildAddBatchButton(bool isDark) {
    return GestureDetector(
      onTap: _addBatch,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 6),
            Text(
              'Add another room type',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1320) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalRooms rooms',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  '$_totalBeds beds in total',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _busy
                    ? const [Color(0xFFBBBBBB), Color(0xFFCCCCCC)]
                    : const [Color(0xFF7C3AED), Color(0xFF4ECDC4)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _busy ? null : _reviewAndCreate,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          'Review & Create',
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
        ],
      ),
    );
  }
}

// ===================================================================
// ======================= PREVIEW SHEET =============================
// ===================================================================
class _PreviewSheet extends StatelessWidget {
  final BulkPreview preview;
  const _PreviewSheet({required this.preview});

  static const int _maxChips = 80;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shown = preview.rooms.take(_maxChips).toList();
    final hidden = preview.rooms.length - shown.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
          const SizedBox(height: 16),
          Text(
            'Review before creating',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _stat('Rooms', '${preview.totalRooms}',
                          const Color(0xFF7C3AED), isDark),
                      const SizedBox(width: 10),
                      _stat('Beds', '${preview.totalBeds}',
                          const Color(0xFF22C55E), isDark),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: preview.countsByType.entries.map((e) {
                      final c = RoomTypeInfo.color(e.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${e.value} × ${RoomTypeInfo.label(e.key)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: c,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (preview.conflicts.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        'These room numbers already exist: '
                        '${preview.conflicts.take(10).join(', ')}'
                        '${preview.conflicts.length > 10 ? ' …' : ''}\n'
                        'Go back and change the start number or prefix.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.5,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Room numbers',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: shown.map((r) {
                      final c = RoomTypeInfo.color(r.roomType);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.withOpacity(0.25)),
                        ),
                        child: Text(
                          r.roomNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (hidden > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+ $hidden more rooms',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF666680),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: preview.canCreate
                      ? () => Navigator.pop(context, true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Create ${preview.totalRooms} rooms',
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

  Widget _stat(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}