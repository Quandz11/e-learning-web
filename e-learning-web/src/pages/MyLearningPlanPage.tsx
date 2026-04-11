import React from 'react';
import DailyPlannerView from '../components/planner/DailyPlannerView';

const MyLearningPlanPage: React.FC = () => {
    return (
        <div className="min-h-full overflow-x-hidden bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-950">
            <DailyPlannerView />
        </div>
    );
};

export default MyLearningPlanPage;
