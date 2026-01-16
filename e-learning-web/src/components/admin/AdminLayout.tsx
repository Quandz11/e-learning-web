import React from 'react';
import type { ReactNode } from 'react';
import AdminHeader from './AdminHeader';
import AdminSidebar from './AdminSidebar';

interface AdminLayoutProps {
  children: ReactNode;
}

const AdminLayout: React.FC<AdminLayoutProps> = ({ children }) => {
  return (
    <div className="flex h-screen w-full overflow-hidden bg-dashboard-background-light font-dashboard text-slate-900 antialiased transition-colors duration-200 dark:bg-dashboard-background-dark dark:text-slate-100">
      <AdminSidebar />
      <div className="relative flex h-full flex-1 flex-col overflow-hidden">
        <AdminHeader />
        <main className="flex-1 overflow-y-auto p-4 scroll-smooth md:p-8">
          {children}
        </main>
      </div>
    </div>
  );
};

export default AdminLayout;
