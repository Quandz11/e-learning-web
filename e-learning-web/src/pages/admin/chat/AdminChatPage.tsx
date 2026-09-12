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
    const [searchQuery, setSearchQuery] = useState('');
    const [loading, setLoading] = useState(true);
    const [sending, setSending] = useState(false);
    const [typingUsers, setTypingUsers] = useState<Record<string, boolean>>({});
    // Offline/Disconnected state: key = guestId
    const [disconnectedGuests, setDisconnectedGuests] = useState<Set<string>>(new Set());
    const [activeTab, setActiveTab] = useState<'guest' | 'authenticated'>('authenticated');
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
            const data = await adminChatApi.getAllConversations();
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
                const msgs = await adminChatApi.getGuestMessages(conversation.guestId);
                setMessages(msgs);

                // Mark as read
                await adminChatApi.markGuestAsRead(conversation.guestId);
                // Also send real-time signal so guest sees we read it immediately
                chatSignalR.markGuestAsRead(conversation.guestId);

                loadConversations(); // Refresh to update unread count
            } else if (conversation.type === 'authenticated') {
                const msgs = await adminChatApi.getConversationMessages(conversation.id);
                setMessages(msgs);

                // Mark as read backend
                // Calling API to mark read (which should also trigger SignalR event to user)
                await adminChatApi.markConversationAsRead(conversation.id);

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

    const filteredConversations = conversations
        .filter(c => c.type === activeTab)
        .filter(c => searchQuery.trim() === '' || c.userName.toLowerCase().includes(searchQuery.toLowerCase()));

    return (
        <AdminLayout>
            <div className="h-full min-h-0 flex flex-col bg-gray-100 -m-3 sm:-m-4 lg:-m-8">
                {/* Main Messenger Container */}
                <div className="relative flex-1 min-h-0 flex overflow-hidden bg-white shadow-sm">
                    <div
                        className={`absolute inset-0 z-20 bg-black/40 transition-opacity lg:hidden ${isConversationListOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}
                        onClick={() => setIsConversationListOpen(false)}
                    />

                    {/* Left Sidebar: Messenger Conversation List */}
                    <div
                        className={`absolute lg:static inset-y-0 left-0 z-30 w-[88vw] max-w-sm lg:w-96 bg-white border-r border-gray-200 transform transition-transform duration-200 ${isConversationListOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'} flex flex-col`}
                    >
                        {/* Sidebar Header & Search */}
                        <div className="p-4 border-b border-gray-200">
                            <div className="flex items-center justify-between mb-3">
                                <h1 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                                    <span className="material-symbols-outlined text-primary text-2xl">forum</span>
                                    Tin nhắn
                                </h1>
                                <button
                                    onClick={() => setIsConversationListOpen(false)}
                                    className="lg:hidden p-1 rounded-lg border border-gray-200 text-gray-500"
                                >
                                    <span className="material-symbols-outlined text-xl">close</span>
                                </button>
                            </div>

                            {/* Search Bar */}
                            <div className="relative">
                                <span className="material-symbols-outlined absolute left-3 top-2.5 text-gray-400 text-lg">search</span>
                                <input
                                    type="text"
                                    value={searchQuery}
                                    onChange={(e) => setSearchQuery(e.target.value)}
                                    placeholder="Tìm kiếm người dùng..."
                                    className="w-full pl-9 pr-4 py-2 bg-gray-100 border border-transparent rounded-full text-sm text-gray-900 placeholder-gray-400 focus:bg-white focus:border-primary focus:outline-none transition-all"
                                />
                            </div>
                        </div>

                        {/* Tabs: Thành viên / Khách */}
                        <div className="flex border-b border-gray-200 bg-gray-50/50 p-1">
                            <button
                                onClick={() => { setActiveTab('authenticated'); setSelectedConversation(null); }}
                                className={`flex-1 py-2 px-3 text-xs font-semibold rounded-lg text-center transition-all flex items-center justify-center gap-1.5 ${activeTab === 'authenticated'
                                    ? 'bg-white text-primary shadow-sm'
                                    : 'text-gray-600 hover:text-gray-900'
                                    }`}
                            >
                                <span className="material-symbols-outlined text-base">person</span>
                                Thành viên
                                <span className="ml-1 px-1.5 py-0.2 bg-primary/10 text-primary text-[10px] rounded-full">
                                    {conversations.filter(c => c.type === 'authenticated').length}
                                </span>
                            </button>
                            <button
                                onClick={() => { setActiveTab('guest'); setSelectedConversation(null); }}
                                className={`flex-1 py-2 px-3 text-xs font-semibold rounded-lg text-center transition-all flex items-center justify-center gap-1.5 ${activeTab === 'guest'
                                    ? 'bg-white text-primary shadow-sm'
                                    : 'text-gray-600 hover:text-gray-900'
                                    }`}
                            >
                                <span className="material-symbols-outlined text-base">support_agent</span>
                                Khách vãng lai
                                <span className="ml-1 px-1.5 py-0.2 bg-amber-100 text-amber-800 text-[10px] rounded-full">
                                    {conversations.filter(c => c.type === 'guest').length}
                                </span>
                            </button>
                        </div>

                        {/* Conversation Item List */}
                        <div className="flex-1 overflow-y-auto divide-y divide-gray-100">
                            {loading ? (
                                <div className="p-8 text-center text-gray-400 text-sm">
                                    <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-2" />
                                    Đang tải cuộc trò chuyện...
                                </div>
                            ) : filteredConversations.length === 0 ? (
                                <div className="p-8 text-center text-gray-400 text-sm">
                                    Không tìm thấy cuộc trò chuyện nào
                                </div>
                            ) : (
                                filteredConversations.map(conv => {
                                    const isSelected = selectedConversation?.id === conv.id;
                                    const isTyping = typingUsers[conv.guestId!] || typingUsers[conv.userId!];
                                    const isOffline = conv.type === 'guest' && disconnectedGuests.has(conv.guestId!);

                                    return (
                                        <div
                                            key={conv.id}
                                            onClick={() => handleSelectConversation(conv)}
                                            className={`p-3.5 cursor-pointer transition-all flex items-center gap-3 ${isSelected ? 'bg-emerald-50/70 border-l-4 border-primary' : 'hover:bg-gray-50'
                                                }`}
                                        >
                                            {/* Avatar */}
                                            <div className="relative shrink-0">
                                                <div className={`w-11 h-11 rounded-full flex items-center justify-center font-bold text-white shadow-sm ${conv.type === 'guest' ? 'bg-amber-500' : 'bg-primary'
                                                    }`}>
                                                    {conv.userName.charAt(0).toUpperCase()}
                                                </div>
                                                <div className={`absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full border-2 border-white ${isOffline ? 'bg-gray-300' : 'bg-green-500'
                                                    }`} />
                                            </div>

                                            {/* Info */}
                                            <div className="flex-1 min-w-0">
                                                <div className="flex items-center justify-between gap-1 mb-0.5">
                                                    <span className="font-semibold text-sm text-gray-900 truncate">
                                                        {conv.userName}
                                                    </span>
                                                    <span className="text-[11px] text-gray-400 shrink-0">
                                                        {new Date(conv.lastActivity).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                    </span>
                                                </div>

                                                <div className="flex items-center justify-between gap-1">
                                                    <p className={`text-xs truncate ${conv.unreadCount > 0 ? 'font-semibold text-gray-900' : 'text-gray-500'}`}>
                                                        {isTyping ? (
                                                            <span className="text-primary italic font-medium">Đang nhập...</span>
                                                        ) : (
                                                            conv.lastMessage || 'Chưa có tin nhắn'
                                                        )}
                                                    </p>
                                                    {conv.unreadCount > 0 && (
                                                        <span className="px-2 py-0.5 text-[11px] font-bold bg-primary text-white rounded-full shrink-0 shadow-sm">
                                                            {conv.unreadCount}
                                                        </span>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    );
                                })
                            )}
                        </div>
                    </div>

                    {/* Right Panel: Chat Room / Messenger Thread */}
                    <div className="flex-1 min-w-0 flex flex-col bg-gray-50/50">
                        {selectedConversation ? (
                            <>
                                {/* Chat Header */}
                                <div className="px-4 py-3 bg-white border-b border-gray-200 flex items-center justify-between shadow-xs">
                                    <div className="flex items-center gap-3 min-w-0">
                                        <button
                                            onClick={() => setIsConversationListOpen(true)}
                                            className="lg:hidden p-1.5 rounded-lg border border-gray-200 text-gray-600"
                                        >
                                            <span className="material-symbols-outlined text-lg">arrow_back</span>
                                        </button>

                                        <div className="relative shrink-0">
                                            <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-white shadow-xs ${selectedConversation.type === 'guest' ? 'bg-amber-500' : 'bg-primary'
                                                }`}>
                                                {selectedConversation.userName.charAt(0).toUpperCase()}
                                            </div>
                                            <div className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-green-500 border-2 border-white" />
                                        </div>

                                        <div className="min-w-0">
                                            <div className="flex items-center gap-2">
                                                <h2 className="font-bold text-gray-900 text-base truncate">
                                                    {selectedConversation.userName}
                                                </h2>
                                                <span className={`px-2 py-0.5 text-[10px] font-semibold rounded-full ${selectedConversation.type === 'guest' ? 'bg-amber-100 text-amber-800' : 'bg-emerald-100 text-primary'
                                                    }`}>
                                                    {selectedConversation.type === 'guest' ? 'Khách hàng' : 'Thành viên'}
                                                </span>
                                            </div>
                                            <p className="text-xs text-gray-500 flex items-center gap-1.5">
                                                <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
                                                Trực tuyến
                                                {(typingUsers[selectedConversation.guestId!] || typingUsers[selectedConversation.userId!]) && (
                                                    <span className="ml-1 text-primary font-medium italic animate-pulse">
                                                        • đang nhập...
                                                    </span>
                                                )}
                                            </p>
                                        </div>
                                    </div>

                                    {selectedConversation.type === 'guest' && (
                                        <button
                                            onClick={() => {
                                                if (selectedConversation.guestId && accessToken) {
                                                    adminChatApi.closeGuestConversation(selectedConversation.guestId);
                                                    setSelectedConversation(null);
                                                    loadConversations();
                                                }
                                            }}
                                            className="px-3 py-1.5 text-xs font-semibold text-red-600 bg-red-50 hover:bg-red-100 rounded-lg transition-colors border border-red-200"
                                        >
                                            Kết thúc chat
                                        </button>
                                    )}
                                </div>

                                {/* Messages Area */}
                                <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-[#F8FAFC]">
                                    {messages.map((msg, idx) => {
                                        const isMe = selectedConversation.type === 'guest'
                                            ? !msg.isFromGuest
                                            : msg.senderId === user?.id;

                                        return (
                                            <div
                                                key={msg.id || idx}
                                                className={`flex flex-col ${isMe ? 'items-end' : 'items-start'}`}
                                            >
                                                <div className={`flex gap-2 max-w-[85%] sm:max-w-lg ${isMe ? 'flex-row-reverse' : 'flex-row'}`}>
                                                    {!isMe && (
                                                        <div className="w-7 h-7 rounded-full bg-gray-300 flex items-center justify-center text-xs font-bold text-gray-700 shrink-0 mt-1">
                                                            {msg.senderName ? msg.senderName.charAt(0).toUpperCase() : 'U'}
                                                        </div>
                                                    )}

                                                    <div className={`rounded-2xl px-4 py-2.5 shadow-2xs ${isMe
                                                        ? 'bg-primary text-white rounded-br-xs'
                                                        : 'bg-white text-gray-900 rounded-bl-xs border border-gray-200/80'
                                                        }`}>
                                                        {!isMe && (
                                                            <p className="text-[11px] font-bold text-primary mb-0.5">
                                                                {msg.senderName}
                                                            </p>
                                                        )}
                                                        <p className="text-sm whitespace-pre-wrap break-words leading-relaxed">
                                                            {msg.content}
                                                        </p>
                                                        <div className={`text-[10px] mt-1 text-right ${isMe ? 'text-white/75' : 'text-gray-400'
                                                            }`}>
                                                            {new Date(msg.sentAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        );
                                    })}

                                    <div ref={messagesEndRef} />
                                </div>

                                {/* Input Bar */}
                                <div className="p-3 bg-white border-t border-gray-200">
                                    <div className="flex items-center gap-2">
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
                                            placeholder="Nhập tin nhắn..."
                                            className="flex-1 px-4 py-2.5 bg-gray-100 border border-transparent rounded-full text-sm text-gray-900 placeholder-gray-400 focus:bg-white focus:border-primary focus:outline-none transition-all"
                                            disabled={sending}
                                        />
                                        <button
                                            onClick={handleSendMessage}
                                            disabled={!inputMessage.trim() || sending}
                                            className="w-10 h-10 rounded-full bg-primary text-white flex items-center justify-center hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm shrink-0"
                                        >
                                            <span className="material-symbols-outlined text-xl">send</span>
                                        </button>
                                    </div>
                                </div>
                            </>
                        ) : (
                            <div className="flex-1 flex items-center justify-center text-gray-400 p-6">
                                <div className="text-center max-w-sm">
                                    <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4 text-primary">
                                        <span className="material-symbols-outlined text-3xl">chat</span>
                                    </div>
                                    <h3 className="text-lg font-bold text-gray-800">Trung tâm Tin nhắn SKVI</h3>
                                    <p className="text-xs text-gray-500 mt-1">
                                        Chọn một cuộc trò chuyện từ danh sách bên trái để bắt đầu trao đổi trực tiếp với học viên hoặc khách hàng.
                                    </p>
                                    <button
                                        onClick={() => setIsConversationListOpen(true)}
                                        className="mt-4 px-4 py-2 bg-primary text-white text-xs font-semibold rounded-lg lg:hidden"
                                    >
                                        Mở danh sách cuộc trò chuyện
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
