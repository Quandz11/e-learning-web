import React from 'react';
import WellnessCoachDashboard from '../components/wellness/WellnessCoachDashboard';

const MyLearningPlanPage: React.FC = () => {
    return (
        <div className="min-h-full overflow-x-hidden bg-[radial-gradient(circle_at_top_left,_rgba(250,204,21,0.18),_transparent_35%),linear-gradient(180deg,_rgba(255,255,255,0.98),_rgba(255,255,255,1))] dark:bg-[radial-gradient(circle_at_top_left,_rgba(250,204,21,0.12),_transparent_30%),linear-gradient(180deg,_rgba(15,23,42,0.98),_rgba(2,6,23,1))]">
            <div className="mx-auto max-w-[1680px] px-4 py-8 sm:px-6 lg:px-8 lg:py-10 2xl:px-10">
                <WellnessCoachDashboard />
            </div>
        </div>
    );
};

export default MyLearningPlanPage;
