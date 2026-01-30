import React, { useState, useEffect, useRef } from 'react';
import { useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import type { RootState } from '../../store/store';
import { chatSignalR, type ChatMessage } from '../../services/chat/chatSignalR';
import { chatApi } from '../../services/chat/chatApi';

interface ChatWindowProps {
    isOpen: boolean;
    onClose: () => void;
    onUnreadCountChange?: (updater: (prev: number) => number) => void;
}

const ChatWindow: React.FC<ChatWindowProps> = ({ isOpen, onClose, onUnreadCountChange }) => {
    const { t } = useTranslation();
    const { isAuthenticated, user, accessToken } = useSelector((state: RootState) => state.auth);
    const [messages, setMessages] = useState<ChatMessage[]>([]);
    const [inputMessage, setInputMessage] = useState('');
    const [isConnected, setIsConnected] = useState(false);
    const [isTyping, setIsTyping] = useState(false);
    const [supportUserId, setSupportUserId] = useState<string | null>(null);
    const [errorMessage, setErrorMessage] = useState<string | null>(null);
    const [guestName, setGuestName] = useState('');
    const [hasEnteredName, setHasEnteredName] = useState(false);
    // Initialize guestId once on mount using UUID (no persistence)
    const [guestId] = useState(() => crypto.randomUUID());
    const [lastReadAt, setLastReadAt] = useState<Date | null>(null); // For Auth/Guest read status

    // NOTE: Removed localStorage persistence logic to ensure fresh session on F5

    const messagesEndRef = useRef<HTMLDivElement>(null);
    const typingTimeoutRef = useRef<number | null>(null);
    const FALLBACK_SUPPORT_ID = '00000000-0000-0000-0000-000000000001'; // Default admin ID

    useEffect(() => {
        if (isOpen) {
            // Reset unread badge when the window opens
            onUnreadCountChange?.(() => 0);
            // Also mark all as read?
            // Should happen in the messages effect
        }
    }, [isOpen]);

    useEffect(() => {
        const initChat = async () => {
            try {
                chatSignalR.clearCallbacks();

                const token = isAuthenticated ? accessToken || undefined : undefined;
                await chatSignalR.connect(token);

                // Wait a bit to ensure connection is fully established
                await new Promise(resolve => setTimeout(resolve, 200));

                setIsConnected(true);

                // Resolve support user id once per session (for both guest and auth sends)
                let supportId = supportUserId;
                if (!supportId) {
                    try {
                        const support = await chatApi.getSupportUser();
                        supportId = support.id;
                        setSupportUserId(supportId);
                    } catch (err) {
                        console.warn('No support user found, fallback to default ID', err);
                        supportId = FALLBACK_SUPPORT_ID;
                        setSupportUserId(supportId);
                    }
                }

                if (isAuthenticated) {
                    // Authenticated user - try to load conversation history
                    try {
                        const conversations = await chatApi.getConversations();
                        let adminConv = conversations.find(c =>
                            c.participants.some(p => p.userId === supportId)
                        );

                        if (!adminConv) {
                            // Try to create conversation with admin
                            try {
                                adminConv = await chatApi.createConversation({ recipientId: supportId });
                            } catch (createError) {
                                console.warn('Could not create conversation with admin, using guest mode');
                                // Fall back to guest mode
                                await chatSignalR.joinGuestChat(guestId);
                            }
                        }

                        if (adminConv) {
                            // Load messages
                            const msgs = await chatApi.getMessages(adminConv.id);
                            setMessages(msgs.map(m => ({
                                id: m.id,
                                conversationId: m.conversationId,
                                senderId: m.senderId,
                                senderName: m.senderName,
                                content: m.content,
                                sentAt: m.sentAt,
                                isRead: m.isRead
                            })));

                            // Join conversation
                            await chatSignalR.joinConversation(adminConv.id);
                        }
                    } catch (error) {
                        console.warn('Failed to load conversation, using guest mode:', error);
                        // Fall back to guest mode if authenticated mode fails
                        await chatSignalR.joinGuestChat(guestId);
                    }
                } else {
                    // Guest user - only use SignalR
                    await chatSignalR.joinGuestChat(guestId);
                }

                // Setup message listener
                chatSignalR.onReceiveMessage((message) => {
                    setMessages(prev => {
                        // avoid duplicate ids causing React key warnings
                        if (prev.some(m => m.id === message.id)) return prev;
                        return [...prev, message];
                    });
                    scrollToBottom();
                    playNotificationSound();

                    // If window is closed and message is from other, increment unread
                    // We need to check if message is from other inside this callback?
                    // We don't have access to 'isFromOther' easily here without 'user' state closure issues?
                    // actually 'user' and 'guestId' are dependencies of useEffect.

                    // Check if message is from other
                    // We need to know who sent it.
                    // But inside this closure, 'user' might be stale if not carefully managed.
                    // However, 'initChat' is called once. SignalR callbacks form closures.
                    // We should use a ref for 'isOpen' to check current state inside callback?
                    // Or just updating unread if !isOpen (passed via ref or dependency rewrite).
                });

                // Setup typing indicators
                chatSignalR.onAgentTyping(() => setIsTyping(true));
                chatSignalR.onAgentStoppedTyping(() => setIsTyping(false));

                // Setup error handlers
                chatSignalR.onError((message) => {
                    setErrorMessage(message);
                    setTimeout(() => setErrorMessage(null), 5000);
                });

                chatSignalR.onRateLimitExceeded((message) => {
                    setErrorMessage(message);
                    setTimeout(() => setErrorMessage(null), 5000);
                });

                // Setup read receipt listener
                chatSignalR.onMessagesRead((data) => {
                    // Check if this read event applies to us
                    if (isAuthenticated) {
                        // For auth user, check if conversationId matches current
                        if (messages.length > 0 && data.conversationId === messages[0].conversationId) {
                            setLastReadAt(new Date());
                        }
                    } else {
                        // For guest, any MessagesRead event means admin read our chat
                        setLastReadAt(new Date());
                    }
                });

            } catch (error) {
                console.error('Failed to connect to chat:', error);
            }
        };

        initChat();

        return () => {
            chatSignalR.clearCallbacks();
            chatSignalR.disconnect();
        };
    }, [isAuthenticated, guestId, accessToken]);

    // Use a ref to track isOpen for SignalR callbacks
    const isOpenRef = useRef(isOpen);
    useEffect(() => {
        isOpenRef.current = isOpen;
    }, [isOpen]);

    // Use a ref for user/guestId to be accessible in callbacks without reconnection
    const userRef = useRef(user);
    useEffect(() => { userRef.current = user; }, [user]);

    // We need to modify the onReceiveMessage callback to use refs
    useEffect(() => {
        if (isConnected) {
            chatSignalR.onReceiveMessage((message) => {
                setMessages(prev => {
                    if (prev.some(m => m.id === message.id)) return prev;
                    return [...prev, message];
                });

                // Logic for unread count
                // If not open, and message is NOT from me
                const isFromMe = isAuthenticated
                    ? message.senderId === userRef.current?.id
                    : message.senderId === guestId;

                if (!isOpenRef.current && !isFromMe) {
                    onUnreadCountChange?.(prev => prev + 1);
                }

                scrollToBottom();
                playNotificationSound();
            });
        }
    }, [isConnected, isAuthenticated, guestId, onUnreadCountChange]); // Re-bind if these change

    useEffect(() => {
        scrollToBottom();
        // If we receive new messages and window is open, mark them as read
        if (messages.length > 0 && isConnected && isOpen) {
            const lastMsg = messages[messages.length - 1];

            // Wait.
            // Guest: Sent by me (Guest) -> isGuest=true (Wait, GuestMessage model has IsFromGuest).
            // ChatMessage interface: isGuest?
            // Let's check ChatMessage definition in signalR.ts used in ChatWindow.
            // In ChatWindow:
            // const isOwn = isAuthenticated ? message.senderId === user?.id : message.senderId === guestId;

            if (!isAuthenticated) {
                // I am guest. If last message is NOT from me (senderId != guestId), mark read.
                if (lastMsg.senderId !== guestId) {
                    chatSignalR.markGuestAsRead(guestId);
                }
            } else {
                // I am auth. If last message NOT from me.
                if (lastMsg.senderId !== user?.id && lastMsg.conversationId) {
                    chatSignalR.markAsRead(lastMsg.conversationId);
                }
            }
        }
    }, [messages, isConnected, isAuthenticated, guestId, user?.id, isOpen]);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    };

    const playNotificationSound = () => {
        // Simple beep using Web Audio API
        try {
            const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);

            oscillator.frequency.value = 800;
            oscillator.type = 'sine';

            gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);

            oscillator.start(audioContext.currentTime);
            oscillator.stop(audioContext.currentTime + 0.1);
        } catch (error) {
            console.error('Failed to play sound:', error);
        }
    };

    const handleSendMessage = async () => {
        if (!inputMessage.trim() || !isConnected) return;

        const content = inputMessage.trim();

        // Validate message length on frontend
        if (content.length > 1000) {
            setErrorMessage('Message is too long (max 1000 characters)');
            setTimeout(() => setErrorMessage(null), 5000);
            return;
        }

        setInputMessage('');

        try {
            if (isAuthenticated) {
                // Send authenticated message via SignalR
                try {
                    const conversations = await chatApi.getConversations();
                    let adminConv = conversations.find(c =>
                        c.participants.some(p => p.userId === (supportUserId || FALLBACK_SUPPORT_ID))
                    );

                    if (!adminConv) {
                        // Create conversation if it doesn't exist
                        adminConv = await chatApi.createConversation({ recipientId: supportUserId || FALLBACK_SUPPORT_ID });
                        await chatSignalR.joinConversation(adminConv.id);
                    }

                    if (adminConv) {
                        await chatSignalR.sendMessage(adminConv.id, content);
                    }
                } catch (convError) {
                    console.error('Conversation error, falling back to guest mode:', convError);
                    // Fallback to guest mode if authenticated mode fails
                    await chatSignalR.sendGuestMessage(guestId, guestName || 'Guest', content, supportUserId || FALLBACK_SUPPORT_ID);
                }
            } else {
                // Send guest message
                await chatSignalR.sendGuestMessage(guestId, guestName || 'Guest', content, supportUserId || FALLBACK_SUPPORT_ID);
            }
        } catch (error) {
            console.error('Failed to send message:', error);
            setErrorMessage(t('chat.messages.error'));
            setTimeout(() => setErrorMessage(null), 5000);
        }
    };

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setInputMessage(e.target.value);

        // Typing indicator logic
        if (typingTimeoutRef.current) {
            clearTimeout(typingTimeoutRef.current);
        }

        if (isAuthenticated) {
            chatSignalR.startTyping(messages.length > 0 ? messages[0].conversationId! : guestId); // Assuming basic
            // Note: Authenticated typing usually requires ConversationID.
            // But if we're in guest fallback mode, we shouldn't send typing?
            // Existing logic had commented out startTyping.
        } else {
            // Guest typing
            // Only send if not just clearing input
            if (e.target.value.trim().length > 0) {
                chatSignalR.guestStartTyping(guestId);
            }
        }

        typingTimeoutRef.current = setTimeout(() => {
            if (isAuthenticated) {
                // chatSignalR.stopTyping(...)
                // Need conversation ID.
            } else {
                chatSignalR.guestStopTyping(guestId);
            }
        }, 1000);
    };

    const handleKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage();
        }
    };

    const formatTime = (dateString: string) => {
        const date = new Date(dateString);
        return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    };

    return (
        <div className="fixed bottom-24 right-6 z-50 w-96 h-[600px] bg-white rounded-2xl shadow-2xl flex flex-col overflow-hidden border border-gray-200">
            {/* Header */}
            <div className="bg-primary text-white p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
                            <span className="material-symbols-outlined">support_agent</span>
                        </div>
                        {isConnected && (
                            <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-400 rounded-full border-2 border-white"></div>
                        )}
                    </div>
                    <div>
                        <h3 className="font-semibold">{t('chat.window.title')}</h3>
                        <p className="text-xs text-white/80">
                            {isConnected ? t('chat.window.online') : t('chat.window.connecting')}
                        </p>
                    </div>
                </div>
                <button
                    onClick={onClose}
                    className="hover:bg-white/20 rounded-full p-1 transition-colors"
                >
                    <span className="material-symbols-outlined">close</span>
                </button>
            </div>

            {/* Messages or Guest Name Form */}
            {!isAuthenticated && !hasEnteredName ? (
                <div className="flex-1 flex items-center justify-center p-6 bg-gray-50">
                    <div className="w-full max-w-sm">
                        <div className="text-center mb-6">
                            <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                                <span className="material-symbols-outlined text-4xl text-primary">chat</span>
                            </div>
                            <h3 className="text-lg font-semibold text-gray-900 mb-2">{t('chat.guest.welcomeTitle')}</h3>
                            <p className="text-sm text-gray-600">{t('chat.guest.welcomeDesc')}</p>
                        </div>

                        <div className="space-y-4">
                            <div>
                                <input
                                    type="text"
                                    value={guestName}
                                    onChange={(e) => setGuestName(e.target.value)}
                                    onKeyPress={(e) => {
                                        if (e.key === 'Enter' && guestName.trim()) {
                                            // No localStorage set
                                            setHasEnteredName(true);
                                        }
                                    }}
                                    placeholder={t('chat.guest.namePlaceholder')}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                                    autoFocus
                                />
                            </div>

                            <button
                                onClick={() => {
                                    if (guestName.trim()) {
                                        // No localStorage set
                                        setHasEnteredName(true);
                                    }
                                }}
                                disabled={!guestName.trim()}
                                className="w-full bg-primary text-white py-3 rounded-lg hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors font-medium"
                            >
                                {t('chat.guest.startChat')}
                            </button>

                            <div className="relative">
                                <div className="absolute inset-0 flex items-center">
                                    <div className="w-full border-t border-gray-300"></div>
                                </div>
                                <div className="relative flex justify-center text-sm">
                                    <span className="px-2 bg-gray-50 text-gray-500">{t('chat.guest.or')}</span>
                                </div>
                            </div>

                            <a
                                href="/login"
                                className="block w-full text-center py-3 border border-primary text-primary rounded-lg hover:bg-primary/5 transition-colors font-medium"
                            >
                                {t('chat.guest.login')}
                            </a>
                        </div>

                        <p className="text-xs text-gray-400 text-center mt-4">
                            {t('chat.guest.guestNote')}
                        </p>
                    </div>
                </div>
            ) : (
                <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50">
                    {messages.length === 0 && (
                        <div className="text-center text-gray-500 mt-8">
                            <span className="material-symbols-outlined text-5xl mb-2">chat_bubble_outline</span>
                            <h3 className="text-sm font-medium text-gray-900">{t('chat.messages.empty.title')}</h3>
                            <p className="text-xs text-gray-500 mt-1">{t('chat.messages.empty.desc')}</p>
                            {!isAuthenticated && (
                                <p className="text-xs mt-2 text-gray-400">
                                    {t('chat.messages.empty.guestNote')}
                                </p>
                            )}
                        </div>
                    )}

                    {messages.map((message, index) => {
                        const isOwn = isAuthenticated
                            ? message.senderId === user?.id
                            : message.senderId === guestId;

                        // Show "Seen" only on the very last message if it is own message and lastReadAt is newer
                        const isLastMessage = index === messages.length - 1;
                        // Simple logic: if admin read at X, and this message sent at Y < X, it is seen.
                        // But for simplicity in Phase 4, we just show "Seen" at the bottom if recently read.
                        // Or better: Check message.isRead from backend?
                        // Backend 'IsRead' is updated. But we only fetch initial.
                        // We need to update local messages IsRead when onMessagesRead fires?
                        // For now, let's use the 'lastReadAt' signal to show a "Seen" label at the bottom.

                        return (
                            <div
                                key={message.id}
                                className={`flex flex-col ${isOwn ? 'items-end' : 'items-start'}`}
                            >
                                <div className={`flex ${isOwn ? 'justify-end' : 'justify-start'} w-full`}>
                                    <div className={`max-w-[75%] ${isOwn ? 'order-2' : 'order-1'}`}>
                                        {!isOwn && (
                                            <p className="text-xs text-gray-500 mb-1 px-1">
                                                {message.senderName}
                                            </p>
                                        )}
                                        <div
                                            className={`rounded-2xl px-4 py-2 ${isOwn
                                                ? 'bg-primary text-white rounded-br-sm'
                                                : 'bg-white text-gray-900 rounded-bl-sm border border-gray-200'
                                                }`}
                                        >
                                            <p className="text-sm break-words">{message.content}</p>
                                            <p className={`text-xs mt-1 ${isOwn ? 'text-white/70' : 'text-gray-500'}`}>
                                                {formatTime(message.sentAt)}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                                {isOwn && isLastMessage && lastReadAt && new Date(message.sentAt) < lastReadAt && (
                                    <div className="text-[10px] text-gray-400 mt-1 mr-1">
                                        {t('chat.messages.seen', 'Đã xem')}
                                    </div>
                                )}
                            </div>
                        );
                    })}

                    {/* Typing Indicator */}
                    {isTyping && (
                        <div className="flex justify-start">
                            <div className="bg-white rounded-2xl px-4 py-3 border border-gray-200">
                                <div className="flex gap-1">
                                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
                                </div>
                            </div>
                        </div>
                    )}

                    <div ref={messagesEndRef} />
                </div>
            )}

            {/* Input */}
            <div className="p-4 bg-white border-t border-gray-200 relative">
                {/* Typing Indicator Text */}
                {isTyping && (
                    <div className="absolute -top-7 left-4 text-xs text-gray-500 bg-white/90 px-3 py-1 rounded-t-lg border border-b-0 border-gray-200 shadow-sm">
                        {t('chat.window.typing')}
                    </div>
                )}
                {/* Error Message Banner */}
                {errorMessage && (
                    <div className="mb-2 px-3 py-2 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
                        {errorMessage}
                    </div>
                )}

                <div className="flex gap-2">
                    <input
                        type="text"
                        value={inputMessage}
                        onChange={handleInputChange}
                        onKeyPress={handleKeyPress}
                        placeholder={t('chat.messages.inputPlaceholder')}
                        className="flex-1 px-4 py-2 border border-gray-300 rounded-full focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                        disabled={!isConnected}
                    />
                    <button
                        onClick={handleSendMessage}
                        disabled={!inputMessage.trim() || !isConnected}
                        className="bg-primary text-white rounded-full p-2 hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                        <span className="material-symbols-outlined">send</span>
                    </button>
                </div>
            </div>
        </div>
    );
};

export default ChatWindow;
