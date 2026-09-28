import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/admin_model.dart';
import '../../models/property_model.dart';
import '../../providers/admin_provider.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() =>
      _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isFirstLoad = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad && mounted) {
        _isFirstLoad = false;
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final p = Provider.of<AdminProvider>(context, listen: false);
    await p.getPendingProperties();
    await p.getAllPropertiesAdmin();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        title: Text('Property Management',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Column(
            children: [
              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search properties...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF7C3AED)),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF141A2C) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Tabs ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141A2C) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: const Color(0xFF7C3AED),
                  unselectedLabelColor:
                      isDark ? Colors.grey[500] : Colors.grey[600],
                  indicator: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: 'Pending (${p.pendingProperties.length})'),
                    Tab(text: 'Published (${p.allProperties.length})'),
                    Tab(text: 'All (${p.pendingProperties.length + p.allProperties.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: p.isLoading &&
              p.pendingProperties.isEmpty &&
              p.allProperties.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildPending(isDark, p),
                _buildPublished(isDark, p),
                _buildAll(isDark, p),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════
  // PENDING TAB
  // ═══════════════════════════════════════════
  Widget _buildPending(bool isDark, AdminProvider p) {
    var filtered = p.pendingProperties.where((prop) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return prop.title.toLowerCase().contains(q) ||
          prop.city.toLowerCase().contains(q) ||
          prop.ownerName.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return _empty('No pending properties', isDark,
          Icons.pending_actions_rounded);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _pendingCard(isDark, filtered[i], p),
      ),
    );
  }

  Widget _pendingCard(bool isDark, PendingProperty prop, AdminProvider p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment_rounded,
                      color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prop.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text('${prop.city}, ${prop.state}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('PENDING',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Chips ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip('${prop.propertyType}', const Color(0xFF3B82F6),
                    isDark),
                _chip('Owner: ${prop.ownerName}', const Color(0xFF8B5CF6),
                    isDark),
                _chip(prop.ownerDisplayId, const Color(0xFF10B981), isDark),
              ],
            ),
            const SizedBox(height: 14),

            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok =
                          await p.publishProperty(prop.propertyId);
                      if (ok && mounted) {
                        _snack('Property published ✅', Colors.green);
                        _loadData();
                      } else if (mounted) {
                        _snack(
                            p.error ?? 'Failed to publish', Colors.red);
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text('Publish',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(prop, p, isDark),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text('Reject',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                          color: Colors.red, width: 1.3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PUBLISHED TAB
  // ═══════════════════════════════════════════
  Widget _buildPublished(bool isDark, AdminProvider p) {
    var filtered = p.allProperties.where((prop) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return prop.title.toLowerCase().contains(q) ||
          prop.city.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return _empty('No published properties', isDark,
          Icons.check_circle_rounded);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _publishedCard(isDark, filtered[i], p),
      ),
    );
  }

  Widget _publishedCard(bool isDark, Property prop, AdminProvider p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cover Image ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Stack(
              children: [
                prop.coverImage != null && prop.coverImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: prop.coverImage!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 150,
                          color: isDark
                              ? Colors.grey[850]
                              : Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 150,
                          color: isDark
                              ? Colors.grey[850]
                              : Colors.grey[200],
                          child: const Icon(Icons.apartment_rounded,
                              size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 150,
                        width: double.infinity,
                        color: isDark
                            ? Colors.grey[850]
                            : Colors.grey[200],
                        child: const Icon(Icons.apartment_rounded,
                            size: 40, color: Colors.grey),
                      ),
                // Verified badge overlay
                if (prop.isVerifiedOwner == true)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text('Verified',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prop.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text('${prop.city}, ${prop.state}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip(prop.propertyType, const Color(0xFF3B82F6),
                        isDark),
                    const Spacer(),
                    Text(
                        '₹${prop.monthlyRentMin?.toStringAsFixed(0) ?? "0"}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        )),
                    Text('/mo',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok =
                              await p.unpublishProperty(prop.propertyId);
                          if (ok && mounted) {
                            _snack('Property unpublished',
                                const Color(0xFFF59E0B));
                            _loadData();
                          }
                        },
                        icon: const Icon(Icons.remove_circle_rounded,
                            size: 16),
                        label: Text('Unpublish',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          side: const BorderSide(
                              color: Color(0xFFF59E0B), width: 1.3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ALL TAB
  // ═══════════════════════════════════════════
  Widget _buildAll(bool isDark, AdminProvider p) {
    final all = [
      ...p.pendingProperties.map((e) => {
            'type': 'pending',
            'title': e.title,
            'city': e.city,
            'state': e.state,
            'ptype': e.propertyType,
            'owner': e.ownerName,
          }),
      ...p.allProperties.map((e) => {
            'type': 'published',
            'title': e.title,
            'city': e.city,
            'state': e.state,
            'ptype': e.propertyType,
            'owner': '',
          }),
    ];

    if (all.isEmpty) {
      return _empty('No properties found', isDark,
          Icons.inbox_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: all.length,
      itemBuilder: (context, i) {
        final prop = all[i];
        final isPending = prop['type'] == 'pending';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141A2C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPending
                  ? const Color(0xFFF59E0B).withOpacity(0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPending
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPending
                      ? Icons.pending_rounded
                      : Icons.check_circle_rounded,
                  color: isPending
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prop['title'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                        '${prop['city']}, ${prop['state']} • ${prop['ptype']}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _chip(
                isPending ? 'Pending' : 'Published',
                isPending
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
  Widget _chip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            color: color,
            fontWeight: FontWeight.w600,
          )),
    );
  }

  Widget _empty(String msg, bool isDark, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 52,
                color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(msg,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              )),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRejectDialog(PendingProperty prop, AdminProvider p, bool isDark) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text('Reject Property',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting: ${prop.title}',
                style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: GoogleFonts.poppins(fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF7C3AED), width: 1.6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                _snack('Please enter a reason', Colors.orange);
                return;
              }
              Navigator.pop(context);
              final ok = await p.unpublishProperty(prop.propertyId);
              if (ok && mounted) {
                _snack('Property rejected ❌', Colors.red);
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}