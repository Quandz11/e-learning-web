import { useEffect } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import ChatButton from '../chat/ChatButton';
import ReferralInviteFloat from '../referral/ReferralInviteFloat';

export default function RootLayout() {
    const location = useLocation();

    useEffect(() => {
        window.scrollTo(0, 0);
    }, [location.pathname]);

    return (
        <>
            <Outlet />
            <ReferralInviteFloat />
            <ChatButton />
        </>
    );
}
