import React, { useState } from 'react';
import type { ReactNode } from 'react';
import RoleDashboardHeader from './RoleDashboardHeader';
import RoleDashboardSidebar, { type RoleSidebarItem } from './RoleDashboardSidebar';

export type { RoleSidebarItem };

interface RoleDashboardLayoutProps {
  brand: string;
  menuItems: RoleSidebarItem[];
  activeTab: string;
  onTabChange: (tabId: string) => void;
  searchPlaceholder?: string;
  children: ReactNode;
}

const RoleDashboardLayout: React.FC<RoleDashboardLayoutProps> = ({
  brand,
  menuItems,
  activeTab,
  onTabChange,
  searchPlaceholder,
  children,
}) => {
  const [isMobileNavOpen, setIsMobileNavOpen] = useState(false);

  return (
    <div className="flex h-screen w-full overflow-hidden bg-dashboard-background-light font-dashboard text-slate-900 antialiased transition-colors duration-200 dark:bg-dashboard-background-dark dark:text-slate-100">
      <RoleDashboardSidebar
        brand={brand}
        menuItems={menuItems}
        activeTab={activeTab}
        onTabChange={onTabChange}
        isMobileOpen={isMobileNavOpen}
        onClose={() => setIsMobileNavOpen(false)}
      />
      <div className="relative flex h-full flex-1 flex-col overflow-hidden">
        <RoleDashboardHeader
          onToggleMobileNav={() => setIsMobileNavOpen((prev) => !prev)}
          searchPlaceholder={searchPlaceholder}
        />
        <main className="flex-1 overflow-y-auto p-3 sm:p-4 md:p-6 lg:p-8 scroll-smooth">{children}</main>
      </div>
    </div>
  );
};

export default RoleDashboardLayout;
