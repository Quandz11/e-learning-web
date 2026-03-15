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
    const [typingUsers, setTypingUsers] = useState<Record<string, boolean>>({});
    // Offline/Disconnected state: key = guestId
    const [disconnectedGuests, setDisconnectedGuests] = useState<Set<string>>(new Set());
    const [activeTab, setActiveTab] = useState<'guest' | 'authenticated'>('guest');
    const [isConversationListOpen, setIsConversationListOpen] = useState(false);

    // Use ref to avoid stale closure in SignalR callbacks
    const selectedConversationRef = useRef<AdminConversation | null>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);

    // Update ref when selectedConversation changes
    useEffect(() => {
        selectedConversationRef.current = selectedConversation;

        // Join/Leave SignalR groups for authenticated conversations
        if (selectedConversation?.type === 'authenticated' && selectedConversation.id) {
            console.log('[AdminChat] Joining conversation group:', selectedConversation.id);
            chatSignalR.joinConversation(selectedConversation.id).catch(err =>
                console.error('[AdminChat] Failed to join group:', err)
            );

            return () => {
                console.log('[AdminChat] Leaving conversation group:', selectedConversation.id);
                chatSignalR.leaveConversation(selectedConversation.id).catch(err =>
                    console.error('[AdminChat] Failed to leave group:', err)
                );
            };
        }
    }, [selectedConversation]);

    // Auto-scroll to bottom when messages change
    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    const playNotificationSound = (type: 'incoming' | 'outgoing') => {
        try {
            const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);

            if (type === 'incoming') {
                oscillator.frequency.value = 800;
                oscillator.type = 'sine';

                gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);

                oscillator.start(audioContext.currentTime);
                oscillator.stop(audioContext.currentTime + 0.3);
            } else {
                oscillator.frequency.setValueAtTime(400, audioContext.currentTime);
                oscillator.frequency.exponentialRampToValueAtTime(200, audioContext.currentTime + 0.1);
                oscillator.type = 'sine';

                gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.1);

                oscillator.start(audioContext.currentTime);
                oscillator.stop(audioContext.currentTime + 0.1);
            }
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
                    console.log('[Admin Chat] Current Selection:', current?.guestId, 'Incoming GuestId:', guestId);

                    if (current?.guestId === guestId) {
                        console.log('[Admin Chat] Adding message to current conversation');
                        setMessages(prev => {
                            if (prev.some(m => m.id === message.id)) return prev;
                            return [...prev, message as unknown as GuestMessage];
                        });

                        // Mark as read immediately if viewing
                        chatSignalR.markGuestAsRead(guestId);
                    }

                    // Play sound for all incoming guest messages
                    playNotificationSound('incoming');
                });

                // Listen for echo back of admin's own messages
                chatSignalR.onReceiveMessage((message) => {
                    console.log('[Admin Chat] Received message (echo back):', message);

                    // Always reload conversations to update snippets/unread
                    loadConversations();

                    // Play sound
                    if (message.senderId !== user?.id) {
                        playNotificationSound('incoming');
                    } else {
                        playNotificationSound('outgoing');
                    }

                    // Add to current conversation if it matches
                    const current = selectedConversationRef.current;
                    if (current) {
                        // Check if message belongs to current conversation
                        // For Echo, we assume it's for the current conversation if we triggered it
                        // But wait, if multiple tabs...
                        // If it's a guest conversation reply
                        if (current.type === 'guest') {
                            console.log('[Admin Chat] Adding admin message to GUEST conversation');
                            setMessages(prev => {
                                if (prev.some(m => m.id === message.id)) return prev;
                                return [...prev, message as unknown as GuestMessage];
                            });
                        }
                        // If it's an authenticated user conversation
                        else if (current.type === 'authenticated') {
                            // Can verify conversationId if message has it
                            if (message.conversationId && message.conversationId !== current.id) return;

                            console.log('[Admin Chat] Adding admin message to AUTH conversation');
                            setMessages(prev => {
                                if (prev.some(m => m.id === message.id)) return prev;
                                return [...prev, message as unknown as GuestMessage];
                            });
                        }
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

                chatSignalR.onMessagesRead(() => {
                    // Read receipts not surfaced in admin UI yet; placeholder to keep hook wired.
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
            console.log('[AdminChat] Loaded conversations:', data);

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
        setIsConversationListOpen(false);
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
            console.log('[AdminChat] Sending message. Selected:', JSON.stringify(selectedConversation, null, 2));

            if (selectedConversation.type === 'guest' && selectedConversation.guestId) {
                console.log('[AdminChat] Call sendGuestReply');
                await chatSignalR.sendGuestReply(selectedConversation.guestId, content);
                console.log('[AdminChat] sendGuestReply done');
                setInputMessage('');
            } else if (selectedConversation.type === 'authenticated' && selectedConversation.id) {
                // For authenticated users, we use sendMessage with conversationId
                await chatSignalR.sendMessage(selectedConversation.id, content);
                setInputMessage('');
            }
        } catch (error) {
            console.error('Failed to send message:', error);
            alert(t('admin.chat.error') || 'Failed to send message');
        } finally {
            console.log('[AdminChat] Cleanup sending state');
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
            <div className="h-full min-h-0 flex flex-col bg-gray-50 -m-3 sm:-m-4 lg:-m-8">
                {/* Header */}
                <div className="bg-white border-b border-gray-200 px-3 py-3 sm:px-4 sm:py-4 lg:px-6">
                    <div className="flex items-center justify-between gap-2">
                        <div>
                            <h1 className="text-xl sm:text-2xl font-bold text-gray-900">{t('admin.chat.title')}</h1>
                            <p className="mt-1 text-xs sm:text-sm text-gray-600">{t('admin.chat.subtitle')}</p>
                        </div>

                        <button
                            onClick={() => setIsConversationListOpen(true)}
                            className="inline-flex h-10 items-center gap-2 rounded-lg border border-gray-200 px-3 text-sm text-gray-700 lg:hidden"
                        >
                            <span className="material-symbols-outlined text-[18px]">chat</span>
                            {activeTab === 'guest' ? t('admin.chat.guestConversations') : t('admin.chat.memberConversations')}
                        </button>
                    </div>
                </div>

                {/* Main Content */}
                <div className="relative flex-1 min-h-0 flex overflow-hidden">
                    <div
                        className={`absolute inset-0 z-20 bg-black/40 transition-opacity lg:hidden ${isConversationListOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}
                        onClick={() => setIsConversationListOpen(false)}
                    />

                    {/* Conversation List */}
                    <div
                        className={`absolute lg:static inset-y-0 left-0 z-30 w-[86vw] max-w-sm lg:w-80 bg-white border-r border-gray-200 transform transition-transform duration-200 ${isConversationListOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'} flex flex-col`}
                    >
                        <div className="flex items-center justify-between border-b border-gray-200 px-4 py-3 lg:hidden">
                            <h2 className="text-sm font-semibold text-gray-900">{t('admin.chat.title')}</h2>
                            <button
                                onClick={() => setIsConversationListOpen(false)}
                                className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-gray-200 text-gray-700"
                                aria-label="Close conversations"
                            >
                                <span className="material-symbols-outlined text-[18px]">close</span>
                            </button>
                        </div>

                        {/* Tabs */}
                        <div className="flex border-b border-gray-200">
                            <button
                                onClick={() => { setActiveTab('guest'); setSelectedConversation(null); }}
                                className={`flex-1 py-3 text-sm font-medium text-center ${activeTab === 'guest'
                                    ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50/50'
                                    : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                                    }`}
                            >
                                {t('admin.chat.guest')}
                            </button>
                            <button
                                onClick={() => { setActiveTab('authenticated'); setSelectedConversation(null); }}
                                className={`flex-1 py-3 text-sm font-medium text-center ${activeTab === 'authenticated'
                                    ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50/50'
                                    : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                                    }`}
                            >
                                {t('admin.chat.member')}
                            </button>
                        </div>

                        <div className="p-4 border-b border-gray-200 bg-gray-50/50">
                            <h2 className="font-semibold text-gray-900">
                                {activeTab === 'guest' ? t('admin.chat.guestConversations') : t('admin.chat.memberConversations')}
                            </h2>
                            <p className="text-xs text-gray-500 mt-1">
                                {conversations.filter(c => c.type === activeTab).length} {t('admin.chat.active')}
                            </p>
                        </div>

                        <div className="flex-1 overflow-y-auto">
                            {loading ? (
                                <div className="p-4 text-center text-gray-500">{t('admin.chat.loading')}</div>
                            ) : conversations.filter(c => c.type === activeTab).length === 0 ? (
                                <div className="p-4 text-center text-gray-500">{t('admin.chat.noConversations')}</div>
                            ) : (
                                conversations
                                    .filter(c => c.type === activeTab)
                                    .map(conv => (
                                        <div
                                            key={conv.id}
                                            onClick={() => handleSelectConversation(conv)}
                                            className={`p-4 border-b border-gray-100 cursor-pointer hover:bg-gray-50 transition-colors ${selectedConversation?.id === conv.id ? 'bg-blue-50 border-l-4 border-l-blue-500' : ''
                                                }`}
                                        >
                                            <div className="flex items-start justify-between gap-2">
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
                                                    {(typingUsers[conv.guestId!] || typingUsers[conv.userId!]) && (
                                                        <span className="text-xs text-green-600 font-medium animate-pulse">
                                                            Typing...
                                                        </span>
                                                    )}
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
                    <div className="flex-1 min-w-0 flex flex-col bg-white">
                        {selectedConversation ? (
                            <>
                                {/* Chat Header */}
                                <div className="px-3 py-3 sm:px-4 sm:py-4 lg:px-6 border-b border-gray-200">
                                    <div className="flex items-center justify-between gap-3">
                                        <div className="min-w-0">
                                            <div className="flex items-center gap-2">
                                                <button
                                                    onClick={() => setIsConversationListOpen(true)}
                                                    className="inline-flex h-8 w-8 items-center justify-center rounded-md border border-gray-200 text-gray-600 lg:hidden"
                                                    aria-label="Back to conversations"
                                                >
                                                    <span className="material-symbols-outlined text-[18px]">arrow_back</span>
                                                </button>
                                                <h3 className="truncate font-semibold text-gray-900">{selectedConversation.userName}</h3>
                                            </div>
                                            <p className="text-xs sm:text-sm text-gray-500 mt-1">
                                                {selectedConversation.type === 'guest' ? t('admin.chat.guest') : t('admin.chat.member')}
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
                                                className="h-9 shrink-0 px-3 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                            >
                                                {t('admin.chat.close')}
                                            </button>
                                        )}
                                    </div>
                                </div>

                                {/* Messages */}
                                <div className="flex-1 overflow-y-auto p-3 sm:p-4 lg:p-6 space-y-3 sm:space-y-4">
                                    {messages.map(msg => {
                                        const isMe = selectedConversation.type === 'guest'
                                            ? !msg.isFromGuest
                                            : msg.senderId === user?.id;

                                        return (
                                            <div
                                                key={msg.id}
                                                className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}
                                            >
                                                <div className={`max-w-[85%] sm:max-w-md rounded-2xl px-4 py-2 ${!isMe
                                                    ? 'bg-white text-gray-900 border border-gray-200 rounded-bl-sm'
                                                    : 'bg-primary text-white rounded-br-sm'
                                                    }`}>
                                                    {!isMe && <p className="text-xs text-gray-500 mb-1">{msg.senderName}</p>}
                                                    <p className="whitespace-pre-wrap break-words">{msg.content}</p>
                                                    <p className={`text-xs mt-1 ${msg.isFromGuest ? 'text-gray-400' : 'text-white/70'}`}>
                                                        {new Date(msg.sentAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                    </p>
                                                </div>
                                            </div>
                                        );
                                    })}

                                    <div ref={messagesEndRef} />
                                </div>

                                {/* Input */}
                                <div className="p-3 sm:p-4 border-t border-gray-200">
                                    <div className="flex flex-col sm:flex-row gap-2">
                                        <input
                                            type="text"
                                            value={inputMessage}
                                            onChange={(e) => setInputMessage(e.target.value)}
                                            onKeyPress={handleKeyPress}
                                            onFocus={() => {
                                                if (selectedConversation?.id && selectedConversation.type === 'authenticated') {
                                                    chatSignalR.markAsRead(selectedConversation.id);
                                                    loadConversations();
                                                } else if (selectedConversation?.guestId && selectedConversation.type === 'guest') {
                                                    chatSignalR.markGuestAsRead(selectedConversation.guestId);
                                                    loadConversations();
                                                }
                                            }}
                                            placeholder="Type your message..."
                                            className="h-11 w-full flex-1 px-4 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                                            disabled={sending}
                                        />
                                        <button
                                            onClick={handleSendMessage}
                                            disabled={!inputMessage.trim() || sending}
                                            className="h-11 w-full sm:w-auto px-5 bg-primary text-white rounded-lg hover:bg-primary/90 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
                                        >
                                            {sending ? t('admin.chat.sending') : t('admin.chat.send')}
                                        </button>
                                    </div>
                                </div>
                            </>
                        ) : (
                            <div className="flex-1 flex items-center justify-center text-gray-500 p-6">
                                <div className="text-center">
                                    <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                                    </svg>
                                    <h3 className="mt-2 text-sm font-medium text-gray-900">{t('admin.chat.selectTitle')}</h3>
                                    <p className="mt-1 text-sm text-gray-500">{t('admin.chat.selectDesc')}</p>
                                    <button
                                        onClick={() => setIsConversationListOpen(true)}
                                        className="mt-4 inline-flex h-10 items-center justify-center rounded-lg border border-gray-200 px-4 text-sm text-gray-700 lg:hidden"
                                    >
                                        {activeTab === 'guest' ? t('admin.chat.guestConversations') : t('admin.chat.memberConversations')}
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
}
