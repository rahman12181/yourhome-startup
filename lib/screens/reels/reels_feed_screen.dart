// lib/screens/reels/reels_feed_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yourhome/providers/reel_provider.dart';
import 'package:yourhome/models/reel_model.dart';
import 'package:yourhome/screens/owner/owner_reel_profile_screen.dart';
import 'package:yourhome/screens/property_detail_screen.dart';

class ReelsFeedScreen extends StatefulWidget {
  const ReelsFeedScreen({super.key});

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  late AnimationController _heartAnimationController;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _isVideoInitialized = {};
  final Map<int, Timer> _viewTimers = {};

  final Map<int, bool> _showCenterIcon = {};
  final Map<int, IconData> _centerIcon = {};
  final Map<int, Timer> _iconHideTimers = {};

  int _currentPage = 0;
  bool _isLiking = false;
  int? _likingReelId;
  bool _isInitialLoad = true;
  bool _isHeartVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isHeartVisible = false;
          });
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReels();
    });
  }

  Future<void> _loadReels() async {
    final reelProvider = Provider.of<ReelProvider>(context, listen: false);
    await reelProvider.loadReelsFeed();
    setState(() {
      _isInitialLoad = false;
    });
    if (reelProvider.reels.isNotEmpty) {
      _initializeAndPlayVideo(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimationController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    for (final timer in _viewTimers.values) {
      timer.cancel();
    }
    for (final timer in _iconHideTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    final previousPage = _currentPage;
    _currentPage = index;

    if (_videoControllers.containsKey(previousPage)) {
      final prevController = _videoControllers[previousPage];
      if (prevController != null && prevController.value.isPlaying) {
        prevController.pause();
      }
    }

    _iconHideTimers[previousPage]?.cancel();
    _showCenterIcon[previousPage] = false;

    _initializeAndPlayVideo(index);

    _viewTimers[index]?.cancel();
    _viewTimers[index] = Timer(const Duration(seconds: 2), () {
      final reelProvider = Provider.of<ReelProvider>(context, listen: false);
      if (index < reelProvider.reels.length) {
        final reel = reelProvider.reels[index];
        reelProvider.registerView(reel.reelId);
      }
    });

    final reelProvider = Provider.of<ReelProvider>(context, listen: false);
    if (index >= reelProvider.reels.length - 3 && reelProvider.hasMore) {
      reelProvider.loadReelsFeed();
    }
  }

  void _initializeAndPlayVideo(int index) {
    final reelProvider = Provider.of<ReelProvider>(context, listen: false);
    if (index >= reelProvider.reels.length) return;

    final reel = reelProvider.reels[index];

    if (_videoControllers.containsKey(index)) {
      final controller = _videoControllers[index];
      if (controller != null && !controller.value.isPlaying) {
        controller.play();
      }
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(reel.videoUrl),
      );

      controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized[index] = true;
          });
          controller.play();
          controller.setLooping(true);
        }
      }).catchError((error) {
        debugPrint('❌ Video init error: $error');
        if (mounted) {
          setState(() {
            _isVideoInitialized[index] = false;
          });
        }
      });

      _videoControllers[index] = controller;
    } catch (e) {
      debugPrint('❌ Error creating video controller: $e');
    }
  }

  // ================= LIKE FUNCTION =================
  Future<void> _toggleLike(int reelId) async {
    if (_isLiking) return;
    setState(() {
      _isLiking = true;
      _likingReelId = reelId;
    });

    final reelProvider = Provider.of<ReelProvider>(context, listen: false);
    final reelIndex = reelProvider.reels.indexWhere((r) => r.reelId == reelId);
    if (reelIndex == -1) {
      setState(() {
        _isLiking = false;
        _likingReelId = null;
      });
      return;
    }

    final reel = reelProvider.reels[reelIndex];
    reel.isLikedByMe == true
        ? await reelProvider.unlikeReel(reelId)
        : await reelProvider.likeReel(reelId);

    setState(() {
      _isLiking = false;
      _likingReelId = null;
    });
  }

  // ================= COMMENT FUNCTION =================
  void _showCommentDialog(int reelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CommentBottomSheet(
        reelId: reelId,
        onCommentAdded: () {
          final reelProvider = Provider.of<ReelProvider>(context, listen: false);
          reelProvider.loadReelsFeed(refresh: true);
        },
      ),
    );
  }

  // ================= SHARE FUNCTION =================
  void _shareReel(int reelId) async {
    final reelProvider = Provider.of<ReelProvider>(context, listen: false);
    final reel = reelProvider.reels.firstWhere((r) => r.reelId == reelId);

    await Share.share(
      'Check out this property on YourHome!\n\n🏠 ${reel.propertyTitle}\n📍 ${reel.propertyCity}\n\nWatch the reel: ${reel.videoUrl}',
      subject: 'Property Reel - YourHome',
    );

    reelProvider.registerShare(reelId);
  }

  // ================= DOUBLE TAP LIKE =================
  void _doubleTapLike(int reelId) {
    setState(() {
      _isHeartVisible = true;
    });
    _heartAnimationController.forward(from: 0);
    _toggleLike(reelId);
  }

  // ================= PLAY/PAUSE =================
  void _togglePlayPause(int index) {
    final controller = _videoControllers[index];
    if (controller == null || !(_isVideoInitialized[index] ?? false)) return;

    _iconHideTimers[index]?.cancel();

    if (controller.value.isPlaying) {
      controller.pause();
      setState(() {
        _centerIcon[index] = Icons.pause_rounded;
        _showCenterIcon[index] = true;
      });
    } else {
      controller.play();
      setState(() {
        _centerIcon[index] = Icons.play_arrow_rounded;
        _showCenterIcon[index] = true;
      });
      _iconHideTimers[index] = Timer(const Duration(milliseconds: 550), () {
        if (mounted) {
          setState(() {
            _showCenterIcon[index] = false;
          });
        }
      });
    }
  }

  // ================= NAVIGATION - ✅ FIXED =================
  void _navigateToOwnerProfile(int ownerId, int propertyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerReelProfileScreen(
          ownerId: ownerId, propertyId: propertyId, // ✅ FIXED: Required parameter
        ),
      ),
    );
  }

  void _navigateToProperty(int propertyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(
          propertyId: propertyId, // ✅ FIXED: Required parameter
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final reelProvider = Provider.of<ReelProvider>(context);
    final reels = reelProvider.reels;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(reelProvider, isDark),
      body: _isInitialLoad || (reels.isEmpty && reelProvider.isLoading)
          ? _buildLoadingState()
          : reels.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: reels.length + (reelProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == reels.length) {
                      return _buildLoadingMore();
                    }
                    final reel = reels[index];
                    return _buildReelItem(
                      context,
                      reel,
                      index,
                      reelProvider,
                    );
                  },
                ),
    );
  }

  // ================= APP BAR =================
  PreferredSizeWidget _buildAppBar(ReelProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : const Color(0xFF2563EB))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.video_library_rounded,
              color: textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'YourHome',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: textColor,
            ),
          ),
        ],
      ),
      actions: [
        if (provider.isLoading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            ),
          ),
      ],
    );
  }

  // ================= REEL ITEM =================
  Widget _buildReelItem(
    BuildContext context,
    Reel reel,
    int index,
    ReelProvider provider,
  ) {
    final isInitialized = _isVideoInitialized[index] ?? false;
    final showIcon = _showCenterIcon[index] ?? false;
    final icon = _centerIcon[index] ?? Icons.play_arrow_rounded;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player - Full Screen
        Container(
          color: Colors.black,
          child: _videoControllers.containsKey(index) && isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoControllers[index]!.value.size.width,
                      height: _videoControllers[index]!.value.size.height,
                      child: VideoPlayer(_videoControllers[index]!),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),

        // Gradient Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Tap layer for play/pause and double tap
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _togglePlayPause(index),
            onDoubleTap: () => _doubleTapLike(reel.reelId),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Center Play/Pause Icon
        IgnorePointer(
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: showIcon ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
        ),

        // Double Tap Heart Animation
        if (_isHeartVisible)
          IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: _heartAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.5 + (_heartAnimationController.value * 0.8),
                    child: Opacity(
                      opacity: 1 - _heartAnimationController.value,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 120 + (_heartAnimationController.value * 60),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // CONTENT - Bottom Left
        Positioned(
          bottom: 34,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Owner Info - CLICKABLE ✅
              GestureDetector(
                onTap: () => _navigateToOwnerProfile(reel.ownerUserId, reel.propertyId),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: ClipOval(
                        child: reel.ownerProfilePic != null
                            ? CachedNetworkImage(
                                imageUrl: reel.ownerProfilePic!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: Colors.grey[800],
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                color: Colors.grey,
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                reel.ownerName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              if (reel.isVerifiedOwner) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '@${reel.ownerDisplayId}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Caption
              if (reel.caption != null && reel.caption!.isNotEmpty)
                Text(
                  reel.caption!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 4),

              // Property Info - CLICKABLE ✅
              GestureDetector(
                onTap: () => _navigateToProperty(reel.propertyId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reel.propertyTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ACTION BUTTONS - Right Side
        Positioned(
          bottom: 90,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like Button
              GestureDetector(
                onTap: () => _toggleLike(reel.reelId),
                child: Column(
                  children: [
                    _isLiking && _likingReelId == reel.reelId
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            reel.isLikedByMe == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: reel.isLikedByMe == true
                                ? Colors.red
                                : Colors.white,
                            size: 30,
                          ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(reel.likeCount),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Comment Button
              GestureDetector(
                onTap: () => _showCommentDialog(reel.reelId),
                child: Column(
                  children: [
                    const Icon(
                      Icons.mode_comment_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(reel.commentCount),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Share Button
              GestureDetector(
                onTap: () => _shareReel(reel.reelId),
                child: Column(
                  children: [
                    Transform.rotate(
                      angle: -0.35,
                      child: const Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(reel.shareCount),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= FORMAT COUNT =================
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  // ================= LOADING / EMPTY STATES =================
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading Reels...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 8),
            Text(
              'Loading more...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.video_library_rounded,
              size: 64,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Reels Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for property reels',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReels,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// ================= COMMENT BOTTOM SHEET =================
class _CommentBottomSheet extends StatefulWidget {
  final int reelId;
  final VoidCallback onCommentAdded;

  const _CommentBottomSheet({
    required this.reelId,
    required this.onCommentAdded,
  });

  @override
  State<_CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<_CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  List<ReelComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final reelProvider = Provider.of<ReelProvider>(context, listen: false);
    await reelProvider.getComments(widget.reelId);
    setState(() {
      _comments = reelProvider.comments;
    });
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final reelProvider = Provider.of<ReelProvider>(context, listen: false);
    final success = await reelProvider.addComment(
      reelId: widget.reelId,
      content: content,
    );

    setState(() => _isSending = false);

    if (success && mounted) {
      _commentController.clear();
      _loadComments();
      widget.onCommentAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('💬 Comment added!'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Comments',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _loadComments,
                  child: Text(
                    'Refresh',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No comments yet',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentItem(comment, isDark);
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.poppins(
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 14,
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendComment,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(ReelComment comment, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (comment.isMine)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  comment.content,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  _formatTimeAgo(comment.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}