import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { dashboardApi, type TopAgent } from '../../services/dashboardApi';

const TopAgents: React.FC = () => {
    const { t } = useTranslation();
    const [agents, setAgents] = useState<TopAgent[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        let isMounted = true;
        const fetchAgents = async () => {
            try {
                setLoading(true);
                const data = await dashboardApi.getTopAgents(5);
                if (isMounted) {
                    setAgents(data);
                    setError(null);
                }
            } catch (err) {
                console.error('Failed to fetch top agents:', err);
                if (isMounted) {
                    setError(err instanceof Error ? err.message : 'Failed to load top agents');
                }
            } finally {
                if (isMounted) {
                    setLoading(false);
                }
            }
        };

        void fetchAgents();
        return () => {
            isMounted = false;
        };
    }, []);

    const getRankBadgeClass = (rank: number) => {
        switch (rank) {
            case 1:
                return 'bg-yellow-400 text-yellow-900 border-white dark:border-slate-800';
            case 2:
                return 'bg-slate-200 text-slate-700 border-white dark:border-slate-800';
            case 3:
                return 'bg-amber-200 text-amber-900 border-white dark:border-slate-800';
            default:
                return 'bg-slate-100 text-slate-500 border-white dark:border-slate-800 dark:bg-slate-700 dark:text-slate-300';
        }
    };

    return (
        <div className="flex flex-col gap-4 lg:col-span-1">
            <div className="flex items-center justify-between">
                <h3 className="text-lg font-bold text-slate-900 dark:text-white">{t('admin.topAgents.title', { defaultValue: 'Top đại lý' })}</h3>
                <Link to="/admin/referrals" className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200" title="Quản lý đại lý">
                    <span className="material-symbols-outlined">more_horiz</span>
                </Link>
            </div>
            <div className="rounded-xl border border-slate-200 bg-dashboard-surface-light p-4 shadow-dashboard-subtle dark:border-slate-800 dark:bg-dashboard-surface-dark">
                {loading ? (
                    <div className="py-8 text-center">
                        <div className="inline-block h-6 w-6 animate-spin rounded-full border-2 border-solid border-dashboard-primary border-r-transparent" />
                        <p className="mt-2 text-xs text-slate-500 dark:text-slate-400">Đang tải top đại lý...</p>
                    </div>
                ) : error ? (
                    <div className="py-6 text-center">
                        <span className="material-symbols-outlined text-2xl text-red-500">error</span>
                        <p className="mt-1 text-xs text-red-500">{error}</p>
                    </div>
                ) : agents.length === 0 ? (
                    <div className="py-8 text-center">
                        <span className="material-symbols-outlined text-3xl text-slate-300 dark:text-slate-600">groups</span>
                        <p className="mt-2 text-xs font-medium text-slate-500 dark:text-slate-400">
                            {t('admin.topAgents.noAgents', { defaultValue: 'Chưa có đại lý nào có doanh thu' })}
                        </p>
                    </div>
                ) : (
                    <div className="flex flex-col gap-4 sm:gap-6">
                        {agents.map((agent) => (
                            <div key={agent.id} className="flex items-center gap-3 sm:gap-4">
                                <div className="relative flex-shrink-0">
                                    {agent.avatarUrl ? (
                                        <div
                                            className="h-10 w-10 sm:h-12 sm:w-12 rounded-full border-2 border-white bg-cover bg-center shadow-sm dark:border-slate-700"
                                            style={{ backgroundImage: `url('${agent.avatarUrl}')` }}
                                        />
                                    ) : (
                                        <div className="flex h-10 w-10 sm:h-12 sm:w-12 items-center justify-center rounded-full border-2 border-white bg-dashboard-primary/10 text-sm font-bold text-dashboard-primary shadow-sm dark:border-slate-700">
                                            {agent.name.charAt(0).toUpperCase()}
                                        </div>
                                    )}
                                    <div className={`absolute -bottom-1 -right-1 rounded-full border px-1.5 py-0.5 text-[10px] font-bold shadow-sm ${getRankBadgeClass(agent.rank)}`}>
                                        {agent.rank}
                                    </div>
                                </div>
                                <div className="min-w-0 flex-1">
                                    <div className="mb-1 flex items-center justify-between gap-2">
                                        <p className="truncate text-xs sm:text-sm font-bold text-slate-900 dark:text-white" title={agent.name}>
                                            {agent.name}
                                        </p>
                                        <p className="text-xs sm:text-sm font-bold text-dashboard-primary whitespace-nowrap">
                                            {agent.formattedRevenue || `${agent.revenue?.toLocaleString('vi-VN')} VND`}
                                        </p>
                                    </div>
                                    <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-700 overflow-hidden">
                                        <div
                                            className="h-1.5 rounded-full bg-dashboard-primary transition-all duration-500"
                                            style={{ width: `${Math.max(5, Math.min(100, agent.percentage))}%` }}
                                        />
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
                <div className="mt-6 border-t border-slate-100 pt-4 dark:border-slate-700/50">
                    <Link className="block text-center text-sm font-medium text-slate-500 transition-colors hover:text-dashboard-primary" to="/admin/referrals">
                        {t('admin.topAgents.viewAll', { defaultValue: 'Xem tất cả đại lý' })}
                    </Link>
                </div>
            </div>
        </div>
    );
};

export default TopAgents;
