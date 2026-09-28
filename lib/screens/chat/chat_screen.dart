// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int otherUserId;
  final String otherUserName;
  final String? propertyTitle;
  final String? otherUserPic;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.propertyTitle,
    this.otherUserPic,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Design tokens ──────────────────────────────────────────
  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF1D4ED8);
  static const Color _darkBg = Color(0xFF0A0E1A);
  static const Color _darkSurface = Color(0xFF1A1F33);
  static const Color _lightBg = Color(0xFFF3F5F9);

  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  Timer? _typingStopTimer;
  bool _lastTypingState = false;
  bool _webSocketSetup = false;

  ChatProvider? _chatProvider;
  bool _providerReady = false;

  // 🆕 REPLY STATE
  Message? _replyToMessage;

  // 🆕 MULTI-TAP TRACKING
  int? _lastTappedMessageId;
  int _tapCount = 0;
  Timer? _tapResetTimer;

  // 🆕 PRESENCE STATE
  bool _presenceActive = false;

  // 🎨 UI-ONLY STATE (animations)
  final ValueNotifier<bool> _showScrollDown = ValueNotifier<bool>(false);
  final Set<int> _seenIds = <int>{}; // messages already shown (no entry anim)
  final Set<int> _forceAnimateIds = <int>{}; // messages I just sent
  final Set<int> _removingIds = <int>{}; // messages playing exit animation
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_providerReady) {
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _providerReady = true;
      if (_chatProvider != null && !_webSocketSetup) {
        _setupWebSocketListener();
      }

      // 🆕 MARK ACTIVE IN THIS CHAT (for smart notification)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markPresence(isActive: true);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // 🆕 Register lifecycle observer (for app background/foreground)
    WidgetsBinding.instance.addObserver(this);

    print('🔍 ═══ ChatScreen.initState ═══');
    print('🔍 conversationId: ${widget.conversationId}');
    print('🔍 otherUserId: ${widget.otherUserId}');
    print('🔍 otherUserName: ${widget.otherUserName}');
    print('🔍 ═══════════════════════════');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_chatProvider != null) {
          _chatProvider!.setActiveConversation(widget.conversationId);
          _chatProvider!.loadMessages(widget.conversationId);
        }
      }
    });

    _messageController.addListener(_updateSendButton);
    _messageController.addListener(_handleTypingChange);
    _scrollController.addListener(_onScroll);
    _focusNode.addListener(_onFocusChange);
  }

  // ============================================
  // 🎨 UI HELPERS (scroll + focus)
  // ============================================
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final far = (pos.maxScrollExtent - pos.pixels) > 240;
    if (_showScrollDown.value != far) _showScrollDown.value = far;
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {});
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted) _scrollToBottom();
      });
    }
  }

  // ============================================
  // 🆕 PRESENCE HELPER — tell backend if user is active in this chat
  // ============================================
  void _markPresence({required bool isActive}) {
    if (_chatProvider == null) return;
    if (_presenceActive == isActive) return;
    _presenceActive = isActive;
    _chatProvider!.wsManager.sendPresence(
      conversationId: widget.conversationId,
      isActive: isActive,
    );
  }

  // 🆕 APP LIFECYCLE — background/foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App background/closed → mark inactive
      _markPresence(isActive: false);
    } else if (state == AppLifecycleState.resumed) {
      // App foreground → mark active again
      _markPresence(isActive: true);
    }
  }

  void _setupWebSocketListener() {
    if (_webSocketSetup || _chatProvider == null) return;
    _webSocketSetup = true;

    _chatProvider!.wsManager.onMessageReceived = (message) {
      if (message.isMine) return;
      if (message.conversationId == widget.conversationId) {
        final exists = _chatProvider!.messages.any(
          (m) => m.messageId == message.messageId,
        );
        if (!exists) {
          _chatProvider!.addOptimisticMessage(message);
          _scrollToBottom();
          _chatService.markAsRead(widget.conversationId);
        }
      }
    };

    _chatProvider!.wsManager.onTypingReceived = (event) {
      if (event.senderId == widget.otherUserId) {
        _chatProvider!.setTypingStatus(event.conversationId, event.isTyping);
      }
    };

    _chatProvider!.wsManager.onMessageEdited = (message) {
      if (message.conversationId == widget.conversationId) {
        _chatProvider!.updateMessage(message);
      }
    };

    _chatProvider!.wsManager.onMessageDeleted = (message) {
      if (message.conversationId == widget.conversationId) {
        if (message.isDeletedForEveryone) {
          _chatProvider!.updateMessage(message);
        } else {
          _chatProvider!.removeMessage(message.messageId);
        }
      }
    };

    _chatProvider!.wsManager.onMessagesRead = (convId) {
      if (convId == widget.conversationId) {
        _chatProvider!.markAllMyMessagesAsRead();
        if (mounted) setState(() {});
      }
    };
  }

  void _updateSendButton() => setState(() {});

  void _handleTypingChange() {
    if (_chatProvider == null) return;
    final hasText = _messageController.text.trim().isNotEmpty;

    if (hasText && !_lastTypingState) {
      _lastTypingState = true;
      _chatProvider!.sendTypingIndicator(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId,
        isTyping: true,
      );
    }

    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 2), () {
      _lastTypingState = false;
      _chatProvider!.sendTypingIndicator(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId,
        isTyping: false,
      );
    });
  }

  @override
  void dispose() {
    // 🆕 Remove observer
    WidgetsBinding.instance.removeObserver(this);

    if (_chatProvider != null) {
      // 🆕 MARK INACTIVE BEFORE DISPOSING (so backend knows user left)
      _chatProvider!.wsManager.sendPresence(
        conversationId: widget.conversationId,
        isActive: false,
      );

      if (_lastTypingState) {
        _chatProvider!.sendTypingIndicator(
          conversationId: widget.conversationId,
          receiverId: widget.otherUserId,
          isTyping: false,
        );
      }
      _chatProvider!.setActiveConversation(null);
      _chatProvider!.wsManager.onMessagesRead = null;
      _chatProvider!.wsManager.onMessageReceived = null;
      _chatProvider!.wsManager.onMessageEdited = null;
      _chatProvider!.wsManager.onMessageDeleted = null;
      _chatProvider!.wsManager.onTypingReceived = null;
    }

    _typingStopTimer?.cancel();
    _tapResetTimer?.cancel();
    _messageController.removeListener(_updateSendButton);
    _messageController.removeListener(_handleTypingChange);
    _scrollController.removeListener(_onScroll);
    _focusNode.removeListener(_onFocusChange);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _showScrollDown.dispose();
    super.dispose();
  }

  // ============================================
  // SEND MESSAGE
  // ============================================
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending || _chatProvider == null) return;

    final replyTarget = _replyToMessage;

    _messageController.clear();
    setState(() => _replyToMessage = null);
    _lastTypingState = false;
    _chatProvider!.sendTypingIndicator(
      conversationId: widget.conversationId,
      receiverId: widget.otherUserId,
      isTyping: false,
    );

    setState(() => _isSending = true);

    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = Message(
      messageId: tempId,
      conversationId: widget.conversationId,
      senderId: 0,
      senderName: 'You',
      content: content,
      isRead: false,
      sentAt: DateTime.now(),
      isMine: true,
      isDeletedForEveryone: false,
      isEdited: false,
      editedAt: null,
      replyToMessageId: replyTarget?.messageId,
      replyToContent: replyTarget?.content,
      replyToSenderName: replyTarget?.senderName,
      replyToIsMine: replyTarget?.isMine,
    );

    // 🎨 make sure my new bubble plays the "send" entry animation
    _forceAnimateIds.add(tempId);
    HapticFeedback.lightImpact();

    _chatProvider!.addOptimisticMessage(tempMessage);
    _scrollToBottom();

    final response = await _chatService.sendMessage(
      widget.conversationId,
      content,
      replyToMessageId: replyTarget?.messageId,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (response.success && response.data != null) {
      // 🎨 real id should not re-play the entry animation
      _seenIds.add(response.data!.messageId);
      _chatProvider!.replaceOptimisticMessage(tempId, response.data!);
      _scrollToBottom();
    } else {
      _chatProvider!.removeOptimisticMessage(tempId);
      _showSnackBar(response.message, isError: true);
    }
  }

  // ============================================
  // REPLY
  // ============================================
  void _startReply(Message message) {
    HapticFeedback.mediumImpact();
    setState(() => _replyToMessage = message);
    _focusNode.requestFocus();
  }

  void _cancelReply() => setState(() => _replyToMessage = null);

  // ============================================
  // MULTI-TAP HANDLER
  // ============================================
  void _handleBubbleTap(Message message) {
    if (!message.isMine) return;
    if (message.isDeletedForEveryone) return;

    if (_lastTappedMessageId != message.messageId) {
      _lastTappedMessageId = message.messageId;
      _tapCount = 0;
    }

    _tapCount++;
    HapticFeedback.selectionClick();

    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(milliseconds: 450), () {
      final count = _tapCount;
      _tapCount = 0;
      _lastTappedMessageId = null;

      if (count == 2) {
        _deleteForMe(message);
      } else if (count >= 3) {
        _deleteForEveryone(message);
      }
    });
  }

  // ============================================
  // 🎨 ANIMATED DIALOG HELPER (fade + scale)
  // ============================================
  Future<T?> _showAnimatedDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = anim.drive(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================
  // LONG PRESS → Bottom Sheet
  // ============================================
  void _showMessageOptions(Message message) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMine = message.isMine;
    final isDeleted = message.isDeletedForEveryone;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? _darkSurface : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: (isMine
                                  ? _primary
                                  : const Color(0xFF22C55E))
                              .withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isMine
                              ? Icons.person_rounded
                              : Icons.person_outline_rounded,
                          color:
                              isMine ? _primary : const Color(0xFF22C55E),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMine ? 'You' : widget.otherUserName,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isDeleted
                                  ? 'This message was deleted'
                                  : (message.content ?? ''),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontStyle: isDeleted
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
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
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                const SizedBox(height: 8),
                if (!isDeleted)
                  _buildSheetOption(
                    icon: Icons.reply_rounded,
                    title: 'Reply',
                    color: _primary,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _startReply(message);
                    },
                  ),
                _buildSheetOption(
                  icon: Icons.copy_rounded,
                  title: 'Copy text',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(message);
                  },
                ),
                if (isMine && !isDeleted)
                  _buildSheetOption(
                    icon: Icons.edit_rounded,
                    title: 'Edit message',
                    color: const Color(0xFF22C55E),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _editMessage(message);
                    },
                  ),
                _buildSheetOption(
                  icon: Icons.info_outline_rounded,
                  title: 'Message info',
                  color: const Color(0xFF64748B),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    _showMessageInfo(message);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // DELETE FOR ME
  // ============================================
  Future<void> _deleteForMe(Message message) async {
    if (_chatProvider == null) return;

    final confirm = await _showConfirmDialog(
      title: 'Delete for me?',
      body: 'This message will be removed only from your side.',
      confirmLabel: 'Delete',
      confirmColor: const Color(0xFFF59E0B),
      icon: Icons.delete_outline_rounded,
    );

    if (confirm == true) {
      // 🎨 play smooth collapse/fade-out first
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _removingIds.add(message.messageId));
      await Future.delayed(const Duration(milliseconds: 340));
      if (!mounted) return;

      final success = await _chatProvider!.deleteForMe(message.messageId);
      if (!mounted) return;
      if (success) {
        _removingIds.remove(message.messageId);
        _showSnackBar('Message deleted for you');
      } else {
        // bring the bubble back smoothly
        setState(() => _removingIds.remove(message.messageId));
        _showSnackBar(
          _chatProvider!.error ?? 'Failed to delete message',
          isError: true,
        );
      }
    }
  }

  // ============================================
  // DELETE FOR EVERYONE
  // ============================================
  Future<void> _deleteForEveryone(Message message) async {
    if (_chatProvider == null) return;

    final confirm = await _showConfirmDialog(
      title: 'Delete for everyone?',
      body:
          'This message will be removed for everyone in this chat. This cannot be undone.',
      confirmLabel: 'Delete for Everyone',
      confirmColor: const Color(0xFFEF4444),
      icon: Icons.delete_forever_rounded,
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      final success = await _chatProvider!.deleteForEveryone(message.messageId);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Message deleted for everyone');
      } else {
        _showSnackBar(
          _chatProvider!.error ?? 'Failed to delete message',
          isError: true,
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
  }) {
    return _showAnimatedDialog<bool>(
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? _darkSurface : Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: confirmColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                confirmLabel,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // MESSAGE INFO
  // ============================================
  void _showMessageInfo(Message message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sentTime = message.sentAt;
    final dateStr =
        '${sentTime.day}/${sentTime.month}/${sentTime.year} at ${message.sentTime}';

    _showAnimatedDialog<void>(
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? _darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Message info',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Sent', dateStr, isDark),
            const SizedBox(height: 10),
            _buildInfoRow('Read', message.isRead ? 'Yes' : 'No', isDark),
            if (message.isEditedNow) ...[
              const SizedBox(height: 10),
              _buildInfoRow('Edited', 'Yes', isDark),
            ],
            const SizedBox(height: 10),
            _buildInfoRow('Type', 'Text', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // EDIT MESSAGE
  // ============================================
  Future<void> _editMessage(Message message) async {
    if (_chatProvider == null) return;

    final controller = TextEditingController(text: message.content);

    final result = await _showAnimatedDialog<bool>(
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? _darkSurface : Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Color(0xFF22C55E), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Edit Message',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            cursorColor: _primary,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Type your message...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              filled: true,
              fillColor: isDark ? const Color(0xFF232945) : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final success = await _chatProvider!.editMessage(
        messageId: message.messageId,
        content: controller.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        _showSnackBar('Message edited');
      } else {
        _showSnackBar(
          _chatProvider!.error ?? 'Failed to edit message',
          isError: true,
        );
      }
    }
  }

  void _copyMessage(Message message) {
    Clipboard.setData(ClipboardData(text: message.content ?? ''));
    _showSnackBar('Message copied');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor:
              isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ============================================
  // NAVIGATE TO OTHER USER PROFILE
  // ============================================
  void _navigateToOwnerProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myRole = (authProvider.user?.role ?? 'STUDENT').toUpperCase();
    final isOtherUserOwner = myRole != 'OWNER';

    print('═══════════════════════════════════════');
    print('🔍 [ChatScreen._navigateToOwnerProfile]');
    print('🔍 myRole: $myRole');
    print('🔍 myUserId: ${authProvider.user?.userId}');
    print('🔍 widget.otherUserId: ${widget.otherUserId}');
    print('🔍 widget.otherUserName: ${widget.otherUserName}');
    print('🔍 isOtherUserOwner: $isOtherUserOwner');
    print('🔍 → Passing userId: ${widget.otherUserId} to ProfileScreen');
    print('═══════════════════════════════════════');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userId: widget.otherUserId,
          isOwner: isOtherUserOwner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTextNotEmpty = _messageController.text.trim().isNotEmpty;

    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;
    final isLoadingMsgs = chatProvider.isLoading;
    final loadError = chatProvider.error;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? _darkBg : _lightBg,
        appBar: _buildPremiumAppBar(context, isDark),
        body: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isLoadingMsgs && messages.isEmpty
                    ? KeyedSubtree(
                        key: const ValueKey('loading'),
                        child: _buildLoadingState(isDark),
                      )
                    : loadError != null && messages.isEmpty
                        ? KeyedSubtree(
                            key: const ValueKey('error'),
                            child: _buildErrorState(isDark, loadError),
                          )
                        : messages.isEmpty
                            ? KeyedSubtree(
                                key: const ValueKey('empty'),
                                child: _buildEmptyState(isDark),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('list'),
                                child: _buildMessagesList(isDark, messages),
                              ),
              ),
            ),
            // 🎨 Reply bar slides in/out smoothly
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _replyToMessage != null
                    ? KeyedSubtree(
                        key: ValueKey('reply_${_replyToMessage!.messageId}'),
                        child: _buildReplyPreviewBar(isDark),
                      )
                    : const SizedBox(
                        key: ValueKey('no_reply'),
                        width: double.infinity,
                      ),
              ),
            ),
            _buildPremiumMessageInput(isDark, isTextNotEmpty),
          ],
        ),
      ),
    );
  }

  // ============================================
  // REPLY PREVIEW BAR
  // ============================================
  Widget _buildReplyPreviewBar(bool isDark) {
    final replyMsg = _replyToMessage!;
    final previewText = replyMsg.isDeletedForEveryone
        ? 'This message was deleted'
        : (replyMsg.content ?? '');
    final senderLabel = replyMsg.isMine ? 'You' : widget.otherUserName;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : Colors.white,
        border: Border(
          left: const BorderSide(color: _primary, width: 4),
          top: BorderSide(
            color: isDark ? const Color(0xFF262C45) : const Color(0xFFEDEFF3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: _primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderLabel',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              size: 20,
            ),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  // ============================================
  // APP BAR
  // ============================================
  PreferredSizeWidget _buildPremiumAppBar(
    BuildContext context,
    bool isDark,
  ) {
    final hasImage =
        widget.otherUserPic != null && widget.otherUserPic!.isNotEmpty;

    return AppBar(
      backgroundColor: isDark ? _darkSurface : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 52,
      shape: Border(
        bottom: BorderSide(
          color: isDark ? const Color(0xFF262C45) : const Color(0xFFEDEFF3),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: isDark ? Colors.white : const Color(0xFF4B5563),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToOwnerProfile,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasImage
                    ? null
                    : const LinearGradient(
                        colors: [_primary, Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: Border.all(
                  color: _primary.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: Colors.transparent,
                backgroundImage: hasImage
                    ? CachedNetworkImageProvider(widget.otherUserPic!)
                    : null,
                child: hasImage
                    ? null
                    : Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, provider, _) {
                      final isTyping =
                          provider.isOtherUserTyping(widget.conversationId);

                      Widget sub;
                      if (isTyping) {
                        sub = Text(
                          'typing...',
                          key: const ValueKey('typing'),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: _primary,
                          ),
                        );
                      } else if (widget.propertyTitle != null) {
                        sub = Text(
                          widget.propertyTitle!,
                          key: const ValueKey('property'),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      } else {
                        sub = const SizedBox.shrink(key: ValueKey('none'));
                      }

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.4),
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
                        child: sub,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // MESSAGES LIST
  // ============================================
  Widget _buildMessagesList(bool isDark, List<Message> messages) {
    final chatProvider = context.watch<ChatProvider>();
    final isTyping = chatProvider.isOtherUserTyping(widget.conversationId);

    // 🎨 First load → don't animate old messages, jump to latest
    if (!_seeded) {
      for (final m in messages) {
        if (!_forceAnimateIds.contains(m.messageId)) {
          _seenIds.add(m.messageId);
        }
      }
      _seeded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                cacheExtent: 600,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = message.isMine;
                  final showDate = index == 0 ||
                      messages[index - 1].sentAt.day != message.sentAt.day;

                  // 🎨 grouping (consecutive messages from same sender)
                  final prev = index > 0 ? messages[index - 1] : null;
                  final next =
                      index < messages.length - 1 ? messages[index + 1] : null;
                  final isFirstInGroup =
                      showDate || prev == null || prev.isMine != isMine;
                  final nextStartsNewDay =
                      next != null && next.sentAt.day != message.sentAt.day;
                  final isLastInGroup =
                      next == null || next.isMine != isMine || nextStartsNewDay;

                  // 🎨 should this bubble play entry animation?
                  final id = message.messageId;
                  final forced = _forceAnimateIds.remove(id);
                  final animate = forced || !_seenIds.contains(id);
                  _seenIds.add(id);

                  return _MessageEntry(
                    key: ValueKey('entry_$id'),
                    animate: animate,
                    isMine: isMine,
                    removing: _removingIds.contains(id),
                    child: Column(
                      children: [
                        if (showDate) _buildDateHeader(message.sentAt, isDark),
                        _buildMessageBubble(
                          message,
                          isMine,
                          isDark,
                          isFirstInGroup: isFirstInGroup,
                          isLastInGroup: isLastInGroup,
                        ),
                      ],
                    ),
                  );
                },
              ),
              // 🎨 scroll-to-bottom button
              Positioned(
                right: 14,
                bottom: 12,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _showScrollDown,
                  builder: (context, show, _) {
                    return IgnorePointer(
                      ignoring: !show,
                      child: AnimatedScale(
                        scale: show ? 1 : 0.6,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: show ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: _TapScale(
                            onTap: _scrollToBottom,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? _darkSurface : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF262C45)
                                      : const Color(0xFFE5E7EB),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.white : _primary,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // 🎨 typing bubble (animated in/out)
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.1, 0.4),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: isTyping
                ? Container(
                    key: const ValueKey('typing_bubble'),
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark ? _darkSurface : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _TypingDots(
                        color: isDark ? Colors.grey[400]! : Colors.grey[500]!,
                      ),
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('no_typing'),
                    width: double.infinity,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date, bool isDark) {
    final now = DateTime.now();
    String dateText;

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      dateText = 'Today';
    } else if (date.day == now.day - 1 &&
        date.month == now.month &&
        date.year == now.year) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day} ${_getMonth(date.month)} ${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? _darkSurface.withOpacity(0.9)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF262C45) : const Color(0xFFE9ECF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        dateText,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // ============================================
  // MESSAGE BUBBLE
  // ============================================
  Widget _buildMessageBubble(
    Message message,
    bool isMine,
    bool isDark, {
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final isDeleted = message.isDeletedForEveryone;

    const big = Radius.circular(20);
    const small = Radius.circular(6);
    const tail = Radius.circular(4);

    final radius = BorderRadius.only(
      topLeft: (!isMine && !isFirstInGroup) ? small : big,
      topRight: (isMine && !isFirstInGroup) ? small : big,
      bottomLeft: !isMine ? (isLastInGroup ? tail : small) : big,
      bottomRight: isMine ? (isLastInGroup ? tail : small) : big,
    );

    final bottomGap = isLastInGroup ? 10.0 : 3.0;

    return Dismissible(
      key: ValueKey('swipe_${message.messageId}'),
      direction: isDeleted
          ? DismissDirection.none
          : (isMine
              ? DismissDirection.startToEnd
              : DismissDirection.endToStart),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.22,
        DismissDirection.endToStart: 0.22,
      },
      confirmDismiss: (direction) async {
        _startReply(message);
        return false;
      },
      background:
          _buildSwipeBackground(isDark, isMine: isMine, bottomGap: bottomGap),
      secondaryBackground: isMine
          ? null
          : _buildSwipeBackground(isDark,
              isMine: false, bottomGap: bottomGap),
      child: GestureDetector(
        onTap: () => _handleBubbleTap(message),
        onLongPress: () => _showMessageOptions(message),
        child: Container(
          margin: EdgeInsets.only(bottom: bottomGap),
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(13, 8, 12, 7),
            decoration: BoxDecoration(
              gradient: isMine
                  ? const LinearGradient(
                      colors: [Color(0xFF3577F2), _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMine ? null : (isDark ? _darkSurface : Colors.white),
              borderRadius: radius,
              border: isMine
                  ? null
                  : Border.all(
                      color: isDark
                          ? const Color(0xFF262C45)
                          : const Color(0xFFEDEFF3),
                    ),
              boxShadow: [
                BoxShadow(
                  color: isMine
                      ? _primary.withOpacity(0.22)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isMine ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            // 🎨 smooth resize when a message is deleted for everyone / edited
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              alignment: isMine ? Alignment.topRight : Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isReply)
                    _buildQuotedReply(message, isMine, isDark),
                  _buildMessageBody(message, isMine, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Text + time/tick/edited (time sits inline at bottom-right, like pro chat apps)
  Widget _buildMessageBody(Message message, bool isMine, bool isDark) {
    final isDeleted = message.isDeletedForEveryone;

    final textColor = isMine
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF111827));
    final mutedColor = isMine
        ? Colors.white70
        : (isDark ? Colors.grey[400]! : Colors.grey[500]!);

    final metaWidth =
        46.0 + (isMine ? 20.0 : 0.0) + (message.isEditedNow ? 38.0 : 0.0);
    final spacer = WidgetSpan(
      child: SizedBox(width: metaWidth, height: 14),
    );

    Widget content;
    if (isDeleted) {
      content = Text.rich(
        key: const ValueKey('deleted'),
        TextSpan(
          style: GoogleFonts.poppins(
            fontStyle: FontStyle.italic,
            fontSize: 13,
            color: mutedColor,
          ),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(Icons.block_rounded, size: 14, color: mutedColor),
              ),
            ),
            const TextSpan(text: 'This message was deleted'),
            spacer,
          ],
        ),
      );
    } else if (message.content != null) {
      content = Text.rich(
        key: const ValueKey('content'),
        TextSpan(
          text: message.content!,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            color: textColor,
            height: 1.4,
          ),
          children: [spacer],
        ),
      );
    } else {
      content = SizedBox(key: const ValueKey('empty'), height: 14, width: metaWidth);
    }

    final metaColor = isMine
        ? Colors.white70
        : (isDark ? Colors.grey[400]! : Colors.grey[500]!);

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (message.isEditedNow) ...[
          Text(
            'edited',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: isMine
                  ? Colors.white60
                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          message.sentTime,
          style: GoogleFonts.poppins(fontSize: 9.5, color: metaColor),
        ),
        if (isMine) ...[
          const SizedBox(width: 3),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
              key: ValueKey(message.isRead),
              size: 15,
              color: message.isRead
                  ? const Color(0xFF7DD3FC)
                  : Colors.white70,
            ),
          ),
        ],
      ],
    );

    return Stack(
      children: [
        // 🎨 cross-fade between normal text and "deleted" state
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topLeft,
            children: [
              ...previous,
              if (current != null) current,
            ],
          ),
          child: content,
        ),
        Positioned(right: 0, bottom: 0, child: meta),
      ],
    );
  }

  Widget _buildSwipeBackground(
    bool isDark, {
    required bool isMine,
    double bottomGap = 8,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: bottomGap),
      padding: EdgeInsets.only(
        left: isMine ? 24 : 0,
        right: isMine ? 0 : 24,
      ),
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.reply_rounded,
          color: _primary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildQuotedReply(Message message, bool isMine, bool isDark) {
    final quoteBg = isMine
        ? Colors.black.withOpacity(0.18)
        : (isDark ? Colors.black.withOpacity(0.25) : Colors.grey[100]!);
    final quoteBorder =
        isMine ? Colors.white.withOpacity(0.6) : _primary;
    final nameColor = isMine
        ? Colors.white
        : (isDark ? const Color(0xFF60A5FA) : _primary);
    final textColor = isMine
        ? Colors.white.withOpacity(0.85)
        : (isDark ? Colors.grey[300]! : Colors.grey[700]!);

    final replySenderName =
        message.replyToIsMine == true ? 'You' : widget.otherUserName;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: quoteBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: quoteBorder, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            replySenderName,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: nameColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToContent ?? '',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: textColor,
              fontStyle: message.replyToContent == 'This message was deleted'
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================
  // INPUT
  // ============================================
  Widget _buildPremiumMessageInput(bool isDark, bool isTextNotEmpty) {
    final fieldBg = isDark ? const Color(0xFF232945) : const Color(0xFFF1F3F7);

    Widget sendChild;
    if (_isSending) {
      sendChild = const SizedBox(
        key: ValueKey('sending'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    } else if (isTextNotEmpty) {
      sendChild = const Icon(
        Icons.send_rounded,
        key: ValueKey('send'),
        color: Colors.white,
        size: 21,
      );
    } else {
      sendChild = Icon(
        Icons.mic_rounded,
        key: const ValueKey('mic'),
        color: isDark ? Colors.grey[500] : Colors.grey[400],
        size: 22,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF262C45) : const Color(0xFFEDEFF3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: fieldBg,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  size: 22,
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? _primary.withOpacity(0.8)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: _focusNode.hasFocus
                      ? [
                          BoxShadow(
                            color: _primary.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  cursorColor: _primary,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14.5,
                  ),
                  decoration: InputDecoration(
                    hintText: _replyToMessage != null
                        ? 'Type your reply...'
                        : 'Type a message...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _TapScale(
              onTap: isTextNotEmpty ? _sendMessage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isTextNotEmpty
                      ? _primary
                      : (isDark
                          ? const Color(0xFF2C3352)
                          : const Color(0xFFE5E8EF)),
                  shape: BoxShape.circle,
                  boxShadow: isTextNotEmpty
                      ? [
                          BoxShadow(
                            color: _primary.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween<double>(begin: 0.85, end: 1.0)
                          .animate(anim),
                      child: ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                    ),
                    child: sendChild,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // STATES
  // ============================================
  Widget _buildLoadingState(bool isDark) {
    final widths = [0.55, 0.40, 0.65, 0.35, 0.50, 0.60];
    final screenW = MediaQuery.of(context).size.width;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      itemCount: widths.length,
      itemBuilder: (context, i) {
        final mine = i.isOdd;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PulseBox(
              width: screenW * widths[i],
              height: 40.0 + (i % 3) * 12,
              radius: 18,
              color: mine
                  ? _primary.withOpacity(isDark ? 0.25 : 0.18)
                  : (isDark ? const Color(0xFF232945) : const Color(0xFFE4E8F0)),
            ),
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
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (_chatProvider != null) {
                    _chatProvider!.loadMessages(widget.conversationId);
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : _primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 54,
                color: isDark ? Colors.grey[600] : _primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No messages yet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start chatting with ${widget.otherUserName}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🎨 HELPER WIDGETS (UI only)
// ═══════════════════════════════════════════════════════════

/// Entry ("send") animation + exit ("delete") animation for a message row.
class _MessageEntry extends StatefulWidget {
  final Widget child;
  final bool animate;
  final bool isMine;
  final bool removing;

  const _MessageEntry({
    super.key,
    required this.child,
    required this.animate,
    required this.isMine,
    required this.removing,
  });

  @override
  State<_MessageEntry> createState() => _MessageEntryState();
}

class _MessageEntryState extends State<_MessageEntry>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _exit;

  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.animate ? 0.0 : 1.0,
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    _fade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));

    if (widget.animate) _enter.forward();
    if (widget.removing) _exit.forward();
  }

  @override
  void didUpdateWidget(covariant _MessageEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.removing != oldWidget.removing) {
      if (widget.removing) {
        _exit.forward();
      } else {
        _exit.reverse();
      }
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entering = AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        if (_enter.isCompleted) return child!;
        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              alignment:
                  widget.isMine ? Alignment.bottomRight : Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );

    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        if (_exit.value == 0) return child!;
        final t = _exit.value;
        final fade = 1.0 - Curves.easeIn.transform(math.min(1.0, t / 0.6));
        final sizeT = Curves.easeInOutCubic
            .transform(math.max(0.0, (t - 0.25) / 0.75));
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: (1.0 - sizeT).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1.0 - 0.06 * t,
                alignment:
                    widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: child,
              ),
            ),
          ),
        );
      },
      child: entering,
    );
  }
}

/// Small press-scale feedback for buttons.
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({required this.child, this.onTap});

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
        scale: _down ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Three bouncing dots for the typing bubble.
class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value - i * 0.16) % 1.0;
            final wave = math.sin(t * math.pi); // 0 → 1 → 0
            return Container(
              margin: EdgeInsets.only(right: i == 2 ? 0 : 4),
              child: Transform.translate(
                offset: Offset(0, -3.5 * wave),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.45 + 0.55 * wave),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Pulsing skeleton placeholder (loading state).
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