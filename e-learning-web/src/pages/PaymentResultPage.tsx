import React, { useEffect, useMemo, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { paymentApi, type OrderStatusResponse } from '../services/paymentApi';
import { paymentCart } from '../services/paymentCart';

const PaymentResultPage: React.FC = () => {
  const location = useLocation();
  const { t, i18n } = useTranslation();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';

  const [loading, setLoading] = useState(true);
  const [checking, setChecking] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [orderStatus, setOrderStatus] = useState<OrderStatusResponse | null>(null);

  const searchParams = useMemo(() => new URLSearchParams(location.search), [location.search]);
  const orderId = searchParams.get('orderId') || '';
  const orderCode = Number(searchParams.get('orderCode') || 0);

  const formatCurrency = (value: number) => `${value.toLocaleString(locale)} ${t('payments.common.currency')}`;
  const formatStatus = (status?: string | null) => {
    if (!status) {
      return '-';
    }

    return t(`payments.status.${status.toUpperCase()}`, { defaultValue: status });
  };

  const getStatusTone = (status: string) => {
    const normalized = status.toUpperCase();
    if (normalized === 'PAID') {
      return {
        border: 'border-green-200 dark:border-green-900/40',
        bg: 'bg-green-50 dark:bg-green-900/20',
        text: 'text-green-700 dark:text-green-300',
        icon: 'check_circle',
        title: t('payments.result.tone.paid.title'),
        subtitle: t('payments.result.tone.paid.subtitle'),
      };
    }

    if (normalized === 'FAILED' || normalized === 'CANCELLED') {
      return {
        border: 'border-red-200 dark:border-red-900/40',
        bg: 'bg-red-50 dark:bg-red-900/20',
        text: 'text-red-700 dark:text-red-300',
        icon: 'error',
        title: t('payments.result.tone.failed.title'),
        subtitle: t('payments.result.tone.failed.subtitle'),
      };
    }

    return {
      border: 'border-amber-200 dark:border-amber-900/40',
      bg: 'bg-amber-50 dark:bg-amber-900/20',
      text: 'text-amber-700 dark:text-amber-300',
      icon: 'hourglass_top',
      title: t('payments.result.tone.pending.title'),
      subtitle: t('payments.result.tone.pending.subtitle'),
    };
  };

  const loadOrderStatus = async (refresh: boolean) => {
    try {
      setError(null);
      if (refresh) {
        setChecking(true);
      }

      let result: OrderStatusResponse;
      if (orderCode > 0) {
        result = await paymentApi.getOrderStatusByCode(orderCode, refresh);
      } else if (orderId) {
        result = await paymentApi.getOrderStatus(orderId, refresh);
      } else {
        throw new Error(t('payments.result.errors.orderCodeMissing'));
      }

      setOrderStatus(result);

      if (result.isPaid) {
        paymentCart.removeMany(result.items.map((item) => item.courseId));
      }
    } catch (err: any) {
      setError(err.message || t('payments.result.errors.loadFailed'));
    } finally {
      setLoading(false);
      setChecking(false);
    }
  };

  useEffect(() => {
    void loadOrderStatus(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orderId, orderCode]);

  const tone = getStatusTone(orderStatus?.status || 'PENDING');

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-10 px-4 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-4xl">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">{t('payments.result.title')}</h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {t('payments.result.subtitle')}
          </p>
        </div>

        {error && (
          <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600 dark:border-red-900/40 dark:bg-red-900/20 dark:text-red-300">
            {error}
          </div>
        )}

        {loading ? (
          <div className="rounded-2xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 p-12 text-center shadow-sm">
            <div className="mx-auto h-10 w-10 animate-spin rounded-full border-4 border-primary border-r-transparent" />
            <p className="mt-4 text-gray-500 dark:text-gray-400">{t('payments.result.loading')}</p>
          </div>
        ) : orderStatus ? (
          <div className="space-y-5">
            <div className={`rounded-2xl border ${tone.border} ${tone.bg} p-6`}>
              <div className="flex items-start gap-3">
                <span className={`material-symbols-outlined text-[28px] ${tone.text}`}>{tone.icon}</span>
                <div>
                  <h2 className={`text-xl font-bold ${tone.text}`}>{tone.title}</h2>
                  <p className={`mt-1 text-sm ${tone.text}`}>{tone.subtitle}</p>
                </div>
              </div>
            </div>

            <div className="rounded-2xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 shadow-sm">
              <div className="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{t('payments.result.orderInfo.title')}</h3>
              </div>

              <div className="p-6 space-y-4">
                <div className="grid gap-3 sm:grid-cols-2 text-sm">
                  <div>
                    <p className="text-gray-500 dark:text-gray-400">{t('payments.result.orderInfo.orderId')}</p>
                    <p className="font-semibold text-gray-900 dark:text-white break-all">{orderStatus.orderId}</p>
                  </div>
                  <div>
                    <p className="text-gray-500 dark:text-gray-400">{t('payments.result.orderInfo.orderCode')}</p>
                    <p className="font-semibold text-gray-900 dark:text-white">{orderStatus.payOSOrderCode ?? '-'}</p>
                  </div>
                  <div>
                    <p className="text-gray-500 dark:text-gray-400">{t('payments.result.orderInfo.status')}</p>
                    <p className="font-semibold text-gray-900 dark:text-white">{formatStatus(orderStatus.status)}</p>
                  </div>
                  <div>
                    <p className="text-gray-500 dark:text-gray-400">{t('payments.result.orderInfo.lastPaymentStatus')}</p>
                    <p className="font-semibold text-gray-900 dark:text-white">{formatStatus(orderStatus.lastPaymentStatus)}</p>
                  </div>
                  <div>
                    <p className="text-gray-500 dark:text-gray-400">{t('payments.result.orderInfo.totalAmount')}</p>
                    <p className="font-semibold text-primary">{formatCurrency(orderStatus.totalAmount)}</p>
                  </div>
                  <div>
                    <p className="text-gray-500 dark:text-gray-400">{t('payments.result.orderInfo.paidAt')}</p>
                    <p className="font-semibold text-gray-900 dark:text-white">
                      {orderStatus.paidAt ? new Date(orderStatus.paidAt).toLocaleString(locale) : '-'}
                    </p>
                  </div>
                </div>

                <div>
                  <p className="mb-2 text-sm font-semibold text-gray-900 dark:text-white">{t('payments.result.orderInfo.courses')}</p>
                  <div className="space-y-2">
                    {orderStatus.items.map((item) => (
                      <div key={item.courseId} className="flex items-center justify-between rounded-lg bg-gray-50 dark:bg-gray-900 px-3 py-2 text-sm">
                        <span className="text-gray-700 dark:text-gray-200">{item.title}</span>
                        <span className="font-semibold text-gray-900 dark:text-white">
                          {item.isFree ? t('payments.common.free') : formatCurrency(item.price)}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="flex flex-wrap gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => void loadOrderStatus(true)}
                    disabled={checking}
                    className="inline-flex items-center gap-2 rounded-lg border border-gray-300 dark:border-gray-700 px-4 py-2 text-sm font-semibold text-gray-700 dark:text-gray-200 hover:border-primary hover:text-primary transition-colors disabled:opacity-60"
                  >
                    <span className="material-symbols-outlined text-[18px]">sync</span>
                    {checking ? t('payments.result.actions.checking') : t('payments.result.actions.refresh')}
                  </button>

                  <Link
                    to="/my-orders"
                    className="inline-flex items-center gap-2 rounded-lg border border-gray-300 dark:border-gray-700 px-4 py-2 text-sm font-semibold text-gray-700 dark:text-gray-200 hover:border-primary hover:text-primary transition-colors"
                  >
                    <span className="material-symbols-outlined text-[18px]">receipt_long</span>
                    {t('payments.result.actions.orderHistory')}
                  </Link>

                  <Link
                    to="/my-courses"
                    className="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-primary/90"
                  >
                    <span className="material-symbols-outlined text-[18px]">menu_book</span>
                    {t('payments.result.actions.myCourses')}
                  </Link>
                </div>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
};

export default PaymentResultPage;
