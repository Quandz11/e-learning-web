import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { testimonialApi, type TestimonialDto, TestimonialType } from '../../services/testimonialApi';

const TestimonialsSection: React.FC = () => {
    const { t } = useTranslation();
    const [testimonials, setTestimonials] = useState<TestimonialDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchTestimonials();
    }, []);

    const fetchTestimonials = async () => {
        try {
            const data = await testimonialApi.getActive();
            // Limit to 6 testimonials for homepage
            setTestimonials(data.slice(0, 6));
        } catch (error) {
            console.error('Failed to load testimonials:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <section className="py-16 bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800">
                <div className="container mx-auto px-4">
                    <div className="text-center">
                        <div className="animate-pulse">
                            <div className="h-8 bg-slate-200 dark:bg-slate-700 rounded w-64 mx-auto mb-4"></div>
                            <div className="h-4 bg-slate-200 dark:bg-slate-700 rounded w-96 mx-auto"></div>
                        </div>
                    </div>
                </div>
            </section>
        );
    }

    if (testimonials.length === 0) {
        return null;
    }

    return (
        <section className="py-16 bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800">
            <div className="container mx-auto px-4">
                <div className="text-center mb-12">
                    <h2 className="text-3xl md:text-4xl font-bold text-primary dark:text-primary-light mb-4">
                        {t('home.testimonials.title')}
                    </h2>
                    <p className="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
                        {t('home.testimonials.subtitle')}
                    </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3 sm:gap-5 max-w-7xl mx-auto">
                    {testimonials.map((testimonial) => (
                        <div
                            key={testimonial.id}
                            className="bg-white dark:bg-slate-800 rounded-2xl p-4 sm:p-6 lg:p-8 shadow-lg hover:shadow-xl transition-all duration-300 border border-slate-100 dark:border-slate-700"
                        >
                            {/* Result Image (Before/After) */}
                            {testimonial.resultImageUrl && (
                                <div className="mb-4 sm:mb-6 -mx-4 sm:-mx-6 lg:-mx-8 overflow-hidden rounded-t-2xl bg-slate-100 dark:bg-slate-700">
                                    <img
                                        src={testimonial.resultImageUrl}
                                        alt={`${testimonial.name} result`}
                                        className="w-full aspect-video object-contain shadow-md hover:shadow-lg transition-shadow"
                                    />
                                </div>
                            )}

                            {testimonial.type === TestimonialType.Video && testimonial.videoUrl ? (
                                /* Video Testimonial */
                                <div className="mb-4 sm:mb-6">
                                    <video
                                        controls
                                        className="w-full rounded-lg"
                                        poster={testimonial.avatarUrl}
                                    >
                                        <source src={testimonial.videoUrl} type="video/mp4" />
                                        Your browser does not support the video tag.
                                    </video>
                                </div>
                            ) : (
                                /* Text Testimonial */
                                <>

                                    {/* Content */}
                                    <p className="text-slate-600 dark:text-slate-300 text-center mb-4 sm:mb-6 text-xs sm:text-sm lg:text-base italic leading-relaxed line-clamp-6 sm:line-clamp-none">
                                        "{testimonial.content}"
                                    </p>

                                    {/* Divider */}
                                    <div className="w-10 sm:w-16 h-1 bg-gradient-to-r from-primary to-primary/50 mx-auto mb-4 sm:mb-6"></div>
                                </>
                            )}

                            {/* Author */}
                            <div className="flex items-center justify-center gap-2 sm:gap-4">
                                {testimonial.avatarUrl && testimonial.type === TestimonialType.Text ? (
                                    <img
                                        src={testimonial.avatarUrl}
                                        alt={testimonial.name}
                                        className="w-10 h-10 sm:w-12 sm:h-12 rounded-full object-cover border-2 border-primary/20"
                                    />
                                ) : testimonial.type === TestimonialType.Text ? (
                                    <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-primary/20 flex items-center justify-center">
                                        <span className="material-symbols-outlined text-primary text-base sm:text-xl">
                                            person
                                        </span>
                                    </div>
                                ) : null}
                                <div>
                                    <h4 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white">
                                        {testimonial.name}
                                    </h4>
                                    {testimonial.position && (
                                        <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400">
                                            {testimonial.position}
                                        </p>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {/* View All Button */}
                <div className="text-center mt-12">
                    <Link
                        to="/testimonials"
                        className="inline-flex items-center gap-2 px-6 sm:px-8 py-3 bg-primary text-white rounded-full text-sm sm:text-base font-semibold hover:bg-primary/90 transition-colors shadow-lg hover:shadow-xl"
                    >
                        {t('home.testimonials.viewAll', { defaultValue: 'Xem tất cả' })}
                        <span className="material-symbols-outlined text-lg sm:text-xl">
                            arrow_forward
                        </span>
                    </Link>
                </div>
            </div>
        </section>
    );
};

export default TestimonialsSection;

