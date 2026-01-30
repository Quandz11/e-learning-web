import { useEffect, useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import type { RootState } from '../../../store/store';
import { adminChatApi, type AdminConversation, type GuestMessage } from '../../../services/admin/adminChatApi';
import { chatSignalR } from '../../../services/chat/chatSignalR';
import AdminLayout from '../../../components/admin/AdminLayout';

export default function AdminChatPage() {
    const { t } = useTranslation();
    const { accessToken, user } = useSelector((state: RootState) => state.auth);
    const [conversations, setConversations] = useState<AdminConversation[]>([]);
    const [selectedConversation, setSelectedConversation] = useState<AdminConversation | null>(null);
    const [messages, setMessages] = useState<GuestMessage[]>([]);
    const [inputMessage, setInputMessage] = useState('');
    const [loading, setLoading] = useState(true);
    const [sending, setSending] = useState(false);
    const [lastReadByGuest, setLastReadByGuest] = useState<Date | null>(null); // For "Seen" status
    // Typing state: key = guestId or userId, value = isTyping
    const [typingUsers, setTypingUsers] = useState<Record<string, boolean>>({});
    // Offline/Disconnected state: key = guestId
    const [disconnectedGuests, setDisconnectedGuests] = useState<Set<string>>(new Set());

    // Use ref to avoid stale closure in SignalR callbacks
    const selectedConversationRef = useRef<AdminConversation | null>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);

    // Update ref when selectedConversation changes
    useEffect(() => {
        selectedConversationRef.current = selectedConversation;
    }, [selectedConversation]);

    // Auto-scroll to bottom when messages change
    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    const playNotificationSound = () => {
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

    useEffect(() => {
        loadConversations();

        // Connect to SignalR
        const connectSignalR = async () => {
            try {
                console.log('[Admin Chat] Connecting to SignalR...');
                await chatSignalR.connect(accessToken || undefined);
                console.log('[Admin Chat] Connected to SignalR');

                // Listen for new guest messages
                chatSignalR.onReceiveGuestMessage((guestId, message) => {
                    console.log('[Admin Chat] Received guest message:', guestId, message);

                    // Update conversation list
                    loadConversations();

                    // If this is the selected conversation, add message
                    const current = selectedConversationRef.current;
                    if (current?.guestId === guestId) {
                        console.log('[Admin Chat] Adding message to current conversation');
                        setMessages(prev => {
                            if (prev.some(m => m.id === message.id)) return prev;
                            return [...prev, message as unknown as GuestMessage];
                        });
                    }

                    // Play sound for all incoming guest messages
                    playNotificationSound();
                });

                // Listen for echo back of admin's own messages
                chatSignalR.onReceiveMessage((message) => {
                    console.log('[Admin Chat] Received message (echo back):', message);

                    // Add to current conversation if it matches
                    const current = selectedConversationRef.current;
                    if (current?.type === 'guest') {
                        console.log('[Admin Chat] Adding admin message to current conversation');
                        setMessages(prev => {
                            if (prev.some(m => m.id === message.id)) return prev;
                            return [...prev, message as unknown as GuestMessage];
                        });
                    }
                });

                // Listen for guest disconnect
                chatSignalR.onGuestDisconnected((guestId) => {
                    console.log('[Admin Chat] Guest disconnected:', guestId);
                    setDisconnectedGuests(prev => new Set(prev).add(guestId));
                    loadConversations(); // Refresh list to update status if needed
                });

                // Listen for typing events
                chatSignalR.onGuestTyping((guestId) => {
                    setTypingUsers(prev => ({ ...prev, [guestId]: true }));
                });

                chatSignalR.onGuestStoppedTyping((guestId) => {
                    setTypingUsers(prev => ({ ...prev, [guestId]: false }));
                });

                chatSignalR.onMessagesRead((data) => {
                    // If current conversation matches data
                    if (!selectedConversationRef.current) return;

                    if (selectedConversationRef.current.type === 'guest') {
                        // If event has no args/generic or matches guestId (if we added that support)
                        // Assuming for now any signal means guest read it
                        setLastReadByGuest(new Date());
                    } else {
                        // Auth user
                        if (data.conversationId === selectedConversationRef.current.id && data.readerId !== user?.id) {
                            setLastReadByGuest(new Date());
                        }
                    }
                });

                chatSignalR.onUserTyping((userId) => {
                    // For auth users, userId is the key
                    setTypingUsers(prev => ({ ...prev, [userId]: true }));
                });

                chatSignalR.onUserStoppedTyping((userId) => {
                    setTypingUsers(prev => ({ ...prev, [userId]: false }));
                });

                console.log('[Admin Chat] Event handlers registered');
            } catch (error) {
                console.error('[Admin Chat] Failed to connect to SignalR:', error);
            }
        };

        connectSignalR();

        return () => {
            console.log('[Admin Chat] Cleaning up SignalR callbacks');
            chatSignalR.clearCallbacks();
        };
    }, [accessToken, user]);

    const loadConversations = async () => {
        if (!accessToken) return;

        try {
            setLoading(true);
            const data = await adminChatApi.getAllConversations(accessToken);
            // Merge lists
            const all = [
                ...data.guestConversations,
                ...data.authenticatedConversations
            ].map(c => ({
                ...c,
                // If guest is in disconnected set, mark as inactive visually
                isOnline: c.type === 'guest' ? !disconnectedGuests.has(c.guestId!) : true // Assume auth users online for now
            })).sort((a, b) => new Date(b.lastActivity).getTime() - new Date(a.lastActivity).getTime());

            setConversations(all);
        } catch (error) {
            console.error('Failed to load conversations:', error);
        } finally {
            setLoading(false);
        }
    };

    const loadMessages = async (conversation: AdminConversation) => {
        if (!accessToken) return;

        try {
            if (conversation.type === 'guest' && conversation.guestId) {
                const msgs = await adminChatApi.getGuestMessages(conversation.guestId, accessToken);
                setMessages(msgs);

                // Mark as read
                await adminChatApi.markGuestAsRead(conversation.guestId, accessToken);
                // Also send real-time signal so guest sees we read it immediately
                chatSignalR.markGuestAsRead(conversation.guestId);

                loadConversations(); // Refresh to update unread count
            } else if (conversation.type === 'authenticated') {
                const msgs = await adminChatApi.getConversationMessages(conversation.id, accessToken);
                setMessages(msgs);

                // Mark as read backend
                // Calling API to mark read (which should also trigger SignalR event to user)
                await adminChatApi.markConversationAsRead(conversation.id, accessToken);

                loadConversations();
            }
        } catch (error) {
            console.error('Failed to load messages:', error);
        }
    };

    const handleSelectConversation = (conversation: AdminConversation) => {
        setSelectedConversation(conversation);
        setLastReadByGuest(null); // Reset seen status when switching
        loadMessages(conversation);
    };

    const handleSendMessage = async () => {
        if (!inputMessage.trim() || !selectedConversation || !accessToken) return;

        const content = inputMessage.trim();

        if (content.length > 1000) {
            alert('Message is too long (max 1000 characters)');
            return;
        }

        try {
            setSending(true);

            if (selectedConversation.type === 'guest' && selectedConversation.guestId) {
                await chatSignalR.sendGuestReply(selectedConversation.guestId, content);
                setInputMessage('');
            } else if (selectedConversation.type === 'authenticated' && selectedConversation.id) {
                // For authenticated users, we use sendMessage with conversationId
                await chatSignalR.sendMessage(selectedConversation.id, content);
                setInputMessage('');
            }
        } catch (error) {
            console.error('Failed to send message:', error);
            console.error('Failed to send message:', error);
            alert(t('admin.chat.error') || 'Failed to send message');
        } finally {
            setSending(false);
        }
    };

    const handleKeyPress = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage();
        }
    };

    return (
        <AdminLayout>
            <div className="h-full flex flex-col bg-gray-50 -m-4 md:-m-8">
                {/* Header */}
                <div className="bg-white border-b border-gray-200 px-6 py-4">
                    <h1 className="text-2xl font-bold text-gray-900">{t('admin.chat.title')}</h1>
                    <p className="text-sm text-gray-600 mt-1">{t('admin.chat.subtitle')}</p>
                </div>

                {/* Main Content */}
                <div className="flex-1 flex overflow-hidden">
                    {/* Conversation List */}
                    <div className="w-80 bg-white border-r border-gray-200 flex flex-col">
                        <div className="p-4 border-b border-gray-200">
                            <h2 className="font-semibold text-gray-900">{t('admin.chat.conversations')}</h2>
                            <p className="text-xs text-gray-500 mt-1">{conversations.length} {t('admin.chat.active')}</p>
                        </div>

                        <div className="flex-1 overflow-y-auto">
                            {loading ? (
                                <div className="p-4 text-center text-gray-500">{t('admin.chat.loading')}</div>
                            ) : conversations.length === 0 ? (
                                <div className="p-4 text-center text-gray-500">{t('admin.chat.noConversations')}</div>
                            ) : (
                                conversations.map(conv => (
                                    <div
                                        key={conv.id}
                                        onClick={() => handleSelectConversation(conv)}
                                        className={`p-4 border-b border-gray-100 cursor-pointer hover:bg-gray-50 transition-colors ${selectedConversation?.id === conv.id ? 'bg-blue-50 border-l-4 border-l-blue-500' : ''
                                            }`}
                                    >
                                        <div className="flex items-start justify-between">
                                            <div className="flex-1 min-w-0">
                                                <div className="flex items-center gap-2">
                                                    <span className="font-medium text-gray-900 truncate">
                                                        {conv.userName}
                                                    </span>
                                                    {conv.type === 'guest' && (
                                                        <span className="px-2 py-0.5 text-xs bg-yellow-100 text-yellow-800 rounded-full">
                                                            {t('admin.chat.guest')}
                                                        </span>
                                                    )}
                                                </div>
                                                <p className="text-sm text-gray-600 truncate mt-1">
                                                    {conv.lastMessage || t('admin.chat.noMessages')}
                                                </p>
                                                <p className="text-xs text-gray-400 mt-1">
                                                    {new Date(conv.lastActivity).toLocaleString()}
                                                </p>
                                            </div>
                                            <div className="flex flex-col items-end gap-1">
                                                {conv.unreadCount > 0 && (
                                                    <span className="px-2 py-1 text-xs font-bold bg-blue-500 text-white rounded-full">
                                                        {conv.unreadCount}
                                                    </span>
                                                )}
                                                {/* Typing Indicator in List */}
                                                {(typingUsers[conv.guestId!] || typingUsers[conv.userId!]) && (
                                                    <span className="text-xs text-green-600 font-medium animate-pulse">
                                                        Typing...
                                                    </span>
                                                )}
                                                {/* Offline Indicator */}
                                                {conv.type === 'guest' && disconnectedGuests.has(conv.guestId!) && (
                                                    <span className="text-xs text-gray-400">Offline</span>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                    </div>

                    {/* Chat Panel */}
                    <div className="flex-1 flex flex-col bg-white">
                        {selectedConversation ? (
                            <>
                                {/* Chat Header */}
                                <div className="px-6 py-4 border-b border-gray-200">
                                    <div className="flex items-center justify-between">
                                        <div>
                                            <h3 className="font-semibold text-gray-900">{selectedConversation.userName}</h3>
                                            <p className="text-sm text-gray-500">
                                                {selectedConversation.type === 'guest' ? 'Guest User' : 'Authenticated User'}
                                                {(typingUsers[selectedConversation.guestId!] || typingUsers[selectedConversation.userId!]) && (
                                                    <span className="ml-2 text-xs text-green-600 font-medium animate-pulse">
                                                        is typing...
                                                    </span>
                                                )}
                                                {selectedConversation.type === 'guest' && disconnectedGuests.has(selectedConversation.guestId!) && (
                                                    <span className="ml-2 text-xs text-gray-400">
                                                        (Offline)
                                                    </span>
                                                )}
                                            </p>
                                        </div>
                                        {selectedConversation.type === 'guest' && (
                                            <button
                                                onClick={() => {
                                                    if (selectedConversation.guestId && accessToken) {
                                                        adminChatApi.closeGuestConversation(selectedConversation.guestId, accessToken);
                                                        setSelectedConversation(null);
                                                        loadConversations();
                                                    }
                                                }}
                                                className="px-3 py-1 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                            >
                                                {t('admin.chat.close')}
                                            </button>
                                        )}
                                    </div>
                                </div>

                                {/* Messages */}
                                <div className="flex-1 overflow-y-auto p-6 space-y-4">
                                    {messages.map(msg => (
                                        <div
                                            key={msg.id}
                                            className={`flex ${msg.isFromGuest ? 'justify-start' : 'justify-end'}`}
                                        >
                                            <div className={`max-w-md rounded-2xl px-4 py-2 ${msg.isFromGuest
                                                ? 'bg-white text-gray-900 border border-gray-200 rounded-bl-sm'
                                                : 'bg-primary text-white rounded-br-sm'
                                                }`}>
                                                {msg.isFromGuest && <p className="text-xs text-gray-500 mb-1">{msg.senderName}</p>}
                                                <p className="whitespace-pre-wrap">{msg.content}</p>
                                                <p className={`text-xs mt-1 ${msg.isFromGuest ? 'text-gray-400' : 'text-white/70'}`}>
                                                    {new Date(msg.sentAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                </p>
                                            </div>
                                        </div>
                                    ))}

                                    {/* SEEN STATUS (Last message from Me) */}
                                    {messages.length > 0 && !messages[messages.length - 1].isFromGuest && lastReadByGuest && (
                                        <div className="flex justify-end mt-1 mr-1">
                                            <span className="text-[10px] text-gray-400">{t('chat.messages.seen', 'Đã xem')}</span>
                                        </div>
                                    )}

                                    <div ref={messagesEndRef} />
                                </div>

                                {/* Input */}
                                <div className="p-4 border-t border-gray-200">
                                    <div className="flex gap-2">
                                        <input
                                            type="text"
                                            value={inputMessage}
                                            onChange={(e) => setInputMessage(e.target.value)}
                                            onKeyPress={handleKeyPress}
                                            onFocus={() => {
                                                // Mark as read when focusing input
                                                if (selectedConversation?.id && selectedConversation.type === 'authenticated') {
                                                    chatSignalR.markAsRead(selectedConversation.id);
                                                    // Refresh list to clear badge? Maybe just update local state if possible specific to this conversation
                                                    // For now, loadConversations is safe
                                                    loadConversations();
                                                } else if (selectedConversation?.guestId && selectedConversation.type === 'guest') {
                                                    chatSignalR.markGuestAsRead(selectedConversation.guestId);
                                                    loadConversations();
                                                }
                                            }}
                                            placeholder="Type your message..."
                                            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                                            disabled={sending}
                                        />
                                        <button
                                            onClick={handleSendMessage}
                                            disabled={!inputMessage.trim() || sending}
                                            className="px-6 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
                                        >
                                            {sending ? t('admin.chat.sending') : t('admin.chat.send')}
                                        </button>
                                    </div>
                                </div>
                            </>
                        ) : (
                            <div className="flex-1 flex items-center justify-center text-gray-500">
                                <div className="text-center">
                                    <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                                    </svg>
                                    <h3 className="mt-2 text-sm font-medium text-gray-900">{t('admin.chat.selectTitle')}</h3>
                                    <p className="mt-1 text-sm text-gray-500">{t('admin.chat.selectDesc')}</p>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
}
