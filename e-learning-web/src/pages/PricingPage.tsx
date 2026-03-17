import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const PricingPage: React.FC = () => {
    const { t } = useTranslation();
    const [openFaqIndex, setOpenFaqIndex] = useState<number | null>(null);

    const faqItems: { q: string; a: string }[] = t('pricingPage.faq.items', { returnObjects: true }) as { q: string; a: string }[];

    return (
        <div className="min-h-screen bg-white dark:bg-slate-900 py-10 px-4 sm:px-6 lg:px-8 font-sans text-[#002d26] dark:text-slate-100">
            <div className="max-w-6xl mx-auto">

                {/* Header */}
                <div className="text-center py-10 px-5 bg-gradient-to-br from-[#004d40] to-[#00796b] text-white rounded-2xl mb-8 shadow-[0_10px_20px_rgba(0,77,64,0.2)]">
                    <p className="text-3xl sm:text-4xl font-black uppercase tracking-widest text-[#ffc107]">
                        {t('pricingPage.hero.title')}
                    </p>
                    <p className="mt-3 italic opacity-90 text-base sm:text-lg">
                        {t('pricingPage.hero.subtitle')}
                    </p>
                </div>

                {/* Comparison Table */}
                <div className="overflow-x-auto mb-8 rounded-2xl shadow-[0_15px_35px_rgba(0,0,0,0.1)] border border-[#e0e0e0]">
                    <table className="w-full border-collapse bg-white dark:bg-slate-800 text-center text-[15px] sm:text-base">
                        <thead>
                            <tr>
                                <th className="bg-[#004d40] text-[#ffc107] font-black uppercase text-left px-4 py-7 text-sm border border-[#eee] w-[18%]">
                                    {t('pricingPage.table.featureCol')}
                                </th>
                                <th className="bg-[#004d40] text-[#ffc107] font-black uppercase py-7 border border-[#eee] text-sm">
                                    {t('pricingPage.table.col1')}
                                </th>
                                <th className="bg-[#004d40] text-[#ffc107] font-black uppercase py-7 border-[3px] border-[#ffc107] text-sm relative">
                                    {t('pricingPage.table.col2')}
                                    <span className="absolute top-0 right-0 bg-[#ffc107] text-[#004d40] text-[0.7rem] font-black px-3 py-1 rounded-bl-2xl">
                                        BESTSELLER
                                    </span>
                                </th>
                                <th className="bg-[#004d40] text-[#ffc107] font-black uppercase py-7 border border-[#eee] text-sm">
                                    {t('pricingPage.table.col3')}
                                </th>
                                <th className="bg-[#004d40] text-[#ffc107] font-black uppercase py-7 border border-[#eee] text-sm">
                                    {t('pricingPage.table.col4')}
                                </th>
                                <th className="bg-[#004d40] text-[#ffc107] font-black uppercase py-7 border border-[#eee] text-sm">
                                    {t('pricingPage.table.col5')}
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            {/* Price row */}
                            <tr className="bg-[#fffdf2] dark:bg-slate-700 text-[#e64a19] font-black text-xl sm:text-2xl">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-2 border border-[#eee]">{t('pricingPage.table.rowPrice')}</td>
                                <td className="py-2 border border-[#eee]">{t('pricingPage.table.price1')}</td>
                                <td className="py-2 border-[3px] border-[#ffc107] bg-[#fffef7] dark:bg-slate-700">{t('pricingPage.table.price2')}</td>
                                <td className="py-2 border border-[#eee]">{t('pricingPage.table.price3')}</td>
                                <td className="py-2 border border-[#eee]">{t('pricingPage.table.price4')}</td>
                                <td className="py-2 border border-[#eee]">{t('pricingPage.table.price5')}</td>
                            </tr>
                            {/* Renewal row */}
                            <tr className="dark:bg-slate-800">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-1 border border-[#eee]">{t('pricingPage.table.rowRenewal')}</td>
                                <td className="py-1 border border-[#eee]">--</td>
                                <td className="py-1 border-[3px] border-[#ffc107] text-[#00796b] font-black bg-[#fffef7] dark:bg-slate-700">{t('pricingPage.table.renewal2')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.renewal3')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.renewal4')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.renewal5')}</td>
                            </tr>
                            {/* Roadmap row */}
                            <tr className="dark:bg-slate-800">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-1 border border-[#eee]">{t('pricingPage.table.rowRoadmap')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.roadmap1')}</td>
                                <td className="py-1 border-[3px] border-[#ffc107] bg-[#fffef7] dark:bg-slate-700">{t('pricingPage.table.roadmap2')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.roadmap3')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.roadmap4')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.roadmap5')}</td>
                            </tr>
                            {/* Zoom live row */}
                            <tr className="dark:bg-slate-800">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-1 border border-[#eee]">{t('pricingPage.table.rowZoom')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.zoom1')}</td>
                                <td className="py-1 border-[3px] border-[#ffc107] bg-[#fffef7] dark:bg-slate-700">{t('pricingPage.table.zoom2')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.zoom3')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.zoom4')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.zoom5')}</td>
                            </tr>
                            {/* Duration row */}
                            <tr className="dark:bg-slate-800">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-1 border border-[#eee]">{t('pricingPage.table.rowDuration')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.duration1')}</td>
                                <td className="py-1 border-[3px] border-[#ffc107] bg-[#fffef7] dark:bg-slate-700">{t('pricingPage.table.duration2')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.duration3')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.duration4')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.duration5')}</td>
                            </tr>
                            {/* Recode kit row */}
                            <tr className="dark:bg-slate-800">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-1 border border-[#eee]">{t('pricingPage.table.rowKit')}</td>
                                <td className="py-1 border border-[#eee]">--</td>
                                <td className="py-1 border-[3px] border-[#ffc107] bg-[#fffef7] dark:bg-slate-700">{t('pricingPage.table.kit2')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.kit3')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.kit4')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.kit5')}</td>
                            </tr>
                            {/* Gift row */}
                            <tr className="dark:bg-slate-800">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-1 border border-[#eee]">{t('pricingPage.table.rowGift')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.gift1')}</td>
                                <td className="py-1 border-[3px] border-[#ffc107] bg-[#fffef7] dark:bg-slate-700">{t('pricingPage.table.gift2')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.gift3')}</td>
                                <td className="py-1 border border-[#eee] text-[#e64a19] font-bold">{t('pricingPage.table.gift4')}</td>
                                <td className="py-1 border border-[#eee] text-[#e64a19] font-bold">{t('pricingPage.table.gift5')}</td>
                            </tr>
                            {/* Commitment row */}
                            <tr className="dark:bg-slate-800">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-1 border border-[#eee]">{t('pricingPage.table.rowCommit')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.commit1')}</td>
                                <td className="py-1 border-[3px] border-[#ffc107] bg-[#fffef7] dark:bg-slate-700">{t('pricingPage.table.commit2')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.commit3')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.commit4')}</td>
                                <td className="py-1 border border-[#eee]">{t('pricingPage.table.commit5')}</td>
                            </tr>
                            {/* CTA row */}
                            <tr className="dark:bg-slate-800">
                                <td className="text-left bg-[#e0f2f1] dark:bg-slate-600 text-[#004d40] dark:text-[#ffc107] font-bold text-sm px-4 py-2 border border-[#eee]">{t('pricingPage.table.rowAction')}</td>
                                <td className="py-2 border border-[#eee]">
                                    <Link to="/courses" className="inline-block px-4 py-2 border-2 border-[#004d40] text-[#004d40] dark:border-[#ffc107] dark:text-[#ffc107] rounded-full font-bold text-sm hover:bg-[#004d40] hover:text-white transition-all">
                                        {t('pricingPage.table.cta1')}
                                    </Link>
                                </td>
                                <td className="py-2 border-[3px] border-[#ffc107] bg-[#fffef7] dark:bg-slate-700">
                                    <Link to="/courses" className="inline-block px-4 py-2 bg-[#e64a19] text-white rounded-full font-bold text-sm hover:bg-[#bf360c] transition-all shadow-md">
                                        {t('pricingPage.table.cta2')}
                                    </Link>
                                </td>
                                <td className="py-2 border border-[#eee]">
                                    <Link to="/courses" className="inline-block px-4 py-2 bg-[#e64a19] text-white rounded-full font-bold text-sm hover:bg-[#bf360c] transition-all shadow-md">
                                        {t('pricingPage.table.cta3')}
                                    </Link>
                                </td>
                                <td className="py-2 border border-[#eee]">
                                    <Link to="/ambassador#register" className="inline-block px-4 py-2 bg-[#e64a19] text-white rounded-full font-bold text-sm hover:bg-[#bf360c] transition-all shadow-md">
                                        {t('pricingPage.table.cta4')}
                                    </Link>
                                </td>
                                <td className="py-2 border border-[#eee]">
                                    <Link to="/ambassador#register" className="inline-block px-4 py-2 bg-[#e64a19] text-white rounded-full font-bold text-sm hover:bg-[#bf360c] transition-all shadow-md">
                                        {t('pricingPage.table.cta5')}
                                    </Link>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                {/* Info Grid: Affiliate + FAQ */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">

                    {/* Affiliate Card */}
                    <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border-2 border-[#e0e0e0] dark:border-slate-700 shadow-sm">
                        <h4 className="text-[#004d40] dark:text-[#ffc107] text-xl font-bold mb-5 border-b-[3px] border-[#ffc107] inline-block pb-1">
                            💎 {t('pricingPage.affiliate.title')}
                        </h4>
                        <table className="w-full text-sm border-collapse mt-2">
                            <thead>
                                <tr>
                                    <th className="bg-[#f1f8f6] dark:bg-slate-700 text-[#004d40] dark:text-[#ffc107] p-3 border border-[#ddd] dark:border-slate-600 text-left">{t('pricingPage.affiliate.colProduct')}</th>
                                    <th className="bg-[#f1f8f6] dark:bg-slate-700 text-[#004d40] dark:text-[#ffc107] p-3 border border-[#ddd] dark:border-slate-600">{t('pricingPage.affiliate.colF1')}</th>
                                    <th className="bg-[#f1f8f6] dark:bg-slate-700 text-[#004d40] dark:text-[#ffc107] p-3 border border-[#ddd] dark:border-slate-600">{t('pricingPage.affiliate.colF2')}</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600">
                                        <strong>{t('pricingPage.affiliate.row1Name')}</strong><br />
                                        <small className="text-gray-500">{t('pricingPage.affiliate.row1Sub')}</small>
                                    </td>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600 text-center text-[#e64a19] font-bold text-lg">{t('pricingPage.affiliate.row1F1')}</td>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600 text-center text-[#00796b] font-bold">{t('pricingPage.affiliate.row1F2')}</td>
                                </tr>
                                <tr>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600">
                                        <strong>{t('pricingPage.affiliate.row2Name')}</strong><br />
                                        <small className="text-gray-500">{t('pricingPage.affiliate.row2Sub')}</small>
                                    </td>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600 text-center text-[#e64a19] font-bold text-lg">{t('pricingPage.affiliate.row2F1')}</td>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600 text-center text-[#00796b] font-bold">{t('pricingPage.affiliate.row2F2')}</td>
                                </tr>
                                <tr>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600">
                                        <strong>{t('pricingPage.affiliate.row3Name')}</strong><br />
                                        <small className="text-gray-500">{t('pricingPage.affiliate.row3Sub')}</small>
                                    </td>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600 text-center text-[#e64a19] font-bold text-lg">{t('pricingPage.affiliate.row3F1')}</td>
                                    <td className="p-3 border border-[#ddd] dark:border-slate-600 text-center text-[#00796b] font-bold">{t('pricingPage.affiliate.row3F2')}</td>
                                </tr>
                            </tbody>
                        </table>
                        <p className="text-xs text-gray-500 mt-4">* {t('pricingPage.affiliate.note')}</p>
                    </div>

                    {/* FAQ Card */}
                    <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border-2 border-[#e0e0e0] dark:border-slate-700 shadow-sm">
                        <h4 className="text-[#004d40] dark:text-[#ffc107] text-xl font-bold mb-5 border-b-[3px] border-[#ffc107] inline-block pb-1">
                            ❓ {t('pricingPage.faq.title')}
                        </h4>
                        <div className="space-y-2">
                            {faqItems.map((faq, index) => {
                                const isOpen = openFaqIndex === index;
                                return (
                                    <div
                                        key={index}
                                        className={`rounded-xl border transition-all ${isOpen ? 'border-[#004d40] dark:border-[#ffc107]' : 'border-[#eee] dark:border-slate-600'} bg-[#f9f9f9] dark:bg-slate-700`}
                                    >
                                        <button
                                            type="button"
                                            onClick={() => setOpenFaqIndex(prev => prev === index ? null : index)}
                                            className="w-full flex justify-between items-center px-5 py-4 text-left"
                                        >
                                            <span className="text-sm font-bold text-[#004d40] dark:text-[#ffc107] pr-3">{faq.q}</span>
                                            <span className="text-lg font-bold text-[#004d40] dark:text-[#ffc107] flex-shrink-0">{isOpen ? '−' : '▼'}</span>
                                        </button>
                                        {isOpen && (
                                            <div className="px-5 pb-4 pt-2 border-t border-[#eee] dark:border-slate-600 text-sm text-gray-600 dark:text-slate-300 leading-relaxed">
                                                {faq.a}
                                            </div>
                                        )}
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                </div>

                {/* Ambassador CTA
                <div className="mt-8 rounded-2xl bg-gradient-to-r from-[#004d40] to-[#00796b] px-6 py-8 text-center text-white shadow-xl">
                    <h2 className="text-xl sm:text-2xl font-extrabold">{t('pricingPage.ambassador.title')}</h2>
                    <p className="mx-auto mt-2 max-w-2xl text-sm sm:text-base text-white/90">{t('pricingPage.ambassador.subtitle')}</p>
                    <Link to="/ambassador" className="mt-4 inline-flex items-center justify-center text-sm font-bold text-[#ffc107] underline underline-offset-4 hover:text-yellow-300 transition-colors">
                        {t('pricingPage.ambassador.cta')}
                    </Link>
                </div> */}

            </div>
        </div>
    );
};

export default PricingPage;
