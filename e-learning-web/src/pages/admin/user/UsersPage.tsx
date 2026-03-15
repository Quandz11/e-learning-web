import { Link } from 'react-router-dom';
import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { userApi, type UserDto, type UserRole, type UserStatus } from '../../../services/userApi';
import { format } from 'date-fns';
import UserFormModal from './components/UserFormModal';
import ResetPasswordModal from './components/ResetPasswordModal';
import ConfirmModal from '../../../components/ui/Modal/ConfirmModal';
import { useToast } from '../../../contexts/ToastContext';

const roles: UserRole[] = ['ADMIN', 'CARE', 'CABIN_OWNER', 'STUDENT', 'LECTURER'];
const statuses: UserStatus[] = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

const UsersPage: React.FC = () => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const [data, setData] = useState<UserDto[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Modals state
  const [showForm, setShowForm] = useState(false);
  const [showReset, setShowReset] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [selectedUser, setSelectedUser] = useState<UserDto | null>(null);

  // Delete Modal State
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const totalPages = useMemo(() => Math.max(1, Math.ceil(total / pageSize)), [total, pageSize]);

  const roleLabel = (value: UserRole) => t(`admin.users.roles.${value}`);
  const statusLabel = (value: UserStatus) => t(`admin.users.statuses.${value}`);

  useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, pageSize, roleFilter, statusFilter]);

  const load = async () => {
    try {
      setLoading(true);
      const res = await userApi.getPaged({ search, role: roleFilter, status: statusFilter, page, pageSize });
      setData(res.items);
      setTotal(res.total);
    } catch (err: any) {
      setError(err.message || t('admin.users.errors.loadFailed'));
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    await load();
  };

  const openCreate = () => {
    setEditingId(null);
    setSelectedUser(null);
    setShowForm(true);
  };

  const openEdit = (u: UserDto) => {
    setEditingId(u.id);
    setSelectedUser(u);
    setShowForm(true);
  };

  const openResetPassword = (id: string) => {
    setEditingId(id);
    setShowReset(true);
  };

  const handleDeleteClick = (id: string) => {
    setDeletingId(id);
    setShowDeleteModal(true);
  };

  const handleConfirmDelete = async () => {
    if (!deletingId) return;

    setIsDeleting(true);
    try {
      await userApi.delete(deletingId);
      showToast(t('notifications.success.deleteSuccess'), 'success');
      setShowDeleteModal(false);
      await load();
    } catch (err: any) {
      showToast(err.message || t('admin.users.errors.deleteFailed'), 'error');
    } finally {
      setIsDeleting(false);
    }
  };

  const handleSuccess = async () => {
    await load();
    // Form closes itself via onSuccess prop if needed, or we close it here? 
    // The Modal calls onSuccess then onClose? Wait, let's check Modal implementation.
    // Modal calls onSuccess() then onClose(). So we just reload here.
  };

  return (
    <AdminLayout>
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{t('admin.users.title')}</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.subtitle')}</p>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex h-11 w-full sm:w-auto items-center justify-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          {t('admin.users.new')}
        </button>
      </div>

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
          {error}
        </div>
      )}

      <form onSubmit={handleSearch} className="mb-4 grid grid-cols-1 gap-3 md:grid-cols-[minmax(0,1fr)_auto_auto_auto]">
        <input
          className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
          placeholder={t('admin.users.searchPlaceholder')}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select
          className="w-full md:w-auto rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
        >
          <option value="">{t('admin.users.filters.roleAll')}</option>
          {roles.map((r) => (
            <option key={r} value={r}>{roleLabel(r)}</option>
          ))}
        </select>
        <select
          className="w-full md:w-auto rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="">{t('admin.users.filters.statusAll')}</option>
          {statuses.map((s) => (
            <option key={s} value={s}>{statusLabel(s)}</option>
          ))}
        </select>
        <button
          type="submit"
          className="inline-flex h-10 w-full md:w-auto items-center justify-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
        >
          <span className="material-symbols-outlined text-[18px]">search</span>
          {t('admin.users.buttons.search')}
        </button>
      </form>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
        <div className="md:hidden divide-y divide-slate-100 dark:divide-slate-800">
          {loading ? (
            <div className="px-4 py-6 text-sm text-slate-500 dark:text-slate-300">{t('admin.users.table.loading')}</div>
          ) : data.length === 0 ? (
            <div className="px-4 py-6 text-sm text-slate-500 dark:text-slate-300">{t('admin.users.table.noData')}</div>
          ) : (
            data.map((u) => (
              <div key={u.id} className="space-y-3 p-4">
                <div className="min-w-0">
                  <Link to={`/admin/users/${u.id}`} className="block truncate font-semibold text-slate-900 transition-colors hover:text-dashboard-primary dark:text-white dark:hover:text-dashboard-primary">
                    {u.email}
                  </Link>
                  <p className="mt-1 truncate text-xs text-slate-500 dark:text-slate-400">{u.phone || '-'}</p>
                </div>

                <p className="text-sm text-slate-700 dark:text-slate-200">{u.fullName || '-'}</p>

                <div className="flex flex-wrap items-center gap-2">
                  <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">{roleLabel(u.role)}</span>
                  <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold ${u.status === 'ACTIVE' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'}`}>
                    {statusLabel(u.status)}
                  </span>
                  <span className="text-xs text-slate-500 dark:text-slate-400">{format(new Date(u.createdAt), 'yyyy-MM-dd')}</span>
                </div>

                <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
                  <button
                    className="h-10 rounded-lg border border-slate-200 px-3 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    onClick={() => openEdit(u)}
                  >
                    {t('admin.users.buttons.edit')}
                  </button>
                  <button
                    className="h-10 rounded-lg border border-slate-200 px-3 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    onClick={() => openResetPassword(u.id)}
                  >
                    {t('admin.users.buttons.reset')}
                  </button>
                  <button
                    className="h-10 rounded-lg border border-red-200 px-3 text-sm text-red-600 transition hover:bg-red-50 dark:border-red-700 dark:text-red-300 dark:hover:bg-red-900/20"
                    onClick={() => handleDeleteClick(u.id)}
                  >
                    {t('admin.users.buttons.delete')}
                  </button>
                </div>
              </div>
            ))
          )}
        </div>

        <div className="hidden md:block overflow-x-auto">
          <table className="min-w-[900px] w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
              <tr>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.email')}</th>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.name')}</th>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.role')}</th>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.status')}</th>
                <th className="px-4 py-3 font-semibold">{t('admin.users.table.created')}</th>
                <th className="px-4 py-3 font-semibold text-right">{t('admin.users.table.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td className="px-4 py-4" colSpan={6}>{t('admin.users.table.loading')}</td></tr>
              ) : data.length === 0 ? (
                <tr><td className="px-4 py-4 text-slate-500" colSpan={6}>{t('admin.users.table.noData')}</td></tr>
              ) : (
                data.map((u) => (
                  <tr key={u.id} className="border-t border-slate-100 dark:border-slate-800">
                    <td className="px-4 py-3">
                      <Link to={`/admin/users/${u.id}`} className="font-semibold text-slate-900 hover:text-dashboard-primary dark:text-white dark:hover:text-dashboard-primary transition-colors">
                        {u.email}
                      </Link>
                      <div className="text-xs text-slate-500 dark:text-slate-400">{u.phone}</div>
                    </td>
                    <td className="px-4 py-3">{u.fullName || '-'}</td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">{roleLabel(u.role)}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold ${u.status === 'ACTIVE' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'}`}>
                        {statusLabel(u.status)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-500 dark:text-slate-400">{format(new Date(u.createdAt), 'yyyy-MM-dd')}</td>
                    <td className="px-4 py-3 text-right space-x-2">
                      <button
                        className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        onClick={() => openEdit(u)}
                      >
                        {t('admin.users.buttons.edit')}
                      </button>
                      <button
                        className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        onClick={() => openResetPassword(u.id)}
                      >
                        {t('admin.users.buttons.reset')}
                      </button>
                      <button
                        className="rounded-lg border border-red-200 px-3 py-1.5 text-sm text-red-600 transition hover:bg-red-50 dark:border-red-700 dark:text-red-300 dark:hover:bg-red-900/20"
                        onClick={() => handleDeleteClick(u.id)}
                      >
                        {t('admin.users.buttons.delete')}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="flex flex-col gap-3 border-t border-slate-200 bg-slate-50 px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900 sm:flex-row sm:items-center sm:justify-between">
          <div className="text-slate-600 dark:text-slate-300">
            {t('admin.users.pagination.summary', { from: (page - 1) * pageSize + 1, to: Math.min(total, page * pageSize), total })}
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <button
              className="h-9 rounded-md border border-slate-200 px-3 text-sm text-slate-700 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200"
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
            >
              {t('admin.users.pagination.prev')}
            </button>
            <span className="text-slate-700 dark:text-slate-200">{page} / {totalPages}</span>
            <button
              className="h-9 rounded-md border border-slate-200 px-3 text-sm text-slate-700 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200"
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
            >
              {t('admin.users.pagination.next')}
            </button>
            <select
              className="h-9 rounded-md border border-slate-200 bg-white px-2 text-sm dark:border-slate-700 dark:bg-slate-900"
              value={pageSize}
              onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}
            >
              {[10, 20, 50].map((s) => <option key={s} value={s}>{s}/page</option>)}
            </select>
          </div>
        </div>
      </div>

      <UserFormModal
        isOpen={showForm}
        onClose={() => setShowForm(false)}
        onSuccess={handleSuccess}
        editingId={editingId}
        initialData={selectedUser}
      />

      {editingId && (
        <ResetPasswordModal
          isOpen={showReset}
          onClose={() => setShowReset(false)}
          userId={editingId}
        />
      )}

      <ConfirmModal
        isOpen={showDeleteModal}
        onClose={() => setShowDeleteModal(false)}
        onConfirm={handleConfirmDelete}
        title={t('modal.confirmDelete.title')}
        message={t('modal.confirmDelete.message', { item: t('modal.confirmDelete.user') })}
        confirmText={t('modal.delete')}
        cancelText={t('modal.cancel')}
        variant="danger"
        isLoading={isDeleting}
      />
    </AdminLayout>
  );
};

export default UsersPage;

