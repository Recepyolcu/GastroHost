import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String recipientName;
  final String recipientRole;
  final VoidCallback onBack;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.recipientName,
    required this.recipientRole,
    required this.onBack,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'sender': 'other',
      'text': 'Hello! I am preparing the fresh ingredients for your Truffle Experience tonight.',
      'time': '6:15 PM',
    },
    {
      'id': '2',
      'sender': 'me',
      'text': 'Great! Looking forward to it. We have a gluten-free guest joining us.',
      'time': '6:18 PM',
    },
    {
      'id': '3',
      'sender': 'other',
      'text': 'Noted! I have sourced gluten-free handmade pasta dough specifically for them.',
      'time': '6:20 PM',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().toString(),
        'sender': 'me',
        'text': text,
        'time': 'Just now',
      });
    });
    _messageController.clear();
    _scrollToBottom();
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
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          onPressed: widget.onBack,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                widget.recipientRole == 'chef'
                    ? 'https://lh3.googleusercontent.com/aida-public/AB6AXuCONoMmOXp0IjymBppcR4QkB6xr80XfagXEBCa0yI1Zt4NWfpJb6dPtzzSmAeUJCZ0UEdd9SEP-anJt2rq_REq4HHH3-K8902WrCKTp-oJluokeNMEJ8w5jKPmGBUZtB0bF9sTCTsBrvbCy2HVMAgcS2n4DSFhUG_gDEO1kbjiiDRKcw16uXYIwjsQE1rioTL1bVJW-635g42PTmwpQTKvuOc7jB-TrTegTDa_K8FhG5mF0rMFZXsHr'
                    : 'https://lh3.googleusercontent.com/aida-public/AB6AXuBZ39tPphYle75Gmb_6AjN9N3Z-66K_iukAW9tqVL7Gvj-M1QjUM5jbY0VtG4Qb2FKmM8YyL6sAdcl9tDWO0IbmiUezB7Q2u4DngEr_sjhOQKmL6MN0XgCF4uRygDK_xMQKt29dslAEAK2j3xcT543wQZ_dDD9oc7hYygS9QN2KC9WxaeYEUk9zCJXaB5Lov9WCtRpFlaFSEs0-YpngYnmp4cKFYZ04BdJLAatycv9bs_LAbzWprbbq',
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName.isNotEmpty ? widget.recipientName : 'Chef Marco',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  'Active now • Event #${widget.bookingId.substring(0, widget.bookingId.length > 6 ? 6 : widget.bookingId.length)}',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: palette.goldAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender'] == 'me';

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? (isDark ? palette.goldAccent : Colors.black)
                            : palette.surface,
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
                                  color: palette.goldAccent.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'],
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isMe
                                  ? (isDark ? const Color(0xFF0B0D11) : Colors.white)
                                  : palette.textPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'],
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: isMe
                                  ? (isDark ? const Color(0xFF0B0D11).withValues(alpha: 0.7) : Colors.white70)
                                  : palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick Suggestion Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildChip('Confirm arrival time', palette),
                  const SizedBox(width: 8),
                  _buildChip('Allergy notes', palette),
                  const SizedBox(width: 8),
                  _buildChip('Kitchen gate code', palette),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.add_circle_outline_rounded, color: palette.textMuted),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.manrope(fontSize: 14, color: palette.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type a message to Chef...',
                        hintStyle: GoogleFonts.manrope(fontSize: 13, color: palette.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send_rounded, color: palette.goldAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, AppThemePalette palette) {
    return InkWell(
      onTap: () {
        _messageController.text = label;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, color: palette.textPrimary),
        ),
      ),
    );
  }
}

