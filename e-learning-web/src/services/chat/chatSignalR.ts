import * as signalR from '@microsoft/signalr';

const API_BASE_URL = import.meta.env.VITE_API_URL?.replace('/api', '') || 'https://localhost:7145';

export interface ChatMessage {
    id: string;
    conversationId?: string;
    senderId: string;
    senderName: string;
    content: string;
    sentAt: string;
    isRead: boolean;
    isFromGuest: boolean;
}

// Define a type for the callbacks object to improve type safety and readability
interface SignalRCallbacks {
    onReceiveMessage: ((message: ChatMessage) => void)[];
    onGuestMessage: ((guestId: string, message: ChatMessage) => void)[];
    onUserTyping: ((userId: string, userName: string) => void)[];
    onUserStoppedTyping: ((userId: string) => void)[];
    onAgentTyping: (() => void)[];
    onAgentStoppedTyping: (() => void)[];
    onError: ((message: string) => void)[];
    onRateLimitExceeded: ((message: string) => void)[];
    onGuestDisconnected: ((guestId: string) => void)[];
    onGuestTyping: ((guestId: string) => void)[];
    onGuestStoppedTyping: ((guestId: string) => void)[];
    onMessagesRead: ((data: { conversationId?: string, guestId?: string, readerId?: string }) => void)[];
}

class ChatSignalRService {
    private connection: signalR.HubConnection | null = null;
    private connectPromise: Promise<void> | null = null;
    private callbacks: SignalRCallbacks = {
        onReceiveMessage: [],
        onGuestMessage: [],
        onUserTyping: [],
        onUserStoppedTyping: [],
        onAgentTyping: [],
        onAgentStoppedTyping: [],
        onError: [],
        onRateLimitExceeded: [],
        onGuestDisconnected: [],
        onGuestTyping: [],
        onGuestStoppedTyping: [],
        onMessagesRead: []
    };

    private async ensureConnected(): Promise<signalR.HubConnection> {
        // If a connect is in-flight, wait for it
        if (this.connectPromise) {
            await this.connectPromise;
        }

        if (!this.connection) {
            throw new Error('Not connected');
        }

        // Wait if currently connecting or reconnecting
        if (this.connection.state === signalR.HubConnectionState.Connecting ||
            this.connection.state === signalR.HubConnectionState.Reconnecting) {
            // Wait a bit for connection to establish
            await new Promise(resolve => setTimeout(resolve, 100));

            // Check again after waiting
            if (this.connection.state === signalR.HubConnectionState.Connecting ||
                this.connection.state === signalR.HubConnectionState.Reconnecting) {
                throw new Error('Connection is still establishing');
            }
        }

        if (this.connection.state === signalR.HubConnectionState.Disconnected) {
            await this.connection.start();
        }

        return this.connection;
    }

    clearCallbacks() {
        this.callbacks = {
            onReceiveMessage: [],
            onGuestMessage: [],
            onUserTyping: [],
            onUserStoppedTyping: [],
            onAgentTyping: [],
            onAgentStoppedTyping: [],
            onError: [],
            onRateLimitExceeded: [],
            onGuestDisconnected: [],
            onGuestTyping: [],
            onGuestStoppedTyping: [],
            onMessagesRead: []
        };
    }

    async connect(token?: string) {
        // Serialize connection attempts to avoid overlapping start/stop
        if (this.connectPromise) {
            return this.connectPromise;
        }

        this.connectPromise = (async () => {
            // Reuse existing connection if it's already in a usable state
            if (this.connection) {
                const state = this.connection.state;
                if (
                    state === signalR.HubConnectionState.Connected ||
                    state === signalR.HubConnectionState.Connecting ||
                    state === signalR.HubConnectionState.Reconnecting
                ) {
                    // If token is provided, we might need to reconnect to update auth
                    // Simplified strategy: Always stop and reconnect if connect is called explicitly with a token
                    // This ensures we don't get stuck in Anonymous mode when User logs in
                    if (token) {
                        console.log('[ChatSignalR] Token provided, forcing reconnection to update auth context.');
                        if (this.connection) {
                            await this.connection.stop();
                        }
                        this.connection = null; // Rebuild connection
                    } else {
                        return;
                    }
                }

                if (state === signalR.HubConnectionState.Disconnected) {
                    try {
                        if (this.connection) {
                            await this.connection.start();
                        }
                        return;
                    } catch {
                        if (this.connection) {
                            await this.connection.stop();
                        }
                        this.connection = null;
                    }
                }
            }

            const connectionBuilder = new signalR.HubConnectionBuilder()
                .withUrl(`${API_BASE_URL}/hubs/chat`, {
                    accessTokenFactory: () => token || '',
                    skipNegotiation: true, // go straight to WebSockets to avoid negotiate aborts
                    transport: signalR.HttpTransportType.WebSockets,
                })
                .withAutomaticReconnect()
                .configureLogging(signalR.LogLevel.Information);

            this.connection = connectionBuilder.build();

            // Register event handlers once per connection
            this.connection.on('ReceiveMessage', (message: ChatMessage) => {
                console.log('[ChatSignalR] Event Received: ReceiveMessage', message);
                this.callbacks.onReceiveMessage.forEach(cb => cb(message));
            });

            this.connection.on('ReceiveGuestMessage', (guestId: string, message: ChatMessage) => {
                console.log('[ChatSignalR] Event Received: ReceiveGuestMessage', guestId, message);
                this.callbacks.onGuestMessage.forEach(cb => cb(guestId, message));
            });

            this.connection.on('UserTyping', (userId: string, userName: string) => {
                this.callbacks.onUserTyping.forEach(cb => cb(userId, userName));
            });

            this.connection.on('UserStoppedTyping', (userId: string) => {
                this.callbacks.onUserStoppedTyping.forEach(cb => cb(userId));
            });

            this.connection.on('AgentTyping', () => {
                this.callbacks.onAgentTyping.forEach(cb => cb());
            });

            this.connection.on('AgentStoppedTyping', () => {
                this.callbacks.onAgentStoppedTyping.forEach(cb => cb());
            });

            this.connection.on('Error', (message: string) => {
                this.callbacks.onError.forEach(cb => cb(message));
            });

            this.connection.on('RateLimitExceeded', (message: string) => {
                this.callbacks.onRateLimitExceeded.forEach(cb => cb(message));
            });

            // New listeners
            this.connection.on('GuestDisconnected', (guestId: string) => {
                this.callbacks.onGuestDisconnected.forEach(cb => cb(guestId));
            });
            this.connection.on('GuestTyping', (guestId: string) => {
                this.callbacks.onGuestTyping.forEach(cb => cb(guestId));
            });
            this.connection.on('GuestStoppedTyping', (guestId: string) => {
                this.callbacks.onGuestStoppedTyping.forEach(cb => cb(guestId));
            });

            this.connection.on('MessagesRead', (arg1?: any, arg2?: any) => {
                // Determine format based on arguments
                // Hub says: SendAsync("MessagesRead") for Guest (when admin reads guest messages)
                // Hub says: SendAsync("MessagesRead", conversationId, userId) for Auth (when user reads messages in a conversation)

                let data: { conversationId?: string, guestId?: string, readerId?: string } = {};

                if (arg1 && arg2) {
                    // Auth format: conversationId, readerId
                    data = { conversationId: arg1, readerId: arg2 };
                } else if (arg1) {
                    // Could be guestId if the hub sends it this way for guest read receipts
                    // For now, assuming if only one arg, it's a guestId or a generic read
                    data = { guestId: arg1 }; // Assuming arg1 is guestId if only one is provided for guest context
                } else {
                    // Guest format (generic "seen" by admin) or no specific context
                    data = {};
                }

                this.callbacks.onMessagesRead.forEach(cb => cb(data));
            });

            try {
                await this.connection.start();
                console.log('SignalR Connected');
            } catch (err) {
                console.error('SignalR Connection Error:', err);
                // Reset connection so next attempt rebuilds cleanly
                this.connection = null;
                throw err;
            }
        })();

        try {
            await this.connectPromise;
        } finally {
            this.connectPromise = null;
        }
    }

    async disconnect() {
        if (this.connectPromise) {
            try { await this.connectPromise; } catch { /* ignore */ }
        }

        if (this.connection && this.connection.state !== signalR.HubConnectionState.Disconnected) {
            try {
                await this.connection.stop();
            } catch (error) {
                console.error('Error stopping connection:', error);
            }
        }
        // Don't set connection to null - allow reconnection
    }

    // Guest chat methods
    async joinGuestChat(guestId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('JoinGuestChat', guestId);
    }

    async sendGuestMessage(guestId: string, guestName: string, content: string, agentId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('SendGuestMessage', guestId, guestName, content, agentId);
    }

    async sendGuestReply(guestId: string, content: string) {
        console.log('[ChatSignalR] Sending guest reply...', guestId);
        const conn = await this.ensureConnected();
        console.log('[ChatSignalR] Connection secured, invoking SendGuestReply...');
        await conn.invoke('SendGuestReply', guestId, content);
        console.log('[ChatSignalR] SendGuestReply invoked successfully.');
    }

    async startTypingGuest(guestId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('StartTypingGuest', guestId);
    }

    async stopTypingGuest(guestId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('StopTypingGuest', guestId);
    }

    // Guest calling to notify admin
    async guestStartTyping(guestId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('GuestStartTyping', guestId);
    }

    async guestStopTyping(guestId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('GuestStopTyping', guestId);
    }

    public async markGuestAsRead(guestId: string): Promise<void> {
        if (!this.connection) return;
        try {
            await this.connection.invoke('MarkGuestAsRead', guestId);
        } catch (err) {
            console.error('Error marking guest as read:', err);
        }
    }

    // Authenticated user chat methods
    async sendMessage(conversationId: string, content: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('SendMessage', conversationId, content);
    }

    async joinConversation(conversationId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('JoinConversation', conversationId);
    }

    async leaveConversation(conversationId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('LeaveConversation', conversationId);
    }

    public async markAsRead(conversationId: string): Promise<void> {
        if (!this.connection) return;
        try {
            await this.connection.invoke('MarkAsRead', conversationId);
        } catch (err) {
            console.error('Error marking conversation as read:', err);
        }
    }

    async startTyping(conversationId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('StartTyping', conversationId);
    }

    async stopTyping(conversationId: string) {
        const conn = await this.ensureConnected();
        await conn.invoke('StopTyping', conversationId);
    }

    // Event listeners
    onReceiveMessage(callback: (message: ChatMessage) => void) {
        this.callbacks.onReceiveMessage.push(callback);
    }

    onReceiveGuestMessage(callback: (guestId: string, message: ChatMessage) => void) {
        this.callbacks.onGuestMessage.push(callback);
    }

    onUserTyping(callback: (userId: string, userName: string) => void) {
        this.callbacks.onUserTyping.push(callback);
    }

    onUserStoppedTyping(callback: (userId: string) => void) {
        this.callbacks.onUserStoppedTyping.push(callback);
    }

    onAgentTyping(callback: () => void) {
        this.callbacks.onAgentTyping.push(callback);
    }

    onAgentStoppedTyping(callback: () => void) {
        this.callbacks.onAgentStoppedTyping.push(callback);
    }

    onError(callback: (message: string) => void) {
        this.callbacks.onError.push(callback);
    }

    onRateLimitExceeded(callback: (message: string) => void) {
        this.callbacks.onRateLimitExceeded.push(callback);
    }

    public onGuestDisconnected(callback: (guestId: string) => void) {
        this.callbacks.onGuestDisconnected.push(callback);
    }

    onGuestTyping(callback: (guestId: string) => void) {
        this.callbacks.onGuestTyping.push(callback);
    }

    onGuestStoppedTyping(callback: (guestId: string) => void) {
        this.callbacks.onGuestStoppedTyping.push(callback);
    }

    public onMessagesRead(callback: (data: { conversationId?: string, guestId?: string, readerId?: string }) => void) {
        this.callbacks.onMessagesRead.push(callback);
    }

    getConnectionState() {
        return this.connection?.state || signalR.HubConnectionState.Disconnected;
    }
}

export const chatSignalR = new ChatSignalRService();
