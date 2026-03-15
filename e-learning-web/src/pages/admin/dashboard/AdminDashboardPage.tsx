import React, { useEffect, useState } from 'react';
import AdminLayout from '../../../components/admin/AdminLayout';
import StatsCard from '../../../components/admin/StatsCard';
import RecentOrdersTable from '../../../components/admin/RecentOrdersTable';
import TopAgents from '../../../components/admin/TopAgents';
import { useTranslation } from 'react-i18next';
import { dashboardApi, type DashboardStats } from '../../../services/dashboardApi';

const AdminDashboardPage: React.FC = () => {
    const { t } = useTranslation();
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                setLoading(true);
                const data = await dashboardApi.getStats();
                setStats(data);
            } catch (err) {
                console.error('Failed to fetch dashboard stats:', err);
                setError(err instanceof Error ? err.message : 'Failed to load dashboard stats');
            } finally {
                setLoading(false);
            }
        };

        void fetchStats();
    }, []);

    const formatCurrency = (amount: number) => {
        return new Intl.NumberFormat('vi-VN', {
            style: 'decimal',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount) + ' VND';
    };

    const formatTrend = (value: number) => {
        const sign = value >= 0 ? '+' : '';
        return `${sign}${value.toFixed(1)}%`;
    };

    const getTrendType = (value: number): 'positive' | 'negative' | 'neutral' => {
        if (value > 0) return 'positive';
        if (value < 0) return 'negative';
        return 'neutral';
    };

    if (loading) {
        return (
            <AdminLayout>
                <div className="flex h-64 items-center justify-center">
                    <div className="text-center">
                        <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-dashboard-primary border-r-transparent" />
                        <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">Loading dashboard...</p>
                    </div>
                </div>
            </AdminLayout>
        );
    }

    if (error || !stats) {
        return (
            <AdminLayout>
                <div className="flex h-64 items-center justify-center">
                    <div className="text-center">
                        <span className="material-symbols-outlined text-4xl text-red-500">error</span>
                        <p className="mt-2 text-sm text-red-500">{error || 'Failed to load dashboard'}</p>
                    </div>
                </div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            {/* Page Heading */}
            <div className="mb-8 flex flex-col justify-between gap-4 md:flex-row md:items-end">
                <div>
                    <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">{t('admin.dashboard.overview')}</h2>
                    <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{t('admin.dashboard.overviewSubtitle')}</p>
                </div>
                <div className="flex w-full md:w-auto flex-col sm:flex-row gap-2 sm:gap-3">
                    <button className="flex h-11 items-center justify-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-dashboard-surface-dark dark:text-slate-200 dark:hover:bg-slate-800">
                        <span className="material-symbols-outlined text-[18px]">calendar_today</span>
                        <span>{t('admin.dashboard.last30Days')}</span>
                    </button>
                    <button className="flex h-11 items-center justify-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white shadow-sm shadow-dashboard-primary/20 transition-colors hover:bg-dashboard-primary-dark">
                        <span className="material-symbols-outlined text-[18px]">download</span>
                        <span>{t('admin.dashboard.exportReport')}</span>
                    </button>
                </div>
            </div>

            {/* Metrics Grid */}
            <div className="mb-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6">
                {/* Card 1: Total Students */}
                <StatsCard
                    title={t('admin.dashboard.totalStudents')}
                    value={stats.totalStudents.toLocaleString('vi-VN')}
                    trend={formatTrend(stats.studentGrowthPercentage)}
                    trendType={getTrendType(stats.studentGrowthPercentage)}
                    chart={
                        <svg className="h-full w-full overflow-visible text-dashboard-primary" preserveAspectRatio="none" viewBox="0 0 100 40">
                            <defs>
                                <linearGradient id="gradient-students" x1="0" x2="0" y1="0" y2="1">
                                    <stop offset="0%" stopColor="currentColor" stopOpacity="0.2"></stop>
                                    <stop offset="100%" stopColor="currentColor" stopOpacity="0"></stop>
                                </linearGradient>
                            </defs>
                            <path className="text-dashboard-primary/10 dark:text-dashboard-primary/20" d="M0 30 Q 10 25, 20 28 T 40 15 T 60 20 T 80 5 L 100 10 V 40 H 0 Z" fill="url(#gradient-students)"></path>
                            <path d="M0 30 Q 10 25, 20 28 T 40 15 T 60 20 T 80 5 L 100 10" fill="none" stroke="currentColor" strokeLinecap="round" strokeWidth="2" vectorEffect="non-scaling-stroke"></path>
                        </svg>
                    }
                />

                {/* Card 2: Total Revenue */}
                <StatsCard
                    title={t('admin.dashboard.totalRevenue')}
                    value={formatCurrency(stats.totalRevenue)}
                    trend={formatTrend(stats.revenueGrowthPercentage)}
                    trendType={getTrendType(stats.revenueGrowthPercentage)}
                    chart={
                        <svg className="h-full w-full overflow-visible text-dashboard-primary" preserveAspectRatio="none" viewBox="0 0 100 40">
                            <defs>
                                <linearGradient id="gradient-revenue" x1="0" x2="0" y1="0" y2="1">
                                    <stop offset="0%" stopColor="currentColor" stopOpacity="0.2"></stop>
                                    <stop offset="100%" stopColor="currentColor" stopOpacity="0"></stop>
                                </linearGradient>
                            </defs>
                            <path className="text-dashboard-primary/10 dark:text-dashboard-primary/20" d="M0 35 Q 25 35, 35 20 T 65 25 T 100 5 V 40 H 0 Z" fill="url(#gradient-revenue)"></path>
                            <path d="M0 35 Q 25 35, 35 20 T 65 25 T 100 5" fill="none" stroke="currentColor" strokeLinecap="round" strokeWidth="2" vectorEffect="non-scaling-stroke"></path>
                        </svg>
                    }
                />

                {/* Card 3: Agent Revenue */}
                <StatsCard
                    title={t('admin.dashboard.agentRevenue')}
                    value={formatCurrency(stats.agentRevenue)}
                    trend={formatTrend(stats.agentRevenueGrowthPercentage)}
                    trendType={getTrendType(stats.agentRevenueGrowthPercentage)}
                    chart={
                        <div className="flex h-12 w-full items-end gap-1">
                            <div className="h-[40%] flex-1 rounded-t-sm bg-dashboard-primary/20"></div>
                            <div className="h-[60%] flex-1 rounded-t-sm bg-dashboard-primary/30"></div>
                            <div className="h-[30%] flex-1 rounded-t-sm bg-dashboard-primary/40"></div>
                            <div className="h-[50%] flex-1 rounded-t-sm bg-dashboard-primary/30"></div>
                            <div className="h-[80%] flex-1 rounded-t-sm bg-dashboard-primary/50"></div>
                            <div className="h-[65%] flex-1 rounded-t-sm bg-dashboard-primary/60"></div>
                            <div className="h-[90%] flex-1 rounded-t-sm bg-dashboard-primary/80"></div>
                            <div className="h-[100%] flex-1 rounded-t-sm bg-dashboard-primary"></div>
                        </div>
                    }
                />

                {/* Card 4: Active Courses */}
                <StatsCard
                    title={t('admin.dashboard.activeCourses')}
                    value={stats.activeCourses.toLocaleString('vi-VN')}
                    trend={formatTrend(stats.coursesGrowthPercentage)}
                    trendType={getTrendType(stats.coursesGrowthPercentage)}
                    chart={
                        <svg className="h-full w-full overflow-visible text-dashboard-accent" preserveAspectRatio="none" viewBox="0 0 100 40">
                            <defs>
                                <linearGradient id="gradient-courses" x1="0" x2="0" y1="0" y2="1">
                                    <stop offset="0%" stopColor="currentColor" stopOpacity="0.2"></stop>
                                    <stop offset="100%" stopColor="currentColor" stopOpacity="0"></stop>
                                </linearGradient>
                            </defs>
                            <path className="text-dashboard-accent/10 dark:text-dashboard-accent/20" d="M0 20 L 20 20 L 40 10 L 60 25 L 80 20 L 100 22 V 40 H 0 Z" fill="url(#gradient-courses)"></path>
                            <path d="M0 20 L 20 20 L 40 10 L 60 25 L 80 20 L 100 22" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" vectorEffect="non-scaling-stroke"></path>
                        </svg>
                    }
                />
            </div>

            {/* Content Split: Table and List */}
            <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
                <RecentOrdersTable />
                <TopAgents />
            </div>
        </AdminLayout>
    );
};

export default AdminDashboardPage;
