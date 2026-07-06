import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/owner_provider.dart';
import '../../models/property_model.dart';
import 'add_edit_property_page.dart';
import 'property_rooms_page.dart';

class OwnerPropertyManagementPage extends StatefulWidget {
  const OwnerPropertyManagementPage({super.key});

  @override
  State<OwnerPropertyManagementPage> createState() =>
      _OwnerPropertyManagementPageState();
}

class _OwnerPropertyManagementPageState
    extends State<OwnerPropertyManagementPage>
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
        _loadProperties();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    await ownerProvider.getMyProperties();
  }

  Future<void> _deleteProperty(int propertyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to delete this property? This action cannot be undone.'),
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
      await ownerProvider.deleteProperty(propertyId);
      if (mounted) _loadProperties();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ownerProvider = Provider.of<OwnerProvider>(context);
    final properties = ownerProvider.myProperties;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'My Properties',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: const Color(0xFF7C3AED),
              size: 26,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditPropertyPage(),
                ),
              );
              if (result == true) _loadProperties();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : const Color(0xFF4B5563),
              size: 22,
            ),
            onPressed: _loadProperties,
          ),
        ],
      ),
      body: ownerProvider.isLoading && properties.isEmpty
          ? _buildLoadingState(isDark)
          : RefreshIndicator(
              onRefresh: _loadProperties,
              color: const Color(0xFF7C3AED),
              backgroundColor: isDark ? const Color(0xFF1A1F33) : Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: properties.isEmpty
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
                            // Stats Banner
                            _buildStatsBanner(isDark, properties),
                            const SizedBox(height: 14),
                            // Property List
                            ...properties.map((property) =>
                                _buildPropertyCard(context, property, isDark)),
                            const SizedBox(height: 8),
                            // Add Property Button
                            _buildAddPropertyButton(isDark),
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
            'Loading properties...',
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

  // ============== STATS BANNER ==============
  Widget _buildStatsBanner(bool isDark, List<Property> properties) {
    final total = properties.length;
    final published = properties.where((p) => p.isPublished).length;
    final draft = total - published;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1F33), const Color(0xFF141A2C)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', total.toString(), Icons.apartment_rounded, const Color(0xFF7C3AED), isDark),
          _statItem('Published', published.toString(), Icons.check_circle_rounded, Colors.green, isDark),
          _statItem('Draft', draft.toString(), Icons.drafts_rounded, Colors.orange, isDark),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // ============== PROPERTY CARD ==============
  Widget _buildPropertyCard(BuildContext context, Property property, bool isDark) {
    final isPublished = property.isPublished;
    final hasImage = property.coverImage.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPublished
              ? Colors.green.withOpacity(0.15)
              : Colors.orange.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyRoomsPage(property: property),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Property Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: property.coverImage,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
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
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.apartment_rounded,
                                  size: 30,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                              )
                            : Icon(
                                Icons.apartment_rounded,
                                size: 30,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Property Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[500],
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '${property.city}, ${property.state}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Badges
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _buildBadge(
                                '${property.totalRooms} rooms',
                                const Color(0xFF3B82F6),
                                isDark,
                              ),
                              _buildBadge(
                                '${property.availableRooms} available',
                                Colors.green,
                                isDark,
                              ),
                              _buildBadge(
                                property.propertyType,
                                const Color(0xFF8B5CF6),
                                isDark,
                              ),
                              _buildBadge(
                                isPublished ? 'Published' : 'Draft',
                                isPublished ? Colors.green : Colors.orange,
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.room_preferences_rounded,
                        label: 'Rooms',
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PropertyRoomsPage(property: property),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditPropertyPage(property: property),
                            ),
                          );
                          if (result == true) _loadProperties();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: Colors.red,
                        isDark: isDark,
                        onTap: () => _deleteProperty(property.propertyId),
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

  Widget _buildActionButton({
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
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

  Widget _buildBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // ============== ADD PROPERTY BUTTON ==============
  Widget _buildAddPropertyButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.selectionClick();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditPropertyPage(),
            ),
          );
          if (result == true) _loadProperties();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1F33), const Color(0xFF141A2C)]
                  : [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Property',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
      ),
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
              Icons.apartment_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Properties Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first property now',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditPropertyPage(),
                ),
              );
              if (result == true) _loadProperties();
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Property'),
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