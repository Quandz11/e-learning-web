import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import CourseList from '../components/courses/CourseList';
import QuizModal from '../components/quiz/QuizModal';
import TestimonialsSection from '../components/home/TestimonialsSection';
import RecodeKitSection from '../components/home/RecodeKitSection';
import CourseConsultationForm from '../components/home/CourseConsultationForm';
import { homeSectionApi, type HomeVideoSectionDto } from '../services/homeSectionApi';
import { whyChooseUsApi, type WhyChooseUsItemDto } from '../services/whyChooseUsApi';

const HomePage: React.FC = () => {
  const { t } = useTranslation();
  const [isQuizOpen, setIsQuizOpen] = useState(false);
  const [homeSection, setHomeSection] = useState<HomeVideoSectionDto | null>(null);
  const [whyChooseUsItems, setWhyChooseUsItems] = useState<WhyChooseUsItemDto[]>([]);

  useEffect(() => {
    homeSectionApi.getHomeSection()
      .then(setHomeSection)
      .catch(() => {}); // Silently fail if not configured yet
    whyChooseUsApi.getActive()
      .then(setWhyChooseUsItems)
      .catch(() => {});
  }, []);

  const getYoutubeId = (url: string) => {
    const match = url.match(/(?:v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
    return match ? match[1] : null;
  };

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
          <p className="mb-4 text-4xl font-extrabold tracking-tight text-white/90 sm:text-5xl md:text-6xl animate-fadeDown">
            {t('fasting.title')}
          </p>
          <p className="mx-auto mb-8 max-w-7xl text-3xl text-white/90 animate-fadeIn delay-100">
            {t('fasting.subtitle')}
          </p>
          {/* <p className="mx-auto mb-10 max-w-3xl text-lg text-white/80 animate-fadeIn delay-200">
            {t('fasting.description')}
          </p> */}

          <div className="flex justify-center animate-fadeIn delay-300">
            <button
              onClick={() => setIsQuizOpen(true)}
              className="transform rounded-full bg-white px-8 py-4 text-lg font-bold text-primary shadow-lg transition-all duration-300 hover:scale-105 hover:shadow-xl hover:bg-gray-50 focus:outline-none focus:ring-4 focus:ring-white/50"
            >
              {t('fasting.takeQuiz')}
            </button>
          </div>
        </div>
      </section>

      {/* Home Video Section */}
      {homeSection && (homeSection.contentHtml || homeSection.videoUrl || homeSection.videoId) && (
        <section className="bg-white dark:bg-gray-900 py-16 px-4 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-7xl">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-center">
              {/* Left: Text Content */}
              <div
                className="rich-text text-gray-700 dark:text-gray-300 text-lg leading-relaxed"
                dangerouslySetInnerHTML={{ __html: homeSection.contentHtml || '' }}
              />
              {/* Right: Video */}
              <div className="rounded-2xl overflow-hidden shadow-xl border border-gray-100 dark:border-gray-800">
                {homeSection.videoType === 'youtube' && homeSection.videoUrl ? (() => {
                  const ytId = getYoutubeId(homeSection.videoUrl);
                  if (ytId) {
                    return (
                      <iframe
                        src={`https://www.youtube.com/embed/${ytId}`}
                        className="w-full aspect-video"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                        allowFullScreen
                      />
                    );
                  }
                  if (homeSection.videoUrl.includes('<iframe')) {
                    return (
                      <div
                        className="w-full aspect-video [&>iframe]:w-full [&>iframe]:h-full"
                        dangerouslySetInnerHTML={{ __html: homeSection.videoUrl }}
                      />
                    );
                  }
                  return null;
                })() : homeSection.videoType === 'bunny' && homeSection.bunnyVideoId ? (
                  <iframe
                    src={`https://iframe.mediadelivery.net/embed/${homeSection.bunnyVideoId}`}
                    className="w-full aspect-video"
                    allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
                    allowFullScreen
                  />
                ) : null}
              </div>
            </div>
          </div>
        </section>
      )}


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

          <CourseList pageSize={12} showPagination cols={4} showFilter={false} />
        </div>
      </section>

      {/* Recode - 10 Kit Section */}
      <RecodeKitSection />

      {/* Testimonials Section */}
      <TestimonialsSection />

      {/* Why Choose Us Section */}
      {whyChooseUsItems.length > 0 && (
        <section className="max-w-7xl mx-auto px-4 py-14 sm:px-6 sm:py-16 lg:px-8 lg:py-20">
          <div className="mx-auto mb-10 max-w-2xl text-center sm:mb-12">
            <h2 className="mb-3 text-2xl font-bold text-[#0c1c1d] dark:text-white sm:mb-4 sm:text-3xl md:text-4xl">
              {t('home.whyChooseUs.title')}
            </h2>
            <p className="text-sm text-gray-600 dark:text-gray-400 sm:text-base">
              {t('home.whyChooseUs.subtitle')}
            </p>
          </div>
          <div className="grid grid-cols-2 gap-3 text-center sm:gap-4 md:grid-cols-3 md:gap-8">
            {whyChooseUsItems.map(item => (
              <div key={item.id} className="rounded-xl border border-gray-100 bg-white p-4 shadow-sm dark:border-gray-700 dark:bg-gray-800 sm:p-5 md:p-6">
                <span className="material-symbols-outlined mb-3 block text-2xl text-primary sm:text-3xl md:mb-4 md:text-4xl">{item.icon}</span>
                <h3 className="mb-1 text-sm font-bold dark:text-white sm:text-base md:mb-2 md:text-xl">{item.title}</h3>
                <p className="line-clamp-4 text-xs text-gray-600 dark:text-gray-400 sm:text-sm md:line-clamp-none">{item.description}</p>
              </div>
            ))}
          </div>
        </section>
        
      )}
      <CourseConsultationForm />

      <QuizModal isOpen={isQuizOpen} onClose={() => setIsQuizOpen(false)} />
    </>
  );
};

export default HomePage;