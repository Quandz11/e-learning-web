import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useToast } from '../../contexts/ToastContext';
import {
  leadApi,
  type CreateLeadRegistrationRequest,
  type LeadRegistrationDto,
  type LeadStatus,
  type UpdateLeadRegistrationRequest,
} from '../../services/leadApi';
import { userApi, type UserDto } from '../../services/userApi';

const leadStatuses: LeadStatus[] = ['NEW', 'CONTACTED', 'CONSULTING', 'CONVERTED', 'LOST'];

interface LeadFormState {
  fullName: string;
  email: string;
  phone: string;
  goal: string;
  status: LeadStatus;
  assignedCareId: string;
}

const initialForm: LeadFormState = {
  fullName: '',
  email: '',
  phone: '',
  goal: '',
  status: 'NEW',
  assignedCareId: '',
};

interface LeadRegistrationsPanelProps {
  title?: string;
  subtitle?: string;
}

const LeadRegistrationsPanel: React.FC<LeadRegistrationsPanelProps> = ({ title, subtitle }) => {
  const { t, i18n } = useTranslation();
  const { showToast } = useToast();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | LeadStatus>('ALL');
  const [leads, setLeads] = useState<LeadRegistrationDto[]>([]);
  const [careUsers, setCareUsers] = useState<UserDto[]>([]);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<LeadRegistrationDto | null>(null);
  const [form, setForm] = useState<LeadFormState>(initialForm);

  const panelTitle = title || t('leadRegistrations.title', { defaultValue: 'Form đăng ký tư vấn' });
  const panelSubtitle =
    subtitle ||
    t('leadRegistrations.subtitle', {
      defaultValue: 'Quản lý thông tin khách đăng ký từ trang chủ.',
    });

  const statusLabel = (value: LeadStatus) =>
    t(`leadRegistrations.status.${value}`, {
      defaultValue: value,
    });

  const formatDateTime = (value: string) =>
    new Date(value).toLocaleString(locale, {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });

  const filteredLeads = useMemo(() => {
    const keyword = search.trim().toUpperCase();

    return leads.filter((lead) => {
      if (statusFilter !== 'ALL' && lead.status !== statusFilter) {
        return false;
      }

      if (!keyword) {
        return true;
      }

      return (
        lead.fullName.toUpperCase().includes(keyword) ||
        lead.email.toUpperCase().includes(keyword) ||
        lead.phone.toUpperCase().includes(keyword) ||
        lead.goal.toUpperCase().includes(keyword)
      );
    });
  }, [leads, search, statusFilter]);

  const statusClass = (status: LeadStatus) => {
    if (status === 'NEW') {
      return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300';
    }

    if (status === 'CONTACTED' || status === 'CONSULTING') {
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300';
    }

    if (status === 'CONVERTED') {
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300';
    }

    return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300';
  };

  const loadLeads = async () => {
    try {
      setLoading(true);
      const result = await leadApi.getPaged({
        page: 1,
        pageSize: 500,
      });
      setLeads(result.items);
    } catch (error: any) {
      showToast(
        error?.message ||
          t('leadRegistrations.toasts.loadFailed', {
            defaultValue: 'Không thể tải danh sách đăng ký.',
          }),
        'error'
      );
    } finally {
      setLoading(false);
    }
  };

  const loadCareUsers = async () => {
    try {
      const result = await userApi.getPaged({ role: 'CARE', page: 1, pageSize: 200 });
      setCareUsers(result.items);
    } catch {
      setCareUsers([]);
    }
  };

  useEffect(() => {
    void loadLeads();
    void loadCareUsers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const openCreate = () => {
    setEditing(null);
    setForm(initialForm);
    setDialogOpen(true);
  };

  const openEdit = (lead: LeadRegistrationDto) => {
    setEditing(lead);
    setForm({
      fullName: lead.fullName,
      email: lead.email,
      phone: lead.phone,
      goal: lead.goal,
      status: lead.status,
      assignedCareId: lead.assignedCareId ?? '',
    });
    setDialogOpen(true);
  };

  const closeDialog = () => {
    if (submitting) {
      return;
    }

    setDialogOpen(false);
    setEditing(null);
    setForm(initialForm);
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!form.fullName.trim() || !form.email.trim() || !form.phone.trim() || !form.goal.trim()) {
      showToast(
        t('leadRegistrations.toasts.required', {
          defaultValue: 'Vui lòng nhập đầy đủ thông tin.',
        }),
        'warning'
      );
      return;
    }

    try {
      setSubmitting(true);

      if (editing) {
        const payload: UpdateLeadRegistrationRequest = {
          fullName: form.fullName.trim(),
          email: form.email.trim(),
          phone: form.phone.trim(),
          goal: form.goal.trim(),
          status: form.status,
          assignedCareId: form.assignedCareId,
        };

        await leadApi.update(editing.id, payload);

        showToast(
          t('leadRegistrations.toasts.updateSuccess', {
            defaultValue: 'Cập nhật đăng ký thành công.',
          }),
          'success'
        );
      } else {
        const payload: CreateLeadRegistrationRequest = {
          fullName: form.fullName.trim(),
          email: form.email.trim(),
          phone: form.phone.trim(),
          goal: form.goal.trim(),
        };

        await leadApi.createPublic(payload);

        showToast(
          t('leadRegistrations.toasts.createSuccess', {
            defaultValue: 'Tạo đăng ký thành công.',
          }),
          'success'
        );
      }

      closeDialog();
      await loadLeads();
    } catch (error: any) {
      showToast(
        error?.message ||
          t('leadRegistrations.toasts.saveFailed', {
            defaultValue: 'Không thể lưu đăng ký.',
          }),
        'error'
      );
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (lead: LeadRegistrationDto) => {
    if (
      !window.confirm(
        t('leadRegistrations.confirmDelete', {
          defaultValue: 'Bạn có chắc muốn xóa đăng ký này?',
        })
      )
    ) {
      return;
    }

    try {
      await leadApi.remove(lead.id);
      showToast(
        t('leadRegistrations.toasts.deleteSuccess', {
          defaultValue: 'Đã xóa đăng ký.',
        }),
        'success'
      );
      await loadLeads();
    } catch (error: any) {
      showToast(
        error?.message ||
          t('leadRegistrations.toasts.deleteFailed', {
            defaultValue: 'Không thể xóa đăng ký.',
          }),
        'error'
      );
    }
  };

  return (
    <>
      <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white">{panelTitle}</h2>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{panelSubtitle}</p>
        </div>

        <button
          type="button"
          onClick={openCreate}
          className="inline-flex h-11 items-center rounded-lg bg-dashboard-primary px-4 text-sm font-semibold text-white hover:bg-dashboard-primary-dark"
        >
          {t('leadRegistrations.actions.create', { defaultValue: 'Tạo mới' })}
        </button>
      </div>

      <div className="mb-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <div className="sm:col-span-2">
          <input
            type="text"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder={t('leadRegistrations.searchPlaceholder', {
              defaultValue: 'Tìm theo tên, email, số điện thoại, mục tiêu',
            })}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
          />
        </div>

        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value as 'ALL' | LeadStatus)}
          className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
        >
          <option value="ALL">{t('leadRegistrations.filters.all', { defaultValue: 'Tất cả trạng thái' })}</option>
          {leadStatuses.map((status) => (
            <option key={status} value={status}>
              {statusLabel(status)}
            </option>
          ))}
        </select>
      </div>

      <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark overflow-hidden">
        <div className="hidden md:block overflow-x-auto">
          <table className="min-w-[1040px] w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
              <tr>
                <th className="px-6 py-4 font-semibold">{t('leadRegistrations.table.customer', { defaultValue: 'Khách hàng' })}</th>
                <th className="px-6 py-4 font-semibold">{t('leadRegistrations.table.phone', { defaultValue: 'Điện thoại' })}</th>
                <th className="px-6 py-4 font-semibold">{t('leadRegistrations.table.goal', { defaultValue: 'Mục tiêu' })}</th>
                <th className="px-6 py-4 font-semibold">{t('leadRegistrations.table.status', { defaultValue: 'Trạng thái' })}</th>
                <th className="px-6 py-4 font-semibold">{t('leadRegistrations.table.assignedCare', { defaultValue: 'Care phụ trách' })}</th>
                <th className="px-6 py-4 font-semibold">{t('leadRegistrations.table.createdAt', { defaultValue: 'Đăng ký lúc' })}</th>
                <th className="px-6 py-4 text-right font-semibold">{t('leadRegistrations.table.actions', { defaultValue: 'Thao tác' })}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-6 py-10 text-center text-slate-500 dark:text-slate-400">
                    {t('leadRegistrations.table.loading', { defaultValue: 'Đang tải dữ liệu...' })}
                  </td>
                </tr>
              ) : filteredLeads.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-10 text-center text-slate-500 dark:text-slate-400">
                    {t('leadRegistrations.table.empty', { defaultValue: 'Chưa có đăng ký nào.' })}
                  </td>
                </tr>
              ) : (
                filteredLeads.map((lead) => (
                  <tr key={lead.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/40">
                    <td className="px-6 py-4">
                      <p className="font-medium text-slate-900 dark:text-white">{lead.fullName}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{lead.email}</p>
                    </td>
                    <td className="px-6 py-4 text-slate-700 dark:text-slate-200">{lead.phone}</td>
                    <td className="px-6 py-4 text-slate-700 dark:text-slate-200">{lead.goal}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${statusClass(lead.status)}`}>
                        {statusLabel(lead.status)}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-slate-700 dark:text-slate-200">{lead.assignedCareName || '-'}</td>
                    <td className="px-6 py-4 text-slate-600 dark:text-slate-300">{formatDateTime(lead.createdAt)}</td>
                    <td className="px-6 py-4 text-right">
                      <div className="inline-flex gap-2">
                        <button
                          type="button"
                          onClick={() => openEdit(lead)}
                          className="rounded-md border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        >
                          {t('common.edit', { defaultValue: 'Sửa' })}
                        </button>
                        <button
                          type="button"
                          onClick={() => void handleDelete(lead)}
                          className="rounded-md border border-red-300 px-3 py-1.5 text-xs font-medium text-red-600 hover:bg-red-50 dark:border-red-700 dark:text-red-300 dark:hover:bg-red-900/20"
                        >
                          {t('common.delete', { defaultValue: 'Xóa' })}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="md:hidden divide-y divide-slate-200 dark:divide-slate-700">
          {loading ? (
            <div className="px-4 py-8 text-sm text-slate-500 dark:text-slate-400">
              {t('leadRegistrations.table.loading', { defaultValue: 'Đang tải dữ liệu...' })}
            </div>
          ) : filteredLeads.length === 0 ? (
            <div className="px-4 py-8 text-sm text-slate-500 dark:text-slate-400">
              {t('leadRegistrations.table.empty', { defaultValue: 'Chưa có đăng ký nào.' })}
            </div>
          ) : (
            filteredLeads.map((lead) => (
              <div key={lead.id} className="space-y-3 p-4">
                <div>
                  <p className="font-medium text-slate-900 dark:text-white">{lead.fullName}</p>
                  <p className="text-xs text-slate-500 dark:text-slate-400 break-all">{lead.email}</p>
                </div>

                <p className="text-sm text-slate-700 dark:text-slate-200">{lead.phone}</p>
                <p className="text-sm text-slate-700 dark:text-slate-200">{lead.goal}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400">{formatDateTime(lead.createdAt)}</p>

                <div className="flex items-center justify-between gap-2">
                  <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${statusClass(lead.status)}`}>
                    {statusLabel(lead.status)}
                  </span>

                  <div className="inline-flex gap-2">
                    <button
                      type="button"
                      onClick={() => openEdit(lead)}
                      className="rounded-md border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                      {t('common.edit', { defaultValue: 'Sửa' })}
                    </button>
                    <button
                      type="button"
                      onClick={() => void handleDelete(lead)}
                      className="rounded-md border border-red-300 px-3 py-1.5 text-xs font-medium text-red-600 hover:bg-red-50 dark:border-red-700 dark:text-red-300 dark:hover:bg-red-900/20"
                    >
                      {t('common.delete', { defaultValue: 'Xóa' })}
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {dialogOpen && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 px-2 py-2 sm:items-center sm:px-4 sm:py-4">
          <div className="w-full max-w-xl rounded-t-2xl sm:rounded-xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 px-4 sm:px-5 py-4">
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                {editing
                  ? t('leadRegistrations.actions.edit', { defaultValue: 'Cập nhật đăng ký' })
                  : t('leadRegistrations.actions.create', { defaultValue: 'Tạo mới' })}
              </h3>
              <button
                type="button"
                onClick={closeDialog}
                className="rounded-md p-1 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 px-4 sm:px-5 py-5">
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="sm:col-span-2">
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                    {t('leadRegistrations.fields.fullName', { defaultValue: 'Họ và tên' })}
                  </label>
                  <input
                    type="text"
                    value={form.fullName}
                    onChange={(event) => setForm((prev) => ({ ...prev, fullName: event.target.value }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                    {t('leadRegistrations.fields.email', { defaultValue: 'Email' })}
                  </label>
                  <input
                    type="email"
                    value={form.email}
                    onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                    {t('leadRegistrations.fields.phone', { defaultValue: 'Số điện thoại' })}
                  </label>
                  <input
                    type="text"
                    value={form.phone}
                    onChange={(event) => setForm((prev) => ({ ...prev, phone: event.target.value }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                  />
                </div>

                <div className="sm:col-span-2">
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                    {t('leadRegistrations.fields.goal', { defaultValue: 'Mục tiêu tư vấn' })}
                  </label>
                  <input
                    type="text"
                    value={form.goal}
                    onChange={(event) => setForm((prev) => ({ ...prev, goal: event.target.value }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                    {t('leadRegistrations.fields.status', { defaultValue: 'Trạng thái' })}
                  </label>
                  <select
                    value={form.status}
                    onChange={(event) => setForm((prev) => ({ ...prev, status: event.target.value as LeadStatus }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                  >
                    {leadStatuses.map((status) => (
                      <option key={status} value={status}>
                        {statusLabel(status)}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                    {t('leadRegistrations.fields.assignedCare', { defaultValue: 'Care phụ trách' })}
                  </label>
                  <select
                    value={form.assignedCareId}
                    onChange={(event) => setForm((prev) => ({ ...prev, assignedCareId: event.target.value }))}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 px-3 py-2 text-sm text-slate-900 dark:text-white focus:border-dashboard-primary focus:outline-none"
                  >
                    <option value="">{t('leadRegistrations.fields.unassigned', { defaultValue: 'Chưa phân công' })}</option>
                    {careUsers.map((careUser) => (
                      <option key={careUser.id} value={careUser.id}>
                        {careUser.fullName || careUser.email}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="flex flex-col-reverse sm:flex-row sm:justify-end gap-2 sm:gap-3 border-t border-slate-200 dark:border-slate-700 pt-4">
                <button
                  type="button"
                  onClick={closeDialog}
                  className="h-11 w-full sm:w-auto rounded-lg border border-slate-300 dark:border-slate-700 px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-200"
                  disabled={submitting}
                >
                  {t('common.cancel', { defaultValue: 'Hủy' })}
                </button>
                <button
                  type="submit"
                  className="h-11 w-full sm:w-auto rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white hover:bg-dashboard-primary-dark disabled:opacity-70"
                  disabled={submitting}
                >
                  {submitting
                    ? t('leadRegistrations.actions.saving', { defaultValue: 'Đang lưu...' })
                    : t('leadRegistrations.actions.save', { defaultValue: 'Lưu' })}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
};

export default LeadRegistrationsPanel;
