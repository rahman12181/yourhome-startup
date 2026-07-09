// lib/screens/owner/owner_reel_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:yourhome/models/reel_model.dart';
import 'package:yourhome/services/api_service.dart';
import 'package:yourhome/services/property_service.dart';
import 'package:yourhome/screens/property_detail_screen.dart';

class OwnerReelProfileScreen extends StatefulWidget {
  final int ownerId;

  const OwnerReelProfileScreen({
    super.key,
    required this.ownerId, required int propertyId,
  });

  @override
  State<OwnerReelProfileScreen> createState() => _OwnerReelProfileScreenState();
}

class _OwnerReelProfileScreenState extends State<OwnerReelProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isLoadingReels = false;
  bool _isLoadingProperties = false;
  
  Map<String, dynamic>? _ownerDetail;
  List<Reel> _reels = [];
  List<Map<String, dynamic>> _properties = [];
  
  String? _error;
  int _selectedTab = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    
    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.wait([
      _loadOwnerDetail(),
      _loadOwnerReels(),
      _loadOwnerProperties(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOwnerDetail() async {
    try {
      final response = await ApiService().get(
        '/admin/owners/${widget.ownerId}/detail',
      );
      if (response.data['success'] == true) {
        setState(() {
          _ownerDetail = response.data['data'];
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading owner detail: $e');
    }

    // Try to get owner info from reels feed
    try {
      final response = await ApiService().get('/reels/feed?page=0&size=100');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final content = data['content'] as List? ?? [];
        
        for (var item in content) {
          final reel = Reel.fromJson(item);
          if (reel.ownerUserId == widget.ownerId) {
            setState(() {
              _ownerDetail = {
                'name': reel.ownerName,
                'displayId': reel.ownerDisplayId,
                'verificationStatus': reel.isVerifiedOwner ? 'VERIFIED' : 'PENDING',
                'businessName': null,
                'profilePic': reel.ownerProfilePic,
              };
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting owner from reels: $e');
    }

    setState(() {
      _ownerDetail = {
        'name': 'Owner ${widget.ownerId}',
        'displayId': 'NST-${widget.ownerId.toString().padLeft(6, '0')}',
        'verificationStatus': 'VERIFIED',
        'businessName': null,
        'profilePic': null,
      };
    });
  }

  Future<void> _loadOwnerReels() async {
    try {
      setState(() => _isLoadingReels = true);
      
      final response = await ApiService().get(
        '/reels/feed?page=0&size=100',
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final content = data['content'] as List? ?? [];
        
        setState(() {
          _reels = content
              .map((item) => Reel.fromJson(item))
              .where((reel) => reel.ownerUserId == widget.ownerId)
              .toList();
          _isLoadingReels = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reels: $e');
      setState(() => _isLoadingReels = false);
    }
  }

  // ✅ FIXED: Only show properties from this specific owner
  Future<void> _loadOwnerProperties() async {
    try {
      setState(() => _isLoadingProperties = true);
      
      // ✅ METHOD 1: Get properties from reels (MOST RELIABLE)
      if (_reels.isNotEmpty) {
        // Get unique property IDs from reels
        final propertyIds = _reels.map((r) => r.propertyId).toSet().toList();
        
        List<Map<String, dynamic>> fetchedProperties = [];
        
        // Fetch each property detail
        for (var id in propertyIds) {
          try {
            final response = await ApiService().get(
              '/properties/$id',
            );
            
            if (response.data['success'] == true) {
              final item = response.data['data'];
              
              fetchedProperties.add({
                'propertyId': item['propertyId'] ?? id,
                'title': item['title'] ?? 'Property $id',
                'city': item['city'] ?? '',
                'coverImage': item['coverImage'],
                'monthlyRentMin': item['monthlyRentMin'],
                'availableRooms': item['availableRooms'] ?? 0,
                'propertyType': item['propertyType'] ?? 'PG',
                'isPublished': item['isPublished'] ?? false,
                'description': item['description'] ?? '',
                'addressLine': item['addressLine'] ?? '',
                'state': item['state'] ?? '',
              });
            }
          } catch (e) {
            debugPrint('Error fetching property $id: $e');
          }
        }
        
        setState(() {
          _properties = fetchedProperties;
          _isLoadingProperties = false;
        });
        return;
      }
      
      // ✅ METHOD 2: If no reels, try to get ALL properties and FILTER by owner
      try {
        final response = await ApiService().get(
          '/properties/search?page=0&size=100',
        );
        
        if (response.data['success'] == true) {
          final data = response.data['data'];
          List<dynamic> content = [];
          
          if (data is Map<String, dynamic>) {
            content = data['content'] as List? ?? [];
          } else if (data is List) {
            content = data;
          }
          
          // ✅ FILTER: Only show properties from this owner
          setState(() {
            _properties = content
                .where((item) {
                  // Try to match ownerId from the property data
                  final itemOwnerId = item['ownerId'] ?? item['ownerUserId'];
                  if (itemOwnerId != null) {
                    return itemOwnerId == widget.ownerId;
                  }
                  // If ownerId field doesn't exist, try to match from reels
                  // Check if this property ID exists in our reels
                  final propertyId = item['propertyId'] is int 
                      ? item['propertyId'] 
                      : int.tryParse(item['propertyId'].toString()) ?? 0;
                  return _reels.any((reel) => reel.propertyId == propertyId);
                })
                .map((item) => {
                  'propertyId': item['propertyId'] is int 
                      ? item['propertyId'] 
                      : int.tryParse(item['propertyId'].toString()) ?? 0,
                  'title': item['title'] ?? 'Unknown Property',
                  'city': item['city'] ?? '',
                  'coverImage': item['coverImage'],
                  'monthlyRentMin': item['monthlyRentMin'],
                  'availableRooms': item['availableRooms'] ?? 0,
                  'propertyType': item['propertyType'] ?? 'PG',
                  'isPublished': item['isPublished'] ?? false,
                })
                .toList();
            _isLoadingProperties = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Search API failed: $e');
      }
      
      // ✅ METHOD 3: If all fails, show empty
      setState(() {
        _properties = [];
        _isLoadingProperties = false;
      });
      
    } catch (e) {
      debugPrint('Error loading properties: $e');
      setState(() => _isLoadingProperties = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
      appBar: _buildAppBar(isDark),
      body: _isLoading
          ? _buildLoadingState(isDark)
          : _buildBody(isDark, bottomPadding),
    );
  }

  // ========== APP BAR ==========
  PreferredSizeWidget _buildAppBar(bool isDark) {
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
      title: Text(
        'Owner Profile',
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
          onPressed: _loadAllData,
        ),
      ],
    );
  }

  // ========== LOADING STATE ==========
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ========== BODY ==========
  Widget _buildBody(bool isDark, double bottomPadding) {
    if (_ownerDetail == null) {
      return _buildErrorState(isDark);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 20 + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOwnerHeader(isDark),
            const SizedBox(height: 16),
            _buildStatsRow(isDark),
            const SizedBox(height: 16),
            _buildTabBar(isDark),
            const SizedBox(height: 12),
            _buildTabContent(isDark),
          ],
        ),
      ),
    );
  }

  // ========== OWNER HEADER ==========
  Widget _buildOwnerHeader(bool isDark) {
    final owner = _ownerDetail!;
    final isVerified = owner['verificationStatus'] == 'VERIFIED' || owner['verificationStatus'] == 'APPROVED';
    final name = owner['name'] ?? 'Unknown Owner';
    final businessName = owner['businessName'];
    final displayId = owner['displayId'] ?? '';
    final profilePic = owner['profilePic'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1F33), const Color(0xFF141A2C)]
              : [Colors.white, const Color(0xFFF7F8FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: profilePic != null && profilePic.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: profilePic,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'O',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'O',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                    ],
                  ],
                ),
                if (businessName != null && businessName.isNotEmpty)
                  Text(
                    businessName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  displayId.isNotEmpty ? '@$displayId' : '',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isVerified ? '✅ Verified Owner' : '⏳ Pending Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  // ========== STATS ROW ==========
  Widget _buildStatsRow(bool isDark) {
    final totalLikes = _reels.fold<int>(0, (sum, reel) => sum + reel.likeCount);
    final totalViews = _reels.fold<int>(0, (sum, reel) => sum + reel.viewCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatItem('📹', _reels.length.toString(), 'Reels', isDark),
          const SizedBox(width: 8),
          _buildStatItem('🏠', _properties.length.toString(), 'Properties', isDark),
          const SizedBox(width: 8),
          _buildStatItem('❤️', totalLikes.toString(), 'Likes', isDark),
          const SizedBox(width: 8),
          _buildStatItem('👁️', totalViews.toString(), 'Views', isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ========== TAB BAR ==========
  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTabItem('🎬 Reels', 0, isDark),
          _buildTabItem('🏠 Properties', 1, isDark),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index, bool isDark) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: isSelected ? Colors.white : 
                  (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== TAB CONTENT ==========
  Widget _buildTabContent(bool isDark) {
    if (_selectedTab == 0) {
      return _buildReelsTab(isDark);
    } else {
      return _buildPropertiesTab(isDark);
    }
  }

  // ========== REELS TAB ==========
  Widget _buildReelsTab(bool isDark) {
    if (_isLoadingReels) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
      );
    }

    if (_reels.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.movie_creation_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No Reels Uploaded',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This owner hasn\'t uploaded any reels yet',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return _buildReelCard(reel, isDark);
      },
    );
  }

  Widget _buildReelCard(Reel reel, bool isDark) {
    return GestureDetector(
      onTap: () => _showReelDetail(reel),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: reel.videoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: const Icon(Icons.movie_creation_rounded, color: Colors.grey, size: 40),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: Center(
                        child: Icon(Icons.play_circle_filled_rounded, color: Colors.white70, size: 40),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          _buildSmallBadge(Icons.favorite_rounded, reel.likeCount, Colors.red),
                          const SizedBox(width: 4),
                          _buildSmallBadge(Icons.chat_bubble_rounded, reel.commentCount, Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reel.propertyTitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    reel.propertyCity,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 2),
          Text(
            count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // ========== PROPERTIES TAB ==========
  Widget _buildPropertiesTab(bool isDark) {
    if (_isLoadingProperties) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
      );
    }

    if (_properties.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.apartment_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No Properties',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This owner hasn\'t added any properties yet',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _properties.length,
      itemBuilder: (context, index) {
        final property = _properties[index];
        return _buildPropertyCard(property, isDark);
      },
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property, bool isDark) {
    final coverImage = property['coverImage'];
    final title = property['title'] ?? 'Unknown Property';
    final city = property['city'] ?? '';
    final monthlyRentMin = property['monthlyRentMin'];
    final availableRooms = property['availableRooms'] ?? 0;
    final propertyType = property['propertyType'] ?? 'PG';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(
              propertyId: property['propertyId'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: coverImage != null && coverImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: coverImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: isDark ? Colors.grey[500] : Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          city,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          propertyType,
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: const Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${availableRooms} rooms',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        monthlyRentMin != null
                            ? '₹${monthlyRentMin.toStringAsFixed(0)}'
                            : 'Contact',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFFF59E0B),
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

  // ========== REEL DETAIL BOTTOM SHEET ==========
  void _showReelDetail(Reel reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ReelPreviewBottomSheet(reel: reel),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAllData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ========== REEL PREVIEW BOTTOM SHEET ==========
class _ReelPreviewBottomSheet extends StatefulWidget {
  final Reel reel;

  const _ReelPreviewBottomSheet({required this.reel});

  @override
  State<_ReelPreviewBottomSheet> createState() => _ReelPreviewBottomSheetState();
}

class _ReelPreviewBottomSheetState extends State<_ReelPreviewBottomSheet>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
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
                      child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reel.propertyTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.reel.propertyCity,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                if (widget.reel.caption != null && widget.reel.caption!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2338) : const Color(0xFFF0F2F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.reel.caption!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildReelStat(Icons.favorite_rounded, widget.reel.likeCount, Colors.red),
                    const SizedBox(width: 16),
                    _buildReelStat(Icons.chat_bubble_rounded, widget.reel.commentCount, Colors.blue),
                    const SizedBox(width: 16),
                    _buildReelStat(Icons.visibility_rounded, widget.reel.viewCount, Colors.grey),
                    const SizedBox(width: 16),
                    _buildReelStat(Icons.share_rounded, widget.reel.shareCount, Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelStat(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : count.toString(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}