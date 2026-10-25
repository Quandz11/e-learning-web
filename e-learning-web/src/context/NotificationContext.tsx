import { tokenService, sessionId } from '../services/tokenService';
import { apiClient } from '../services/apiClient';
import { getHubUrl } from '../services/apiConfig';
import React, { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { HubConnection, HubConnectionBuilder, LogLevel } from '@microsoft/signalr';
import { useSelector } from 'react-redux';
import { toast } from 'react-hot-toast';
import notificationApi, { type NotificationDto } from '../services/notificationApi';
import type { RootState } from '../store/store';

interface NotificationContextType {
    notifications: NotificationDto[];
    unreadCount: number;
    isConnected: boolean;
    fetchNotifications: () => Promise<void>;
    markAsRead: (id: string) => Promise<void>;
    markAllAsRead: () => Promise<void>;
    sendNotification: (data: any) => Promise<void>;
    loading: boolean;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);


export const NotificationProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const { user, accessToken: token } = useSelector((state: RootState) => state.auth);
    const [connection, setConnection] = useState<HubConnection | null>(null);
    const [notifications, setNotifications] = useState<NotificationDto[]>([]);
    const [unreadCount, setUnreadCount] = useState(0);
    const [isConnected, setIsConnected] = useState(false);
    const [loading, setLoading] = useState(false);

    // Initial fetch
    const fetchNotifications = async () => {
        if (!user) return;
        try {
            setLoading(true);
            const data = await notificationApi.getMyNotifications();
            setNotifications(data.notifications);
            setUnreadCount(data.unreadCount);
        } catch (error) {
            console.error('Failed to fetch notifications', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (user) {
            fetchNotifications();
        } else {
            setNotifications([]);
            setUnreadCount(0);
        }
    }, [user]);

    // SignalR Connection
    useEffect(() => {
        if (!user || !token) return;

        const hubUrl = getHubUrl('notification');

        const newConnection = new HubConnectionBuilder()
            .withUrl(hubUrl, {
                accessTokenFactory: () => tokenService.getAccessToken() || ''
            })
            .withAutomaticReconnect()
            .configureLogging(LogLevel.None)
            .build();

        newConnection.on('SessionRevoked', (event: { sessionId: string }) => {
            if (event.sessionId === sessionId(tokenService.getAccessToken())) tokenService.clearToken();
        });
        const verify = () => { if (tokenService.getAccessToken()) void apiClient('/auth/sessions').catch(() => undefined); };
        newConnection.onreconnected(verify);
        newConnection.onclose(verify);
        setConnection(newConnection);

        return () => {
            if (newConnection) {
                newConnection.stop();
            }
        };
    }, [user, token]);

    useEffect(() => {
        if (connection) {
            connection.start()
                .then(() => {
                    setIsConnected(true);

                    connection.on('ReceiveNotification', (notification: NotificationDto) => {
                        // Sound/Toast?
                        if (notification.id === '00000000-0000-0000-0000-000000000000') {
                            // Broadcast notification, maybe we fetch to get proper ID or just display
                            // If ID is empty, we might not be able to mark as read individuallly until refresh
                            // Strategy: Refresh list
                            fetchNotifications();
                        } else {
                            setNotifications(prev => [notification, ...prev]);
                            setUnreadCount(prev => prev + 1);
                        }

                        toast(`🔔 ${notification.title}: ${notification.content}`);
                    });
                })
                .catch(err => console.error('Notification Hub Connection Failed: ', err));
        }

        return () => {
            if (connection) {
                connection.off('ReceiveNotification');
            }
        };
    }, [connection]);

    const markAsRead = async (id: string) => {
        try {
            await notificationApi.markAsRead(id);
            setNotifications(prev => prev.map(n =>
                n.id === id ? { ...n, isRead: true } : n
            ));
            setUnreadCount(prev => Math.max(0, prev - 1));
        } catch (error) {
            console.error('Failed to mark as read', error);
        }
    };

    const markAllAsRead = async () => {
        try {
            await notificationApi.markAllAsRead();
            setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
            setUnreadCount(0);
        } catch (error) {
            console.error('Failed to mark all as read', error);
        }
    };

    const sendNotification = async (data: any) => {
        await notificationApi.send(data);
    };

    return (
        <NotificationContext.Provider value={{
            notifications,
            unreadCount,
            isConnected,
            fetchNotifications,
            markAsRead,
            markAllAsRead,
            sendNotification,
            loading
        }}>
            {children}
        </NotificationContext.Provider>
    );
};

export const useNotification = () => {
    const context = useContext(NotificationContext);
    if (!context) {
        throw new Error('useNotification must be used within a NotificationProvider');
    }
    return context;
};
