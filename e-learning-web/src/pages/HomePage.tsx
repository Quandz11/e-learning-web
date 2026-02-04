import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useSelector, useDispatch } from 'react-redux';
import { useTranslation } from 'react-i18next';
import type { RootState, AppDispatch } from '../store/store';
import { logout } from '../store/authSlice';
import { authApi } from '../services/authApi';
import { clearAuth } from '../services/authStorage';
import { courseApi, type CourseResponse } from '../services/courseApi';
import HeaderNotification from '../components/common/HeaderNotification';

const HomePage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);

  const [courses, setCourses] = useState<CourseResponse[]>([]);
  const [coursesLoading, setCoursesLoading] = useState(true);
  const [coursesError, setCoursesError] = useState<string | null>(null);

  useEffect(() => {
    const fetchCourses = async () => {
      try {
        setCoursesLoading(true);
        const allCourses = await courseApi.getAll();
        // Filter only published courses for students
        const publishedCourses = allCourses.filter(c => c.isPublished);
        setCourses(publishedCourses.slice(0, 3)); // Show only first 3 on homepage
      } catch (err: any) {
        setCoursesError(err.message || 'Failed to load courses');
      } finally {
        setCoursesLoading(false);
      }
    };
    fetchCourses();
  }, []);

  const handleLogout = async () => {
    try {
      await authApi.logout();
      dispatch(logout());
      clearAuth();
      navigate('/login');
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  return (
    <div className="bg-background-light dark:bg-background-dark min-h-screen flex flex-col font-display text-[#0c1c1d] dark:text-white overflow-x-hidden">
      {/* Sticky Header */}
      <header className="sticky top-0 z-50 w-full bg-background-light/95 dark:bg-background-dark/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-20">
            {/* Logo */}
            <Link to="/" className="flex items-center gap-3">
              <div className="size-8 text-primary flex items-center justify-center">
                <span className="material-symbols-outlined text-4xl">school</span>
              </div>
              <h2 className="text-[#0c1c1d] dark:text-white text-xl font-bold tracking-tight">
                SKVI Learning<span className="text-primary">.</span>
              </h2>
            </Link>

            {/* Desktop Nav */}
            <nav className="hidden md:flex items-center gap-8">
              <Link className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-semibold" to="/">
                {t('home.header.nav.home')}
              </Link>
              <a className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium" href="#courses">
                {t('home.header.nav.courses')}
              </a>
              <a className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium" href="#benefits">
                {t('home.header.nav.benefits')}
              </a>
              <a className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium" href="#testimonials">
                {t('home.header.nav.testimonials')}
              </a>
            </nav>

            {/* Auth Buttons */}
            <div className="flex items-center gap-3">
              {isAuthenticated && user ? (
                <>
                  <div className="mr-2">
                    <HeaderNotification />
                  </div>
                  <span className="hidden sm:inline text-sm text-gray-600 dark:text-gray-300 font-display">
                    {t('home.header.welcome')}, <span className="font-medium text-gray-900 dark:text-white normal-case">{user.fullName}</span>
                  </span>
                  <button
                    onClick={handleLogout}
                    className="flex h-10 items-center justify-center rounded-lg px-5 bg-primary hover:bg-primary/90 text-white font-bold text-sm shadow-md shadow-primary/20 transition-all hover:scale-105"
                  >
                    {t('home.header.logout')}
                  </button>
                </>
              ) : (
                <>
                  <Link
                    to="/login"
                    className="hidden sm:flex h-10 items-center justify-center rounded-lg px-4 text-primary font-bold text-sm hover:bg-primary/10 transition-colors"
                  >
                    {t('auth.logIn')}
                  </Link>
                  <Link
                    to="/register"
                    className="flex h-10 items-center justify-center rounded-lg px-5 bg-primary hover:bg-primary/90 text-white font-bold text-sm shadow-md shadow-primary/20 transition-all hover:scale-105"
                  >
                    {t('auth.signUp')}
                  </Link>
                </>
              )}
            </div>
          </div>
        </div>
      </header>

      <main className="flex-grow">
        {/* Hero Section */}
        <section className="relative py-12 lg:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            {/* Content */}
            <div className="flex flex-col gap-8 max-w-2xl">
              <div className="space-y-4">
                <span className="inline-block py-1 px-3 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider">
                  {t('home.hero.badge')}
                </span>
                <h1 className="text-5xl lg:text-6xl font-bold leading-[1.1] tracking-tight text-[#0c1c1d] dark:text-white">
                  {t('home.hero.title')} <br />
                  <span className="text-primary">{t('home.hero.titleHighlight')}</span>
                </h1>
                <h2 className="text-lg text-gray-600 dark:text-gray-300 font-medium leading-relaxed max-w-lg">
                  {t('home.hero.subtitle')}
                </h2>
              </div>

              {/* Search Box */}
              <div className="relative w-full max-w-md group">
                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <span className="material-symbols-outlined text-primary">search</span>
                </div>
                <input
                  className="block w-full pl-12 pr-32 py-4 rounded-xl border-0 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-[0_8px_30px_rgb(0,0,0,0.04)] placeholder:text-gray-400 focus:ring-2 focus:ring-primary sm:text-sm sm:leading-6"
                  placeholder={t('home.hero.searchPlaceholder')}
                  type="text"
                />
                <div className="absolute inset-y-2 right-2">
                  <button
                    className="h-full px-6 bg-primary hover:bg-primary/90 text-white text-sm font-bold rounded-lg transition-colors"
                    type="button"
                  >
                    {t('home.hero.searchButton')}
                  </button>
                </div>
              </div>

              {/* Social Proof */}
              <div className="flex items-center gap-4 pt-2">
                <div className="flex -space-x-3">
                  <div className="inline-block h-10 w-10 rounded-full ring-2 ring-white dark:ring-background-dark bg-gradient-to-br from-blue-400 to-blue-600"></div>
                  <div className="inline-block h-10 w-10 rounded-full ring-2 ring-white dark:ring-background-dark bg-gradient-to-br from-purple-400 to-purple-600"></div>
                  <div className="inline-block h-10 w-10 rounded-full ring-2 ring-white dark:ring-background-dark bg-gradient-to-br from-pink-400 to-pink-600"></div>
                  <div className="h-10 w-10 rounded-full ring-2 ring-white dark:ring-background-dark bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-xs font-bold text-gray-600 dark:text-gray-300">
                    +2k
                  </div>
                </div>
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  {t('home.hero.socialProof')}
                </p>
              </div>
            </div>

            {/* Bento Grid Imagery */}
            <div className="h-full w-full grid grid-cols-2 grid-rows-2 gap-4 h-[400px] lg:h-[500px]">
              <div className="row-span-2 rounded-2xl overflow-hidden shadow-lg relative group bg-gradient-to-br from-blue-500 to-purple-600">
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent z-10"></div>
                <div className="absolute bottom-4 left-4 z-20 text-white">
                  <p className="font-bold text-lg">{t('home.hero.interactive')}</p>
                  <p className="text-xs opacity-90">{t('home.hero.liveSession')}</p>
                </div>
              </div>
              <div className="rounded-2xl overflow-hidden shadow-lg relative group bg-gradient-to-br from-orange-400 to-pink-500">
              </div>
              <div className="rounded-2xl bg-primary text-white p-6 flex flex-col justify-between relative overflow-hidden group">
                <span className="material-symbols-outlined text-6xl opacity-20 absolute -right-4 -bottom-4 rotate-12 group-hover:rotate-0 transition-transform">verified</span>
                <div>
                  <p className="text-3xl font-bold">98%</p>
                  <p className="text-sm opacity-90">{t('home.hero.stats.completionRate')}</p>
                </div>
                <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider mt-2">
                  {t('home.hero.stats.viewStats')} <span className="material-symbols-outlined text-sm">arrow_forward</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Featured Courses */}
        <section id="courses" className="py-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-8">
            <div>
              <h2 className="text-3xl md:text-4xl font-bold text-[#0c1c1d] dark:text-white">
                {t('home.courses.title')}
              </h2>
              <p className="mt-2 text-gray-600 dark:text-gray-400">
                {t('home.courses.subtitle')}
              </p>
            </div>
            <button
              onClick={() => navigate('/courses')}
              className="flex items-center gap-2 text-primary font-bold hover:gap-3 transition-all"
            >
              {t('home.courses.viewAll')} <span className="material-symbols-outlined text-sm">arrow_forward</span>
            </button>
          </div>

          {/* Course Grid */}
          {coursesLoading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[0, 1, 2].map((i) => (
                <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden animate-pulse">
                  <div className="aspect-video bg-gray-200 dark:bg-gray-700" />
                  <div className="p-5 space-y-3">
                    <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4" />
                    <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded" />
                    <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-5/6" />
                  </div>
                </div>
              ))}
            </div>
          ) : coursesError ? (
            <div className="text-center py-12 text-red-500">
              {coursesError}
            </div>
          ) : courses.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              {t('home.courses.noCourses', { defaultValue: 'No courses available yet' })}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {courses.map((course, index) => (
                <Link
                  key={course.id}
                  to={`/courses/${course.id}`}
                  className="group flex flex-col bg-white dark:bg-gray-800 rounded-2xl shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100 dark:border-gray-700 overflow-hidden"
                >
                  <div className="relative aspect-video overflow-hidden bg-gradient-to-br from-primary/20 to-primary/5">
                    {course.thumbnailUrl ? (
                      <img
                        src={course.thumbnailUrl}
                        alt={course.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    ) : (
                      <div className="absolute inset-0 bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500" />
                    )}
                    {course.isFree && (
                      <div className="absolute top-3 left-3 bg-green-500 text-white text-xs font-bold px-2 py-1 rounded shadow-sm z-10">
                        {t('home.courses.free', { defaultValue: 'FREE' })}
                      </div>
                    )}
                    {index === 0 && !course.isFree && (
                      <div className="absolute top-3 left-3 bg-red-500 text-white text-xs font-bold px-2 py-1 rounded shadow-sm z-10">
                        {t('home.courses.popular', { defaultValue: 'POPULAR' })}
                      </div>
                    )}
                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors"></div>
                  </div>
                  <div className="p-5 flex flex-col flex-grow">
                    <div className="flex items-center gap-2 mb-3">
                      <span className="material-symbols-outlined text-yellow-400 text-sm">star</span>
                      <span className="text-xs font-bold text-gray-700 dark:text-gray-300">
                        4.8 (128 {t('home.courses.reviews')})
                      </span>
                    </div>
                    <h3 className="text-xl font-bold text-[#0c1c1d] dark:text-white mb-2 leading-tight line-clamp-2">
                      {course.title}
                    </h3>
                    <p className="text-sm text-gray-500 dark:text-gray-400 mb-4 line-clamp-2">
                      {course.description}
                    </p>
                    <div className="mt-auto pt-4 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        {course.lecturer?.avatarUrl ? (
                          <img
                            src={course.lecturer.avatarUrl}
                            alt={course.lecturer.fullName}
                            className="w-6 h-6 rounded-full object-cover"
                          />
                        ) : (
                          <div className="w-6 h-6 rounded-full bg-gradient-to-br from-primary to-blue-600" />
                        )}
                        <span className="text-xs font-medium text-gray-600 dark:text-gray-300 truncate max-w-[120px]">
                          {course.lecturer?.fullName || 'SKVI Instructor'}
                        </span>
                      </div>
                      <span className="text-primary font-bold text-lg">
                        {course.isFree ? t('home.courses.free', { defaultValue: 'FREE' }) : `${course.price.toLocaleString('vi-VN')} VND`}
                      </span>
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </section>

        {/* Benefits Bento Grid */}
        <section id="benefits" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
          <div className="text-center max-w-2xl mx-auto mb-12">
            <h2 className="text-3xl md:text-4xl font-bold text-[#0c1c1d] dark:text-white mb-4">
              {t('home.benefits.title')}
            </h2>
            <p className="text-gray-600 dark:text-gray-400">
              {t('home.benefits.subtitle')}
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 grid-rows-auto md:grid-rows-2 gap-4">
            {/* Large Box 1 */}
            <div className="md:col-span-2 md:row-span-2 bg-white dark:bg-gray-800 p-8 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 flex flex-col justify-center items-start">
              <div className="p-3 bg-primary/10 rounded-xl mb-6">
                <span className="material-symbols-outlined text-primary text-3xl">school</span>
              </div>
              <h3 className="text-2xl font-bold mb-3 dark:text-white">{t('home.benefits.certifiedInstructors.title')}</h3>
              <p className="text-gray-600 dark:text-gray-300 mb-6">
                {t('home.benefits.certifiedInstructors.description')}
              </p>
              <button className="px-5 py-2 rounded-lg border border-gray-300 dark:border-gray-600 font-bold text-sm hover:border-primary hover:text-primary transition-colors dark:text-white">
                {t('home.benefits.certifiedInstructors.cta')}
              </button>
            </div>

            {/* Box 2 */}
            <div className="bg-primary/10 dark:bg-primary/20 p-6 rounded-2xl flex flex-col justify-between">
              <span className="material-symbols-outlined text-primary text-4xl mb-4">schedule</span>
              <div>
                <h4 className="font-bold text-lg dark:text-white">{t('home.benefits.selfPaced.title')}</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400">{t('home.benefits.selfPaced.description')}</p>
              </div>
            </div>

            {/* Box 3 */}
            <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl border border-gray-100 dark:border-gray-700 flex flex-col justify-between">
              <span className="material-symbols-outlined text-orange-500 text-4xl mb-4">workspace_premium</span>
              <div>
                <h4 className="font-bold text-lg dark:text-white">{t('home.benefits.certificates.title')}</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400">{t('home.benefits.certificates.description')}</p>
              </div>
            </div>

            {/* Box 4 (Wide) */}
            <div className="md:col-span-2 bg-gradient-to-r from-primary to-teal-700 p-8 rounded-2xl flex items-center justify-between text-white relative overflow-hidden">
              <div className="relative z-10">
                <h3 className="text-2xl font-bold mb-2">{t('home.benefits.support.title')}</h3>
                <p className="opacity-90 max-w-xs">{t('home.benefits.support.description')}</p>
              </div>
              <div className="p-3 bg-white/20 backdrop-blur-sm rounded-full relative z-10">
                <span className="material-symbols-outlined text-3xl">support_agent</span>
              </div>
              <div className="absolute -right-10 -bottom-10 w-40 h-40 bg-white/10 rounded-full blur-2xl"></div>
            </div>
          </div>
        </section>

        {/* Testimonials */}
        <section id="testimonials" className="bg-gray-50 dark:bg-gray-900 py-16">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <h2 className="text-3xl font-bold text-center mb-12 dark:text-white">
              {t('home.testimonials.title')}
            </h2>
            <div className="grid md:grid-cols-3 gap-8">
              {([0, 1, 2] as const).map((index) => {
                const testimonial = t(`home.testimonials.items.${index}`, { returnObjects: true }) as any;
                return (
                  <div
                    key={index}
                    className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 relative"
                  >
                    <span className="material-symbols-outlined text-primary/20 text-6xl absolute top-4 right-4">
                      format_quote
                    </span>
                    <p className="text-gray-600 dark:text-gray-300 italic mb-6 relative z-10">
                      "{testimonial.quote}"
                    </p>
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-blue-600"></div>
                      <div>
                        <p className="font-bold text-sm dark:text-white">{testimonial.name}</p>
                        <p className="text-xs text-gray-500">{testimonial.role}</p>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </section>

        {/* Newsletter CTA */}
        <section className="py-20 px-4">
          <div className="max-w-4xl mx-auto bg-primary rounded-3xl p-8 md:p-12 text-center text-white relative overflow-hidden">
            <div className="absolute top-0 left-0 w-full h-full opacity-10 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-white via-transparent to-transparent"></div>
            <h2 className="text-3xl font-bold mb-4 relative z-10">{t('home.newsletter.title')}</h2>
            <p className="mb-8 opacity-90 relative z-10">{t('home.newsletter.subtitle')}</p>
            <div className="flex flex-col sm:flex-row gap-2 justify-center relative z-10 max-w-md mx-auto">
              <input
                className="px-4 py-3 rounded-lg text-gray-900 border-none focus:ring-2 focus:ring-teal-300 flex-grow"
                placeholder={t('home.newsletter.placeholder')}
                type="email"
              />
              <button className="bg-gray-900 hover:bg-gray-800 text-white px-6 py-3 rounded-lg font-bold transition-colors">
                {t('home.newsletter.cta')}
              </button>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="bg-background-dark text-white pt-16 pb-8 border-t border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-3xl">school</span>
                <span className="text-xl font-bold">SKVI Learning.</span>
              </div>
              <p className="text-gray-400 text-sm">
                {t('home.footer.description')}
              </p>
            </div>
            <div>
              <h3 className="font-bold mb-4">{t('home.footer.platform.title')}</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><a className="hover:text-primary transition-colors" href="#courses">{t('home.footer.platform.browseCourses')}</a></li>
                <li><a className="hover:text-primary transition-colors" href="#testimonials">{t('home.footer.platform.successStories')}</a></li>
                <li><a className="hover:text-primary transition-colors" href="#">{t('home.footer.platform.pricing')}</a></li>
                <li><a className="hover:text-primary transition-colors" href="#">{t('home.footer.platform.forBusiness')}</a></li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold mb-4">{t('home.footer.portals.title')}</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><Link className="hover:text-primary transition-colors" to="/login">{t('home.footer.portals.studentLogin')}</Link></li>
                <li><Link className="hover:text-primary transition-colors" to="/login">{t('home.footer.portals.instructorDashboard')}</Link></li>
                <li><Link className="hover:text-primary transition-colors" to="/login">{t('home.footer.portals.agentPortal')}</Link></li>
                <li><Link className="hover:text-primary transition-colors" to="/admin/dashboard">{t('home.footer.portals.adminAccess')}</Link></li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold mb-4">{t('home.footer.connect.title')}</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><a className="hover:text-primary transition-colors" href="#">{t('home.footer.connect.aboutUs')}</a></li>
                <li><a className="hover:text-primary transition-colors" href="#">{t('home.footer.connect.careers')}</a></li>
                <li><a className="hover:text-primary transition-colors" href="#">{t('home.footer.connect.contactSupport')}</a></li>
                <li><a className="hover:text-primary transition-colors" href="#">{t('home.footer.connect.privacyPolicy')}</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 pt-8 flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-gray-500">
            <p>{t('home.footer.copyright')}</p>
            <div className="flex gap-6">
              <a className="hover:text-white transition-colors" href="#">{t('home.footer.terms')}</a>
              <a className="hover:text-white transition-colors" href="#">{t('home.footer.privacy')}</a>
              <a className="hover:text-white transition-colors" href="#">{t('home.footer.cookies')}</a>
            </div>
          </div>
        </div>
      </footer>
    </div >
  );
};

export default HomePage;
