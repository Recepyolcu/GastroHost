import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
}

class ChatMessage {
  final String id;
  final String bookingId;
  final String senderRole; // 'customer' or 'chef' or 'bartender'
  final String senderName;
  final String text;
  final DateTime createdAt;
  final MessageDeliveryStatus status;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.status = MessageDeliveryStatus.sent,
    this.readAt,
  });

  bool get isCustomer => senderRole == 'customer';

  ChatMessage copyWith({
    String? id,
    String? bookingId,
    String? senderRole,
    String? senderName,
    String? text,
    DateTime? createdAt,
    MessageDeliveryStatus? status,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
    );
  }
}

class ChatConversation {
  final String bookingId;
  final String recipientName;
  final String recipientRole;
  final String recipientImage;
  final List<ChatMessage> messages;

  const ChatConversation({
    required this.bookingId,
    required this.recipientName,
    required this.recipientRole,
    required this.recipientImage,
    this.messages = const [],
  });

  int get unreadCount =>
      messages.where((m) => m.senderRole != 'customer' && m.status != MessageDeliveryStatus.read).length;

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  ChatConversation copyWith({
    String? bookingId,
    String? recipientName,
    String? recipientRole,
    String? recipientImage,
    List<ChatMessage>? messages,
  }) {
    return ChatConversation(
      bookingId: bookingId ?? this.bookingId,
      recipientName: recipientName ?? this.recipientName,
      recipientRole: recipientRole ?? this.recipientRole,
      recipientImage: recipientImage ?? this.recipientImage,
      messages: messages ?? this.messages,
    );
  }
}

class ChatState {
  final Map<String, ChatConversation> conversations;
  final String? activeBookingId;

  const ChatState({
    this.conversations = const {},
    this.activeBookingId,
  });

  ChatConversation? get activeConversation {
    if (activeBookingId != null && conversations.containsKey(activeBookingId)) {
      return conversations[activeBookingId];
    }
    if (conversations.isNotEmpty) {
      return conversations.values.first;
    }
    return null;
  }

  int get totalUnreadCount =>
      conversations.values.fold(0, (sum, conv) => sum + conv.unreadCount);

  ChatState copyWith({
    Map<String, ChatConversation>? conversations,
    String? activeBookingId,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      activeBookingId: activeBookingId ?? this.activeBookingId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(_initialState());

  static ChatState _initialState() {
    final now = DateTime.now();

    final julianConv = ChatConversation(
      bookingId: 'GH-94821',
      recipientName: 'Chef Julian',
      recipientRole: 'Executive Chef & Gastronomi Danışmanı',
      recipientImage:
          'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80',
      messages: [
        ChatMessage(
          id: 'msg_1',
          bookingId: 'GH-94821',
          senderRole: 'chef',
          senderName: 'Chef Julian',
          text: 'Merhabalar! Bu akşamki Trüflü İtalyan Tadım Menüsü için tüm taze malzemeleri tedarik ettim.',
          createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
          status: MessageDeliveryStatus.read,
          readAt: now.subtract(const Duration(hours: 2, minutes: 20)),
        ),
        ChatMessage(
          id: 'msg_2',
          bookingId: 'GH-94821',
          senderRole: 'customer',
          senderName: 'Siz',
          text: 'Harika Chef! Misafirlerimizden birinin fıstık alerjisi var, tatlıda dikkat edebilirseniz çok seviniriz.',
          createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
          status: MessageDeliveryStatus.read,
          readAt: now.subtract(const Duration(hours: 2, minutes: 10)),
        ),
        ChatMessage(
          id: 'msg_3',
          bookingId: 'GH-94821',
          senderRole: 'chef',
          senderName: 'Chef Julian',
          text: 'Kesinlikle, notumu aldım. O porsiyonu tamamen fıstıksız ve güvenli ayrı bir kapta hazırlayacağım.',
          createdAt: now.subtract(const Duration(hours: 2, minutes: 8)),
          status: MessageDeliveryStatus.read,
          readAt: now.subtract(const Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'msg_4',
          bookingId: 'GH-94821',
          senderRole: 'chef',
          senderName: 'Chef Julian',
          text: 'Yaklaşık 45 dakika içinde adresinize varmış ve hazırlıklara başlamış olurum.',
          createdAt: now.subtract(const Duration(minutes: 35)),
          status: MessageDeliveryStatus.delivered,
          readAt: null,
        ),
      ],
    );

    final marcusConv = ChatConversation(
      bookingId: 'GH-82194',
      recipientName: 'Marcus T.',
      recipientRole: 'Master Mixologist & Bar Danışmanı',
      recipientImage:
          'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&auto=format&fit=crop&q=80',
      messages: [
        ChatMessage(
          id: 'msg_m1',
          bookingId: 'GH-82194',
          senderRole: 'bartender',
          senderName: 'Marcus T.',
          text: 'Selamlar! Kristal elmas buzlar ve özel infüzyon şurupları hazırlandı.',
          createdAt: now.subtract(const Duration(days: 7, hours: 4)),
          status: MessageDeliveryStatus.read,
          readAt: now.subtract(const Duration(days: 7, hours: 3)),
        ),
        ChatMessage(
          id: 'msg_m2',
          bookingId: 'GH-82194',
          senderRole: 'customer',
          senderName: 'Siz',
          text: 'Teşekkürler Marcus, bar tezgahı ve soğutucu hazır durumda.',
          createdAt: now.subtract(const Duration(days: 7, hours: 3, minutes: 40)),
          status: MessageDeliveryStatus.read,
          readAt: now.subtract(const Duration(days: 7, hours: 3, minutes: 30)),
        ),
      ],
    );

    return ChatState(
      conversations: {
        'GH-94821': julianConv,
        'GH-82194': marcusConv,
      },
      activeBookingId: 'GH-94821',
    );
  }

  void setActiveBooking(String bookingId) {
    state = state.copyWith(activeBookingId: bookingId);
    markAsRead(bookingId);
  }

  void ensureConversationExists({
    required String bookingId,
    required String recipientName,
    required String recipientRole,
    String? recipientImage,
  }) {
    if (!state.conversations.containsKey(bookingId)) {
      final newConv = ChatConversation(
        bookingId: bookingId,
        recipientName: recipientName,
        recipientRole: recipientRole,
        recipientImage: recipientImage ??
            'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80',
        messages: [],
      );
      final updated = Map<String, ChatConversation>.from(state.conversations);
      updated[bookingId] = newConv;
      state = state.copyWith(conversations: updated, activeBookingId: bookingId);
    }
    _loadMessagesFromSupabase(bookingId);
  }

  Future<void> _loadMessagesFromSupabase(String bookingId) async {
    try {
      final supabase = SupabaseService();
      final resolvedUuid = await supabase.resolveBookingUuid(bookingId);
      if (resolvedUuid == null) return;

      final rows = await supabase.client
          .from('messages')
          .select('*')
          .eq('booking_id', resolvedUuid)
          .order('created_at', ascending: true);

      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isEmpty) return;

      final conv = state.conversations[bookingId];
      if (conv == null) return;

      final loadedMessages = list.map((row) {
        final role = row['sender_role']?.toString() ?? 'customer';
        return ChatMessage(
          id: row['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
          bookingId: bookingId,
          senderRole: role,
          senderName: role == 'customer' ? 'Siz' : conv.recipientName,
          text: row['content']?.toString() ?? '',
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          status: MessageDeliveryStatus.read,
        );
      }).toList();

      final updatedMap = Map<String, ChatConversation>.from(state.conversations);
      updatedMap[bookingId] = conv.copyWith(messages: loadedMessages);
      state = state.copyWith(conversations: updatedMap);
    } catch (e) {
      debugPrint('Supabase chat messages load warning: $e');
    }
  }

  void sendMessage({
    required String bookingId,
    required String text,
    String senderRole = 'customer',
    String senderName = 'Siz',
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conv = state.conversations[bookingId];
    if (conv == null) return;

    final newMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final newMsg = ChatMessage(
      id: newMsgId,
      bookingId: bookingId,
      senderRole: senderRole,
      senderName: senderName,
      text: trimmed,
      createdAt: DateTime.now(),
      status: MessageDeliveryStatus.sent,
    );

    final updatedMessages = List<ChatMessage>.from(conv.messages)..add(newMsg);
    final updatedConv = conv.copyWith(messages: updatedMessages);

    final updatedMap = Map<String, ChatConversation>.from(state.conversations);
    updatedMap[bookingId] = updatedConv;

    state = state.copyWith(conversations: updatedMap);

    // Persist message to Supabase messages table using safe UUID resolution
    Future.microtask(() async {
      try {
        final supabase = SupabaseService();
        if (supabase.currentUser == null) return;
        final resolvedUuid = await supabase.resolveBookingUuid(bookingId);
        if (resolvedUuid != null) {
          await supabase.client.from('messages').insert({
            'booking_id': resolvedUuid,
            'sender_id': supabase.currentUser!.id,
            'sender_role': senderRole,
            'content': trimmed,
            'delivery_status': 'sent',
          });
        }
      } catch (e) {
        debugPrint('Supabase chat message insert warning: $e');
      }
    });

    // Simulate delivery after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      _updateMessageStatus(bookingId, newMsgId, MessageDeliveryStatus.delivered);
    });

    // Simulate read and chef response after 2.5 seconds (Demo & UX feeling)
    Future.delayed(const Duration(milliseconds: 2500), () {
      _updateMessageStatus(bookingId, newMsgId, MessageDeliveryStatus.read, readAt: DateTime.now());
      _simulateChefReply(bookingId, conv.recipientName, conv.recipientRole);
    });
  }

  void markAsRead(String bookingId) {
    final conv = state.conversations[bookingId];
    if (conv == null) return;

    bool hasChanges = false;
    final updatedMessages = conv.messages.map((m) {
      if (m.senderRole != 'customer' && m.status != MessageDeliveryStatus.read) {
        hasChanges = true;
        return m.copyWith(
          status: MessageDeliveryStatus.read,
          readAt: DateTime.now(),
        );
      }
      return m;
    }).toList();

    if (hasChanges) {
      final updatedConv = conv.copyWith(messages: updatedMessages);
      final updatedMap = Map<String, ChatConversation>.from(state.conversations);
      updatedMap[bookingId] = updatedConv;
      state = state.copyWith(conversations: updatedMap);
    }
  }

  void _updateMessageStatus(
    String bookingId,
    String messageId,
    MessageDeliveryStatus newStatus, {
    DateTime? readAt,
  }) {
    final conv = state.conversations[bookingId];
    if (conv == null) return;

    final updatedMessages = conv.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(status: newStatus, readAt: readAt ?? m.readAt);
      }
      return m;
    }).toList();

    final updatedConv = conv.copyWith(messages: updatedMessages);
    final updatedMap = Map<String, ChatConversation>.from(state.conversations);
    updatedMap[bookingId] = updatedConv;

    state = state.copyWith(conversations: updatedMap);
  }

  void _simulateChefReply(String bookingId, String chefName, String role) {
    final conv = state.conversations[bookingId];
    if (conv == null) return;

    final replies = [
      'Mesajınızı aldım, her şey planlandığı gibi ilerliyor. Görüşmek üzere!',
      'Bilgilendirme için çok teşekkürler, özenle hazırlayacağım.',
      'Harika! İlettiğiniz notlara göre menüyü organize ettim.',
      'Adresinize yaklaştığımda tekrar haber vereceğim.',
    ];
    final selectedReply = replies[conv.messages.length % replies.length];

    final replyMsg = ChatMessage(
      id: 'msg_reply_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      senderRole: role.toLowerCase().contains('bartender') || role.toLowerCase().contains('mixologist') ? 'bartender' : 'chef',
      senderName: chefName,
      text: selectedReply,
      createdAt: DateTime.now(),
      status: MessageDeliveryStatus.delivered,
    );

    final updatedMessages = List<ChatMessage>.from(conv.messages)..add(replyMsg);
    final updatedConv = conv.copyWith(messages: updatedMessages);
    final updatedMap = Map<String, ChatConversation>.from(state.conversations);
    updatedMap[bookingId] = updatedConv;

    state = state.copyWith(conversations: updatedMap);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
