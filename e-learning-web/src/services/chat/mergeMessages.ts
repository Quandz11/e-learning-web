export interface CorrelatedMessage {
  id: string;
  clientMessageId?: string | null;
  conversationId?: string;
  senderId?: string;
  sentAt: string;
}

export function mergeMessages<T extends CorrelatedMessage>(existing: T[], incoming: T[]): T[] {
  const result = [...existing];
  for (const message of incoming) {
    if (!message.id) continue;
    const index = result.findIndex(m => m.id === message.id || (
      !!message.clientMessageId && m.clientMessageId === message.clientMessageId &&
      m.conversationId === message.conversationId && m.senderId === message.senderId));
    if (index < 0) result.push(message);
    else result[index] = { ...result[index], ...message };
  }
  return result.sort((a, b) => Date.parse(a.sentAt) - Date.parse(b.sentAt));
}
