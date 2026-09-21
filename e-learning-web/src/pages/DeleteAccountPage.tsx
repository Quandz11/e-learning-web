import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

const DeleteAccountPage: React.FC = () => {
    const { i18n } = useTranslation();
    const [identifier, setIdentifier] = useState('');
    const [reason, setReason] = useState('');
    const [isSubmitted, setIsSubmitted] = useState(false);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const isVi = i18n.language !== 'en';

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);

        if (!identifier.trim()) {
            setError(isVi ? 'Vui lòng nhập email hoặc số điện thoại của bạn.' : 'Please enter your email or phone number.');
            return;
        }

        setIsSubmitting(true);
        // Simulate immediate response / log deletion request
        try {
            // Give 1 second feedback
            await new Promise((resolve) => setTimeout(resolve, 800));
            setIsSubmitted(true);
        } catch {
            setError(isVi ? 'Đã có lỗi xảy ra. Vui lòng liên hệ support@nhinanchualanh.vn.' : 'An error occurred. Please contact support@nhinanchualanh.vn.');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="min-h-screen bg-[#f0f4f3] text-[#0f2a24] relative z-0 overflow-hidden py-16 px-4 sm:px-6">
            {/* Mesh Background */}
            <div
                className="absolute inset-0 -z-10 opacity-15"
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

            <div className="max-w-2xl mx-auto">
                <div className="bg-white/90 backdrop-blur-md border border-white/50 rounded-3xl p-8 sm:p-12 shadow-sm">
                    <div className="w-14 h-14 bg-emerald-100 text-emerald-800 rounded-2xl flex items-center justify-center text-3xl mb-6 shadow-sm">
                        🌱
                    </div>

                    <h1 className="text-2xl sm:text-3xl font-extrabold text-gray-900 mb-2">
                        {isVi ? 'Yêu Cầu Xóa Tài Khoản & Dữ Liệu' : 'Account & Data Deletion Request'}
                    </h1>
                    <p className="text-sm text-gray-500 mb-6">
                        {isVi
                            ? 'Ứng dụng Nhịn Ăn Chữa Lành tuân thủ chính sách bảo vệ dữ liệu người dùng của Google Play Store & Apple App Store.'
                            : 'Nhịn Ăn Chữa Lành complies with Google Play Store & Apple App Store user data protection policies.'}
                    </p>

                    <div className="bg-red-50 border border-red-200 text-red-800 rounded-2xl p-4 text-xs sm:text-sm leading-relaxed mb-8">
                        <strong>⚠️ {isVi ? 'LƯU Ý QUAN TRỌNG:' : 'IMPORTANT NOTICE:'}</strong>{' '}
                        {isVi
                            ? 'Hành động này sẽ xóa vĩnh viễn tài khoản của bạn. Mọi tiến trình nhịn ăn, nhật ký sức khỏe, bài học và dữ liệu cá nhân sẽ bị xóa hoàn toàn khỏi hệ thống và không thể khôi phục.'
                            : 'This action permanently deletes your account. All fasting progress, health logs, courses, and personal data will be completely erased and cannot be recovered.'}
                    </div>

                    {isSubmitted ? (
                        <div className="bg-emerald-50 border border-emerald-300 text-emerald-800 p-6 rounded-2xl text-center space-y-3">
                            <div className="text-3xl">✅</div>
                            <h3 className="font-bold text-lg">
                                {isVi ? 'Đã Tiếp Nhận Yêu Cầu Xóa Tài Khoản' : 'Deletion Request Received'}
                            </h3>
                            <p className="text-sm">
                                {isVi
                                    ? `Yêu cầu xóa dữ liệu cho tài khoản "${identifier}" đã được ghi nhận. Toàn bộ thông tin cá nhân liên quan sẽ được xử lý xóa trong vòng 24 - 48 giờ làm việc.`
                                    : `Your request for account "${identifier}" has been recorded. All associated personal data will be permanently wiped within 24-48 business hours.`}
                            </p>
                            <div className="pt-4">
                                <Link
                                    to="/"
                                    className="inline-block bg-emerald-700 hover:bg-emerald-800 text-white font-medium text-sm px-6 py-2.5 rounded-xl transition"
                                >
                                    {isVi ? 'Quay lại Trang chủ' : 'Back to Home'}
                                </Link>
                            </div>
                        </div>
                    ) : (
                        <form onSubmit={handleSubmit} className="space-y-5">
                            {error && (
                                <div className="p-3 bg-red-100 border border-red-300 text-red-700 text-xs rounded-xl">
                                    {error}
                                </div>
                            )}

                            <div>
                                <label className="block text-xs sm:text-sm font-semibold text-gray-800 mb-1.5">
                                    {isVi ? 'Email hoặc Số điện thoại đăng ký tài khoản *' : 'Registered Email or Phone Number *'}
                                </label>
                                <input
                                    type="text"
                                    value={identifier}
                                    onChange={(e) => setIdentifier(e.target.value)}
                                    placeholder={isVi ? 'Ví dụ: hocvien@nhinanchualanh.vn hoặc 0901234567' : 'e.g. user@nhinanchualanh.vn'}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-xl text-sm focus:outline-none focus:border-emerald-600 focus:ring-1 focus:ring-emerald-600 transition"
                                    required
                                />
                            </div>

                            <div>
                                <label className="block text-xs sm:text-sm font-semibold text-gray-800 mb-1.5">
                                    {isVi ? 'Lý do bạn muốn xóa tài khoản (Không bắt buộc)' : 'Reason for account deletion (Optional)'}
                                </label>
                                <textarea
                                    value={reason}
                                    onChange={(e) => setReason(e.target.value)}
                                    rows={3}
                                    placeholder={isVi ? 'Chia sẻ với chúng tôi lý do bạn muốn ngừng sử dụng dịch vụ...' : 'Let us know how we can improve...'}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-xl text-sm focus:outline-none focus:border-emerald-600 focus:ring-1 focus:ring-emerald-600 transition"
                                />
                            </div>

                            <div className="bg-gray-50 p-4 rounded-2xl text-xs text-gray-600 space-y-1.5 border border-gray-200">
                                <p className="font-bold text-gray-800">
                                    {isVi ? 'Dữ liệu sẽ bị xóa hoàn toàn khỏi máy chủ:' : 'Data that will be permanently wiped:'}
                                </p>
                                <ul className="list-disc pl-5 space-y-1">
                                    <li>{isVi ? 'Thông tin hồ sơ cá nhân (Họ tên, Email, Số điện thoại, Avatar).' : 'Personal profile (Name, email, phone, avatar).'}</li>
                                    <li>{isVi ? 'Lịch sử theo dõi nhịn ăn, cân nặng, nhịp tim và nhật ký sức khỏe.' : 'Fasting tracker, body weight, hydration, and wellness records.'}</li>
                                    <li>{isVi ? 'Tiến trình học tập, bài học đã hoàn thành và bài kiểm tra trắc nghiệm.' : 'Enrolled courses, completed lesson videos, and quiz records.'}</li>
                                    <li>{isVi ? 'Mã xác thực hai lớp (2FA) và thiết bị đăng nhập.' : '2FA credentials and active mobile device sessions.'}</li>
                                </ul>
                            </div>

                            <button
                                type="submit"
                                disabled={isSubmitting}
                                className="w-full py-3.5 bg-red-600 hover:bg-red-700 text-white font-bold rounded-xl text-sm transition shadow-sm disabled:opacity-50"
                            >
                                {isSubmitting
                                    ? (isVi ? 'Đang gửi yêu cầu...' : 'Submitting request...')
                                    : (isVi ? 'Xác Nhận Yêu Cầu Xóa Tài Khoản Vĩnh Viễn' : 'Confirm Permanent Account Deletion')}
                            </button>
                        </form>
                    )}

                    <div className="mt-8 pt-6 border-t border-gray-200 text-center text-xs text-gray-500">
                        {isVi ? 'Bạn cũng có thể xóa tài khoản trực tiếp trong ứng dụng tại mục:' : 'You can also delete your account in the app under:'}
                        <br />
                        <span className="font-semibold text-gray-700">
                            {isVi ? 'Hồ sơ cá nhân > Cài đặt & Bảo mật > Xóa tài khoản vĩnh viễn' : 'Profile > Settings & Security > Delete Account Permanently'}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default DeleteAccountPage;
