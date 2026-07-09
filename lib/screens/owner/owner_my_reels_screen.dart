// lib/screens/owner/owner_my_reels_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:yourhome/providers/reel_provider.dart';
import 'package:yourhome/models/reel_model.dart';
import 'owner_reels_upload_screen.dart';

class OwnerMyReelsScreen extends StatefulWidget {
  const OwnerMyReelsScreen({super.key});

  @override
  State<OwnerMyReelsScreen> createState() => _OwnerMyReelsScreenState();
}

class _OwnerMyReelsScreenState extends State<OwnerMyReelsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  int? _selectedReelId;
  String? _selectedFilter;

  final List<String> _filterOptions = ['All', 'Most Viewed', 'Most Liked', 'Most Commented', 'Recent'];

  // ✅ FIXED: Using single animation controller with TickerProviderStateMixin
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadReels();
  }

  void _setupAnimations() {
    // ✅ SINGLE AnimationController for all animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fabAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _animationController.forward();
  }

  Future<void> _loadReels() async {
    final reelProvider = Provider.of<ReelProvider>(context, listen: false);
    await reelProvider.loadMyReels();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshReels() async {
    setState(() => _isRefreshing = true);
    await _loadReels();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _deleteReel(int reelId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(context),
    );

    if (confirmed == true) {
      final reelProvider = Provider.of<ReelProvider>(context, listen: false);
      final success = await reelProvider.deleteReel(reelId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Reel deleted successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF141A2C) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Reel?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. Are you sure you want to delete this reel?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B2338)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  void _showReelDetail(Reel reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ReelDetailBottomSheet(reel: reel),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reelProvider = Provider.of<ReelProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
      appBar: _buildAppBar(isDark, reelProvider),
      body: _isLoading
          ? _buildLoadingState(isDark)
          : _buildBody(isDark, reelProvider),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: _buildFAB(isDark),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ========== APP BAR ==========
  PreferredSizeWidget _buildAppBar(bool isDark, ReelProvider provider) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.movie_creation_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'My Reels',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.myReels.length}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
          onPressed: _refreshReels,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildFilterChips(isDark),
      ),
    );
  }

  // ========== FILTER CHIPS ==========
  Widget _buildFilterChips(bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter || 
              (_selectedFilter == null && index == 0);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : 
                    (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : null;
                });
              },
              backgroundColor: isDark ? const Color(0xFF1B2338) : Colors.grey[200],
              selectedColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFF59E0B) : 
                    (isDark ? Colors.white.withOpacity(0.06) : Colors.grey[300]!),
                  width: isSelected ? 0 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          );
        },
      ),
    );
  }

  // ========== BODY ==========
  Widget _buildBody(bool isDark, ReelProvider provider) {
    final reels = _getFilteredReels(provider.myReels);

    if (reels.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _refreshReels,
      color: const Color(0xFFF59E0B),
      backgroundColor: isDark ? const Color(0xFF141A2C) : Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return _buildReelCard(context, reel, isDark);
        },
      ),
    );
  }

  List<Reel> _getFilteredReels(List<Reel> allReels) {
    if (_selectedFilter == null || _selectedFilter == 'All') {
      return allReels;
    }

    switch (_selectedFilter) {
      case 'Most Viewed':
        final sorted = List<Reel>.from(allReels);
        sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        return sorted;
      case 'Most Liked':
        final sorted = List<Reel>.from(allReels);
        sorted.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        return sorted;
      case 'Most Commented':
        final sorted = List<Reel>.from(allReels);
        sorted.sort((a, b) => b.commentCount.compareTo(a.commentCount));
        return sorted;
      case 'Recent':
        final sorted = List<Reel>.from(allReels);
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;
      default:
        return allReels;
    }
  }

  // ========== REEL CARD ==========
  Widget _buildReelCard(BuildContext context, Reel reel, bool isDark) {
    return GestureDetector(
      onTap: () => _showReelDetail(reel),
      onLongPress: () => _deleteReel(reel.reelId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail Image
                    CachedNetworkImage(
                      imageUrl: reel.videoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie_creation_rounded,
                              size: 40,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No Preview',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Play Icon
                    const Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.white70,
                          size: 44,
                        ),
                      ),
                    ),

                    // Stats Badges
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          _buildStatBadge(
                            Icons.favorite_rounded,
                            reel.likeCount,
                            Colors.red,
                          ),
                          const SizedBox(width: 4),
                          _buildStatBadge(
                            Icons.chat_bubble_rounded,
                            reel.commentCount,
                            Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          _buildStatBadge(
                            Icons.visibility_rounded,
                            reel.viewCount,
                            Colors.grey,
                          ),
                        ],
                      ),
                    ),

                    // Duration Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${reel.duration ?? 20}s',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Verified Badge
                    if (reel.isVerifiedOwner)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Verified',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reel.propertyTitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          reel.propertyCity,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (reel.caption != null && reel.caption!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            reel.caption!.length > 15
                                ? '${reel.caption!.substring(0, 15)}...'
                                : reel.caption!,
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        _formatDate(reel.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 10,
          ),
          const SizedBox(width: 2),
          Text(
            count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : count.toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
    }
  }

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF141A2C)
                  : const Color(0xFFF0F2F6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.movie_creation_outlined,
              size: 64,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Reels Yet',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first property reel\nand attract more students! 🎬',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OwnerReelsUploadScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.upload_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Upload First Reel 🚀',
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
    );
  }

  // ========== LOADING STATE ==========
  Widget _buildLoadingState(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141A2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== FAB ==========
  Widget _buildFAB(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OwnerReelsUploadScreen(),
              ),
            ).then((_) => _refreshReels());
          },
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// ========== REEL DETAIL BOTTOM SHEET ==========
class _ReelDetailBottomSheet extends StatefulWidget {
  final Reel reel;

  const _ReelDetailBottomSheet({required this.reel});

  @override
  State<_ReelDetailBottomSheet> createState() => _ReelDetailBottomSheetState();
}

class _ReelDetailBottomSheetState extends State<_ReelDetailBottomSheet>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.videoUrl),
      );
      await _videoController.initialize();
      await _videoController.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Player
                  Container(
                    height: 350,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _isInitialized
                          ? Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: _videoController.value.aspectRatio,
                                  child: VideoPlayer(_videoController),
                                ),
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_videoController.value.isPlaying) {
                                        _videoController.pause();
                                      } else {
                                        _videoController.play();
                                      }
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      child: Center(
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 300),
                                          opacity: _videoController.value.isPlaying ? 0 : 1,
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _videoController.value.isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.reel.propertyTitle,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.reel.propertyCity,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: const Color(0xFF2563EB),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified Owner',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Caption
                        if (widget.reel.caption != null && widget.reel.caption!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1B2338)
                                  : const Color(0xFFF0F2F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.format_quote_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.reel.caption!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Stats Row
                        Row(
                          children: [
                            _buildDetailStat(
                              Icons.favorite_rounded,
                              widget.reel.likeCount,
                              Colors.red,
                              isDark,
                            ),
                            const SizedBox(width: 16),
                            _buildDetailStat(
                              Icons.chat_bubble_rounded,
                              widget.reel.commentCount,
                              Colors.blue,
                              isDark,
                            ),
                            const SizedBox(width: 16),
                            _buildDetailStat(
                              Icons.visibility_rounded,
                              widget.reel.viewCount,
                              Colors.grey,
                              isDark,
                            ),
                            const SizedBox(width: 16),
                            _buildDetailStat(
                              Icons.share_rounded,
                              widget.reel.shareCount,
                              Colors.green,
                              isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Date
                        Text(
                          'Posted on ${_formatDate(widget.reel.createdAt)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to property
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'View Property 🏠',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                // Delete
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 24,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(IconData icon, int count, Color color, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : count.toString(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    }
  }
}