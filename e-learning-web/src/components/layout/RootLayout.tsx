import { Outlet } from 'react-router-dom';
import ChatButton from '../chat/ChatButton';

export default function RootLayout() {
    return (
        <>
            <Outlet />
            <ChatButton />
        </>
    );
}
