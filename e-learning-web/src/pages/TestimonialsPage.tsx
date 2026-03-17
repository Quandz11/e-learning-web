import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { testimonialApi, type TestimonialDto, TestimonialType } from '../services/testimonialApi';

const TestimonialsPage: React.FC = () => {
    const { t } = useTranslation();
    const [testimonials, setTestimonials] = useState<TestimonialDto[]>([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState<'all' | 'text' | 'video'>('all');

    useEffect(() => {
        fetchTestimonials();
    }, []);

    const fetchTestimonials = async () => {
        try {
            const data = await testimonialApi.getActive();
            setTestimonials(data);
        } catch (error) {
            console.error('Failed to load testimonials:', error);
        } finally {
            setLoading(false);
        }
    };

    const filteredTestimonials = testimonials.filter(t => {
        if (filter === 'all') return true;
        if (filter === 'text') return t.type === TestimonialType.Text;
        if (filter === 'video') return t.type === TestimonialType.Video;
        return true;
    });

    if (loading) {
        return (
            <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 py-16">
                <div className="container mx-auto px-4">
                    <div className="text-center">
                        <div className="animate-pulse">
                            <div className="h-12 bg-slate-200 dark:bg-slate-700 rounded w-96 mx-auto mb-4"></div>
                            <div className="h-6 bg-slate-200 dark:bg-slate-700 rounded w-64 mx-auto"></div>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 py-16">
            <div className="container mx-auto px-4">
                {/* Header */}
                <div className="text-center mb-12">
                    <h1 className="text-4xl md:text-5xl font-bold text-slate-900 dark:text-white mb-4">
                        {t('home.testimonials.title')}
                    </h1>
                    <p className="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
                        {t('home.testimonials.subtitle')}
                    </p>
                </div>

                {/* Filter Buttons */}
                <div className="flex justify-center gap-4 mb-12">
                    <button
                        onClick={() => setFilter('all')}
                        className={`px-6 py-2 rounded-full font-semibold transition-colors ${filter === 'all'
                                ? 'bg-primary text-white'
                                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:border-primary'
                            }`}
                    >
                        {t('testimonials.filter.all', { defaultValue: 'Tất cả' })}
                    </button>
                    <button
                        onClick={() => setFilter('text')}
                        className={`px-6 py-2 rounded-full font-semibold transition-colors ${filter === 'text'
                                ? 'bg-primary text-white'
                                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:border-primary'
                            }`}
                    >
                        {t('testimonials.filter.text', { defaultValue: 'Văn bản' })}
                    </button>
                    <button
                        onClick={() => setFilter('video')}
                        className={`px-6 py-2 rounded-full font-semibold transition-colors ${filter === 'video'
                                ? 'bg-primary text-white'
                                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:border-primary'
                            }`}
                    >
                        {t('testimonials.filter.video', { defaultValue: 'Video' })}
                    </button>
                </div>

                {/* Testimonials Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6 max-w-7xl mx-auto">
                    {filteredTestimonials.map((testimonial) => (
                        <div
                            key={testimonial.id}
                            className="bg-white dark:bg-slate-800 rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-all duration-300 border border-slate-100 dark:border-slate-700 flex flex-col group/card"
                        >
                            {/* Result Image / Video */}
                            {testimonial.resultImageUrl ? (
                                <div className="relative w-full aspect-video bg-slate-100 dark:bg-slate-700 overflow-hidden">
                                    <img
                                        src={testimonial.resultImageUrl}
                                        alt={`${testimonial.name} result`}
                                        className="w-full h-full object-cover group-hover/card:scale-105 transition-transform duration-500"
                                    />
                                </div>
                            ) : testimonial.type === TestimonialType.Video && testimonial.videoUrl ? (
                                <div className="w-full aspect-video bg-slate-100 dark:bg-slate-700">
                                    <video
                                        controls
                                        className="w-full h-full object-cover"
                                        poster={testimonial.avatarUrl}
                                    >
                                        <source src={testimonial.videoUrl} type="video/mp4" />
                                    </video>
                                </div>
                            ) : (
                                <div className="p-6 bg-slate-50 dark:bg-slate-750 flex flex-col items-center justify-center aspect-video border-b border-slate-100 dark:border-slate-700">
                                    <span className="material-symbols-outlined text-4xl text-primary/20 mb-3">format_quote</span>
                                    <p className="text-slate-600 dark:text-slate-300 text-sm italic leading-relaxed line-clamp-4 text-center">
                                        "{testimonial.content}"
                                    </p>
                                </div>
                            )}

                            {/* Author Info Area */}
                            <div className="p-4 bg-white dark:bg-slate-800 flex-grow flex items-center justify-center">
                                <div className="text-center w-full">
                                    <h4 className="text-[15px] font-bold text-slate-800 dark:text-white truncate" title={testimonial.name}>
                                        KH {testimonial.name}{testimonial.position ? ` - ${testimonial.position}` : ''}
                                    </h4>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Empty State */}
                {filteredTestimonials.length === 0 && (
                    <div className="text-center py-16">
                        <p className="text-slate-500 dark:text-slate-400 text-lg">
                            {t('testimonials.empty', { defaultValue: 'Không có phản hồi nào' })}
                        </p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default TestimonialsPage;
