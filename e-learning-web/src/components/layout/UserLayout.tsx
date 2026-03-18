import { Outlet } from 'react-router-dom';
import UserHeader from './UserHeader';
import UserFooter from './UserFooter';
import AiChatWidget from '../ai/AiChatWidget';

export default function UserLayout() {
    return (
        <div className="bg-background-light dark:bg-background-dark min-h-screen flex flex-col">
            <UserHeader />
            <main className="flex-1">
                <Outlet />
            </main>
            <UserFooter />
            <AiChatWidget />
        </div>
    );
}
