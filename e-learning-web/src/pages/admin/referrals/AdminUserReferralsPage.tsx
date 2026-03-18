import React, { useCallback, useEffect, useMemo, useState } from 'react';
import AdminLayout from '../../../components/admin/AdminLayout';
import { useToast } from '../../../contexts/ToastContext';
import { userReferralApi, type AdminUserReferralItemDto } from '../../../services/userReferralApi';

type StatusFilter = 'all' | 'active' | 'inactive';

interface EditFormState {
  discountCode: string;
  discountPercent: string;
  isActive: boolean;
}

const initialFormState: EditFormState = {
  discountCode: '',
  discountPercent: '5',
  isActive: true,
};

const AdminUserReferralsPage: React.FC = () => {
  const { showToast } = useToast();

  const [items, setItems] = useState<AdminUserReferralItemDto[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [bulkDiscountPercent, setBulkDiscountPercent] = useState('5');
  const [bulkSubmitting, setBulkSubmitting] = useState(false);

  const [editingItem, setEditingItem] = useState<AdminUserReferralItemDto | null>(null);
  const [editForm, setEditForm] = useState<EditFormState>(initialFormState);
  const [submitting, setSubmitting] = useState(false);

  const totalPages = useMemo(() => Math.max(1, Math.ceil(total / pageSize)), [total, pageSize]);
  const selectedCount = selectedIds.size;
  const allCurrentPageSelected = useMemo(
    () => items.length > 0 && items.every((item) => selectedIds.has(item.id)),
    [items, selectedIds]
  );

  const formatDateTime = (value: string) =>
    new Date(value).toLocaleString('vi-VN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });

  const formatCurrency = (value: number) =>
    `${value.toLocaleString('vi-VN', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    })} VND`;

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const result = await userReferralApi.getAdminPaged({
        search: search || undefined,
        isActive: statusFilter === 'all' ? undefined : statusFilter === 'active',
        page,
        pageSize,
      });

      setItems(result.items);
      setTotal(result.total);
      setSelectedIds((prev) => {
        const currentPageIds = new Set(result.items.map((item) => item.id));
        const next = new Set<string>();

        prev.forEach((id) => {
          if (currentPageIds.has(id)) {
            next.add(id);
          }
        });

        return next;
      });
    } catch (err: any) {
      const message = err?.message || 'Không thể tải danh sách mã giới thiệu người dùng.';
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, search, statusFilter]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const handleSearchSubmit = (event: React.FormEvent) => {
    event.preventDefault();
    const nextSearch = searchInput.trim();

    if (page !== 1) {
      setPage(1);
    }

    if (nextSearch !== search) {
      setSearch(nextSearch);
      return;
    }

    if (page === 1) {
      void loadData();
    }
  };

  const handleStatusChange = (value: StatusFilter) => {
    setStatusFilter(value);
    setPage(1);
    setSelectedIds(new Set());
  };

  const openEdit = (item: AdminUserReferralItemDto) => {
    setEditingItem(item);
    setEditForm({
      discountCode: item.discountCode,
      discountPercent: String(item.discountPercent),
      isActive: item.isActive,
    });
  };

  const closeEdit = () => {
    if (submitting) {
      return;
    }

    setEditingItem(null);
    setEditForm(initialFormState);
  };

  const handleSaveEdit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!editingItem) {
      return;
    }

    const discountCode = editForm.discountCode.trim().toUpperCase();
    const discountPercent = Number(editForm.discountPercent);

    if (!discountCode) {
      showToast('Vui lòng nhập mã giảm giá.', 'error');
      return;
    }

    if (Number.isNaN(discountPercent) || discountPercent < 0 || discountPercent > 100) {
      showToast('Phần trăm giảm giá phải nằm trong khoảng 0-100.', 'error');
      return;
    }

    try {
      setSubmitting(true);
      await userReferralApi.updateByAdmin(editingItem.id, {
        discountCode,
        discountPercent,
        isActive: editForm.isActive,
      });

      showToast('Đã cập nhật mã giảm giá thành công.', 'success');
      closeEdit();
      await loadData();
    } catch (err: any) {
      showToast(err?.message || 'Không thể cập nhật mã giảm giá.', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const handleRegenerateDiscountCode = async (item: AdminUserReferralItemDto) => {
    if (!window.confirm(`Tạo lại mã giảm giá cho ${item.userEmail}?`)) {
      return;
    }

    try {
      await userReferralApi.regenerateDiscountCode(item.id);
      showToast('Đã tạo mã giảm giá mới.', 'success');
      await loadData();
    } catch (err: any) {
      showToast(err?.message || 'Không thể tạo lại mã giảm giá.', 'error');
    }
  };

  const handleCopy = async (value: string) => {
    try {
      await navigator.clipboard.writeText(value);
      showToast('Đã sao chép mã.', 'success');
    } catch {
      showToast('Không thể sao chép tự động. Vui lòng sao chép thủ công.', 'error');
    }
  };

  const toggleItemSelection = (itemId: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(itemId)) {
        next.delete(itemId);
      } else {
        next.add(itemId);
      }
      return next;
    });
  };

  const toggleSelectAllCurrentPage = () => {
    setSelectedIds((prev) => {
      const next = new Set(prev);

      if (allCurrentPageSelected) {
        items.forEach((item) => next.delete(item.id));
      } else {
        items.forEach((item) => next.add(item.id));
      }

      return next;
    });
  };

  const clearSelection = () => {
    setSelectedIds(new Set());
  };

  const handleBulkUpdateDiscountPercent = async () => {
    if (selectedCount === 0) {
      showToast('Bạn chưa chọn mã nào để cập nhật hàng loạt.', 'error');
      return;
    }

    const discountPercent = Number(bulkDiscountPercent);
    if (Number.isNaN(discountPercent) || discountPercent < 0 || discountPercent > 100) {
      showToast('Phần trăm giảm giá phải nằm trong khoảng 0-100.', 'error');
      return;
    }

    try {
      setBulkSubmitting(true);
      const response = await userReferralApi.bulkUpdateDiscountPercentByAdmin({
        referralIds: Array.from(selectedIds),
        discountPercent,
      });

      showToast(
        `Đã cập nhật ${response.updatedCount}/${response.requestedCount} mã sang ${response.discountPercent}%.`,
        'success'
      );

      clearSelection();
      await loadData();
    } catch (err: any) {
      showToast(err?.message || 'Không thể cập nhật hàng loạt phần trăm giảm giá.', 'error');
    } finally {
      setBulkSubmitting(false);
    }
  };

  const getAverageRevenuePerSuccess = (item: AdminUserReferralItemDto) => {
    if (item.successfulInvites <= 0 || item.referredPaidRevenue <= 0) {
      return 0;
    }

    return item.referredPaidRevenue / item.successfulInvites;
  };

  return (
    <AdminLayout>
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Quản lý mã giảm giá chia sẻ</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Quản lý toàn bộ mã referral và mã giảm giá của user trong hệ thống.
          </p>
        </div>
      </div>

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
          {error}
        </div>
      )}

      <form onSubmit={handleSearchSubmit} className="mb-4 grid grid-cols-1 gap-3 md:grid-cols-[minmax(0,1fr)_200px_auto]">
        <input
          value={searchInput}
          onChange={(event) => setSearchInput(event.target.value)}
          placeholder="Tìm theo email, tên user, referral code hoặc discount code"
          className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
        />

        <select
          value={statusFilter}
          onChange={(event) => handleStatusChange(event.target.value as StatusFilter)}
          className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
        >
          <option value="all">Tất cả trạng thái</option>
          <option value="active">Đang hoạt động</option>
          <option value="inactive">Ngưng hoạt động</option>
        </select>

        <button
          type="submit"
          className="inline-flex h-10 w-full md:w-auto items-center justify-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
        >
          <span className="material-symbols-outlined text-[18px]">search</span>
          Tìm kiếm
        </button>
      </form>

      <div className="mb-4 rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-sm font-semibold text-slate-900 dark:text-white">Cập nhật hàng loạt % giảm giá</p>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Đã chọn <span className="font-semibold text-slate-700 dark:text-slate-200">{selectedCount}</span> mã trên trang hiện tại.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
              onClick={toggleSelectAllCurrentPage}
              disabled={items.length === 0 || loading}
            >
              {allCurrentPageSelected ? 'Bỏ chọn trang này' : 'Chọn tất cả trang này'}
            </button>

            <input
              type="number"
              min={0}
              max={100}
              step="0.1"
              value={bulkDiscountPercent}
              onChange={(event) => setBulkDiscountPercent(event.target.value)}
              className="w-28 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
              placeholder="% giảm"
            />

            <button
              type="button"
              className="rounded-lg bg-dashboard-primary px-3 py-2 text-sm font-semibold text-white transition hover:bg-dashboard-primary-dark disabled:cursor-not-allowed disabled:opacity-60"
              onClick={handleBulkUpdateDiscountPercent}
              disabled={selectedCount === 0 || bulkSubmitting || loading}
            >
              {bulkSubmitting ? 'Đang cập nhật...' : 'Áp dụng hàng loạt'}
            </button>

            <button
              type="button"
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
              onClick={clearSelection}
              disabled={selectedCount === 0 || bulkSubmitting}
            >
              Bỏ chọn
            </button>
          </div>
        </div>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
        <div className="divide-y divide-slate-100 dark:divide-slate-800 md:hidden">
          {loading ? (
            <div className="px-4 py-6 text-sm text-slate-500 dark:text-slate-300">Đang tải dữ liệu...</div>
          ) : items.length === 0 ? (
            <div className="px-4 py-6 text-sm text-slate-500 dark:text-slate-300">Không có dữ liệu.</div>
          ) : (
            items.map((item) => (
              <div key={item.id} className="space-y-3 p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-slate-900 dark:text-white">{item.userName || 'Chưa cập nhật tên'}</p>
                    <p className="mt-1 truncate text-xs text-slate-500 dark:text-slate-400">{item.userEmail}</p>
                  </div>

                  <label className="inline-flex items-center gap-2 text-xs text-slate-600 dark:text-slate-300">
                    <input
                      type="checkbox"
                      checked={selectedIds.has(item.id)}
                      onChange={() => toggleItemSelection(item.id)}
                      className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                    />
                    Chọn
                  </label>
                </div>

                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="rounded-lg bg-slate-50 p-2 dark:bg-slate-800">
                    <p className="text-slate-500">Referral</p>
                    <p className="mt-1 font-semibold text-slate-900 dark:text-white">{item.referralCode}</p>
                  </div>
                  <div className="rounded-lg bg-slate-50 p-2 dark:bg-slate-800">
                    <p className="text-slate-500">Discount</p>
                    <p className="mt-1 font-semibold text-slate-900 dark:text-white">{item.discountCode}</p>
                  </div>
                </div>

                <div className="rounded-lg border border-slate-200 bg-slate-50 p-2 text-xs dark:border-slate-700 dark:bg-slate-800">
                  <p className="text-slate-500">Doanh thu theo mã</p>
                  <p className="mt-1 font-semibold text-slate-900 dark:text-white">{formatCurrency(item.referredPaidRevenue)}</p>
                  <p className="mt-1 text-slate-600 dark:text-slate-300">
                    Đơn PAID: {item.referredPaidOrderCount} | TB/ref thành công: {formatCurrency(getAverageRevenuePerSuccess(item))}
                  </p>
                </div>

                <div className="flex flex-wrap items-center gap-2">
                  <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                    {item.discountPercent}%
                  </span>
                  <span
                    className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold ${
                      item.isActive
                        ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
                        : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'
                    }`}
                  >
                    {item.isActive ? 'Hoạt động' : 'Ngưng hoạt động'}
                  </span>
                  <span className="text-xs text-slate-500 dark:text-slate-400">
                    Mời: {item.totalInvites} | Thành công: {item.successfulInvites}
                  </span>
                </div>

                <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
                  <button
                    className="h-10 rounded-lg border border-slate-200 px-3 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    onClick={() => openEdit(item)}
                  >
                    Chỉnh sửa
                  </button>
                  <button
                    className="h-10 rounded-lg border border-slate-200 px-3 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    onClick={() => handleCopy(item.discountCode)}
                  >
                    Sao chép mã
                  </button>
                  <button
                    className="h-10 rounded-lg border border-blue-200 px-3 text-sm text-blue-700 transition hover:bg-blue-50 dark:border-blue-800 dark:text-blue-300 dark:hover:bg-blue-900/20"
                    onClick={() => handleRegenerateDiscountCode(item)}
                  >
                    Tạo mã mới
                  </button>
                </div>
              </div>
            ))
          )}
        </div>

        <div className="hidden overflow-x-auto md:block">
          <table className="min-w-[1350px] w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
              <tr>
                <th className="px-4 py-3 font-semibold">
                  <input
                    type="checkbox"
                    checked={allCurrentPageSelected}
                    onChange={toggleSelectAllCurrentPage}
                    className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                    aria-label="Select all rows on current page"
                  />
                </th>
                <th className="px-4 py-3 font-semibold">User</th>
                <th className="px-4 py-3 font-semibold">Referral Code</th>
                <th className="px-4 py-3 font-semibold">Discount Code</th>
                <th className="px-4 py-3 font-semibold">Ưu đãi</th>
                <th className="px-4 py-3 font-semibold">Hiệu suất mời</th>
                <th className="px-4 py-3 font-semibold">Doanh thu theo mã</th>
                <th className="px-4 py-3 font-semibold">Cập nhật</th>
                <th className="px-4 py-3 font-semibold text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td className="px-4 py-4" colSpan={9}>
                    Đang tải dữ liệu...
                  </td>
                </tr>
              ) : items.length === 0 ? (
                <tr>
                  <td className="px-4 py-4 text-slate-500" colSpan={9}>
                    Không có dữ liệu.
                  </td>
                </tr>
              ) : (
                items.map((item) => (
                  <tr key={item.id} className="border-t border-slate-100 dark:border-slate-800">
                    <td className="px-4 py-3">
                      <input
                        type="checkbox"
                        checked={selectedIds.has(item.id)}
                        onChange={() => toggleItemSelection(item.id)}
                        className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                        aria-label={`Select referral row ${item.discountCode}`}
                      />
                    </td>
                    <td className="px-4 py-3">
                      <p className="font-semibold text-slate-900 dark:text-white">{item.userName || 'Chưa cập nhật tên'}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{item.userEmail}</p>
                    </td>
                    <td className="px-4 py-3">
                      <span className="rounded-md bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                        {item.referralCode}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <span className="rounded-md bg-emerald-100 px-2 py-1 text-xs font-semibold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300">
                          {item.discountCode}
                        </span>
                        <button
                          className="rounded-md border border-slate-200 px-2 py-1 text-xs text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                          onClick={() => handleCopy(item.discountCode)}
                        >
                          Copy
                        </button>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-1">
                        <span className="text-sm font-semibold text-slate-900 dark:text-white">{item.discountPercent}%</span>
                        <span
                          className={`inline-flex w-fit items-center rounded-full px-2 py-0.5 text-xs font-semibold ${
                            item.isActive
                              ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
                              : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'
                          }`}
                        >
                          {item.isActive ? 'Hoạt động' : 'Ngưng hoạt động'}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-600 dark:text-slate-300">
                      <p>Tổng mời: {item.totalInvites}</p>
                      <p>Thành công: {item.successfulInvites}</p>
                      <p>Đang chờ: {item.pendingInvites}</p>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-600 dark:text-slate-300">
                      <p>Đơn PAID: {item.referredPaidOrderCount}</p>
                      <p>Doanh thu: {formatCurrency(item.referredPaidRevenue)}</p>
                      <p>TB/ref thành công: {formatCurrency(getAverageRevenuePerSuccess(item))}</p>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-500 dark:text-slate-400">{formatDateTime(item.updatedAt)}</td>
                    <td className="px-4 py-3 text-right space-x-2">
                      <button
                        className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        onClick={() => openEdit(item)}
                      >
                        Chỉnh sửa
                      </button>
                      <button
                        className="rounded-lg border border-blue-200 px-3 py-1.5 text-sm text-blue-700 transition hover:bg-blue-50 dark:border-blue-800 dark:text-blue-300 dark:hover:bg-blue-900/20"
                        onClick={() => handleRegenerateDiscountCode(item)}
                      >
                        Tạo mã mới
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-slate-500 dark:text-slate-400">
          Tổng: <span className="font-semibold text-slate-700 dark:text-slate-200">{total}</span> mã
        </p>

        <div className="inline-flex items-center gap-2">
          <button
            className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
            onClick={() => setPage((prev) => Math.max(1, prev - 1))}
            disabled={page <= 1 || loading}
          >
            Trước
          </button>
          <span className="text-sm text-slate-600 dark:text-slate-300">
            Trang {page}/{totalPages}
          </span>
          <button
            className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
            onClick={() => setPage((prev) => Math.min(totalPages, prev + 1))}
            disabled={page >= totalPages || loading}
          >
            Sau
          </button>
        </div>
      </div>

      {editingItem && (
        <div className="fixed inset-0 z-[90] flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-5 shadow-2xl dark:bg-slate-900">
            <div className="mb-4">
              <h2 className="text-lg font-bold text-slate-900 dark:text-white">Chỉnh sửa mã giảm giá</h2>
              <p className="text-sm text-slate-500 dark:text-slate-400">{editingItem.userEmail}</p>
            </div>

            <form onSubmit={handleSaveEdit} className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-200">Mã giảm giá</label>
                <input
                  value={editForm.discountCode}
                  onChange={(event) =>
                    setEditForm((prev) => ({
                      ...prev,
                      discountCode: event.target.value.toUpperCase(),
                    }))
                  }
                  className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm uppercase focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                  placeholder="INV-ABCDEFGH"
                />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-200">Phần trăm giảm (%)</label>
                <input
                  type="number"
                  min={0}
                  max={100}
                  step="0.1"
                  value={editForm.discountPercent}
                  onChange={(event) => setEditForm((prev) => ({ ...prev, discountPercent: event.target.value }))}
                  className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                />
              </div>

              <label className="inline-flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200">
                <input
                  type="checkbox"
                  checked={editForm.isActive}
                  onChange={(event) => setEditForm((prev) => ({ ...prev, isActive: event.target.checked }))}
                  className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                />
                Kích hoạt mã referral này
              </label>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={closeEdit}
                  disabled={submitting}
                  className="rounded-lg border border-slate-200 px-4 py-2 text-sm text-slate-700 transition hover:bg-slate-100 disabled:opacity-60 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white transition hover:bg-dashboard-primary-dark disabled:opacity-60"
                >
                  {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AdminLayout>
  );
};

export default AdminUserReferralsPage;