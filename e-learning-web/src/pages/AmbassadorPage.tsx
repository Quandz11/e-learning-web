import React, { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { leadApi } from '../services/leadApi';
import { useToast } from '../contexts/ToastContext';

interface AmbassadorFormState {
  fullName: string;
  email: string;
  phone: string;
  course: string;
  voucherCode: string;
}

const initialFormState: AmbassadorFormState = {
  fullName: '',
  email: '',
  phone: '',
  course: '',
  voucherCode: '',
};

const AmbassadorPage: React.FC = () => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const [form, setForm] = useState<AmbassadorFormState>(initialFormState);
  const [submitting, setSubmitting] = useState(false);

  const courseOptions = useMemo(
    () => [
      t('ambassadorPage.form.courses.0'),
      t('ambassadorPage.form.courses.1'),
      t('ambassadorPage.form.courses.2'),
      t('ambassadorPage.form.courses.3'),
      t('ambassadorPage.form.courses.4'),
    ],
    [t]
  );

  const commissionCards = [
    {
      title: t('ambassadorPage.commissions.direct.title'),
      value: t('ambassadorPage.commissions.direct.value'),
      note: t('ambassadorPage.commissions.direct.note'),
    },
    {
      title: t('ambassadorPage.commissions.indirect.title'),
      value: t('ambassadorPage.commissions.indirect.value'),
      note: t('ambassadorPage.commissions.indirect.note'),
    },
    {
      title: t('ambassadorPage.commissions.voucher.title'),
      value: t('ambassadorPage.commissions.voucher.value'),
      note: t('ambassadorPage.commissions.voucher.note'),
    },
  ];

  const voucherSteps = [
    t('ambassadorPage.voucher.steps.0'),
    t('ambassadorPage.voucher.steps.1'),
    t('ambassadorPage.voucher.steps.2'),
  ];

  const rewardItems = [
    t('ambassadorPage.rewards.items.0'),
    t('ambassadorPage.rewards.items.1'),
    t('ambassadorPage.rewards.items.2'),
  ];

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!form.fullName.trim() || !form.email.trim() || !form.phone.trim() || !form.course.trim()) {
      showToast(t('ambassadorPage.form.messages.required'), 'warning');
      return;
    }

    try {
      setSubmitting(true);

      const goal = t('ambassadorPage.form.goalValue', {
        course: form.course.trim(),
        voucher: form.voucherCode.trim() || t('ambassadorPage.form.noVoucher'),
      });

      await leadApi.createPublic({
        fullName: form.fullName.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
        goal,
        source: 'AMBASSADOR_FORM',
      });

      setForm(initialFormState);
      showToast(t('ambassadorPage.form.messages.success'), 'success');
    } catch (error: any) {
      showToast(error?.message || t('ambassadorPage.form.messages.failed'), 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="bg-[#f8f9fa]">
      <section className="bg-gradient-to-br from-[#1b4332] to-[#2d6a4f] px-4 py-14 text-white sm:px-6 sm:py-16">
        <div className="mx-auto max-w-5xl text-center">
          <p className="text-3xl font-extrabold text-[#ffb703] sm:text-4xl lg:text-5xl">{t('ambassadorPage.hero.title')}</p>
          <p className="mx-auto mt-3 max-w-3xl text-sm text-white/90 sm:text-base">{t('ambassadorPage.hero.subtitle')}</p>
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6 sm:py-12 lg:px-8">
        <section className="grid grid-cols-1 gap-5 md:grid-cols-3">
          {commissionCards.map((card) => (
            <article key={card.title} className="rounded-2xl border-t-[5px] border-[#ffb703] bg-white p-6 text-center shadow-[0_12px_24px_rgba(0,0,0,0.06)]">
              <p className="text-sm font-bold text-gray-600">{card.title}</p>
              <p className="mt-2 text-4xl font-extrabold text-[#2d6a4f]">{card.value}</p>
              <p className="mt-2 text-sm text-gray-600">{card.note}</p>
            </article>
          ))}
        </section>

        <section className="mt-8 rounded-2xl bg-white p-6 shadow-[0_8px_20px_rgba(0,0,0,0.06)] sm:p-8">
          <h2 className="border-l-[5px] border-[#ffb703] pl-3 text-xl font-bold text-[#2d6a4f] sm:text-2xl">{t('ambassadorPage.voucher.title')}</h2>
          <p className="mt-3 text-sm text-gray-700 sm:text-base">{t('ambassadorPage.voucher.description')}</p>

          <ol className="mt-5 space-y-3">
            {voucherSteps.map((step, index) => (
              <li key={step} className="flex items-start gap-3">
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[#2d6a4f] text-xs font-bold text-white">
                  {index + 1}
                </span>
                <p className="text-sm leading-relaxed text-gray-700 sm:text-base">{step}</p>
              </li>
            ))}
          </ol>
        </section>

        <section className="mt-8 rounded-2xl border-2 border-dashed border-[#ffb703] bg-white p-6 shadow-[0_8px_20px_rgba(0,0,0,0.05)] sm:p-8">
          <h2 className="text-xl font-bold text-[#2d6a4f] sm:text-2xl">{t('ambassadorPage.rewards.title')}</h2>
          <p className="mt-3 text-sm text-gray-700 sm:text-base">{t('ambassadorPage.rewards.subtitle')}</p>
          <ul className="mt-4 list-disc space-y-2 pl-5 text-sm text-gray-700 sm:text-base">
            {rewardItems.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>

        <section id="register" className="mt-10 rounded-2xl border-2 border-[#2d6a4f] bg-[#e9f5ee] p-5 sm:mt-12 sm:p-8">
          <h2 className="text-center text-2xl font-extrabold text-[#2d6a4f] sm:text-3xl">{t('ambassadorPage.form.title')}</h2>

          <form onSubmit={handleSubmit} className="mx-auto mt-6 max-w-2xl space-y-4">
            <div>
              <label className="mb-2 block text-sm font-bold text-[#1b4332]">{t('ambassadorPage.form.fields.fullName')}</label>
              <input
                type="text"
                value={form.fullName}
                onChange={(event) => setForm((prev) => ({ ...prev, fullName: event.target.value }))}
                placeholder={t('ambassadorPage.form.placeholders.fullName')}
                className="h-12 w-full rounded-lg border border-gray-300 bg-white px-4 text-sm text-gray-800 outline-none transition focus:border-[#2d6a4f]"
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-[#1b4332]">{t('ambassadorPage.form.fields.email')}</label>
              <input
                type="email"
                value={form.email}
                onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
                placeholder={t('ambassadorPage.form.placeholders.email')}
                className="h-12 w-full rounded-lg border border-gray-300 bg-white px-4 text-sm text-gray-800 outline-none transition focus:border-[#2d6a4f]"
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-[#1b4332]">{t('ambassadorPage.form.fields.phone')}</label>
              <input
                type="text"
                value={form.phone}
                onChange={(event) => setForm((prev) => ({ ...prev, phone: event.target.value }))}
                placeholder={t('ambassadorPage.form.placeholders.phone')}
                className="h-12 w-full rounded-lg border border-gray-300 bg-white px-4 text-sm text-gray-800 outline-none transition focus:border-[#2d6a4f]"
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-[#1b4332]">{t('ambassadorPage.form.fields.course')}</label>
              <select
                value={form.course}
                onChange={(event) => setForm((prev) => ({ ...prev, course: event.target.value }))}
                className="h-12 w-full rounded-lg border border-gray-300 bg-white px-4 text-sm text-gray-800 outline-none transition focus:border-[#2d6a4f]"
              >
                <option value="">{t('ambassadorPage.form.placeholders.course')}</option>
                {courseOptions.map((option) => (
                  <option key={option} value={option}>
                    {option}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-[#1b4332]">{t('ambassadorPage.form.fields.voucherCode')}</label>
              <input
                type="text"
                value={form.voucherCode}
                onChange={(event) => setForm((prev) => ({ ...prev, voucherCode: event.target.value.toUpperCase() }))}
                placeholder={t('ambassadorPage.form.placeholders.voucherCode')}
                className="h-12 w-full rounded-lg border border-gray-300 bg-white px-4 text-sm text-gray-800 outline-none transition focus:border-[#2d6a4f]"
              />
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="mt-2 h-12 w-full rounded-lg bg-[#2d6a4f] px-5 text-sm font-extrabold text-white transition hover:bg-[#40916c] disabled:cursor-not-allowed disabled:opacity-70"
            >
              {submitting ? t('ambassadorPage.form.actions.submitting') : t('ambassadorPage.form.actions.submit')}
            </button>

            <p className="text-center text-xs italic text-gray-600 sm:text-sm">{t('ambassadorPage.form.note')}</p>
          </form>
        </section>

        <div className="mt-6 text-center">
          <Link to="/pricing" className="text-sm font-bold text-[#2d6a4f] underline underline-offset-4">
            {t('ambassadorPage.backToPricing')}
          </Link>
        </div>
      </div>
    </div>
  );
};

export default AmbassadorPage;
