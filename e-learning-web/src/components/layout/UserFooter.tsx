import React from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { FaFacebookF, FaTiktok, FaYoutube } from 'react-icons/fa6';
import logoImg from '../../assets/logo-rm-bg.png';

const UserFooter: React.FC = () => {
    const { t } = useTranslation();
    const currentYear = new Date().getFullYear();

    const discoverLinks = [
        { to: '/', icon: 'eco', label: t('home.footer.discover.about') },
        { to: '/#fasting', icon: 'self_improvement', label: t('home.footer.discover.method') },
        { to: '/courses', icon: 'school', label: t('home.footer.discover.courses') },
        { to: '/pricing', icon: 'payments', label: t('home.footer.discover.pricing') },
        { to: '/testimonials', icon: 'favorite', label: t('home.footer.discover.stories') },
        { to: '/articles', icon: 'library_books', label: t('home.footer.discover.blog') }
    ];

    const supportLinks = [
        { to: '/forum', icon: 'help', label: t('home.footer.support.faq') },
        { to: '/ambassador', icon: 'volunteer_activism', label: t('home.footer.support.ambassador') },
        { to: '/privacy-policy', icon: 'policy', label: t('home.footer.support.privacy') },
        { to: '/privacy-policy', icon: 'gavel', label: t('home.footer.support.terms') },
        { to: '/privacy-policy', icon: 'warning', label: t('home.footer.support.disclaimer') },
        { to: '/contact', icon: 'handshake', label: t('home.footer.support.collaboration') }
    ];

    return (
        <footer className="mt-auto border-t border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
            <div className="mx-auto max-w-none px-3 py-8 sm:px-4 sm:py-10 lg:px-6 xl:px-8">
                <div className="grid grid-cols-1 overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-800 md:grid-cols-2 xl:grid-cols-4">
                    <div className="p-6 sm:p-7 xl:border-r xl:border-gray-200 dark:xl:border-gray-800">
                        <div className="mb-4 flex items-center gap-2 border-b border-gray-200 pb-3 dark:border-gray-800">
                            <span className="material-symbols-outlined text-[22px] text-primary">spa</span>
                            <h4 className="text-sm font-extrabold uppercase tracking-wide text-[#0c1c1d] dark:text-white">
                                {t('home.footer.journey.title')}
                            </h4>
                        </div>

                        <Link to="/" className="mb-4 flex items-center gap-3">
                            <img src={logoImg} alt={t('home.footer.logoAlt')} className="h-10 w-10 object-contain" />
                            <p className="text-2xl font-bold tracking-tight text-[#0c1c1d] dark:text-white">
                                {t('home.footer.journey.brand')}
                            </p>
                        </Link>

                        <p className="text-sm leading-relaxed text-gray-700 dark:text-gray-300">
                            {t('home.footer.journey.description')}
                        </p>
                        <p className="mt-5 font-medium text-[#0c1c1d] dark:text-white">{t('home.footer.journey.tagline')}</p>
                    </div>

                    <div className="p-6 sm:p-7 xl:border-r xl:border-gray-200 dark:xl:border-gray-800">
                        <div className="mb-4 flex items-center gap-2 border-b border-gray-200 pb-3 dark:border-gray-800">
                            <span className="material-symbols-outlined text-[22px] text-primary">menu_book</span>
                            <h4 className="text-sm font-extrabold uppercase tracking-wide text-[#0c1c1d] dark:text-white">
                                {t('home.footer.discover.title')}
                            </h4>
                        </div>

                        <ul className="space-y-2.5">
                            {discoverLinks.map((item) => (
                                <li key={item.label}>
                                    <Link
                                        to={item.to}
                                        className="group flex items-center gap-2 text-[17px] text-gray-700 transition-colors hover:text-primary dark:text-gray-300"
                                    >
                                        <span className="material-symbols-outlined text-[18px] text-primary/80 transition-transform group-hover:scale-110">
                                            {item.icon}
                                        </span>
                                        <span>{item.label}</span>
                                    </Link>
                                </li>
                            ))}
                        </ul>
                    </div>

                    <div className="p-6 sm:p-7 xl:border-r xl:border-gray-200 dark:xl:border-gray-800">
                        <div className="mb-4 flex items-center gap-2 border-b border-gray-200 pb-3 dark:border-gray-800">
                            <span className="material-symbols-outlined text-[22px] text-primary">support_agent</span>
                            <h4 className="text-sm font-extrabold uppercase tracking-wide text-[#0c1c1d] dark:text-white">
                                {t('home.footer.support.title')}
                            </h4>
                        </div>

                        <ul className="space-y-2.5">
                            {supportLinks.map((item) => (
                                <li key={item.label}>
                                    <Link
                                        to={item.to}
                                        className="group flex items-center gap-2 text-[17px] text-gray-700 transition-colors hover:text-primary dark:text-gray-300"
                                    >
                                        <span className="material-symbols-outlined text-[18px] text-primary/80 transition-transform group-hover:scale-110">
                                            {item.icon}
                                        </span>
                                        <span>{item.label}</span>
                                    </Link>
                                </li>
                            ))}
                        </ul>
                    </div>

                    <div id="footer-contact" className="p-6 sm:p-7">
                        <div className="mb-4 flex items-center gap-2 border-b border-gray-200 pb-3 dark:border-gray-800">
                            <span className="material-symbols-outlined text-[22px] text-primary">podcasts</span>
                            <h4 className="text-sm font-extrabold uppercase tracking-wide text-[#0c1c1d] dark:text-white">
                                {t('home.footer.connect.title')}
                            </h4>
                        </div>

                        <div className="space-y-2 text-[17px] text-gray-700 dark:text-gray-300">
                            <p>
                                <span className="font-semibold text-[#0c1c1d] dark:text-white">{t('home.footer.connect.hotlineLabel')}:</span>{' '}
                                {t('home.footer.connect.hotlineValue')}
                            </p>
                            <p>
                                <span className="font-semibold text-[#0c1c1d] dark:text-white">{t('home.footer.connect.emailLabel')}:</span>{' '}
                                {t('home.footer.connect.emailValue')}
                            </p>
                        </div>

                        <div className="mt-4 flex items-center gap-3">
                            <a
                                href="https://www.facebook.com/nhinanchualanhvn"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-gray-100 text-[#0c1c1d] transition-colors hover:border-primary hover:bg-primary hover:text-white dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                                aria-label={t('home.footer.connect.social.facebook')}
                            >
                                <FaFacebookF className="h-[18px] w-[18px]" />
                            </a>
                            <a
                                href="https://www.youtube.com/@nhinanchualanhvn"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-gray-100 text-[#0c1c1d] transition-colors hover:border-primary hover:bg-primary hover:text-white dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                                aria-label={t('home.footer.connect.social.youtube')}
                            >
                                <FaYoutube className="h-[18px] w-[18px]" />
                            </a>
                            <a
                                href="https://www.tiktok.com/@nhinanchualanhvn"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-gray-100 text-[#0c1c1d] transition-colors hover:border-primary hover:bg-primary hover:text-white dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                                aria-label={t('home.footer.connect.social.tiktok')}
                            >
                                <FaTiktok className="h-[18px] w-[18px]" />
                            </a>
                            <a
                                href="/forum"
                                className="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-gray-100 text-[#0c1c1d] transition-colors hover:border-primary hover:bg-primary hover:text-white dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                                aria-label={t('home.footer.connect.social.community')}
                            >
                                <span className="material-symbols-outlined text-[20px]">groups</span>
                            </a>
                        </div>

                        <div className="mt-4 grid grid-cols-2 gap-2">
                            <button
                                type="button"
                                className="rounded-full border border-primary/30 bg-primary/10 px-3 py-2 text-xs font-semibold text-primary transition-colors hover:bg-primary hover:text-white"
                            >
                                {t('home.footer.connect.chatAction')}
                            </button>
                            <button
                                type="button"
                                className="rounded-full border border-primary/30 bg-primary/10 px-3 py-2 text-xs font-semibold text-primary transition-colors hover:bg-primary hover:text-white"
                            >
                                {t('home.footer.connect.newsAction')}
                            </button>
                        </div>
                    </div>
                </div>

                <div className="mt-6 border-t border-gray-200 pt-5 dark:border-gray-800">
                    <p className="text-center text-sm leading-relaxed text-gray-700 dark:text-gray-300">
                        {t('home.footer.copyrightLine', { year: currentYear })}
                    </p>
                </div>

                <div className="mt-4 rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-700 dark:bg-gray-800/70">
                    <p className="text-center text-xs leading-relaxed text-gray-700 dark:text-gray-300">
                        {t('home.footer.medicalNotice')}
                    </p>
                </div>
            </div>
        </footer>
    );
};

export default UserFooter;
