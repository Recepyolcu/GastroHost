import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String recipientName;
  final String recipientRole;
  final VoidCallback onBack;
  final Function(Map<String, dynamic> provider)? onOpenChefProfile;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.recipientName,
    required this.recipientRole,
    required this.onBack,
    this.onOpenChefProfile,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentBookingId;

  @override
  void initState() {
    super.initState();
    _currentBookingId = widget.bookingId.isNotEmpty ? widget.bookingId : 'GH-94821';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final effectiveId = _currentBookingId!;
      ref.read(chatProvider.notifier).ensureConversationExists(
            bookingId: effectiveId,
            recipientName: widget.recipientName.isNotEmpty ? widget.recipientName : 'Chef Julian',
            recipientRole: widget.recipientRole.isNotEmpty ? widget.recipientRole : 'Executive Chef',
          );
      ref.read(chatProvider.notifier).markAsRead(effectiveId);
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookingId != oldWidget.bookingId && widget.bookingId.isNotEmpty) {
      _currentBookingId = widget.bookingId;
      ref.read(chatProvider.notifier).markAsRead(_currentBookingId!);
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty || _currentBookingId == null) return;

    final bool isRecipientCustomer =
        widget.recipientRole.toLowerCase().contains('customer') ||
            widget.recipientRole.toLowerCase().contains('müşteri');
    final String effectiveSenderRole =
        isRecipientCustomer ? 'chef' : 'customer';

    ref.read(chatProvider.notifier).sendMessage(
          bookingId: _currentBookingId!,
          text: text,
          senderRole: effectiveSenderRole,
          senderName: 'Siz',
        );

    if (customText == null) {
      _messageController.clear();
    }
    _scrollToBottom();
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Bugün';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Dün';
    } else {
      const months = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);
    final chatState = ref.watch(chatProvider);

    final bookingId = _currentBookingId ?? chatState.activeBookingId ?? 'GH-94821';
    final conversation = chatState.conversations[bookingId] ??
        chatState.activeConversation ??
        const ChatConversation(
          bookingId: 'GH-94821',
          recipientName: 'Chef Julian',
          recipientRole: 'Executive Chef',
          recipientImage:
              'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80',
          messages: [],
        );

    final messages = conversation.messages;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          onPressed: widget.onBack,
        ),
        title: InkWell(
          onTap: () {
            if (widget.onOpenChefProfile != null) {
              widget.onOpenChefProfile!({
                'name': conversation.recipientName,
                'role': conversation.recipientRole,
                'image': conversation.recipientImage,
                'rating': '4.9',
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: palette.surfaceElevated,
                      backgroundImage: NetworkImage(conversation.recipientImage),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.bg, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              conversation.recipientName,
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded, color: palette.goldAccent, size: 14),
                        ],
                      ),
                      Text(
                        '${conversation.recipientRole} • Profili İncele',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: palette.goldAccent,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Multi-Conversation Switcher Chips (if more than 1 chat exists)
            if (chatState.conversations.length > 1) ...[
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: chatState.conversations.values.map((conv) {
                    final isSelected = conv.bookingId == bookingId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: conv.unreadCount > 0
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        label: Text(
                          '${conv.recipientName} (#${conv.bookingId})',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? const Color(0xFF0B0D11) : Colors.white)
                                : palette.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: isDark ? palette.goldAccent : Colors.black,
                        backgroundColor: palette.surfaceElevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSelected ? Colors.transparent : palette.border),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _currentBookingId = conv.bookingId;
                            });
                            ref.read(chatProvider.notifier).setActiveBooking(conv.bookingId);
                            _scrollToBottom();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Divider(height: 1, color: palette.borderSubtle),
            ],

            // Message List
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 48, color: palette.goldAccent.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              '${conversation.recipientName} ile Mesajlaşın',
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Etkinlik detayları, mutfak hazırlığı veya varış saatiyle ilgili sorularınızı iletin.',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: palette.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.isCustomer;

                        // Check if we should render a date header separator
                        bool showDateHeader = false;
                        if (index == 0) {
                          showDateHeader = true;
                        } else {
                          final prevMsg = messages[index - 1];
                          final prevDate = DateTime(prevMsg.createdAt.year, prevMsg.createdAt.month, prevMsg.createdAt.day);
                          final currDate = DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
                          if (prevDate != currDate) {
                            showDateHeader = true;
                          }
                        }

                        return Column(
                          children: [
                            if (showDateHeader) _buildDateHeader(msg.createdAt, palette),
                            _buildMessageBubble(msg, isMe, palette, isDark),
                          ],
                        );
                      },
                    ),
            ),

            // Quick Suggestion Chips (Pure Text Templates)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickTextChip('Varış saatinizi teyit edebilir miyiz?', palette),
                  const SizedBox(width: 8),
                  _buildQuickTextChip('Alerjen notunu menüye ekledim.', palette),
                  const SizedBox(width: 8),
                  _buildQuickTextChip('Mutfak ve ocak hazır durumda.', palette),
                  const SizedBox(width: 8),
                  _buildQuickTextChip('Kapı / Zil Kodu: 14', palette),
                ],
              ),
            ),

            // Pure Text Input Bar (No media, camera, or gallery buttons)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: palette.borderSubtle),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        keyboardType: TextInputType.text,
                        maxLines: null,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: palette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '${conversation.recipientName}\'e mesaj yazın...',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: 13,
                            color: palette.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send Button
                  InkWell(
                    onTap: () => _sendMessage(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? palette.goldAccent : Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: palette.goldAccent.withValues(alpha: isDark ? 0.3 : 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: isDark ? const Color(0xFF0B0D11) : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, AppThemePalette palette) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        _formatDateHeader(date),
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: palette.textMuted,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, AppThemePalette palette, bool isDark) {
    final bubbleColor = isMe
        ? (isDark ? palette.goldAccent : Colors.black)
        : palette.surface;

    final textColor = isMe
        ? (isDark ? const Color(0xFF0B0D11) : Colors.white)
        : palette.textPrimary;

    final timeColor = isMe
        ? (isDark ? const Color(0xFF0B0D11).withValues(alpha: 0.7) : Colors.white70)
        : palette.textMuted;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          border: isMe ? null : Border.all(color: palette.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: isMe && isDark
              ? [
                  BoxShadow(
                    color: palette.goldAccent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message text
            Text(
              msg.text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),

            // Timestamp and Read Receipts
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(msg.createdAt),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: timeColor,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusTick(msg.status, isDark, palette),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTick(MessageDeliveryStatus status, bool isDark, AppThemePalette palette) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: isDark ? const Color(0xFF0B0D11) : Colors.white70,
          ),
        );
      case MessageDeliveryStatus.sent:
        // Single Grey Tick
        return Icon(
          Icons.check_rounded,
          size: 13,
          color: isDark ? const Color(0xFF0B0D11).withValues(alpha: 0.6) : Colors.white60,
        );
      case MessageDeliveryStatus.delivered:
        // Double Grey Ticks
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 13, color: isDark ? const Color(0xFF0B0D11).withValues(alpha: 0.6) : Colors.white60),
            Transform.translate(
              offset: const Offset(-6, 0),
              child: Icon(Icons.check_rounded, size: 13, color: isDark ? const Color(0xFF0B0D11).withValues(alpha: 0.6) : Colors.white60),
            ),
          ],
        );
      case MessageDeliveryStatus.read:
        // Double Gold / Accent Ticks
        final tickColor = isDark ? const Color(0xFF0B0D11) : const Color(0xFFFDC34D);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded, size: 14, color: tickColor),
          ],
        );
    }
  }

  Widget _buildQuickTextChip(String text, AppThemePalette palette) {
    return InkWell(
      onTap: () => _sendMessage(text),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.borderSubtle),
        ),
        child: Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
      ),
    );
  }
}
