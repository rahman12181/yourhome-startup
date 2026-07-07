// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yourhome/screens/home_screen.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import 'chat_screen.dart';
import '../profile_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Conversation> _filteredConversations = [];
  bool _isSearching = false;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late AnimationController _staggerController;
  late List<Animation<double>> _staggerAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // ✅ CHANGED — load via provider, no local ChatService/local WS listener anymore
    Provider.of<ChatProvider>(context, listen: false).loadConversations();

    _searchController.addListener(_filterConversations);

    // ❌ REMOVED — _setupWebSocketListener() is gone.
    // ChatProvider owns onConversationUpdated globally now, so this screen
    // just watches provider.conversations and rebuilds automatically.
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleIn = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _staggerAnimations = List.generate(20, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            index * 0.05,
            0.5 + (index * 0.025),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _animationController.forward();
    _staggerController.forward();
  }

  // ✅ CHANGED — filters straight from provider.conversations instead of local _conversations
  void _filterConversations() {
    final query = _searchController.text.toLowerCase().trim();
    final allConversations =
        Provider.of<ChatProvider>(context, listen: false).conversations;

    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredConversations = allConversations;
      } else {
        _filteredConversations = allConversations.where((conv) {
          return conv.otherUserName.toLowerCase().contains(query) ||
              (conv.propertyTitle?.toLowerCase().contains(query) ?? false) ||
              (conv.lastMessage?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterConversations);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ CHANGED — watch provider so any real-time conversation-update rebuilds this screen
    final chatProvider = context.watch<ChatProvider>();
    final conversations = chatProvider.conversations;
    final isLoading = chatProvider.isLoading;
    final error = chatProvider.error;

    // keep the filtered list in sync with provider unless actively searching
    final displayedConversations =
        _isSearching ? _filteredConversations : conversations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildPremiumAppBar(context, isDark, conversations.length),
              _buildPremiumSearchBar(context, isDark),
              Expanded(
                child: isLoading && conversations.isEmpty
                    ? _buildLoadingState(isDark)
                    : error != null && conversations.isEmpty
                        ? _buildErrorState(isDark, error)
                        : conversations.isEmpty
                            ? _buildEmptyState(isDark)
                            : displayedConversations.isEmpty
                                ? _buildNoResultsState(isDark)
                                : FadeTransition(
                                    opacity: _fadeIn,
                                    child: SlideTransition(
                                      position: _slideUp,
                                      child: ScaleTransition(
                                        scale: _scaleIn,
                                        child: RefreshIndicator(
                                          onRefresh: () => Provider.of<ChatProvider>(
                                                  context,
                                                  listen: false)
                                              .loadConversations(), // ✅ CHANGED
                                          color: const Color(0xFF2563EB),
                                          child: ListView.builder(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            physics: const BouncingScrollPhysics(),
                                            itemCount: displayedConversations.length,
                                            itemBuilder: (context, index) {
                                              final conversation = displayedConversations[index];
                                              final animation = _staggerAnimations[index % _staggerAnimations.length];
                                              
                                              return FadeTransition(
                                                opacity: animation,
                                                child: SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0, 0.04),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: _buildPremiumChatItem(
                                                    context,
                                                    conversation,
                                                    isDark,
                                                    index,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== PREMIUM APP BAR ==========
  // ✅ CHANGED — takes totalChats as parameter instead of using this._conversations
  Widget _buildPremiumAppBar(BuildContext context, bool isDark, int totalChats) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F33) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chats',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  totalChats > 0 
                      ? '$totalChats conversations' 
                      : 'No conversations yet',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                color: isDark ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                size: 20,
              ),
              onPressed: () {
                final themeProvider = Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                );
                themeProvider.setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ========== PREMIUM SEARCH BAR ==========
  Widget _buildPremiumSearchBar(BuildContext context, bool isDark) {
    final hasFocus = _searchFocusNode.hasFocus;
    final hasText = _searchController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (_) {
          _filterConversations();
          setState(() {});
        },
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: const Color(0xFF2563EB),
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey[500] : Colors.grey[400],
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: hasFocus
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.grey[500] : Colors.grey[400]),
            size: 22,
          ),
          suffixIcon: hasText
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterConversations();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF141A2E) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  // ========== PREMIUM CHAT ITEM ==========
  Widget _buildPremiumChatItem(
    BuildContext context,
    Conversation conversation,
    bool isDark,
    int index,
  ) {
    final hasImage = conversation.otherUserPic != null &&
        conversation.otherUserPic!.isNotEmpty;
    final isUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChatScreen(
              conversationId: conversation.conversationId,
              otherUserId: conversation.otherUserId,
              otherUserName: conversation.otherUserName,
              propertyTitle: conversation.propertyTitle,
              otherUserPic: conversation.otherUserPic,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ).then((_) {
          // ✅ CHANGED — refresh via provider when coming back from a chat
          Provider.of<ChatProvider>(context, listen: false).loadConversations();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(
                  color: const Color(0xFF2563EB).withOpacity(0.2),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isUnread
                  ? const Color(0xFF2563EB).withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with Online Status
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF2563EB),
                  backgroundImage: hasImage
                      ? CachedNetworkImageProvider(conversation.otherUserPic!)
                      : null,
                  child: hasImage
                      ? null
                      : Text(
                          conversation.otherUserName.isNotEmpty
                              ? conversation.otherUserName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUserName,
                          style: GoogleFonts.poppins(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.lastMessageTime,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (conversation.propertyTitle != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            conversation.propertyTitle!,
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        // ✅ CHANGED — shows "typing..." live if the other user is typing
                        // in this conversation, otherwise the last message
                        child: Consumer<ChatProvider>(
                          builder: (context, provider, _) {
                            final isTyping = provider
                                .isOtherUserTyping(conversation.conversationId);
                            if (isTyping) {
                              return Text(
                                'typing...',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            return Text(
                              conversation.lastMessage ?? 'No messages yet',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isUnread
                                    ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
                                    : (isDark ? Colors.grey[400] : Colors.grey[500]),
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Unread Badge
            if (isUnread) ...[
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(5),
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
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== LOADING STATE ==========
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
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.25),
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
          const SizedBox(height: 14),
          Text(
            'Loading chats...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ========== ERROR STATE ==========
  // ✅ CHANGED — takes error string, retries via provider
  Widget _buildErrorState(bool isDark, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<ChatProvider>(context, listen: false)
                    .loadConversations(); // ✅ CHANGED
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Chats Yet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start chatting with property owners',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final homeState = HomeScreen.navigatorKey.currentState;
                  if (homeState != null) {
                    homeState.changeTab(1);
                  }
                },
                icon: const Icon(Icons.search_rounded, size: 20),
                label: Text(
                  'Browse Properties',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== NO RESULTS STATE ==========
  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with different keywords',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _filterConversations();
              },
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: Text(
                'Clear Search',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}