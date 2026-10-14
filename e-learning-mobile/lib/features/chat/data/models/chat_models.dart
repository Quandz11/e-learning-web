class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderRole = '',
    required this.content,
    required this.sentAt,
    required this.isRead,
    this.isMe = false,
    this.clientMessageId,
    this.delivery = 'sent',
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final bool isMe;
  final String? clientMessageId;
  final String delivery;

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final senderId = json['senderId']?.toString() ?? '';
    return ChatMessage(
      clientMessageId: json['clientMessageId']?.toString(),
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: senderId,
      senderName: json['senderName']?.toString() ?? 'Tư vấn viên',
      senderRole: json['senderRole']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      isMe: currentUserId != null && senderId == currentUserId,
    );
  }

  factory ChatMessage.fromGuestJson(Map<String, dynamic> json, String guestId) {
    final guest = json['isFromGuest'] == true;
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: guestId,
      senderId: guest ? guestId : 'support',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: guest ? 'Guest' : 'Admin',
      content: json['content']?.toString() ?? '',
      sentAt:
          DateTime.tryParse(
            (json['sentAt'] ?? json['timestamp'])?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: json['isRead'] == true,
      isMe: !guest,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? content,
    DateTime? sentAt,
    bool? isRead,
    bool? isMe,
    String? clientMessageId,
    String? delivery,
  }) {
    return ChatMessage(
      clientMessageId: clientMessageId ?? this.clientMessageId,
      delivery: delivery ?? this.delivery,
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      isMe: isMe ?? this.isMe,
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.otherParticipant,
    this.lastMessage,
    required this.unreadCount,
  });

  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final SupportUser? otherParticipant;
  final ChatMessage? lastMessage;
  final int unreadCount;

  factory ChatConversation.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      otherParticipant:
          json['otherParticipant'] != null &&
              json['otherParticipant'] is Map<String, dynamic>
          ? SupportUser.fromJson(
              json['otherParticipant'] as Map<String, dynamic>,
            )
          : null,
      lastMessage:
          json['lastMessage'] != null &&
              json['lastMessage'] is Map<String, dynamic>
          ? ChatMessage.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
              currentUserId: currentUserId,
            )
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}

class SupportUser {
  const SupportUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.role,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? role;

  factory SupportUser.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['userId']?.toString() ?? '';
    final name =
        json['fullName']?.toString() ??
        json['userName']?.toString() ??
        'Ban Cố Vấn Sống Khỏe';
    return SupportUser(
      id: id,
      fullName: name,
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role']?.toString() ?? 'Chuyên viên Tư vấn',
    );
  }
}

class AdminConversationItem {
  const AdminConversationItem({
    required this.id,
    required this.type,
    this.guestId,
    this.userId,
    required this.userName,
    this.lastMessage,
    this.lastActivity,
    required this.unreadCount,
    required this.isActive,
  });

  final String id;
  final String type; // "authenticated" | "guest"
  final String? guestId;
  final String? userId;
  final String userName;
  final String? lastMessage;
  final DateTime? lastActivity;
  final int unreadCount;
  final bool isActive;

  factory AdminConversationItem.fromJson(Map<String, dynamic> json) {
    return AdminConversationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'authenticated',
      guestId: json['guestId']?.toString(),
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString() ?? 'Người dùng',
      lastMessage: json['lastMessage']?.toString(),
      lastActivity: json['lastActivity'] != null
          ? DateTime.tryParse(json['lastActivity'].toString())
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  AdminConversationItem copyWith({
    String? id,
    String? type,
    String? guestId,
    String? userId,
    String? userName,
    String? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
    bool? isActive,
  }) {
    return AdminConversationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      guestId: guestId ?? this.guestId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AdminConversationsResponse {
  const AdminConversationsResponse({
    required this.authenticatedConversations,
    required this.guestConversations,
  });

  final List<AdminConversationItem> authenticatedConversations;
  final List<AdminConversationItem> guestConversations;

  factory AdminConversationsResponse.fromJson(Map<String, dynamic> json) {
    final authList = <AdminConversationItem>[];
    if (json['authenticatedConversations'] is List) {
      for (final item in json['authenticatedConversations']) {
        if (item is Map<String, dynamic>) {
          authList.add(AdminConversationItem.fromJson(item));
        }
      }
    }

    final guestList = <AdminConversationItem>[];
    if (json['guestConversations'] is List) {
      for (final item in json['guestConversations']) {
        if (item is Map<String, dynamic>) {
          guestList.add(AdminConversationItem.fromJson(item));
        }
      }
    }

    return AdminConversationsResponse(
      authenticatedConversations: authList,
      guestConversations: guestList,
    );
  }
}
