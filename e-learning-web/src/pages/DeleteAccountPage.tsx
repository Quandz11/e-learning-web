import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import type { AppDispatch, RootState } from '../store/store';
import { logout } from '../store/authSlice';
import { authApi } from '../services/authApi';
import { clearAuth } from '../services/authStorage';
import { profileApi } from '../services/profileApi';
import { useToast } from '../contexts/ToastContext';

const DeleteAccountPage: React.FC = () => {
    const { i18n } = useTranslation();
    const dispatch = useDispatch<AppDispatch>();
    const { showToast } = useToast();
    const { user, isAuthenticated } = useSelector((state: RootState) => state.auth);

    const isVi = i18n.language !== 'en';

    // Public form states
    const [identifier, setIdentifier] = useState('');
    const [password, setPassword] = useState('');
    const [reason, setReason] = useState('Chưa có nhu cầu tiếp tục');
    const [customReason, setCustomReason] = useState('');
    const [confirmed, setConfirmed] = useState(false);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [result, setResult] = useState<{
        success: boolean;
        message: string;
        isDeletedImmediately: boolean;
    } | null>(null);

    // Modal state for logged in user
    const [showConfirmModal, setShowConfirmModal] = useState(false);

    // Handle deletion for logged in user
    const handleLoggedInDelete = async () => {
        try {
            setIsSubmitting(true);
            const res = await profileApi.deleteMyAccount();
            showToast(res.message || (isVi ? 'Tài khoản của bạn đã được xóa thành công.' : 'Account deleted successfully.'), 'success');
            
            // Clean up session
            try {
                await authApi.logout();
            } catch {
                // Ignore logout network error on deleted account
            }
            authApi.setAccessToken(null);
            clearAuth();
            dispatch(logout());

            setResult({
                success: true,
                message: res.message || (isVi ? 'Tài khoản của bạn đã được xóa thành công.' : 'Your account has been deleted.'),
                isDeletedImmediately: true
            });
            setShowConfirmModal(false);
        } catch (err: any) {
            console.error('Failed to delete account:', err);
            const msg = err?.message || (isVi ? 'Không thể xóa tài khoản. Vui lòng thử lại sau.' : 'Failed to delete account.');
            showToast(msg, 'error');
        } finally {
            setIsSubmitting(false);
        }
    };

    // Handle deletion / request for public visitor
    const handlePublicSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!identifier.trim()) {
            showToast(isVi ? 'Vui lòng nhập email hoặc số điện thoại.' : 'Please enter your email or phone number.', 'warning');
            return;
        }

        if (!confirmed) {
            showToast(isVi ? 'Vui lòng tích xác nhận bạn đã hiểu rủi ro mất dữ liệu.' : 'Please confirm that you understand the risk of data loss.', 'warning');
            return;
        }

        const finalReason = reason === 'Khác' ? customReason.trim() : reason;

        try {
            setIsSubmitting(true);
            const res = await profileApi.requestPublicDeleteAccount({
                emailOrPhone: identifier.trim(),
                password: password.trim() || undefined,
                reason: finalReason || undefined
            });

            setResult({
                success: true,
                message: res.message,
                isDeletedImmediately: res.isDeletedImmediately
            });
            showToast(res.message, 'success');
        } catch (err: any) {
            console.error('Account deletion request failed:', err);
            const msg = err?.message || (isVi ? 'Đã có lỗi xảy ra. Vui lòng thử lại.' : 'An error occurred. Please try again.');
            showToast(msg, 'error');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="min-h-screen bg-[#f0f4f3] text-[#0f2a24] relative z-0 overflow-hidden py-12 sm:py-16 px-4 sm:px-6 lg:px-8">
            {/* Mesh Background */}
            <div
                className="absolute inset-0 -z-10 opacity-20"
                style={{
                    backgroundImage: `
                        radial-gradient(at 0% 0%, hsla(164,72%,16%,1) 0, transparent 50%), 
                        radial-gradient(at 100% 0%, hsla(145,63%,42%,1) 0, transparent 50%), 
                        radial-gradient(at 100% 100%, hsla(158,54%,95%,1) 0, transparent 50%), 
                        radial-gradient(at 0% 100%, hsla(160,84%,12%,1) 0, transparent 50%)
                    `,
                    backgroundColor: '#f0f7f4'
                }}
            />

            <div className="container mx-auto max-w-3xl">
                {/* Header Badge */}
                <div className="text-center mb-8 sm:mb-10">
                    <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-emerald-100 text-emerald-800 text-xs font-semibold uppercase tracking-wider mb-4 shadow-sm border border-emerald-200">
                        <span className="material-symbols-outlined text-base">verified_user</span>
                        <span>{isVi ? 'Quyền Riêng Tư & Bảo Vệ Dữ Liệu' : 'Privacy & Data Protection'}</span>
                    </div>
                    <h1 className="text-3xl sm:text-4xl md:text-5xl font-extrabold tracking-tight bg-gradient-to-r from-[#0F5B38] to-[#2ecc71] bg-clip-text text-transparent">
                        {isVi ? 'Xóa Tài Khoản & Dữ Liệu' : 'Delete Account & Data'}
                    </h1>
                    <p className="mt-3 text-sm sm:text-base text-gray-600 max-w-xl mx-auto leading-relaxed">
                        {isVi
                            ? 'Chúng tôi tôn trọng quyền riêng tư của bạn theo chính sách người dùng của Google Play Store & Apple App Store.'
                            : 'We respect your privacy in accordance with Google Play Store & Apple App Store user data policies.'}
                    </p>
                </div>

                {/* Main Card */}
                <div className="bg-white/90 backdrop-blur-md border border-white/60 rounded-3xl p-6 sm:p-10 shadow-lg transition-all">
                    {/* Important Alert Box */}
                    <div className="flex items-start gap-3.5 bg-red-50 border border-red-200 rounded-2xl p-4 sm:p-5 text-red-900 mb-8 text-xs sm:text-sm leading-relaxed">
                        <span className="material-symbols-outlined text-red-600 text-2xl flex-shrink-0">warning</span>
                        <div>
                            <strong className="font-bold text-red-800 block mb-1">
                                {isVi ? 'CẢNH BÁO QUAN TRỌNG:' : 'IMPORTANT WARNING:'}
                            </strong>
                            <span>
                                {isVi
                                    ? 'Hành động này không thể hoàn tác. Khi tài khoản bị xóa, toàn bộ thông tin cá nhân, hồ sơ sức khỏe, dữ liệu nhật ký nhịn ăn và lịch sử các khóa học đã mua sẽ bị hủy bỏ vĩnh viễn.'
                                    : 'This action cannot be undone. Once deleted, all personal records, wellness logs, fasting trackers, and course access will be permanently erased.'}
                            </span>
                        </div>
                    </div>

                    {/* Result View */}
                    {result ? (
                        <div className="text-center py-6 space-y-4">
                            <div className="inline-flex h-16 w-16 items-center justify-center rounded-full bg-emerald-100 text-emerald-600 text-3xl shadow-sm border border-emerald-200">
                                <span className="material-symbols-outlined text-4xl">check_circle</span>
                            </div>
                            <h2 className="text-2xl font-bold text-gray-900">
                                {result.isDeletedImmediately
                                    ? (isVi ? 'Xóa Tài Khoản Thành Công' : 'Account Deleted Successfully')
                                    : (isVi ? 'Đã Tiếp Nhận Yêu Cầu Xóa Tài Khoản' : 'Deletion Request Received')}
                            </h2>
                            <p className="text-sm text-gray-600 max-w-lg mx-auto leading-relaxed">
                                {result.message}
                            </p>
                            <div className="pt-6 flex flex-wrap justify-center gap-3">
                                <Link
                                    to="/"
                                    className="px-6 py-3 rounded-xl bg-emerald-700 hover:bg-emerald-800 text-white text-sm font-semibold transition shadow-sm"
                                >
                                    {isVi ? 'Quay lại Trang Chủ' : 'Return to Home'}
                                </Link>
                                <Link
                                    to="/privacy"
                                    className="px-6 py-3 rounded-xl border border-gray-300 hover:bg-gray-50 text-gray-700 text-sm font-semibold transition"
                                >
                                    {isVi ? 'Xem Chính Sách Bảo Mật' : 'Privacy Policy'}
                                </Link>
                            </div>
                        </div>
                    ) : isAuthenticated && user ? (
                        /* Logged In View */
                        <div className="space-y-6">
                            <div className="bg-emerald-50/60 border border-emerald-200/80 rounded-2xl p-5 flex flex-col sm:flex-row items-center sm:items-start gap-4">
                                {user.avatarUrl ? (
                                    <img
                                        src={user.avatarUrl}
                                        alt={user.fullName || 'User'}
                                        className="h-16 w-16 rounded-full object-cover border-2 border-white shadow-sm flex-shrink-0"
                                    />
                                ) : (
                                    <div className="h-16 w-16 rounded-full bg-emerald-700 text-white flex items-center justify-center font-bold text-xl flex-shrink-0 shadow-sm">
                                        {(user.fullName || user.email || 'U').charAt(0).toUpperCase()}
                                    </div>
                                )}
                                <div className="text-center sm:text-left flex-1 min-w-0">
                                    <div className="flex items-center justify-center sm:justify-start gap-2">
                                        <h3 className="font-bold text-gray-900 text-base sm:text-lg truncate">
                                            {user.fullName || (isVi ? 'Học viên' : 'Student')}
                                        </h3>
                                        <span className="px-2 py-0.5 rounded-full bg-emerald-200/70 text-emerald-900 text-[11px] font-semibold">
                                            {user.role}
                                        </span>
                                    </div>
                                    <p className="text-xs sm:text-sm text-gray-600 truncate mt-0.5">{user.email}</p>
                                    {user.phone && <p className="text-xs text-gray-500 mt-0.5">SĐT: {user.phone}</p>}
                                    <p className="text-xs text-emerald-700 font-medium mt-2 flex items-center justify-center sm:justify-start gap-1">
                                        <span className="material-symbols-outlined text-sm">lock_open</span>
                                        <span>{isVi ? 'Đang đăng nhập - Có thể xóa ngay tức thì' : 'Logged in - Instant deletion available'}</span>
                                    </p>
                                </div>
                            </div>

                            <div className="border border-gray-200 rounded-2xl p-5 space-y-3 bg-gray-50/70 text-xs sm:text-sm text-gray-600">
                                <p className="font-semibold text-gray-800">
                                    {isVi ? 'Các dữ liệu sẽ bị xóa hoàn toàn khỏi máy chủ:' : 'Data that will be permanently wiped:'}
                                </p>
                                <ul className="list-disc pl-5 space-y-1.5">
                                    <li>{isVi ? 'Hồ sơ cá nhân, ảnh đại diện, email, số điện thoại.' : 'Profile, avatar, email, and contact info.'}</li>
                                    <li>{isVi ? 'Toàn bộ nhật ký nhịn ăn, biểu đồ cân nặng, chỉ số sức khỏe hàng ngày.' : 'All fasting tracker entries and wellness health logs.'}</li>
                                    <li>{isVi ? 'Tiến trình học tập, lịch sử bài học và các câu trả lời trắc nghiệm.' : 'Course progress, video watch history, and quiz submissions.'}</li>
                                    <li>{isVi ? 'Phiên đăng nhập trên ứng dụng di động và thiết bị web.' : 'Active login sessions on mobile and web devices.'}</li>
                                </ul>
                            </div>

                            <div className="pt-2">
                                <button
                                    type="button"
                                    onClick={() => setShowConfirmModal(true)}
                                    className="w-full py-3.5 px-6 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold text-sm transition shadow-sm flex items-center justify-center gap-2"
                                >
                                    <span className="material-symbols-outlined text-lg">delete_forever</span>
                                    <span>{isVi ? 'Xóa Vĩnh Viễn Tài Khoản Này' : 'Permanently Delete This Account'}</span>
                                </button>
                            </div>
                        </div>
                    ) : (
                        /* Not Logged In View */
                        <form onSubmit={handlePublicSubmit} className="space-y-5">
                            <div>
                                <label className="block text-xs sm:text-sm font-semibold text-gray-800 mb-1.5">
                                    {isVi ? 'Email hoặc Số điện thoại đăng ký tài khoản *' : 'Registered Email or Phone Number *'}
                                </label>
                                <div className="relative">
                                    <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-gray-400 pointer-events-none">
                                        <span className="material-symbols-outlined text-lg">person</span>
                                    </span>
                                    <input
                                        type="text"
                                        value={identifier}
                                        onChange={(e) => setIdentifier(e.target.value)}
                                        placeholder={isVi ? 'Ví dụ: hocvien@nhinanchualanh.vn hoặc 0912345678' : 'e.g. user@nhinanchualanh.vn or 0912345678'}
                                        required
                                        className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl text-sm focus:outline-none focus:border-emerald-600 focus:ring-1 focus:ring-emerald-600 transition bg-white"
                                    />
                                </div>
                            </div>

                            <div>
                                <div className="flex items-center justify-between mb-1.5">
                                    <label className="text-xs sm:text-sm font-semibold text-gray-800">
                                        {isVi ? 'Mật khẩu tài khoản (Để xóa tức thì)' : 'Account Password (For instant deletion)'}
                                    </label>
                                    <span className="text-[11px] text-gray-500 italic">
                                        {isVi ? 'Không bắt buộc' : 'Optional'}
                                    </span>
                                </div>
                                <div className="relative">
                                    <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-gray-400 pointer-events-none">
                                        <span className="material-symbols-outlined text-lg">lock</span>
                                    </span>
                                    <input
                                        type="password"
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        placeholder={isVi ? 'Nhập mật khẩu để hệ thống xóa tài khoản ngay lập tức' : 'Enter password for immediate permanent deletion'}
                                        className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl text-sm focus:outline-none focus:border-emerald-600 focus:ring-1 focus:ring-emerald-600 transition bg-white"
                                    />
                                </div>
                                <p className="text-[11px] text-gray-500 mt-1">
                                    {isVi
                                        ? '💡 Nếu bạn quên mật khẩu hoặc đăng nhập bằng OTP, hãy để trống ô này. Yêu cầu của bạn sẽ được gửi tới đội ngũ hỗ trợ để xác minh.'
                                        : '💡 If you forgot your password or registered via OTP, leave this empty to submit a verified manual request.'}
                                </p>
                            </div>

                            <div>
                                <label className="block text-xs sm:text-sm font-semibold text-gray-800 mb-1.5">
                                    {isVi ? 'Lý do bạn muốn xóa tài khoản' : 'Reason for deletion'}
                                </label>
                                <select
                                    value={reason}
                                    onChange={(e) => setReason(e.target.value)}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-xl text-sm focus:outline-none focus:border-emerald-600 focus:ring-1 focus:ring-emerald-600 transition bg-white mb-2"
                                >
                                    <option value="Chưa có nhu cầu tiếp tục">{isVi ? 'Chưa có nhu cầu tiếp tục sử dụng' : 'No longer needed'}</option>
                                    <option value="Đã hoàn thành lộ trình">{isVi ? 'Đã hoàn thành lộ trình thanh lọc chữa lành' : 'Completed health journey'}</option>
                                    <option value="Tạo tài khoản khác">{isVi ? 'Muốn tạo lại tài khoản mới' : 'Want to create a new account'}</option>
                                    <option value="Lý do bảo mật">{isVi ? 'Lý do bảo mật thông tin cá nhân' : 'Privacy / security concern'}</option>
                                    <option value="Khác">{isVi ? 'Lý do khác...' : 'Other reason...'}</option>
                                </select>
                                {reason === 'Khác' && (
                                    <textarea
                                        value={customReason}
                                        onChange={(e) => setCustomReason(e.target.value)}
                                        rows={2}
                                        placeholder={isVi ? 'Hãy chia sẻ thêm với chúng tôi...' : 'Please tell us more...'}
                                        className="w-full px-4 py-2.5 border border-gray-300 rounded-xl text-sm focus:outline-none focus:border-emerald-600 focus:ring-1 focus:ring-emerald-600 transition bg-white"
                                    />
                                )}
                            </div>

                            <div className="bg-gray-50 border border-gray-200 rounded-2xl p-4 text-xs text-gray-600 space-y-2">
                                <p className="font-semibold text-gray-800">
                                    {isVi ? 'Dữ liệu được xử lý xóa:' : 'Data processed for deletion:'}
                                </p>
                                <ul className="list-disc pl-5 space-y-1">
                                    <li>{isVi ? 'Thông tin cá nhân (Email, Họ tên, SĐT).' : 'Personal information (Email, Name, Phone).'}</li>
                                    <li>{isVi ? 'Lịch sử nhật ký sức khỏe và theo dõi nhịn ăn.' : 'Health logs and fasting records.'}</li>
                                    <li>{isVi ? 'Quyền truy cập các khóa học đã đăng ký.' : 'Enrolled course access.'}</li>
                                </ul>
                            </div>

                            <div className="flex items-start gap-2.5 pt-1">
                                <input
                                    type="checkbox"
                                    id="confirmDelete"
                                    checked={confirmed}
                                    onChange={(e) => setConfirmed(e.target.checked)}
                                    className="mt-1 h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500"
                                />
                                <label htmlFor="confirmDelete" className="text-xs text-gray-700 leading-relaxed cursor-pointer select-none">
                                    {isVi
                                        ? 'Tôi xác nhận rằng tôi muốn xóa tài khoản này và hiểu rằng dữ liệu không thể khôi phục sau khi xóa.'
                                        : 'I confirm that I want to delete this account and understand that all data is non-recoverable.'}
                                </label>
                            </div>

                            <button
                                type="submit"
                                disabled={isSubmitting || !confirmed}
                                className="w-full py-3.5 px-6 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold text-sm transition shadow-sm disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                            >
                                {isSubmitting ? (
                                    <>
                                        <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-r-transparent" />
                                        <span>{isVi ? 'Đang xử lý...' : 'Processing...'}</span>
                                    </>
                                ) : (
                                    <>
                                        <span className="material-symbols-outlined text-lg">delete</span>
                                        <span>{isVi ? 'Xác Nhận Xóa Tài Khoản' : 'Confirm Account Deletion'}</span>
                                    </>
                                )}
                            </button>

                            <div className="text-center pt-2">
                                <Link to="/login" className="text-xs text-emerald-700 hover:text-emerald-800 font-medium">
                                    {isVi ? '👉 Bạn đã có tài khoản? Đăng nhập tại đây' : '👉 Already have an account? Sign in here'}
                                </Link>
                            </div>
                        </form>
                    )}

                    {/* App guide footnote */}
                    <div className="mt-8 pt-6 border-t border-gray-200 text-center text-xs text-gray-500 space-y-1">
                        <p className="font-medium text-gray-700">
                            {isVi ? '📱 Thao tác xóa trực tiếp trên ứng dụng di động:' : '📱 Delete directly in the mobile app:'}
                        </p>
                        <p>
                            {isVi
                                ? 'Mở App Nhịn Ăn Chữa Lành > Cá nhân > Cài đặt & Bảo mật > Xóa tài khoản vĩnh viễn'
                                : 'Open App > Profile > Settings & Security > Delete Account Permanently'}
                        </p>
                        <p className="text-[11px] text-gray-400 pt-2">
                            {isVi ? 'Hỗ trợ khách hàng:' : 'Customer support:'}{' '}
                            <a href="mailto:support@nhinanchualanh.vn" className="text-emerald-700 underline">
                                support@nhinanchualanh.vn
                            </a>
                        </p>
                    </div>
                </div>
            </div>

            {/* Confirmation Modal for Logged In User */}
            {showConfirmModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-white rounded-3xl max-w-md w-full p-6 sm:p-8 shadow-2xl border border-gray-100 text-center space-y-4">
                        <div className="inline-flex h-14 w-14 items-center justify-center rounded-full bg-red-100 text-red-600 text-3xl mb-1">
                            <span className="material-symbols-outlined text-3xl">delete_forever</span>
                        </div>
                        <h3 className="text-xl font-bold text-gray-900">
                            {isVi ? 'Xác nhận xóa tài khoản?' : 'Confirm account deletion?'}
                        </h3>
                        <p className="text-xs sm:text-sm text-gray-600 leading-relaxed">
                            {isVi
                                ? `Bạn đang thực hiện xóa vĩnh viễn tài khoản "${user?.email || user?.fullName}". Sau khi xóa, bạn sẽ bị đăng xuất và không thể khôi phục lại dữ liệu.`
                                : `You are permanently deleting account "${user?.email || user?.fullName}". You will be logged out and cannot recover your data.`}
                        </p>
                        <div className="pt-4 flex flex-col sm:flex-row gap-3">
                            <button
                                type="button"
                                onClick={() => setShowConfirmModal(false)}
                                disabled={isSubmitting}
                                className="flex-1 py-3 px-4 rounded-xl border border-gray-300 text-gray-700 font-semibold text-sm hover:bg-gray-50 transition"
                            >
                                {isVi ? 'Hủy bỏ' : 'Cancel'}
                            </button>
                            <button
                                type="button"
                                onClick={handleLoggedInDelete}
                                disabled={isSubmitting}
                                className="flex-1 py-3 px-4 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold text-sm transition shadow-sm flex items-center justify-center gap-2"
                            >
                                {isSubmitting ? (
                                    <>
                                        <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-r-transparent" />
                                        <span>{isVi ? 'Đang xóa...' : 'Deleting...'}</span>
                                    </>
                                ) : (
                                    <span>{isVi ? 'Xóa Vĩnh Viễn' : 'Delete Forever'}</span>
                                )}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default DeleteAccountPage;
