import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { dashboardApi, type RecentOrder } from '../../services/dashboardApi';

const RecentOrdersTable: React.FC = () => {
  const { t } = useTranslation();
  const [orders, setOrders] = useState<RecentOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    const fetchOrders = async () => {
      try {
        setLoading(true);
        const data = await dashboardApi.getRecentOrders(10);
        if (isMounted) {
          setOrders(data);
          setError(null);
        }
      } catch (err) {
        console.error('Failed to fetch recent orders:', err);
        if (isMounted) {
          setError(err instanceof Error ? err.message : 'Failed to load orders');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    void fetchOrders();
    return () => {
      isMounted = false;
    };
  }, []);

  const renderStatus = (status: RecentOrder['status']) => {
    if (status === 'paid') {
      return (
        <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-100 bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-400">
          <span className="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
          {t('admin.recentOrders.status.paid', { defaultValue: 'Đã thanh toán' })}
        </span>
      );
    }

    if (status === 'pending') {
      return (
        <span className="inline-flex items-center gap-1.5 rounded-full border border-amber-100 bg-amber-50 px-2.5 py-1 text-xs font-medium text-amber-700 dark:border-amber-800 dark:bg-amber-900/20 dark:text-amber-400">
          <span className="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
          {t('admin.recentOrders.status.pending', { defaultValue: 'Chờ xử lý' })}
        </span>
      );
    }

    return (
      <span className="inline-flex items-center gap-1.5 rounded-full border border-red-100 bg-red-50 px-2.5 py-1 text-xs font-medium text-red-700 dark:border-red-800 dark:bg-red-900/20 dark:text-red-400">
        <span className="h-1.5 w-1.5 rounded-full bg-red-500"></span>
        {t('admin.recentOrders.status.failed', { defaultValue: 'Thất bại' })}
      </span>
    );
  };

  return (
    <div className="flex flex-col gap-4 lg:col-span-2">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-bold text-slate-900 dark:text-white">{t('admin.recentOrders.title', { defaultValue: 'Đơn hàng gần đây' })}</h3>
        <button
          onClick={() => {
            setLoading(true);
            dashboardApi.getRecentOrders(10)
              .then(data => setOrders(data))
              .catch(err => console.error(err))
              .finally(() => setLoading(false));
          }}
          className="text-sm font-medium text-dashboard-primary hover:text-dashboard-primary-dark dark:text-blue-400 dark:hover:text-blue-300"
        >
          {t('admin.recentOrders.refresh', { defaultValue: 'Làm mới' })}
        </button>
      </div>
      <div className="overflow-hidden rounded-xl border border-slate-200 bg-dashboard-surface-light shadow-dashboard-subtle dark:border-slate-800 dark:bg-dashboard-surface-dark">
        {loading ? (
          <div className="p-8 text-center">
            <div className="inline-block h-7 w-7 animate-spin rounded-full border-3 border-solid border-dashboard-primary border-r-transparent" />
            <p className="mt-2 text-xs text-slate-500 dark:text-slate-400">Đang tải danh sách đơn hàng...</p>
          </div>
        ) : error ? (
          <div className="p-8 text-center">
            <span className="material-symbols-outlined text-3xl text-red-500">error</span>
            <p className="mt-2 text-sm text-red-500">{error}</p>
          </div>
        ) : orders.length === 0 ? (
          <div className="p-8 text-center">
            <span className="material-symbols-outlined text-4xl text-slate-300 dark:text-slate-600">receipt_long</span>
            <p className="mt-2 text-sm font-medium text-slate-600 dark:text-slate-400">
              {t('admin.recentOrders.noOrders', { defaultValue: 'Chưa có đơn hàng nào' })}
            </p>
          </div>
        ) : (
          <>
            {/* Mobile card view */}
            <div className="md:hidden divide-y divide-slate-100 dark:divide-slate-800">
              {orders.map((row) => (
                <div key={row.id} className="p-4 space-y-3">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="font-semibold text-slate-900 dark:text-white">{row.id}</p>
                      <p className="text-xs text-slate-500">{row.formattedDate || row.date}</p>
                    </div>
                    {renderStatus(row.status)}
                  </div>

                  <div className="flex items-center gap-3">
                    {row.avatarUrl ? (
                      <div className="h-9 w-9 rounded-full bg-slate-200 bg-cover bg-center" style={{ backgroundImage: `url('${row.avatarUrl}')` }}></div>
                    ) : (
                      <div className="flex h-9 w-9 items-center justify-center rounded-full border border-dashboard-primary/20 bg-dashboard-primary/10 text-xs font-bold text-dashboard-primary">
                        {row.initials || row.student.charAt(0).toUpperCase()}
                      </div>
                    )}
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-slate-900 dark:text-white truncate">{row.student}</p>
                      <p className="text-xs text-slate-500 truncate">{row.course}</p>
                    </div>
                  </div>

                  <p className="text-sm font-semibold text-dashboard-primary">{row.formattedAmount || `${row.amount?.toLocaleString('vi-VN')} VND`}</p>
                </div>
              ))}
            </div>

            {/* Desktop table view */}
            <div className="hidden md:block overflow-x-auto">
              <table className="w-full text-left text-sm min-w-[760px]">
                <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500 dark:border-slate-800 dark:bg-slate-800/50">
                  <tr>
                    <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.orderId', { defaultValue: 'Mã đơn' })}</th>
                    <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.student', { defaultValue: 'Học viên' })}</th>
                    <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.course', { defaultValue: 'Khóa học / Gói' })}</th>
                    <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.amount', { defaultValue: 'Số tiền' })}</th>
                    <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.status', { defaultValue: 'Trạng thái' })}</th>
                    <th className="px-6 py-4 font-semibold text-right" scope="col">{t('admin.recentOrders.table.date', { defaultValue: 'Ngày tạo' })}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                  {orders.map((row) => (
                    <tr key={row.id} className="transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/50">
                      <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{row.id}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          {row.avatarUrl ? (
                            <div className="h-8 w-8 rounded-full bg-slate-200 bg-cover bg-center" style={{ backgroundImage: `url('${row.avatarUrl}')` }}></div>
                          ) : (
                            <div className="flex h-8 w-8 items-center justify-center rounded-full border border-dashboard-primary/20 bg-dashboard-primary/10 text-xs font-bold text-dashboard-primary">
                              {row.initials || row.student.charAt(0).toUpperCase()}
                            </div>
                          )}
                          <span className="text-slate-700 dark:text-slate-300 font-medium">{row.student}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-slate-600 dark:text-slate-400">{row.course}</td>
                      <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{row.formattedAmount || `${row.amount?.toLocaleString('vi-VN')} VND`}</td>
                      <td className="px-6 py-4">{renderStatus(row.status)}</td>
                      <td className="px-6 py-4 text-right text-slate-500">{row.formattedDate || row.date}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default RecentOrdersTable;
