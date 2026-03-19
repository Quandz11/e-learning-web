import React from 'react';
import AiCoachDashboard from '../components/ai/AiCoachDashboard';

const MyLearningPlanPage: React.FC = () => {

    return (
        <div className="min-h-full overflow-x-hidden bg-[radial-gradient(circle_at_top_left,_rgba(250,204,21,0.18),_transparent_35%),linear-gradient(180deg,_rgba(255,255,255,0.98),_rgba(255,255,255,1))] dark:bg-[radial-gradient(circle_at_top_left,_rgba(250,204,21,0.12),_transparent_30%),linear-gradient(180deg,_rgba(15,23,42,0.98),_rgba(2,6,23,1))]">
            <div className="mx-auto max-w-[1680px] px-4 py-8 sm:px-6 lg:px-8 lg:py-10 2xl:px-10">
                {/* <div className="mb-8 flex flex-col gap-4 rounded-[28px] border border-white/70 bg-white/80 p-6 shadow-sm backdrop-blur dark:border-slate-800 dark:bg-slate-900/80 lg:flex-row lg:items-end lg:justify-between">
                    <div className="min-w-0">
                        <div className="text-sm font-semibold uppercase tracking-[0.2em] text-primary">
                            {t('aiCoach.page.eyebrow')}
                        </div>
                        <h1 className="mt-3 break-words text-3xl font-bold tracking-tight text-slate-900 dark:text-white">
                            {t('aiCoach.page.title')}
                        </h1>
                        <p className="mt-3 max-w-2xl break-words text-sm leading-7 text-slate-600 dark:text-slate-300">
                            {t('aiCoach.page.subtitle')}
                        </p>
                    </div>

                    <Link
                        to="/my-courses"
                        className="inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-4 py-2 text-sm font-semibold text-primary transition-colors hover:bg-primary/15"
                    >
                        <span className="material-symbols-outlined text-[18px]">library_books</span>
                        {t('aiCoach.page.backToCourses')}
                    </Link>
                </div> */}

                <AiCoachDashboard mode="page" />
            </div>
        </div>
    );
};

export default MyLearningPlanPage;
