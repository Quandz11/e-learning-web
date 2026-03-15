import React from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import logoImg from '../../assets/logo.jpg';

const UserFooter: React.FC = () => {
    const { t } = useTranslation();
    const currentYear = new Date().getFullYear();

    return (
        <footer className="bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800 mt-auto">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                    {/* Company Info */}
                    <div className="col-span-1 md:col-span-2">
                        <Link to="/" className="flex items-center gap-3 mb-4">
                            <img src={logoImg} alt="Logo" className="w-20 h-20 object-cover rounded-full border border-primary bg-white shadow-sm" />
                            <h3 className="text-[#0c1c1d] dark:text-white text-xl font-bold tracking-tight">
                                NhinAnChuaLanh<span className="text-primary">.</span>
                            </h3>
                        </Link>
                        <p className="text-gray-600 dark:text-gray-400 text-sm mb-4 max-w-md">
                            {t('footer.description', {
                                defaultValue: 'Nền tảng học tập trực tuyến hàng đầu, cung cấp các khóa học chất lượng cao và kiến thức chuyên sâu.'
                            })}
                        </p>
                        {/* Social Links */}
                        <div className="flex items-center gap-3">
                            <a
                                href="https://www.facebook.com/nhinanchualanhvn"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center text-gray-600 dark:text-gray-400 hover:bg-primary hover:text-white transition-colors"
                                aria-label="Facebook"
                            >
                                <span className="material-symbols-outlined text-xl">facebook</span>
                            </a>
                            <a
                                href="https://www.youtube.com/@nhinanchualanhvn"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center text-gray-600 dark:text-gray-400 hover:bg-primary hover:text-white transition-colors"
                                aria-label="YouTube"
                            >
                                <span className="material-symbols-outlined text-xl">youtube_video</span>
                            </a>
                        </div>
                    </div>

                    {/* Quick Links */}
                    <div>
                        <h4 className="text-[#0c1c1d] dark:text-white font-bold mb-4">
                            {t('footer.quickLinks', { defaultValue: 'Liên kết' })}
                        </h4>
                        <ul className="space-y-2">
                            <li>
                                <Link
                                    to="/courses"
                                    className="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors text-sm"
                                >
                                    {t('footer.courses', { defaultValue: 'Khóa học' })}
                                </Link>
                            </li>
                            <li>
                                <Link
                                    to="/articles"
                                    className="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors text-sm"
                                >
                                    {t('footer.articles', { defaultValue: 'Bài viết' })}
                                </Link>
                            </li>
                            <li>
                                <Link
                                    to="/"
                                    className="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors text-sm"
                                >
                                    {t('footer.about', { defaultValue: 'Về chúng tôi' })}
                                </Link>
                            </li>
                            <li>
                                <Link
                                    to="/"
                                    className="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors text-sm"
                                >
                                    {t('footer.contact', { defaultValue: 'Liên hệ' })}
                                </Link>
                            </li>
                        </ul>
                    </div>

                    {/* Support */}
                    <div>
                        <h4 className="text-[#0c1c1d] dark:text-white font-bold mb-4">
                            {t('footer.support', { defaultValue: 'Hỗ trợ' })}
                        </h4>
                        <ul className="space-y-2">
                            <li>
                                <Link
                                    to="/"
                                    className="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors text-sm"
                                >
                                    {t('footer.faq', { defaultValue: 'Câu hỏi thường gặp' })}
                                </Link>
                            </li>
                            <li>
                                <Link
                                    to="/"
                                    className="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors text-sm"
                                >
                                    {t('footer.privacy', { defaultValue: 'Chính sách bảo mật' })}
                                </Link>
                            </li>
                            <li>
                                <Link
                                    to="/"
                                    className="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors text-sm"
                                >
                                    {t('footer.terms', { defaultValue: 'Điều khoản sử dụng' })}
                                </Link>
                            </li>
                        </ul>
                    </div>
                </div>

                {/* Copyright */}
                <div className="mt-8 pt-8 border-t border-gray-200 dark:border-gray-800">
                    <p className="text-center text-gray-600 dark:text-gray-400 text-sm">
                        © {currentYear} NhinAnChuaLanh. {t('footer.copyright', { defaultValue: 'Tất cả quyền được bảo lưu.' })}
                    </p>
                </div>
            </div>
        </footer>
    );
};

export default UserFooter;
