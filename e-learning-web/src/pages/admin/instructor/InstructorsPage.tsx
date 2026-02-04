import { Link } from 'react-router-dom';
import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { instructorApi, type InstructorDto, type InstructorStatus } from '../../../services/instructorApi';
import { format } from 'date-fns';
import InstructorFormModal from './components/InstructorFormModal';
import { userApi } from '../../../services/userApi';
import ConfirmModal from '../../../components/ui/Modal/ConfirmModal';
import { useToast } from '../../../contexts/ToastContext';

const statuses: InstructorStatus[] = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

const InstructorsPage: React.FC = () => {
    const { t } = useTranslation();
    const { showToast } = useToast();
    const [data, setData] = useState<InstructorDto[]>([]);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    // Modals state
    const [showForm, setShowForm] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [selectedInstructor, setSelectedInstructor] = useState<InstructorDto | null>(null);

    // Delete Modal State
    const [showDeleteModal, setShowDeleteModal] = useState(false);
    const [deletingId, setDeletingId] = useState<string | null>(null);
    const [isDeleting, setIsDeleting] = useState(false);

    const totalPages = useMemo(() => Math.max(1, Math.ceil(total / pageSize)), [total, pageSize]);

    const statusLabel = (value: InstructorStatus) => t(`admin.instructors.statuses.${value}`);

    useEffect(() => {
        void load();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [page, pageSize, statusFilter]);

    const load = async () => {
        try {
            setLoading(true);
            const res = await instructorApi.getPaged({ search, status: statusFilter, page, pageSize });
            setData(res.items);
            setTotal(res.total);
        } catch (err: any) {
            setError(err.message || t('admin.instructors.errors.loadFailed'));
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
        setSelectedInstructor(null);
        setShowForm(true);
    };

    const openEdit = (instructor: InstructorDto) => {
        setEditingId(instructor.id);
        setSelectedInstructor(instructor);
        setShowForm(true);
    };

    const handleDeleteClick = (id: string) => {
        setDeletingId(id);
        setShowDeleteModal(true);
    };

    const handleConfirmDelete = async () => {
        if (!deletingId) return;

        setIsDeleting(true);
        try {
            await instructorApi.delete(deletingId);
            showToast(t('notifications.success.deleteSuccess'), 'success');
            setShowDeleteModal(false);
            await load();
        } catch (err: any) {
            showToast(err.message || t('admin.instructors.errors.deleteFailed'), 'error');
        } finally {
            setIsDeleting(false);
        }
    };

    const openResetPassword = async (id: string) => {
        const newPassword = prompt(t('admin.instructors.resetPasswordPrompt'));
        if (!newPassword) return;
        if (newPassword.length < 8) {
            alert(t('admin.instructors.errors.passwordLength'));
            return;
        }
        try {
            await userApi.resetPassword(id, { newPassword });
            alert(t('admin.instructors.resetPasswordSuccess'));
        } catch (err: any) {
            setError(err.message || t('admin.instructors.errors.resetFailed'));
        }
    };

    const handleSuccess = async () => {
        await load();
    };

    return (
        <AdminLayout>
            <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{t('admin.instructors.title')}</h1>
                    <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.instructors.subtitle')}</p>
                </div>
                <button
                    onClick={openCreate}
                    className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark"
                >
                    <span className="material-symbols-outlined text-[18px]">add</span>
                    {t('admin.instructors.new')}
                </button>
            </div>

            {error && (
                <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
                    {error}
                </div>
            )}

            <form onSubmit={handleSearch} className="mb-4 flex flex-wrap items-center gap-3">
                <input
                    className="w-full max-w-sm rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                    placeholder={t('admin.instructors.searchPlaceholder')}
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                />
                <select
                    className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                >
                    <option value="">{t('admin.instructors.filters.statusAll')}</option>
                    {statuses.map((s) => (
                        <option key={s} value={s}>{statusLabel(s)}</option>
                    ))}
                </select>
                <button
                    type="submit"
                    className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                >
                    <span className="material-symbols-outlined text-[18px]">search</span>
                    {t('admin.instructors.buttons.search')}
                </button>
            </form>

            <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
                <div className="overflow-x-auto">
                    <table className="min-w-full text-left text-sm">
                        <thead className="bg-slate-50 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                            <tr>
                                <th className="px-4 py-3 font-semibold">{t('admin.instructors.table.email')}</th>
                                <th className="px-4 py-3 font-semibold">{t('admin.instructors.table.name')}</th>
                                <th className="px-4 py-3 font-semibold">{t('admin.instructors.table.courses')}</th>
                                <th className="px-4 py-3 font-semibold">{t('admin.instructors.table.students')}</th>
                                <th className="px-4 py-3 font-semibold">{t('admin.instructors.table.status')}</th>
                                <th className="px-4 py-3 font-semibold">{t('admin.instructors.table.created')}</th>
                                <th className="px-4 py-3 font-semibold text-right">{t('admin.instructors.table.actions')}</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr><td className="px-4 py-4" colSpan={7}>{t('admin.instructors.table.loading')}</td></tr>
                            ) : data.length === 0 ? (
                                <tr><td className="px-4 py-4 text-slate-500" colSpan={7}>{t('admin.instructors.table.noData')}</td></tr>
                            ) : (
                                data.map((instructor) => (
                                    <tr key={instructor.id} className="border-t border-slate-100 dark:border-slate-800">
                                        <td className="px-4 py-3">
                                            <Link to={`/admin/instructors/${instructor.id}`} className="font-semibold text-slate-900 hover:text-dashboard-primary dark:text-white dark:hover:text-dashboard-primary transition-colors">
                                                {instructor.email}
                                            </Link>
                                            {instructor.phone && <div className="text-xs text-slate-500 dark:text-slate-400">{instructor.phone}</div>}
                                        </td>
                                        <td className="px-4 py-3">{instructor.fullName || '-'}</td>
                                        <td className="px-4 py-3">
                                            <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-1 text-xs font-semibold text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
                                                {instructor.totalCourses}
                                            </span>
                                        </td>
                                        <td className="px-4 py-3">
                                            <span className="inline-flex items-center gap-1 rounded-full bg-purple-100 px-2 py-1 text-xs font-semibold text-purple-700 dark:bg-purple-900/30 dark:text-purple-300">
                                                {instructor.totalStudents}
                                            </span>
                                        </td>
                                        <td className="px-4 py-3">
                                            <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold ${instructor.status === 'ACTIVE' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'}`}>
                                                {statusLabel(instructor.status)}
                                            </span>
                                        </td>
                                        <td className="px-4 py-3 text-slate-500 dark:text-slate-400">{format(new Date(instructor.createdAt), 'yyyy-MM-dd')}</td>
                                        <td className="px-4 py-3 text-right space-x-2">
                                            <button
                                                className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                                                onClick={() => openEdit(instructor)}
                                            >
                                                {t('admin.instructors.buttons.edit')}
                                            </button>
                                            <button
                                                className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                                                onClick={() => openResetPassword(instructor.id)}
                                            >
                                                {t('admin.instructors.buttons.reset')}
                                            </button>
                                            <button
                                                className="rounded-lg border border-red-200 px-3 py-1.5 text-sm text-red-600 transition hover:bg-red-50 dark:border-red-700 dark:text-red-300 dark:hover:bg-red-900/20"
                                                onClick={() => handleDeleteClick(instructor.id)}
                                            >
                                                {t('admin.instructors.buttons.delete')}
                                            </button>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>

                <div className="flex flex-wrap items-center justify-between gap-3 border-t border-slate-200 bg-slate-50 px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                    <div className="text-slate-600 dark:text-slate-300">
                        {t('admin.instructors.pagination.summary', { from: (page - 1) * pageSize + 1, to: Math.min(total, page * pageSize), total })}
                    </div>
                    <div className="flex items-center gap-2">
                        <button
                            className="rounded-md border border-slate-200 px-3 py-1 text-sm text-slate-700 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200"
                            onClick={() => setPage((p) => Math.max(1, p - 1))}
                            disabled={page === 1}
                        >
                            {t('admin.instructors.pagination.prev')}
                        </button>
                        <span className="text-slate-700 dark:text-slate-200">{page} / {totalPages}</span>
                        <button
                            className="rounded-md border border-slate-200 px-3 py-1 text-sm text-slate-700 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200"
                            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                            disabled={page >= totalPages}
                        >
                            {t('admin.instructors.pagination.next')}
                        </button>
                        <select
                            className="rounded-md border border-slate-200 bg-white px-2 py-1 text-sm dark:border-slate-700 dark:bg-slate-900"
                            value={pageSize}
                            onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}
                        >
                            {[10, 20, 50].map((s) => <option key={s} value={s}>{s}/page</option>)}
                        </select>
                    </div>
                </div>
            </div>

            <InstructorFormModal
                isOpen={showForm}
                onClose={() => setShowForm(false)}
                onSuccess={handleSuccess}
                editingId={editingId}
                initialData={selectedInstructor}
            />

            <ConfirmModal
                isOpen={showDeleteModal}
                onClose={() => setShowDeleteModal(false)}
                onConfirm={handleConfirmDelete}
                title={t('modal.confirmDelete.title')}
                message={t('modal.confirmDelete.message', { item: t('modal.confirmDelete.instructor') })}
                confirmText={t('modal.delete')}
                cancelText={t('modal.cancel')}
                variant="danger"
                isLoading={isDeleting}
            />
        </AdminLayout>
    );
};

export default InstructorsPage;
