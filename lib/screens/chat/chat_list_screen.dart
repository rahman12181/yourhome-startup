// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yourhome/screens/home_screen.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────
  static const Color _primary = Color(0xFF2563EB);
  static const Color _darkBg = Color(0xFF0B0F1A);
  static const Color _darkSurface = Color(0xFF151B2E);
  static const Color _lightBg = Colors.white;
  static const Color _lightSurface = Color(0xFFF3F4F8);

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF0EA5E9), Color(0xFF2563EB)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Conversation> _filteredConversations = [];
  bool _isSearching = false;
  bool _wsListenerSetup = false; // 🆕
  ChatProvider? _chatProvider;

  // 🎨 UI state
  bool _showUnreadOnly = false;
  bool _introScheduled = false;
  bool _introDone = false;

  late final AnimationController _headerController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _headerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ChatProvider>(context, listen: false).loadConversations();
        _setupWebSocketListener(); // 🆕
      }
    });

    _searchController.addListener(_filterConversations);
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  // 🆕 CHAT LIST KE LIYE WS LISTENER (unread count ++)
  void _setupWebSocketListener() {
    if (_wsListenerSetup) return;
    _wsListenerSetup = true;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider = chatProvider;

    chatProvider.wsManager.onConversationUpdated = (conv) {
      print(
          '📩 [ChatList] Conversation update: convId=${conv.conversationId}, unread=${conv.unreadCount}');

      if (!mounted) return;

      final existingIndex = chatProvider.conversations
          .indexWhere((c) => c.conversationId == conv.conversationId);

      if (existingIndex != -1) {
        chatProvider.conversations[existingIndex] = conv;
      } else {
        chatProvider.conversations.insert(0, conv);
      }

      // Latest message ke hisaab se sort
      chatProvider.conversations.sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      _filterConversations();
      setState(() {});
    };

    print('✅ [ChatList] WS listener set up for conversation updates');
  }

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
    // 🆕 Listener clean karo
    _chatProvider?.wsManager.onConversationUpdated = null;

    _searchController.removeListener(_filterConversations);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _headerController.dispose();
    super.dispose();
  }

  // ============================================
  // NAVIGATION
  // ============================================
  void _openChat(BuildContext context, Conversation conversation) {
    HapticFeedback.selectionClick();
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
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
      ),
    ).then((_) {
      if (!mounted) return;
      Provider.of<ChatProvider>(context, listen: false).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chatProvider = context.watch<ChatProvider>();
    final conversations = chatProvider.conversations;
    final isLoading = chatProvider.isLoading;
    final error = chatProvider.error;

    final base = _isSearching ? _filteredConversations : conversations;
    final displayedConversations = _showUnreadOnly
        ? base.where((c) => c.unreadCount > 0).toList()
        : base;

    final totalUnread =
        conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
    final unreadChats = conversations.where((c) => c.unreadCount > 0).length;

    // 🎨 stagger intro only for the first render of the list
    if (displayedConversations.isNotEmpty && !_introScheduled) {
      _introScheduled = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        _introDone = true;
      });
    }

    Widget body;
    if (isLoading && conversations.isEmpty) {
      body = KeyedSubtree(
        key: const ValueKey('loading'),
        child: _buildLoadingState(isDark),
      );
    } else if (error != null && conversations.isEmpty) {
      body = KeyedSubtree(
        key: const ValueKey('error'),
        child: _buildErrorState(isDark, error),
      );
    } else if (conversations.isEmpty) {
      body = KeyedSubtree(
        key: const ValueKey('empty'),
        child: _buildEmptyState(isDark),
      );
    } else if (displayedConversations.isEmpty) {
      final onlyUnread = _showUnreadOnly && !_isSearching;
      body = KeyedSubtree(
        key: ValueKey(onlyUnread ? 'no_unread' : 'no_results'),
        child: onlyUnread
            ? _buildNoResultsState(
                isDark,
                icon: Icons.done_all_rounded,
                title: "You're all caught up",
                subtitle: 'No unread messages right now',
                actionLabel: 'Show all chats',
                onAction: () => setState(() => _showUnreadOnly = false),
              )
            : _buildNoResultsState(
                isDark,
                icon: Icons.search_off_rounded,
                title: 'No results found',
                subtitle: 'Try searching with different keywords',
                actionLabel: 'Clear search',
                onAction: () {
                  _searchController.clear();
                  _filterConversations();
                },
              ),
      );
    } else {
      body = KeyedSubtree(
        key: const ValueKey('list'),
        child: RefreshIndicator(
          onRefresh: () => Provider.of<ChatProvider>(context, listen: false)
              .loadConversations(),
          color: _primary,
          backgroundColor: isDark ? _darkSurface : Colors.white,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 28),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: displayedConversations.length,
            itemBuilder: (context, index) {
              final conversation = displayedConversations[index];
              final isLast = index == displayedConversations.length - 1;
              return _StaggerIn(
                key: ValueKey('chat_${conversation.conversationId}'),
                animate: !_introDone && index < 10,
                index: index,
                child: _buildChatItem(context, conversation, isDark, isLast),
              );
            },
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? _darkBg : _lightBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Column(
                    children: [
                      _buildHeader(
                          isDark, totalUnread, conversations.length),
                      _buildSearchBar(isDark),
                      _buildFilterChips(
                          isDark, conversations.length, unreadChats),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // HEADER
  // ============================================
  Widget _buildHeader(bool isDark, int totalUnread, int totalChats) {
    final subtitle = totalChats == 0
        ? 'No conversations yet'
        : totalUnread > 0
            ? '$totalUnread unread · $totalChats chats'
            : '$totalChats ${totalChats == 1 ? 'conversation' : 'conversations'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ...previous,
                      if (current != null) current,
                    ],
                  ),
                  child: Text(
                    subtitle,
                    key: ValueKey(subtitle),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: totalUnread > 0
                          ? _primary
                          : (isDark
                              ? const Color(0xFF8B93A7)
                              : const Color(0xFF6B7280)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _TapScale(
            onTap: () {
              HapticFeedback.selectionClick();
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              themeProvider.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? _darkSurface : _lightSurface,
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
                  child: FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                ),
                child: Icon(
                  isDark
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round_outlined,
                  key: ValueKey(isDark),
                  size: 20,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SEARCH
  // ============================================
    Widget _buildSearchBar(bool isDark) {
    final hasFocus = _searchFocusNode.hasFocus;
    final hasText = _searchController.text.isNotEmpty;

    // iPhone-style palette
    final bgColor = isDark
        ? const Color(0xFF1C1C1E)                        // iOS dark
        : const Color(0xFFF2F2F7);                       // iOS light grey

    final focusBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE8E8ED);

    final iconColor = isDark
        ? const Color(0xFF8E8E93)                        // iOS grey
        : const Color(0xFF8E8E93);

    final hintColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);

    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1C1C1E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 8, 17, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 40,
        decoration: BoxDecoration(
          color: hasFocus ? focusBgColor : bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),

            // Left search icon — iOS style
            Icon(
              Icons.search_rounded,
              color: iconColor,
              size: 18,
            ),

            const SizedBox(width: 8),

            // Input
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                cursorColor: _primary,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _filterConversations();
                  _searchFocusNode.unfocus();
                },
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: GoogleFonts.poppins(
                    color: hintColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            // Clear button (X) — iOS style
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: hasText
                  ? Padding(
                      key: const ValueKey('clear'),
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _filterConversations();
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),

            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
  // ============================================
  // FILTER CHIPS
  // ============================================
  Widget _buildFilterChips(bool isDark, int total, int unread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          _buildChip(
            isDark: isDark,
            label: 'All',
            selected: !_showUnreadOnly,
            onTap: () {
              if (_showUnreadOnly) {
                HapticFeedback.selectionClick();
                setState(() => _showUnreadOnly = false);
              }
            },
          ),
          const SizedBox(width: 8),
          _buildChip(
            isDark: isDark,
            label: 'Unread',
            count: unread,
            selected: _showUnreadOnly,
            onTap: () {
              if (!_showUnreadOnly) {
                HapticFeedback.selectionClick();
                setState(() => _showUnreadOnly = true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required bool isDark,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int count = 0,
  }) {
    final idleBg = isDark ? _darkSurface : _lightSurface;
    final idleText = isDark ? const Color(0xFFA5ADC2) : const Color(0xFF4B5563);

    return _TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primary : idleBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 240),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : idleText,
              ),
              child: Text(label),
            ),
            if (count > 0) ...[
              const SizedBox(width: 7),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.25)
                      : _primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================
  // CHAT ITEM
  // ============================================
  Widget _buildChatItem(
    BuildContext context,
    Conversation conversation,
    bool isDark,
    bool isLast,
  ) {
    final isUnread = conversation.unreadCount > 0;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8B93A7) : const Color(0xFF6B7280);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isUnread
              ? _primary.withOpacity(isDark ? 0.08 : 0.045)
              : Colors.transparent,
          child: InkWell(
            onTap: () => _openChat(context, conversation),
            splashColor: _primary.withOpacity(0.08),
            highlightColor: _primary.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(conversation, isUnread),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.otherUserName,
                                style: GoogleFonts.poppins(
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 15.5,
                                  color: titleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              conversation.lastMessageTime,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isUnread ? _primary : mutedColor,
                              ),
                            ),
                          ],
                        ),
                        if (conversation.propertyTitle != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.home_work_outlined,
                                size: 12,
                                color: _primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  conversation.propertyTitle!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Consumer<ChatProvider>(
                                builder: (context, provider, _) {
                                  final isTyping = provider.isOtherUserTyping(
                                      conversation.conversationId);

                                  final Widget line = isTyping
                                      ? Text(
                                          'typing...',
                                          key: const ValueKey('typing'),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: _primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Text(
                                          conversation.lastMessage ??
                                              'No messages yet',
                                          key: const ValueKey('last'),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            height: 1.3,
                                            color: isUnread
                                                ? titleColor
                                                : mutedColor,
                                            fontWeight: isUnread
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );

                                  return AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 220),
                                    layoutBuilder: (current, previous) =>
                                        Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        ...previous,
                                        if (current != null) current,
                                      ],
                                    ),
                                    child: line,
                                  );
                                },
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 10),
                              _buildUnreadBadge(conversation.unreadCount),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 86,
            endIndent: 16,
            color: isDark ? const Color(0xFF1C2238) : const Color(0xFFEFF1F5),
          ),
      ],
    );
  }

  Widget _buildUnreadBadge(int count) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(count),
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Conversation conversation, bool isUnread) {
    final hasImage = conversation.otherUserPic != null &&
        conversation.otherUserPic!.isNotEmpty;
    final name = conversation.otherUserName;
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final colors = _avatarGradients[hash % _avatarGradients.length];

    Widget initial() => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isUnread ? _primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: SizedBox(
          width: 50,
          height: 50,
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: conversation.otherUserPic!,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (_, __) => initial(),
                  errorWidget: (_, __, ___) => initial(),
                )
              : initial(),
        ),
      ),
    );
  }

  // ============================================
  // STATES
  // ============================================
  Widget _buildLoadingState(bool isDark) {
    final base = isDark ? const Color(0xFF1C2238) : const Color(0xFFE9ECF2);

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: 7,
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _PulseBox(width: 54, height: 54, radius: 27, color: base),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PulseBox(
                      width: 110.0 + (i % 3) * 30,
                      height: 13,
                      radius: 6,
                      color: base,
                    ),
                    const SizedBox(height: 9),
                    _PulseBox(
                      width: double.infinity,
                      height: 11,
                      radius: 6,
                      color: base,
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

  Widget _buildErrorState(bool isDark, String errorMessage) {
    return _FadeSlideIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 40,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
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
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () {
                  Provider.of<ChatProvider>(context, listen: false)
                      .loadConversations();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Try again',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return _FadeSlideIn(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // layered illustration
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(isDark ? 0.08 : 0.06),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(isDark ? 0.12 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), _primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'No chats yet',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start chatting with property owners',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
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
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return _FadeSlideIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? _darkSurface : _lightSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🎨 HELPER WIDGETS (UI only)
// ═══════════════════════════════════════════════════════════

/// Staggered fade + slide entrance for list rows.
class _StaggerIn extends StatefulWidget {
  final Widget child;
  final bool animate;
  final int index;

  const _StaggerIn({
    super.key,
    required this.child,
    required this.animate,
    required this.index,
  });

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.animate ? 0.0 : 1.0,
    );
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(curved);

    if (widget.animate) {
      Future.delayed(Duration(milliseconds: 55 * widget.index), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        if (_c.isCompleted) return child!;
        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(position: _slide, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Press-scale feedback.
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({super.key, required this.child, this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Pulsing skeleton placeholder.
class _PulseBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _PulseBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  State<_PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<_PulseBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Fade + slight upward slide on first build.
class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  const _FadeSlideIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - v)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}