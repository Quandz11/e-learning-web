import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import CourseList from '../components/courses/CourseList';
import QuizModal from '../components/quiz/QuizModal';
import TestimonialsSection from '../components/home/TestimonialsSection';

const HomePage: React.FC = () => {
  const { t } = useTranslation();
  const [isQuizOpen, setIsQuizOpen] = useState(false);

  return (
    <>
      <section className="relative overflow-hidden bg-primary px-4 py-20 sm:px-6 lg:px-8">
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-10">
          <svg className="h-full w-full" viewBox="0 0 100 100" preserveAspectRatio="none">
            <path d="M0 100 C 20 0 50 0 100 100 Z" fill="white" />
          </svg>
        </div>

        <div className="relative mx-auto max-w-7xl text-center">
          <h1 className="mb-4 text-4xl font-extrabold tracking-tight text-white sm:text-5xl md:text-6xl animate-fadeDown">
            {t('fasting.title', { defaultValue: 'Welcome to the Fasting Method' })}
          </h1>
          <p className="mx-auto mb-8 max-w-2xl text-xl text-white/90 animate-fadeIn delay-100">
            {t('fasting.subtitle', { defaultValue: 'Intermittent Fasting for Weight Loss' })}
          </p>
          <p className="mx-auto mb-10 max-w-3xl text-lg text-white/80 animate-fadeIn delay-200">
            {t('fasting.description', { defaultValue: 'Experience the most comprehensive fasting program.' })}
          </p>

          <div className="flex justify-center animate-fadeIn delay-300">
            <button
              onClick={() => setIsQuizOpen(true)}
              className="transform rounded-full bg-white px-8 py-4 text-lg font-bold text-primary shadow-lg transition-all duration-300 hover:scale-105 hover:shadow-xl hover:bg-gray-50 focus:outline-none focus:ring-4 focus:ring-white/50"
            >
              {t('fasting.takeQuiz', { defaultValue: 'Take the quiz to start' })}
            </button>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <TestimonialsSection />

      {/* Featured Courses Section */}
      <section className="bg-gray-50 dark:bg-gray-800 py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mb-12 text-center">
            <h2 className="text-3xl font-bold text-gray-900 dark:text-white sm:text-4xl">
              {t('home.courses.title')}
            </h2>
            <p className="mt-4 text-lg text-gray-600 dark:text-gray-300">
              {t('home.courses.subtitle')}
            </p>
          </div>

          <CourseList limit={3} showFilter={false} />

          <div className="mt-12 text-center">
            <Link
              to="/courses"
              className="inline-flex items-center rounded-lg border border-gray-300 bg-white px-6 py-3 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200 dark:hover:bg-gray-600"
            >
              {t('home.courses.viewAll')}
              <span className="material-symbols-outlined ml-2 text-sm">arrow_forward</span>
            </Link>
          </div>
        </div>
      </section>

      {/* Benefits / Social Proof (Simplified for now) */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="text-center max-w-2xl mx-auto mb-12">
          <h2 className="text-3xl md:text-4xl font-bold text-[#0c1c1d] dark:text-white mb-4">
            Why Choose Us?
          </h2>
          <p className="text-gray-600 dark:text-gray-400">
            The best way to learn and grow.
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
          <div className="p-6 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
            <span className="material-symbols-outlined text-4xl text-primary mb-4">school</span>
            <h3 className="text-xl font-bold mb-2 dark:text-white">Expert Instructors</h3>
            <p className="text-gray-600 dark:text-gray-400">Learn from the best in the industry.</p>
          </div>
          <div className="p-6 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
            <span className="material-symbols-outlined text-4xl text-primary mb-4">schedule</span>
            <h3 className="text-xl font-bold mb-2 dark:text-white">Flexible Learning</h3>
            <p className="text-gray-600 dark:text-gray-400">Study at your own pace, anytime, anywhere.</p>
          </div>
          <div className="p-6 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
            <span className="material-symbols-outlined text-4xl text-primary mb-4">workspace_premium</span>
            <h3 className="text-xl font-bold mb-2 dark:text-white">Certified</h3>
            <p className="text-gray-600 dark:text-gray-400">Earn certificates upon completion.</p>
          </div>
        </div>
      </section>

      <QuizModal isOpen={isQuizOpen} onClose={() => setIsQuizOpen(false)} />
    </>
  );
};

export default HomePage;