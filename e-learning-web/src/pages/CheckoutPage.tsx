import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { QRCodeSVG } from 'qrcode.react';
import { useTranslation } from 'react-i18next';
import { courseApi } from '../services/courseApi';
import { paymentApi, type PaymentInstructionDto, type ReferralPreviewResponse } from '../services/paymentApi';
import { paymentCart, type PaymentCartItem } from '../services/paymentCart';

interface PendingPaymentSession {
  orderId: string;
  payOSOrderCode?: number;
  totalAmount: number;
  status: string;
  qrCode?: string;
  checkoutUrl?: string;
  paymentInstruction?: PaymentInstructionDto;
  createdAt: string;
  expiresAt?: string;
}

type ReferralPreviewState = 'idle' | 'loading' | 'valid' | 'invalid' | 'error';

const parseCourseIds = (raw: string | null): string[] => {
  if (!raw) {
    return [];
  }

  return raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
};

const CheckoutPage: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { t, i18n } = useTranslation();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [checkingStatus, setCheckingStatus] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [items, setItems] = useState<PaymentCartItem[]>([]);
  const [referralCode, setReferralCode] = useState('');
  const [referralPreview, setReferralPreview] = useState<ReferralPreviewResponse | null>(null);
  const [referralPreviewState, setReferralPreviewState] = useState<ReferralPreviewState>('idle');
  const [referralMessage, setReferralMessage] = useState<string | null>(null);
  const [pendingPayment, setPendingPayment] = useState<PendingPaymentSession | null>(null);
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const pendingPaymentRef = useRef<HTMLDivElement | null>(null);
  const referralLookupRef = useRef(0);

  const searchParams = useMemo(() => new URLSearchParams(location.search), [location.search]);
  const singleMode = searchParams.get('single') === '1';
  const queryCourseIds = useMemo(() => parseCourseIds(searchParams.get('courseIds')), [searchParams]);

  const formatCurrency = useCallback(
    (value: number) => `${value.toLocaleString(locale)} ${t('payments.common.currency')}`,
    [locale, t],
  );

  const formatDateTime = useCallback((value: string | Date) => {
    return new Date(value).toLocaleString(locale);
  }, [locale]);

  const formatStatus = useCallback(
    (status: string) => t(`payments.status.${status.toUpperCase()}`, { defaultValue: status }),
    [t],
  );

  const buildTransferContentFallback = useCallback((orderCode?: number, orderId?: string) => {
    if (orderCode) {
      const compactCode = orderCode % 10000000;
      return `DH${compactCode.toString().padStart(7, '0')}`;
    }

    if (orderId) {
      return orderId.replace(/-/g, '').slice(0, 10).toUpperCase();
    }

    return '';
  }, []);

  const copyText = useCallback(async (value: string, fieldKey: string) => {
    if (!value) {
      return;
    }

    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(value);
      } else {
        const tempTextArea = document.createElement('textarea');
        tempTextArea.value = value;
        tempTextArea.setAttribute('readonly', '');
        tempTextArea.style.position = 'absolute';
        tempTextArea.style.left = '-9999px';
        document.body.appendChild(tempTextArea);
        tempTextArea.select();
        document.execCommand('copy');
        document.body.removeChild(tempTextArea);
      }

      setCopiedField(fieldKey);
      window.setTimeout(() => {
        setCopiedField((current) => (current === fieldKey ? null : current));
      }, 1400);
    } catch {
      // Keep silent to avoid interrupting checkout flow when clipboard permission is denied.
    }
  }, []);

  const mergePaymentInstruction = useCallback(
    (nextInstruction?: PaymentInstructionDto, prevInstruction?: PaymentInstructionDto): PaymentInstructionDto | undefined => {
      if (!nextInstruction) {
        return prevInstruction;
      }

      if (!prevInstruction) {
        return nextInstruction;
      }

      return {
        bankBin: nextInstruction.bankBin || prevInstruction.bankBin,
        bankName: nextInstruction.bankName || prevInstruction.bankName,
        bankShortName: nextInstruction.bankShortName || prevInstruction.bankShortName,
        accountNumber: nextInstruction.accountNumber || prevInstruction.accountNumber,
        accountName: nextInstruction.accountName || prevInstruction.accountName,
        transferContent: nextInstruction.transferContent || prevInstruction.transferContent,
        amount: nextInstruction.amount > 0 ? nextInstruction.amount : prevInstruction.amount,
      };
    },
    [],
  );

  useEffect(() => {
    const loadCheckoutItems = async () => {
      try {
        setLoading(true);
        setError(null);

        const fromCart = paymentCart.getItems();
        const sourceIds = singleMode
          ? queryCourseIds
          : Array.from(new Set([...fromCart.map((item) => item.courseId), ...queryCourseIds]));

        if (sourceIds.length === 0) {
          setItems(singleMode ? [] : fromCart);
          return;
        }

        const allCourses = await courseApi.getAll();
        const selected = allCourses
          .filter((course) => sourceIds.includes(course.id))
          .map((course) => ({
            courseId: course.id,
            title: course.title,
            price: course.price,
            isFree: course.isFree,
            thumbnailUrl: course.thumbnailUrl,
          }));

        if (!singleMode) {
          paymentCart.setItems(selected);
        }

        setItems(selected);
      } catch (err: any) {
        setError(err.message || t('payments.checkout.errors.loadInfo'));
      } finally {
        setLoading(false);
      }
    };

    void loadCheckoutItems();
  }, [queryCourseIds, singleMode]);

  useEffect(() => {
    const normalizedCode = referralCode.trim();
    referralLookupRef.current += 1;
    const lookupId = referralLookupRef.current;

    if (!normalizedCode) {
      setReferralPreview(null);
      setReferralPreviewState('idle');
      setReferralMessage(null);
      return;
    }

    const timeoutId = window.setTimeout(() => {
      const lookupReferral = async () => {
        try {
          setReferralPreviewState('loading');
          setReferralMessage(null);

          const preview = await paymentApi.previewReferralCode(normalizedCode);
          if (lookupId !== referralLookupRef.current) {
            return;
          }

          setReferralPreview(preview);
          setReferralPreviewState('valid');
        } catch (err: any) {
          if (lookupId !== referralLookupRef.current) {
            return;
          }

          setReferralPreview(null);
          if (err?.status === 404 || err?.status === 400) {
            setReferralPreviewState('invalid');
            setReferralMessage(t('payments.checkout.referral.invalid'));
            return;
          }

          setReferralPreviewState('error');
          setReferralMessage(t('payments.checkout.referral.lookupFailed'));
        }
      };

      void lookupReferral();
    }, 350);

    return () => {
      window.clearTimeout(timeoutId);
    };
  }, [referralCode, t]);

  const totalAmount = useMemo(() => {
    return items.reduce((sum, item) => sum + (item.isFree ? 0 : item.price), 0);
  }, [items]);

  const handleRemove = (courseId: string) => {
    const updated = items.filter((item) => item.courseId !== courseId);
    setItems(updated);

    if (!singleMode) {
      paymentCart.removeCourse(courseId);
    }
  };

  const handleCheckout = async () => {
    if (items.length === 0) {
      return;
    }

    const normalizedReferralCode = referralCode.trim();
    if (normalizedReferralCode && referralPreviewState === 'invalid') {
      setError(t('payments.checkout.referral.invalid'));
      return;
    }

    if (normalizedReferralCode && referralPreviewState === 'loading') {
      setError(t('payments.checkout.referral.checking'));
      return;
    }

    try {
      setSubmitting(true);
      setError(null);

      const result = await paymentApi.createCheckout({
        courseIds: items.map((item) => item.courseId),
        referralCode: normalizedReferralCode || undefined,
      });

      if (!result.requiresPayment) {
        paymentCart.removeMany(result.items.map((item) => item.courseId));
        navigate(`/payment/result?orderId=${result.orderId}&status=success`);
        return;
      }

      setPendingPayment({
        orderId: result.orderId,
        payOSOrderCode: result.payOSOrderCode,
        totalAmount: result.totalAmount,
        status: result.status,
        qrCode: result.qrCode,
        checkoutUrl: result.checkoutUrl,
        paymentInstruction: result.paymentInstruction,
        createdAt: result.createdAt,
        expiresAt: result.expiresAt,
      });

      if (!result.qrCode && !result.checkoutUrl) {
        setError(t('payments.checkout.errors.noQrData'));
      }
    } catch (err: any) {
      setError(err.message || t('payments.checkout.errors.create'));
    } finally {
      setSubmitting(false);
    }
  };

  const refreshPaymentStatus = useCallback(
    async (showInlineError = false) => {
      if (!pendingPayment) {
        return;
      }

      try {
        setCheckingStatus(true);
        const status = await paymentApi.getOrderStatus(pendingPayment.orderId, true);

        if (status.isPaid) {
          paymentCart.removeMany(status.items.map((item) => item.courseId));
          navigate(`/payment/result?orderId=${status.orderId}&status=success`);
          return;
        }

        if (status.status.toUpperCase() === 'FAILED' || status.status.toUpperCase() === 'CANCELLED') {
          navigate(`/payment/result?orderId=${status.orderId}`);
          return;
        }

        setPendingPayment((prev) =>
          prev
            ? {
                ...prev,
                status: status.status,
                qrCode: status.qrCode || prev.qrCode,
                checkoutUrl: status.checkoutUrl || prev.checkoutUrl,
                paymentInstruction: mergePaymentInstruction(status.paymentInstruction, prev.paymentInstruction),
                createdAt: status.createdAt || prev.createdAt,
              }
            : prev,
        );
      } catch (err: any) {
        if (showInlineError) {
          setError(err.message || t('payments.checkout.errors.checkStatus'));
        }
      } finally {
        setCheckingStatus(false);
      }
    },
    [mergePaymentInstruction, navigate, pendingPayment],
  );

  useEffect(() => {
    if (!pendingPayment) {
      return;
    }

    const interval = window.setInterval(() => {
      void refreshPaymentStatus(false);
    }, 10000);

    return () => {
      window.clearInterval(interval);
    };
  }, [pendingPayment, refreshPaymentStatus]);

  useEffect(() => {
    if (!pendingPayment?.orderId) {
      return;
    }

    pendingPaymentRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }, [pendingPayment?.orderId]);

  const paymentInstruction = pendingPayment?.paymentInstruction;
  const displayAmount = paymentInstruction?.amount ?? pendingPayment?.totalAmount ?? 0;
  const transferContent = paymentInstruction?.transferContent
    || buildTransferContentFallback(pendingPayment?.payOSOrderCode, pendingPayment?.orderId);
  const bankDisplay = [paymentInstruction?.bankName, paymentInstruction?.bankShortName]
    .filter(Boolean)
    .join(' - ')
    || (paymentInstruction?.bankBin ? `BIN ${paymentInstruction.bankBin}` : t('payments.checkout.pending.bankFallback'));

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <div className="mb-6 flex items-center justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">{t('payments.checkout.title')}</h1>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
              {t('payments.checkout.subtitle')}
            </p>
          </div>
          <Link
            to="/courses"
            className="inline-flex items-center gap-2 rounded-lg border border-gray-300 dark:border-gray-700 px-4 py-2 text-sm font-semibold text-gray-700 dark:text-gray-300 hover:border-primary hover:text-primary transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">arrow_back</span>
            {t('payments.checkout.continueCourses')}
          </Link>
        </div>

        {error && (
          <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600 dark:border-red-900/40 dark:bg-red-900/20 dark:text-red-300">
            {error}
          </div>
        )}

        <div className="grid gap-6 lg:grid-cols-3">
          <div className="lg:col-span-2 rounded-2xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 shadow-sm">
            <div className="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('payments.checkout.courseListTitle')}</h2>
            </div>

            {loading ? (
              <div className="p-6 space-y-3">
                {Array.from({ length: 3 }).map((_, index) => (
                  <div key={index} className="h-16 rounded-lg bg-gray-100 dark:bg-gray-700 animate-pulse" />
                ))}
              </div>
            ) : items.length === 0 ? (
              <div className="p-12 text-center">
                <span className="material-symbols-outlined text-[52px] text-gray-300 dark:text-gray-600">shopping_cart</span>
                <p className="mt-4 text-gray-500 dark:text-gray-400">{t('payments.checkout.emptyCart')}</p>
              </div>
            ) : (
              <div className={`divide-y divide-gray-200 dark:divide-gray-700 ${pendingPayment ? 'max-h-[320px] overflow-y-auto' : ''}`}>
                {items.map((item) => (
                  <div key={item.courseId} className="flex items-start justify-between gap-4 px-6 py-4">
                    <div className="flex items-center gap-4">
                      <div className="h-14 w-20 overflow-hidden rounded-lg bg-gray-100 dark:bg-gray-700">
                        {item.thumbnailUrl ? (
                          <img src={item.thumbnailUrl} alt={item.title} className="h-full w-full object-cover" />
                        ) : (
                          <div className="h-full w-full bg-gradient-to-br from-primary/30 to-blue-400/30" />
                        )}
                      </div>
                      <div>
                        <p className="font-semibold text-gray-900 dark:text-white">{item.title}</p>
                        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                          {item.isFree ? t('payments.common.free') : formatCurrency(item.price)}
                        </p>
                      </div>
                    </div>

                    {!singleMode && (
                      <button
                        type="button"
                        onClick={() => handleRemove(item.courseId)}
                        className="inline-flex items-center gap-1 rounded-md px-2 py-1 text-sm text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20"
                      >
                        <span className="material-symbols-outlined text-[18px]">delete</span>
                        {t('common.delete')}
                      </button>
                    )}
                  </div>
                ))}
              </div>
            )}

            {pendingPayment && (
              <div ref={pendingPaymentRef} className="scroll-mt-24 border-t border-gray-200 dark:border-gray-700 px-6 py-5">
                <div className="overflow-hidden rounded-2xl border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-900/40">
                  <div className="flex items-center justify-between border-b border-gray-200 bg-white px-5 py-4 dark:border-gray-700 dark:bg-gray-800">
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                      {t('payments.checkout.pending.orderDetailSection')}
                    </h3>
                    <Link
                      to={`/payment/result?orderId=${pendingPayment.orderId}&status=pending`}
                      className="text-sm font-semibold text-primary hover:underline"
                    >
                      {t('payments.checkout.pending.view')}
                    </Link>
                  </div>

                  <div className="space-y-5 p-5">
                    <div className="flex items-start gap-3 rounded-xl border border-gray-200 bg-white px-4 py-3 dark:border-gray-700 dark:bg-gray-800">
                      <span className="material-symbols-outlined text-[24px] text-gray-800 dark:text-gray-200">lightbulb</span>
                      <p className="text-sm text-gray-700 dark:text-gray-200">
                        {t('payments.checkout.pending.scanInstruction')}
                      </p>
                    </div>

                    <div className="grid gap-5 lg:grid-cols-[300px_1fr]">
                      <div className="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-800">
                        <p className="mb-3 text-center text-xs font-black tracking-[0.2em] text-primary">VIETQR PRO</p>

                        <div className="flex justify-center rounded-lg border border-gray-200 bg-white p-3 dark:border-gray-700 dark:bg-gray-900">
                          {pendingPayment.qrCode ? (
                            <QRCodeSVG value={pendingPayment.qrCode} size={220} includeMargin />
                          ) : (
                            <div className="flex h-[220px] w-[220px] items-center justify-center rounded-lg border border-dashed border-gray-300 text-xs text-gray-500">
                              {t('payments.checkout.pending.noQrData')}
                            </div>
                          )}
                        </div>

                        <p className="mt-3 text-center text-xs text-gray-500 dark:text-gray-400">
                          {t('payments.checkout.pending.scanHint')}
                        </p>
                      </div>

                      <div className="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-800">
                        <div className="space-y-3">
                          <div className="grid gap-1 sm:grid-cols-[130px_1fr] sm:items-center">
                            <p className="text-sm text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.bank')}</p>
                            <p className="text-base font-bold text-gray-900 dark:text-white">{bankDisplay}</p>
                          </div>

                          <div className="grid gap-1 sm:grid-cols-[130px_1fr] sm:items-center">
                            <p className="text-sm text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.accountName')}</p>
                            <p className="text-base font-bold text-gray-900 dark:text-white">{paymentInstruction?.accountName || t('payments.checkout.pending.noData')}</p>
                          </div>

                          <div className="grid gap-2 sm:grid-cols-[130px_1fr_auto] sm:items-center">
                            <p className="text-sm text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.accountNumber')}</p>
                            <p className="break-all text-base font-bold text-gray-900 dark:text-white">{paymentInstruction?.accountNumber || t('payments.checkout.pending.noData')}</p>
                            <button
                              type="button"
                              onClick={() => void copyText(paymentInstruction?.accountNumber || '', 'account-number')}
                              disabled={!paymentInstruction?.accountNumber}
                              className="inline-flex h-8 items-center justify-center rounded-md border border-gray-300 px-3 text-xs font-semibold text-gray-700 hover:border-primary hover:text-primary disabled:cursor-not-allowed disabled:opacity-60 dark:border-gray-600 dark:text-gray-200"
                            >
                              {copiedField === 'account-number' ? t('payments.checkout.pending.copied') : t('payments.checkout.pending.copy')}
                            </button>
                          </div>

                          <div className="grid gap-2 sm:grid-cols-[130px_1fr_auto] sm:items-center">
                            <p className="text-sm text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.amount')}</p>
                            <p className="break-all text-base font-bold text-gray-900 dark:text-white">{formatCurrency(displayAmount)}</p>
                            <button
                              type="button"
                              onClick={() => void copyText(String(displayAmount), 'amount')}
                              disabled={displayAmount <= 0}
                              className="inline-flex h-8 items-center justify-center rounded-md border border-gray-300 px-3 text-xs font-semibold text-gray-700 hover:border-primary hover:text-primary disabled:cursor-not-allowed disabled:opacity-60 dark:border-gray-600 dark:text-gray-200"
                            >
                              {copiedField === 'amount' ? t('payments.checkout.pending.copied') : t('payments.checkout.pending.copy')}
                            </button>
                          </div>

                          <div className="grid gap-2 sm:grid-cols-[130px_1fr_auto] sm:items-center">
                            <p className="text-sm text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.transferContent')}</p>
                            <p className="break-all text-base font-bold text-gray-900 dark:text-white">{transferContent || t('payments.checkout.pending.noData')}</p>
                            <button
                              type="button"
                              onClick={() => void copyText(transferContent, 'transfer-content')}
                              disabled={!transferContent}
                              className="inline-flex h-8 items-center justify-center rounded-md border border-gray-300 px-3 text-xs font-semibold text-gray-700 hover:border-primary hover:text-primary disabled:cursor-not-allowed disabled:opacity-60 dark:border-gray-600 dark:text-gray-200"
                            >
                              {copiedField === 'transfer-content' ? t('payments.checkout.pending.copied') : t('payments.checkout.pending.copy')}
                            </button>
                          </div>
                        </div>

                        <p className="mt-4 text-sm text-gray-700 dark:text-gray-200">
                          {t('payments.checkout.pending.exactAmountNote', { amount: formatCurrency(displayAmount) })}
                        </p>
                      </div>
                    </div>

                    <div className="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-800">
                      <h4 className="text-base font-semibold text-gray-900 dark:text-white">{t('payments.checkout.pending.orderInfoTitle')}</h4>

                      <div className="mt-3 grid gap-3 text-sm sm:grid-cols-2">
                        <div>
                          <p className="text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.orderId')}</p>
                          <p className="break-all font-semibold text-gray-900 dark:text-white">{pendingPayment.orderId}</p>
                        </div>
                        <div>
                          <p className="text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.orderCode')}</p>
                          <p className="font-semibold text-gray-900 dark:text-white">{pendingPayment.payOSOrderCode ?? '-'}</p>
                        </div>
                        <div>
                          <p className="text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.createdAt')}</p>
                          <p className="font-semibold text-gray-900 dark:text-white">{formatDateTime(pendingPayment.createdAt)}</p>
                        </div>
                        <div>
                          <p className="text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.statusLabel')}</p>
                          <p className="font-semibold text-gray-900 dark:text-white">{formatStatus(pendingPayment.status)}</p>
                        </div>
                        <div className="sm:col-span-2">
                          <p className="text-gray-500 dark:text-gray-400">{t('payments.checkout.pending.expiresAtLabel')}</p>
                          <p className="font-semibold text-gray-900 dark:text-white">
                            {pendingPayment.expiresAt
                              ? t('payments.checkout.pending.expiresAt', { time: formatDateTime(pendingPayment.expiresAt) })
                              : t('payments.checkout.pending.expiresAtFallback')}
                          </p>
                        </div>
                      </div>

                      <div className="mt-4 border-t border-gray-200 pt-3 dark:border-gray-700">
                        <p className="text-sm font-semibold text-gray-900 dark:text-white">{t('payments.checkout.pending.courseList')}</p>
                        <div className="mt-2 space-y-2">
                          {items.map((item) => (
                            <div key={item.courseId} className="flex items-center justify-between rounded-lg bg-gray-50 px-3 py-2 text-sm dark:bg-gray-900">
                              <span className="text-gray-700 dark:text-gray-200">{item.title}</span>
                              <span className="font-semibold text-gray-900 dark:text-white">
                                {item.isFree ? t('payments.common.free') : formatCurrency(item.price)}
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
                      <button
                        type="button"
                        onClick={() => void refreshPaymentStatus(true)}
                        disabled={checkingStatus}
                        className="inline-flex items-center justify-center gap-2 rounded-lg border border-gray-300 dark:border-gray-700 px-3 py-2 text-sm font-semibold text-gray-700 dark:text-gray-200 hover:border-primary hover:text-primary transition-colors disabled:opacity-60"
                      >
                        <span className="material-symbols-outlined text-[18px]">sync</span>
                        {checkingStatus ? t('payments.checkout.actions.checkingStatus') : t('payments.checkout.actions.iPaid')}
                      </button>

                      <a
                        href={pendingPayment.checkoutUrl || '#'}
                        target="_blank"
                        rel="noreferrer"
                        className="inline-flex items-center justify-center gap-2 rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white hover:bg-primary/90 disabled:opacity-60"
                        aria-disabled={!pendingPayment.checkoutUrl}
                      >
                        <span className="material-symbols-outlined text-[18px]">open_in_new</span>
                        {t('payments.checkout.actions.openFallback')}
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>

          <div className="space-y-4">
            <div className="rounded-2xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 shadow-sm p-5">
              <h3 className="text-base font-semibold text-gray-900 dark:text-white">{t('payments.checkout.referral.title')}</h3>
              <input
                type="text"
                value={referralCode}
                onChange={(event) => setReferralCode(event.target.value.toUpperCase())}
                placeholder={t('payments.checkout.referral.placeholder')}
                className="mt-3 w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 px-3 py-2 text-sm text-gray-900 dark:text-white focus:border-primary focus:outline-none"
              />
              <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                {t('payments.checkout.referral.hint')}
              </p>

              {referralPreviewState === 'loading' && (
                <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                  {t('payments.checkout.referral.checking')}
                </p>
              )}

              {referralPreviewState === 'valid' && referralPreview && (
                <div className="mt-3 rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-700 dark:border-emerald-900/50 dark:bg-emerald-900/20 dark:text-emerald-200">
                  <p className="font-semibold">{t('payments.checkout.referral.matched')}</p>
                  <p className="mt-1">
                    {t('payments.checkout.referral.cabin')}: <span className="font-semibold">{referralPreview.cabinName}</span>
                  </p>
                  <p>
                    {t('payments.checkout.referral.owner')}: <span className="font-semibold">{referralPreview.ownerName}</span>
                  </p>
                </div>
              )}

              {(referralPreviewState === 'invalid' || referralPreviewState === 'error') && referralMessage && (
                <p className="mt-2 text-xs text-red-600 dark:text-red-300">
                  {referralMessage}
                </p>
              )}
            </div>

            <div className="rounded-2xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 shadow-sm p-5">
              <h3 className="text-base font-semibold text-gray-900 dark:text-white">{t('payments.checkout.summary.title')}</h3>
              <div className="mt-4 space-y-2 text-sm">
                <div className="flex items-center justify-between text-gray-600 dark:text-gray-300">
                  <span>{t('payments.checkout.summary.courseCount')}</span>
                  <span>{items.length}</span>
                </div>
                <div className="flex items-center justify-between text-gray-600 dark:text-gray-300">
                  <span>{t('payments.checkout.summary.totalAmount')}</span>
                  <span className="font-semibold text-primary">{formatCurrency(totalAmount)}</span>
                </div>
              </div>

              <button
                type="button"
                onClick={handleCheckout}
                disabled={loading || submitting || items.length === 0 || !!pendingPayment || referralPreviewState === 'loading'}
                className="mt-5 w-full rounded-lg bg-primary px-4 py-3 text-sm font-bold text-white shadow-md shadow-primary/20 transition-all hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {submitting
                  ? t('payments.checkout.actions.creatingOrder')
                  : totalAmount > 0
                    ? t('payments.checkout.actions.payWithVietQr')
                    : t('payments.checkout.actions.confirmFreeCourses')}
              </button>

              <p className="mt-3 text-xs text-gray-500 dark:text-gray-400">
                {t('payments.checkout.summary.note')}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CheckoutPage;
