import React, { useEffect, useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { testimonialApi, type TestimonialDto, TestimonialType } from '../../services/testimonialApi';

const TestimonialsSection: React.FC = () => {
    const { t } = useTranslation();
    const [testimonials, setTestimonials] = useState<TestimonialDto[]>([]);
    const [loading, setLoading] = useState(true);
    const scrollContainerRef = useRef<HTMLDivElement>(null);
    const [activeIndex, setActiveIndex] = useState(0);

    useEffect(() => {
        fetchTestimonials();
    }, []);

    const fetchTestimonials = async () => {
        try {
            const data = await testimonialApi.getActive();
            // Fetch more items for a better slider experience
            setTestimonials(data.slice(0, 12));
        } catch (error) {
            console.error('Failed to load testimonials:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleScroll = () => {
        if (scrollContainerRef.current) {
            const container = scrollContainerRef.current;
            const scrollLeft = container.scrollLeft;
            const itemWidth = container.children[0]?.clientWidth || 320;
            const gap = window.innerWidth >= 640 ? 24 : 16;
            const itemTotalWidth = itemWidth + gap;
            
            let index = Math.round(scrollLeft / itemTotalWidth);
            if (index < 0) index = 0;
            if (index >= testimonials.length) index = testimonials.length - 1;
            
            setActiveIndex(index);
        }
    };

    const prev = () => {
        if (scrollContainerRef.current) {
            const itemWidth = scrollContainerRef.current.children[0]?.clientWidth || 320;
            const gap = window.innerWidth >= 640 ? 24 : 16;
            scrollContainerRef.current.scrollBy({ left: -(itemWidth + gap), behavior: 'smooth' });
        }
    };

    const next = () => {
        if (scrollContainerRef.current) {
            const itemWidth = scrollContainerRef.current.children[0]?.clientWidth || 320;
            const gap = window.innerWidth >= 640 ? 24 : 16;
            scrollContainerRef.current.scrollBy({ left: (itemWidth + gap), behavior: 'smooth' });
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
        <section className="py-16 bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 overflow-hidden">
            <div className="container mx-auto px-4">
                <div className="text-center mb-10">
                    <h2 className="text-3xl md:text-4xl font-bold text-primary dark:text-primary-light mb-4">
                        {t('home.testimonials.title')}
                    </h2>
                    <p className="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
                        {t('home.testimonials.subtitle')}
                    </p>
                </div>

                <div className="relative max-w-[1280px] mx-auto sm:px-14 group">
                    {/* Prev Button */}
                    <button 
                        onClick={prev} 
                        className="hidden sm:flex absolute left-0 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-primary/90 text-white items-center justify-center hover:bg-primary z-10 transition-all shadow-md hover:scale-105"
                        aria-label="Previous Testimonial"
                    >
                        <span className="material-symbols-outlined font-medium text-2xl">chevron_left</span>
                    </button>

                    {/* Slider Container */}
                    <div 
                        ref={scrollContainerRef}
                        onScroll={handleScroll}
                        className="flex gap-4 sm:gap-6 overflow-x-auto snap-x snap-mandatory pt-2 pb-6 px-2 md:px-0 scroll-smooth [&::-webkit-scrollbar]:hidden [-ms-overflow-style:'none'] [scrollbar-width:'none']"
                    >
                        {testimonials.map((testimonial) => (
                            <div
                                key={testimonial.id}
                                className="w-[80vw] sm:w-[320px] md:w-[340px] flex-shrink-0 snap-center sm:snap-start bg-white dark:bg-slate-800 rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-all duration-300 border border-slate-100 dark:border-slate-700 cursor-grab active:cursor-grabbing flex flex-col group/card"
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

                    {/* Next Button */}
                    <button 
                        onClick={next} 
                        className="hidden sm:flex absolute right-0 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-primary/90 text-white items-center justify-center hover:bg-primary z-10 transition-all shadow-md hover:scale-105"
                        aria-label="Next Testimonial"
                    >
                        <span className="material-symbols-outlined font-medium text-2xl">chevron_right</span>
                    </button>
                </div>

                {/* Dashboard / Dots */}
                <div className="flex justify-center mt-4 gap-2 flex-wrap max-w-lg mx-auto px-4">
                    {testimonials.map((_, idx) => (
                        <button 
                            key={idx}
                            onClick={() => {
                                if(scrollContainerRef.current) {
                                    const itemWidth = scrollContainerRef.current.children[0]?.clientWidth || 320;
                                    const gap = window.innerWidth >= 640 ? 24 : 16;
                                    scrollContainerRef.current.scrollTo({ left: idx * (itemWidth + gap), behavior: 'smooth' });
                                }
                            }}
                            className={`h-2 rounded-full transition-all duration-300 ${
                                idx === activeIndex 
                                    ? 'w-8 bg-primary' 
                                    : 'w-2 bg-slate-200 hover:bg-slate-300 dark:bg-slate-700 dark:hover:bg-slate-600'
                            }`}
                            aria-label={`Go to slide ${idx + 1}`}
                        />
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

