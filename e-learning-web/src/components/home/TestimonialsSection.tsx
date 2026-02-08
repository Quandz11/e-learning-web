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
            // Limit to 3 testimonials for homepage
            setTestimonials(data.slice(0, 3));
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
                    <h2 className="text-3xl md:text-4xl font-bold text-slate-900 dark:text-white mb-4">
                        {t('home.testimonials.title')}
                    </h2>
                    <p className="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
                        {t('home.testimonials.subtitle')}
                    </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
                    {testimonials.map((testimonial) => (
                        <div
                            key={testimonial.id}
                            className="bg-white dark:bg-slate-800 rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 border border-slate-100 dark:border-slate-700"
                        >
                            {testimonial.type === TestimonialType.Video && testimonial.videoUrl ? (
                                /* Video Testimonial */
                                <div className="mb-6">
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
                                    {/* Quote Icon */}
                                    <div className="flex justify-center mb-6">
                                        <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
                                            <span className="material-symbols-outlined text-primary text-2xl">
                                                format_quote
                                            </span>
                                        </div>
                                    </div>

                                    {/* Content */}
                                    <p className="text-slate-600 dark:text-slate-300 text-center mb-6 italic leading-relaxed">
                                        "{testimonial.content}"
                                    </p>

                                    {/* Divider */}
                                    <div className="w-16 h-1 bg-gradient-to-r from-primary to-primary/50 mx-auto mb-6"></div>
                                </>
                            )}

                            {/* Author */}
                            <div className="flex items-center justify-center gap-4">
                                {testimonial.avatarUrl && testimonial.type === TestimonialType.Text ? (
                                    <img
                                        src={testimonial.avatarUrl}
                                        alt={testimonial.name}
                                        className="w-12 h-12 rounded-full object-cover border-2 border-primary/20"
                                    />
                                ) : testimonial.type === TestimonialType.Text ? (
                                    <div className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center">
                                        <span className="material-symbols-outlined text-primary text-xl">
                                            person
                                        </span>
                                    </div>
                                ) : null}
                                <div>
                                    <h4 className="font-bold text-slate-900 dark:text-white">
                                        {testimonial.name}
                                    </h4>
                                    {testimonial.position && (
                                        <p className="text-sm text-slate-500 dark:text-slate-400">
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
                        className="inline-flex items-center gap-2 px-8 py-3 bg-primary text-white rounded-full font-semibold hover:bg-primary/90 transition-colors shadow-lg hover:shadow-xl"
                    >
                        {t('home.testimonials.viewAll', { defaultValue: 'Xem tất cả' })}
                        <span className="material-symbols-outlined text-xl">
                            arrow_forward
                        </span>
                    </Link>
                </div>
            </div>
        </section>
    );
};

export default TestimonialsSection;

