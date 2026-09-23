import 'dart:math';
import 'models/chat_models.dart';

String newClientMessageId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Server IDs deduplicate delivery; correlation IDs replace pending messages.
List<ChatMessage> mergeMessages(Iterable<ChatMessage> existing,
    Iterable<ChatMessage> incoming, {String? currentUserId}) {
  final result = <ChatMessage>[];
  for (final message in [...existing, ...incoming]) {
    if (message.id.isEmpty || message.conversationId.isEmpty) continue;
    final index = result.indexWhere((m) => m.conversationId == message.conversationId &&
      (m.id == message.id || (message.clientMessageId != null &&
       m.clientMessageId == message.clientMessageId && m.senderId == message.senderId)));
    var normalized = currentUserId == null ? message : message.copyWith(
      isMe: message.senderId.toLowerCase() == currentUserId.toLowerCase());
    if (index < 0) { result.add(normalized); }
    else {
      // A late HTTP error/pending update must not replace an acknowledged echo.
      if (result[index].delivery == 'sent' && normalized.delivery != 'sent') normalized = result[index];
      result[index] = normalized;
    }
  }
  result.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  return result;
}
