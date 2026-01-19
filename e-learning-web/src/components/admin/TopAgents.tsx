import React from 'react';
import { useTranslation } from 'react-i18next';

const TopAgents: React.FC = () => {
    const { t } = useTranslation();

    return (
        <div className="flex flex-col gap-4 lg:col-span-1">
            <div className="flex items-center justify-between">
                <h3 className="text-lg font-bold text-slate-900 dark:text-white">{t('admin.topAgents.title')}</h3>
                <button className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
                    <span className="material-symbols-outlined">more_horiz</span>
                </button>
            </div>
            <div className="rounded-xl border border-slate-200 bg-dashboard-surface-light p-4 shadow-dashboard-subtle dark:border-slate-800 dark:bg-dashboard-surface-dark">
                <div className="flex flex-col gap-6">
                    {/* Agent Item 1 */}
                    <div className="flex items-center gap-4">
                        <div className="relative">
                            <div className="h-12 w-12 rounded-full border-2 border-white bg-cover bg-center shadow-sm dark:border-slate-700" style={{ backgroundImage: "url('https://lh3.googleusercontent.com/aida-public/AB6AXuAC9_qMIOs4-7XDtqbJiAK1ntUMziUWniVTDHYlUmcy-nGXWsmBya-tUodNhc8uigTBm69Dy6qweLI1NAbtM0HrZRgtLpiajbMT7QTGgSclhKQp_-kUGh-m_NDVGaykDbzPZEkk09ZDSfrNVaLIVj0hDrqiqQZ1h9fI2m-ZWQUTiYp8Xyzs10ZqT_qwglt4Z171N7nS2dEk1RYR9FEj-DnHtFYeH5gEvTV-XUTECtX88cJ32Z9aUQB9ytkZirRT24rqDXlbWNdOcQ')" }}></div>
                            <div className="absolute -bottom-1 -right-1 rounded-full border border-white bg-yellow-400 px-1.5 py-0.5 text-[10px] font-bold text-yellow-900 shadow-sm dark:border-slate-800">1</div>
                        </div>
                        <div className="min-w-0 flex-1">
                            <div className="mb-1 flex items-center justify-between">
                                <p className="truncate text-sm font-bold text-slate-900 dark:text-white">Jenny Wilson</p>
                                <p className="text-sm font-bold text-dashboard-primary">12.5 triệu VND</p>
                            </div>
                            <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-700">
                                <div className="h-1.5 rounded-full bg-dashboard-primary" style={{ width: '85%' }}></div>
                            </div>
                        </div>
                    </div>
                    {/* Agent Item 2 */}
                    <div className="flex items-center gap-4">
                        <div className="relative">
                            <div className="h-12 w-12 rounded-full border-2 border-white bg-cover bg-center shadow-sm dark:border-slate-700" style={{ backgroundImage: "url('https://lh3.googleusercontent.com/aida-public/AB6AXuBljycSiqe33ltJY_k5NNFs1R03XlYLL2zZIzBR6bq74wQWHWicB-b1df3zqamnMo2DJkk2zQcZDCB7SnGTrqBFbFfY0FQt4R7Qwknug6L1XQtcKAawe5o5NwcXeTJkYJXFQ5fBudogdZjTaAJd-it_R8gm5mya1zCHl5JH74bLhc3RNAo6fD-9HNqa66XJ43gfR_4DtY-HMEPBJ5rSZgqFLOXSKcQUtzg_ao8U-EpOvtybAtSfLRvwMrxwH5h8Fe3cVMcvogpiGA')" }}></div>
                            <div className="absolute -bottom-1 -right-1 rounded-full border border-white bg-slate-200 px-1.5 py-0.5 text-[10px] font-bold text-slate-600 shadow-sm dark:border-slate-800">2</div>
                        </div>
                        <div className="min-w-0 flex-1">
                            <div className="mb-1 flex items-center justify-between">
                                <p className="truncate text-sm font-bold text-slate-900 dark:text-white">Robert Fox</p>
                                <p className="text-sm font-bold text-dashboard-primary">9.2 triệu VND</p>
                            </div>
                            <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-700">
                                <div className="h-1.5 rounded-full bg-dashboard-primary/80" style={{ width: '65%' }}></div>
                            </div>
                        </div>
                    </div>
                    {/* Agent Item 3 */}
                    <div className="flex items-center gap-4">
                        <div className="relative">
                            <div className="h-12 w-12 rounded-full border-2 border-white bg-cover bg-center shadow-sm dark:border-slate-700" style={{ backgroundImage: "url('https://lh3.googleusercontent.com/aida-public/AB6AXuCFAfLkqI8KBqbn2lvC6Kcj2gIzDv6rh-jguT1zhf21LzI3XRUVfBqnoPZreGyByFSQ4Mpzb2tO8e-nLQ7z0L_yitImThmjfZ5kdXtEUTrXNV2v67x_PJx35P-aEEk9CqrrIT7-HBk6Fr0tYtKD1ZSygAMkVkh8Ln2wValkNB5pQfUuv6uJ2nwh5axhqWjsQEEcfXXV7Y-KylO1uqtXKc4j0RJYqoVzpRDwlzE3_VZrG_2-B4Si1gfFBmHXaNYCWWQM86UWjm1RpQ')" }}></div>
                            <div className="absolute -bottom-1 -right-1 rounded-full border border-white bg-orange-200 px-1.5 py-0.5 text-[10px] font-bold text-orange-800 shadow-sm dark:border-slate-800">3</div>
                        </div>
                        <div className="min-w-0 flex-1">
                            <div className="mb-1 flex items-center justify-between">
                                <p className="truncate text-sm font-bold text-slate-900 dark:text-white">Cody Fisher</p>
                                <p className="text-sm font-bold text-dashboard-primary">5.4 triệu VND</p>
                            </div>
                            <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-700">
                                <div className="h-1.5 rounded-full bg-dashboard-primary/60" style={{ width: '45%' }}></div>
                            </div>
                        </div>
                    </div>
                    {/* Agent Item 4 */}
                    <div className="flex items-center gap-4 opacity-75">
                        <div className="relative">
                            <div className="h-12 w-12 rounded-full border-2 border-white bg-cover bg-center shadow-sm dark:border-slate-700" style={{ backgroundImage: "url('https://lh3.googleusercontent.com/aida-public/AB6AXuC2phEvD8MEp399JcWoE-Ychc_5xaR43DOz0wWXlSlZDU_rcpmSDRYZ861TnUfhfH5aG6idpBbmUyEnwHbBt7LGVuja1zhZZSq1CNHnPga6bpeYWyknJ5RjC8G_VIRtNtlrnN9F3efG2iGVVCEb1jVtbuR4JZ25PSnfGAC0rdoW1xPSf8FOX7HYUcBpRPuN0pdQ479Ymv4eoocAls49odwykOcqrEj-pbd59FrSyTANvVeQpdOZB51DMJZYnKaXQiB5LXjHuXgvpg')" }}></div>
                        </div>
                        <div className="min-w-0 flex-1">
                            <div className="mb-1 flex items-center justify-between">
                                <p className="truncate text-sm font-bold text-slate-900 dark:text-white">Guy Hawkins</p>
                                <p className="text-sm font-bold text-dashboard-primary">3.1 triệu VND</p>
                            </div>
                            <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-700">
                                <div className="h-1.5 rounded-full bg-dashboard-primary/40" style={{ width: '30%' }}></div>
                            </div>
                        </div>
                    </div>
                </div>
                <div className="mt-6 border-t border-slate-100 pt-4 dark:border-slate-700/50">
                    <a className="block text-center text-sm font-medium text-slate-500 transition-colors hover:text-dashboard-primary" href="#">{t('admin.topAgents.viewAll')}</a>
                </div>
            </div>
        </div>
    );
};

export default TopAgents;
