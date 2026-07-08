// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_providerReady) {
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _providerReady = true;
      if (_chatProvider != null && !_webSocketSetup) {
        _setupWebSocketListener();
      }
    }
  }

  @override
  void initState() {
    super.initState();

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
  }

  void _setupWebSocketListener() {
    if (_webSocketSetup || _chatProvider == null) return;
    _webSocketSetup = true;

    print('🔌 Setting up WebSocket listeners for ChatScreen');

    _chatProvider!.wsManager.onMessageReceived = (message) {
      print('📩 [WS] Message received in ChatScreen: ${message.content}');
      
      if (message.conversationId == widget.conversationId) {
        final exists = _chatProvider!.messages.any(
          (m) => m.messageId == message.messageId
        );
        if (!exists) {
          _chatProvider!.addOptimisticMessage(message);
          _scrollToBottom();
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

    print('✅ WebSocket listeners set up successfully');
  }

  void _updateSendButton() {
    setState(() {});
  }

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
    if (_chatProvider != null) {
      if (_lastTypingState) {
        _chatProvider!.sendTypingIndicator(
          conversationId: widget.conversationId,
          receiverId: widget.otherUserId,
          isTyping: false,
        );
      }
      _chatProvider!.setActiveConversation(null);
    }

    _typingStopTimer?.cancel();
    _messageController.removeListener(_updateSendButton);
    _messageController.removeListener(_handleTypingChange);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending || _chatProvider == null) return;

    _messageController.clear();
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
    );

    _chatProvider!.addOptimisticMessage(tempMessage);
    _scrollToBottom();

    final response = await _chatService.sendMessage(
      widget.conversationId,
      content,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (response.success && response.data != null) {
      _chatProvider!.replaceOptimisticMessage(tempId, response.data!);
      _scrollToBottom();
    } else {
      _chatProvider!.removeOptimisticMessage(tempId);
      _showSnackBar(response.message, isError: true);
    }
  }

  void _navigateToOwnerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userId: widget.otherUserId,
          isOwner: true,
        ),
      ),
    );
  }

  // ============== EDIT MESSAGE ==============
  Future<void> _editMessage(Message message) async {
    if (_chatProvider == null) return;
    
    final controller = TextEditingController(text: message.content);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: Colors.blue[400]),
            const SizedBox(width: 10),
            Text(
              'Edit Message',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final success = await _chatProvider!.editMessage(
        messageId: message.messageId,
        content: controller.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        _showSnackBar('Message edited ✏️');
      } else {
        _showSnackBar(_chatProvider!.error ?? 'Failed to edit message',
            isError: true);
      }
    }
  }

  // ============== DELETE FOR EVERYONE ==============
  Future<void> _deleteForEveryone(Message message) async {
    if (_chatProvider == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red[400]),
            const SizedBox(width: 10),
            Text(
              'Delete for Everyone',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'This message will be deleted for everyone in the chat.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _chatProvider!.deleteForEveryone(message.messageId);

      if (!mounted) return;
      if (success) {
        _showSnackBar('Message deleted for everyone');
      } else {
        _showSnackBar(_chatProvider!.error ?? 'Failed to delete message',
            isError: true);
      }
    }
  }

  // ============== DELETE FOR ME ==============
  Future<void> _deleteForMe(Message message) async {
    if (_chatProvider == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.orange[400]),
            const SizedBox(width: 10),
            Text(
              'Delete for Me',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'This message will be deleted only for you.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _chatProvider!.deleteForMe(message.messageId);

      if (!mounted) return;
      if (success) {
        _showSnackBar('Message deleted for you');
      } else {
        _showSnackBar(_chatProvider!.error ?? 'Failed to delete message',
            isError: true);
      }
    }
  }

  // ============== COPY MESSAGE ==============
  void _copyMessage(Message message) {
    Clipboard.setData(ClipboardData(text: message.content ?? ''));
    _showSnackBar('Message copied 📋');
    Navigator.pop(context);
  }

  void _showMessageOptions(Message message) {
    HapticFeedback.mediumImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMine = message.isMine;
    final isDeleted = message.isDeletedForEveryone;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F33) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMine ? 'You' : widget.otherUserName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDeleted
                            ? 'This message was deleted'
                            : (message.content ?? ''),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDeleted
                              ? (isDark ? Colors.grey[500] : Colors.grey[400])
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isDeleted) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              message.sentTime,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                            ),
                            if (message.isEditedNow) ...[
                              const SizedBox(width: 4),
                              Text(
                                '• Edited',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildWhatsAppOption(
                  icon: Icons.copy_rounded,
                  title: 'Copy',
                  color: Colors.grey,
                  isDark: isDark,
                  onTap: () => _copyMessage(message),
                ),
                if (isMine && !isDeleted)
                  _buildWhatsAppOption(
                    icon: Icons.edit_rounded,
                    title: 'Edit',
                    color: Colors.blue,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _editMessage(message);
                    },
                  ),
                if (isMine && !isDeleted)
                  _buildWhatsAppOption(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete for Everyone',
                    color: Colors.red,
                    isDark: isDark,
                    isDanger: true,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteForEveryone(message);
                    },
                  ),
                if (!isDeleted)
                  _buildWhatsAppOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete for Me',
                    color: Colors.red,
                    isDark: isDark,
                    isDanger: true,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteForMe(message);
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

  Widget _buildWhatsAppOption({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDanger ? Colors.red.withOpacity(0.1) : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDanger ? Colors.red : color,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDanger ? Colors.red : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
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
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTextNotEmpty = _messageController.text.trim().isNotEmpty;

    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;
    final isLoadingMsgs = chatProvider.isLoading;
    final loadError = chatProvider.error;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        appBar: _buildPremiumAppBar(context, isDark),
        body: Column(
          children: [
            Expanded(
              child: isLoadingMsgs && messages.isEmpty
                  ? _buildLoadingState(isDark)
                  : loadError != null && messages.isEmpty
                      ? _buildErrorState(isDark, loadError)
                      : messages.isEmpty
                          ? _buildEmptyState(isDark)
                          : _buildMessagesList(isDark, messages),
            ),
            _buildPremiumMessageInput(isDark, isTextNotEmpty),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar(
    BuildContext context,
    bool isDark,
  ) {
    final hasImage = widget.otherUserPic != null && widget.otherUserPic!.isNotEmpty;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1F33) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : const Color(0xFF4B5563),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _navigateToOwnerProfile,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasImage ? null : const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: hasImage ? Colors.transparent : Colors.transparent,
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
            const SizedBox(width: 10),
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
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, provider, _) {
                      final isTyping = provider.isOtherUserTyping(widget.conversationId);
                      if (isTyping) {
                        return Text(
                          'typing...',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2563EB),
                          ),
                        );
                      }
                      if (widget.propertyTitle != null) {
                        return Text(
                          widget.propertyTitle!,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDark ? Colors.white : const Color(0xFF4B5563),
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessagesList(bool isDark, List<Message> messages) {
    final chatProvider = context.watch<ChatProvider>();
    final isTyping = chatProvider.isOtherUserTyping(widget.conversationId);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMine = message.isMine;
              final showDate = index == 0 ||
                  messages[index - 1].sentAt.day != message.sentAt.day;

              return Column(
                children: [
                  if (showDate) _buildDateHeader(message.sentAt, isDark),
                  _buildMessageBubble(message, isMine, isDark),
                ],
              );
            },
          ),
        ),
        if (isTyping)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.otherUserName} is typing...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontWeight: FontWeight.w500,
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

  Widget _buildMessageBubble(Message message, bool isMine, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF2563EB)
                    : (isDark ? const Color(0xFF1A1F33) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMine ? const Radius.circular(18) : Radius.zero,
                  bottomRight: isMine ? Radius.zero : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isDeletedForEveryone)
                    Text(
                      'This message was deleted',
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: isMine
                            ? Colors.white70
                            : (isDark ? Colors.grey[400] : Colors.grey[500]),
                      ),
                    )
                  else if (message.content != null)
                    Text(
                      message.content!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isMine
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.sentTime,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: isMine
                              ? Colors.white70
                              : (isDark ? Colors.grey[400] : Colors.grey[500]),
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 3),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: message.isRead
                              ? const Color(0xFF34B7F1)
                              : (isDark ? Colors.grey[500] : Colors.grey[500]),
                        ),
                      ],
                      if (message.isEditedNow) ...[
                        const SizedBox(width: 3),
                        Text(
                          'edited',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontStyle: FontStyle.italic,
                            color: isMine
                                ? Colors.white60
                                : (isDark ? Colors.grey[500] : Colors.grey[500]),
                          ),
                        ),
                      ],
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

  Widget _buildPremiumMessageInput(bool isDark, bool isTextNotEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  size: 24,
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? const Color(0xFF2563EB)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.poppins(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: isTextNotEmpty ? _sendMessage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isTextNotEmpty
                      ? const Color(0xFF2563EB)
                      : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  shape: BoxShape.circle,
                  boxShadow: isTextNotEmpty
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: _isSending
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        isTextNotEmpty ? Icons.send_rounded : Icons.mic_rounded,
                        color: isTextNotEmpty
                            ? Colors.white
                            : (isDark ? Colors.grey[500] : Colors.grey[400]),
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading messages...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String errorMessage) {
    return Center(
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
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
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
    );
  }
}