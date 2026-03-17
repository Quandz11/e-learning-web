import React from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import recodeKitImg from '../../assets/RECODE-KIT.jpg';

const RecodeKitSection: React.FC = () => {
    const { t } = useTranslation();

    return (
        <section className="py-20 md:py-28 bg-[#fcfcfc] dark:bg-slate-900 font-sans border-y border-gray-100 dark:border-slate-800">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                {/* Section Header */}
                <div className="text-center mb-16">
                    <h2 className="text-3xl font-bold text-gray-900 dark:text-white sm:text-4xl">
                        {t('home.recodeKit.title')}
                    </h2>
                    <p className="mt-4 text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
                        {t('home.recodeKit.subtitle')}
                    </p>
                </div>

                <div className="flex flex-col lg:flex-row items-center gap-12 lg:gap-16">

                    {/* Image Column */}
                    <div className="w-full lg:flex-[1.2] relative">
                        <div className="relative z-10">
                            <img
                                src={recodeKitImg}
                                alt="RE-CODE 10 Kit"
                                className="w-full rounded-2xl shadow-[0_30px_60px_rgba(0,75,35,0.15)] dark:shadow-[0_30px_60px_rgba(0,0,0,0.5)] transform hover:scale-[1.02] transition-transform duration-500"
                            />
                            {/* Floating Tag */}
                            <div className="absolute -top-4 -left-4 sm:-top-6 sm:-left-6 bg-[#ccff33] text-[#004b23] px-5 py-3 rounded-xl font-extrabold shadow-lg transform -rotate-6 z-20 text-sm md:text-base border-2 border-white">
                                {t('home.recodeKit.limitedEdition')}
                            </div>
                        </div>
                    </div>

                    {/* Content Column */}
                    <div className="w-full lg:flex-[1]">
                        <h4 className="text-[#38b000] tracking-[3px] text-sm md:text-[0.9rem] font-bold mb-4 uppercase">
                            {t('home.recodeKit.eynt')}
                        </h4>

                        <h2 className="text-[#004b23] dark:text-white text-4xl md:text-5xl lg:text-[2.8rem] font-bold leading-[1.15] mb-6 font-serif tracking-tight">
                            {t('home.recodeKit.heading')}
                        </h2>

                        <p className="text-[#4a5568] dark:text-slate-300 text-lg md:text-[1.1rem] mb-10 leading-[1.8]">
                            {t('home.recodeKit.desc')}
                        </p>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 md:gap-x-8 md:gap-y-8 mb-12">
                            {/* Feature 1 */}
                            <div className="bg-white dark:bg-slate-800 p-5 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 hover:shadow-md transition-shadow">
                                <strong className="text-[#004b23] dark:text-green-400 block mb-2 text-lg">{t('home.recodeKit.f1Title')}</strong>
                                <span className="text-[#718096] dark:text-slate-400 text-[0.95rem] leading-relaxed block">
                                    {t('home.recodeKit.f1Desc')}
                                </span>
                            </div>

                            {/* Feature 2 */}
                            <div className="bg-white dark:bg-slate-800 p-5 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 hover:shadow-md transition-shadow">
                                <strong className="text-[#004b23] dark:text-green-400 block mb-2 text-lg">{t('home.recodeKit.f2Title')}</strong>
                                <span className="text-[#718096] dark:text-slate-400 text-[0.95rem] leading-relaxed block">
                                    {t('home.recodeKit.f2Desc')}
                                </span>
                            </div>

                            {/* Feature 3 */}
                            <div className="bg-white dark:bg-slate-800 p-5 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 hover:shadow-md transition-shadow">
                                <strong className="text-[#004b23] dark:text-green-400 block mb-2 text-lg">{t('home.recodeKit.f3Title')}</strong>
                                <span className="text-[#718096] dark:text-slate-400 text-[0.95rem] leading-relaxed block">
                                    {t('home.recodeKit.f3Desc')}
                                </span>
                            </div>

                            {/* Feature 4 */}
                            <div className="bg-white dark:bg-slate-800 p-5 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 hover:shadow-md transition-shadow">
                                <strong className="text-[#004b23] dark:text-green-400 block mb-2 text-lg">{t('home.recodeKit.f4Title')}</strong>
                                <span className="text-[#718096] dark:text-slate-400 text-[0.95rem] leading-relaxed block">
                                    {t('home.recodeKit.f4Desc')}
                                </span>
                            </div>
                        </div>

                        {/* CTA Button */}
                        <Link
                            to="/checkout"
                            className="inline-flex items-center justify-center bg-[#004b23] hover:bg-[#006400] text-white px-8 py-4 md:px-10 md:py-5 rounded-full font-bold text-sm md:text-base uppercase tracking-wide transition-all duration-300 shadow-[0_10px_20px_rgba(0,75,35,0.2)] hover:shadow-[0_15px_25px_rgba(0,75,35,0.3)] hover:-translate-y-1"
                        >
                            {t('home.recodeKit.cta')}
                        </Link>
                    </div>

                </div>
            </div>
        </section>
    );
};

export default RecodeKitSection;
