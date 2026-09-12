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

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['senderId']?.toString() ?? '';
    return ChatMessage(
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
  }) {
    return ChatMessage(
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

  factory ChatConversation.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      otherParticipant: json['otherParticipant'] != null && json['otherParticipant'] is Map<String, dynamic>
          ? SupportUser.fromJson(json['otherParticipant'] as Map<String, dynamic>)
          : null,
      lastMessage: json['lastMessage'] != null && json['lastMessage'] is Map<String, dynamic>
          ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>, currentUserId: currentUserId)
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
    final name = json['fullName']?.toString() ?? json['userName']?.toString() ?? 'Ban Cố Vấn Sống Khỏe';
    return SupportUser(
      id: id,
      fullName: name,
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role']?.toString() ?? 'Chuyên viên Tư vấn',
    );
  }
}
