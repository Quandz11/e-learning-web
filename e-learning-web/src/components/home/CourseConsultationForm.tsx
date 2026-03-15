import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { leadApi } from '../../services/leadApi';
import { useToast } from '../../contexts/ToastContext';

interface ConsultationFormState {
  fullName: string;
  email: string;
  phone: string;
  goal: string;
}

const initialState: ConsultationFormState = {
  fullName: '',
  email: '',
  phone: '',
  goal: '',
};

const CourseConsultationForm: React.FC = () => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState<ConsultationFormState>(initialState);

  const goalOptions = useMemo(
    () => [
      t('home.consultForm.goals.detox', { defaultValue: 'Thanh lọc cơ thể' }),
      t('home.consultForm.goals.weightLoss', { defaultValue: 'Giảm cân lành mạnh' }),
      t('home.consultForm.goals.chronicSupport', { defaultValue: 'Hỗ trợ bệnh nền' }),
      t('home.consultForm.goals.personalPlan', { defaultValue: 'Lộ trình cá nhân hóa' }),
    ],
    [t]
  );

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!form.fullName.trim() || !form.email.trim() || !form.phone.trim() || !form.goal) {
      showToast(
        t('home.consultForm.messages.required', {
          defaultValue: 'Vui lòng điền đầy đủ thông tin.',
        }),
        'warning'
      );
      return;
    }

    try {
      setSubmitting(true);
      await leadApi.createPublic({
        fullName: form.fullName.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
        goal: form.goal,
      });

      setForm(initialState);
      showToast(
        t('home.consultForm.messages.success', {
          defaultValue: 'Đăng ký thành công. Đội ngũ sẽ liên hệ bạn sớm.',
        }),
        'success'
      );
    } catch (error: any) {
      showToast(
        error?.message ||
          t('home.consultForm.messages.failed', {
            defaultValue: 'Không thể gửi đăng ký. Vui lòng thử lại.',
          }),
        'error'
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section className="bg-[#dce5e3] py-12 sm:py-14">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <h2 className="mb-6 text-center text-3xl font-extrabold text-[#11332e] sm:text-4xl">
          {t('home.consultForm.title', { defaultValue: 'Đăng Ký Tư Vấn Khóa Học' })}
        </h2>

        <div className="mx-auto max-w-3xl rounded-[20px] bg-white px-5 py-6 shadow-[0_20px_45px_rgba(17,51,46,0.09)] sm:px-8 sm:py-8">
          <form onSubmit={handleSubmit} className="space-y-3">
            <input
              type="text"
              value={form.fullName}
              onChange={(event) => setForm((prev) => ({ ...prev, fullName: event.target.value }))}
              placeholder={t('home.consultForm.fields.fullName', { defaultValue: 'Họ và tên của bạn' })}
              className="h-12 w-full rounded-xl border border-slate-200 bg-[#f9fbfb] px-4 text-sm text-slate-800 outline-none transition focus:border-[#0f4f43]"
            />

            <input
              type="email"
              value={form.email}
              onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
              placeholder={t('home.consultForm.fields.email', { defaultValue: 'Địa chỉ Email' })}
              className="h-12 w-full rounded-xl border border-slate-200 bg-[#f9fbfb] px-4 text-sm text-slate-800 outline-none transition focus:border-[#0f4f43]"
            />

            <input
              type="text"
              value={form.phone}
              onChange={(event) => setForm((prev) => ({ ...prev, phone: event.target.value }))}
              placeholder={t('home.consultForm.fields.phone', { defaultValue: 'Số điện thoại (Zalo)' })}
              className="h-12 w-full rounded-xl border border-slate-200 bg-[#f9fbfb] px-4 text-sm text-slate-800 outline-none transition focus:border-[#0f4f43]"
            />

            <select
              value={form.goal}
              onChange={(event) => setForm((prev) => ({ ...prev, goal: event.target.value }))}
              className="h-12 w-full rounded-xl border border-slate-200 bg-[#f9fbfb] px-4 text-sm text-slate-800 outline-none transition focus:border-[#0f4f43]"
            >
              <option value="">
                {t('home.consultForm.fields.goal', { defaultValue: 'Mục tiêu của bạn là gì?' })}
              </option>
              {goalOptions.map((goalOption) => (
                <option key={goalOption} value={goalOption}>
                  {goalOption}
                </option>
              ))}
            </select>

            <button
              type="submit"
              disabled={submitting}
              className="mt-2 h-11 w-full rounded-xl bg-[#0b3d35] px-5 text-sm font-semibold text-white shadow-[0_8px_18px_rgba(11,61,53,0.25)] transition hover:bg-[#0f4f43] disabled:cursor-not-allowed disabled:opacity-70"
            >
              {submitting
                ? t('home.consultForm.actions.submitting', { defaultValue: 'Đang gửi...' })
                : t('home.consultForm.actions.submit', { defaultValue: 'Gửi yêu cầu ngay' })}
            </button>
          </form>
        </div>
      </div>
    </section>
  );
};

export default CourseConsultationForm;
