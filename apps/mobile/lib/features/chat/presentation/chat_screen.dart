import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
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
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B1C1C),
                  ),
                ),
                Text(
                  'Active now • Event #${widget.bookingId.substring(0, widget.bookingId.length > 6 ? 6 : widget.bookingId.length)}',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF7B5800),
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
                        color: isMe ? Colors.black : const Color(0xFFEFEDED),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'],
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: isMe ? Colors.white : const Color(0xFF1B1C1C),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'],
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : const Color(0xFF747878),
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
                  _buildChip('Confirm arrival time'),
                  const SizedBox(width: 8),
                  _buildChip('Allergy notes'),
                  const SizedBox(width: 8),
                  _buildChip('Kitchen gate code'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE4E2E2))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF747878)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.manrope(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message to Chef...',
                        hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return InkWell(
      onTap: () {
        _messageController.text = label;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E2E2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF1B1C1C)),
        ),
      ),
    );
  }
}
