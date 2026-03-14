import React, { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { paymentApi, type UserOrderSummaryDto } from '../services/paymentApi';

const statusStyles: Record<string, string> = {
  PAID: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300',
  PENDING: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
  FAILED: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300',
  CANCELLED: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300',
};

const OrderHistoryPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [orders, setOrders] = useState<UserOrderSummaryDto[]>([]);

  const formatCurrency = (value: number) => `${value.toLocaleString(locale)} ${t('payments.common.currency')}`;
  const formatStatus = (status: string) => t(`payments.status.${status.toUpperCase()}`, { defaultValue: status });

  const totalPaidOrders = useMemo(() => {
    return orders.filter((order) => order.status.toUpperCase() === 'PAID').length;
  }, [orders]);

  useEffect(() => {
    const loadOrders = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await paymentApi.getMyOrders();
        setOrders(data);
      } catch (err: any) {
        setError(err.message || t('payments.orders.errors.loadFailed'));
      } finally {
        setLoading(false);
      }
    };

    void loadOrders();
  }, []);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-10 px-4 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">{t('payments.orders.title')}</h1>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
              {t('payments.orders.subtitle', { total: orders.length, paid: totalPaidOrders })}
            </p>
          </div>
          <Link
            to="/checkout"
            className="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-primary/90"
          >
            <span className="material-symbols-outlined text-[18px]">shopping_cart_checkout</span>
            {t('payments.orders.openCheckout')}
          </Link>
        </div>

        {error && (
          <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600 dark:border-red-900/40 dark:bg-red-900/20 dark:text-red-300">
            {error}
          </div>
        )}

        <div className="rounded-2xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 shadow-sm overflow-hidden">
          {loading ? (
            <div className="p-6 space-y-3">
              {Array.from({ length: 4 }).map((_, index) => (
                <div key={index} className="h-16 rounded-lg bg-gray-100 dark:bg-gray-700 animate-pulse" />
              ))}
            </div>
          ) : orders.length === 0 ? (
            <div className="p-12 text-center">
              <span className="material-symbols-outlined text-[52px] text-gray-300 dark:text-gray-600">receipt_long</span>
              <p className="mt-4 text-gray-500 dark:text-gray-400">{t('payments.orders.empty')}</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="bg-gray-50 dark:bg-gray-900/60 text-gray-500 dark:text-gray-400 uppercase text-xs">
                  <tr>
                    <th className="px-6 py-4 font-semibold">{t('payments.orders.table.order')}</th>
                    <th className="px-6 py-4 font-semibold">{t('payments.orders.table.createdAt')}</th>
                    <th className="px-6 py-4 font-semibold">{t('payments.orders.table.status')}</th>
                    <th className="px-6 py-4 font-semibold">{t('payments.orders.table.totalAmount')}</th>
                    <th className="px-6 py-4 font-semibold">{t('payments.orders.table.courses')}</th>
                    <th className="px-6 py-4 text-right font-semibold">{t('payments.orders.table.detail')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                  {orders.map((order) => {
                    const status = order.status.toUpperCase();
                    return (
                      <tr key={order.orderId} className="hover:bg-gray-50 dark:hover:bg-gray-900/40">
                        <td className="px-6 py-4">
                          <p className="font-semibold text-gray-900 dark:text-white">#{order.payOSOrderCode ?? '-'}</p>
                          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400 break-all">{order.orderId}</p>
                        </td>
                        <td className="px-6 py-4 text-gray-700 dark:text-gray-200">
                          {new Date(order.createdAt).toLocaleString(locale)}
                        </td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${statusStyles[status] || statusStyles.PENDING}`}>
                            {formatStatus(status)}
                          </span>
                        </td>
                        <td className="px-6 py-4 font-semibold text-primary">
                          {formatCurrency(order.totalAmount)}
                        </td>
                        <td className="px-6 py-4 text-gray-700 dark:text-gray-200">
                          <div className="max-w-[300px] space-y-1">
                            {order.items.slice(0, 2).map((item) => (
                              <p key={item.courseId} className="truncate">{item.title}</p>
                            ))}
                            {order.items.length > 2 && (
                              <p className="text-xs text-gray-500 dark:text-gray-400">
                                {t('payments.orders.moreCourses', { count: order.items.length - 2 })}
                              </p>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4 text-right">
                          <Link
                            to={`/payment/result?orderId=${order.orderId}`}
                            className="inline-flex items-center gap-1 rounded-lg border border-gray-300 dark:border-gray-700 px-3 py-1.5 text-xs font-semibold text-gray-700 dark:text-gray-200 hover:border-primary hover:text-primary transition-colors"
                          >
                            <span className="material-symbols-outlined text-[16px]">open_in_new</span>
                            {t('payments.orders.view')}
                          </Link>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default OrderHistoryPage;
