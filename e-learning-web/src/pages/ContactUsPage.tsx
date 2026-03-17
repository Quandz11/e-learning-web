import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useToast } from '../contexts/ToastContext';
import { leadApi } from '../services/leadApi';

const ContactUsPage: React.FC = () => {
    const { t } = useTranslation();
    const { showToast } = useToast();
    const [submitting, setSubmitting] = useState(false);
    
    const [formData, setFormData] = useState({
        fullName: '',
        email: '',
        phone: '',
        topic: 'Tư vấn nhịn ăn cơ bản',
        message: ''
    });

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        
        if (!formData.fullName.trim() || !formData.phone.trim() || !formData.email.trim()) {
            showToast(t('contact.validation.required', { defaultValue: 'Vui lòng điền đủ thông tin bắt buộc (họ tên, email, sđt)' }), 'warning');
            return;
        }

        try {
            setSubmitting(true);
            const goal = `${formData.topic}${formData.message ? ` - Ghi chú: ${formData.message}` : ''}`;
            
            await leadApi.createPublic({
                fullName: formData.fullName.trim(),
                email: formData.email.trim(),
                phone: formData.phone.trim(),
                goal: goal,
                source: 'WEBSITE_FORM'
            });
            
            showToast(t('contact.success', { defaultValue: 'Yêu cầu của bạn đã được gửi. Chúng tôi sẽ liên hệ lại sớm nhất.' }), 'success');
            setFormData({
                fullName: '',
                email: '',
                phone: '',
                topic: 'Tư vấn nhịn ăn cơ bản',
                message: ''
            });
        } catch (error: any) {
             showToast(
                 error?.message || t('contact.error', { defaultValue: 'Có lỗi xảy ra, vui lòng thử lại sau.' }), 
                 'error'
             );
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <div className="min-h-screen bg-[#f9fafb] py-20 text-[#333]">
            <div className="container mx-auto max-w-5xl px-5">
                <div className="text-center mb-12">
                    <h1 className="text-3xl md:text-5xl font-extrabold text-[#6B8E23] mb-4">
                        {t('contact.title', { defaultValue: 'Liên Hệ Với Chúng Tôi' })}
                    </h1>
                    <p className="italic text-gray-500 font-medium">
                        {t('contact.subtitle', { defaultValue: '"Lắng nghe cơ thể để khơi nguồn sức sống tự nhiên"' })}
                    </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                    <div className="space-y-8">
                        <div className="bg-[#F5F5DC] p-8 rounded-2xl shadow-sm">
                            <h3 className="text-xl font-bold mb-6 text-[#6B8E23]">
                                {t('contact.info.title', { defaultValue: 'Kết nối trực tiếp' })}
                            </h3>
                            <div className="space-y-4">
                                <div className="flex flex-col sm:flex-row gap-1 sm:gap-4">
                                    <span className="font-bold text-[#6B8E23] w-24 flex-shrink-0">{t('contact.info.address', { defaultValue: 'Địa chỉ:' })}</span>
                                    <div className="text-gray-700">Tầng 1- Tòa nhà HPC - KĐT Văn Khê - Hà Đông - Hà Nội</div>
                                </div>
                                <div className="flex flex-col sm:flex-row gap-1 sm:gap-4">
                                    <span className="font-bold text-[#6B8E23] w-24 flex-shrink-0">{t('contact.info.hotline', { defaultValue: 'Hotline:' })}</span>
                                    <div className="text-gray-700">0977 698 753</div>
                                </div>
                                <div className="flex flex-col sm:flex-row gap-1 sm:gap-4">
                                    <span className="font-bold text-[#6B8E23] w-24 flex-shrink-0">{t('contact.info.email', { defaultValue: 'Email:' })}</span>
                                    <div className="text-gray-700">nhinanchualanh.vn@gmail.com</div>
                                </div>
                                <div className="flex flex-col sm:flex-row gap-1 sm:gap-4">
                                    <span className="font-bold text-[#6B8E23] w-24 flex-shrink-0">{t('contact.info.hours', { defaultValue: 'Giờ làm:' })}</span>
                                    <div className="text-gray-700">08:00 – 21:00 (T2 - CN)</div>
                                </div>
                            </div>
                        </div>

                        <div className="border-l-4 border-[#6B8E23] pl-4 text-gray-600 text-sm py-1 bg-white/50">
                            <strong>{t('contact.note.title', { defaultValue: 'Lưu ý:' })}</strong> {t('contact.note.text', { defaultValue: 'Quá trình chữa lành cần sự kiên nhẫn. Nếu bạn đang có bệnh lý nền nặng, vui lòng ghi chú rõ để chúng tôi hỗ trợ phương pháp an toàn nhất.' })}
                        </div>
                    </div>

                    <div className="bg-white p-8 rounded-2xl shadow-[0_5px_20px_rgba(0,0,0,0.05)] border border-gray-100">
                        <form onSubmit={handleSubmit} className="space-y-5">
                            <div>
                                <label className="block font-medium text-gray-700 mb-2">{t('contact.form.name', { defaultValue: 'Họ và tên *' })}</label>
                                <input required name="fullName" value={formData.fullName} onChange={handleChange} type="text" placeholder={t('contact.form.namePlaceholder', { defaultValue: 'Nhập tên của bạn' })} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-[#6B8E23] focus:ring-1 focus:ring-[#6B8E23] transition-colors bg-gray-50/50" />
                            </div>
                            <div>
                                <label className="block font-medium text-gray-700 mb-2">{t('contact.form.email', { defaultValue: 'Địa chỉ Email *' })}</label>
                                <input required name="email" value={formData.email} onChange={handleChange} type="email" placeholder={t('contact.form.emailPlaceholder', { defaultValue: 'Nhập email liên hệ' })} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-[#6B8E23] focus:ring-1 focus:ring-[#6B8E23] transition-colors bg-gray-50/50" />
                            </div>
                            <div>
                                <label className="block font-medium text-gray-700 mb-2">{t('contact.form.phone', { defaultValue: 'Số điện thoại / Zalo *' })}</label>
                                <input required name="phone" value={formData.phone} onChange={handleChange} type="tel" placeholder={t('contact.form.phonePlaceholder', { defaultValue: 'Nhập số điện thoại' })} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-[#6B8E23] focus:ring-1 focus:ring-[#6B8E23] transition-colors bg-gray-50/50" />
                            </div>
                            <div>
                                <label className="block font-medium text-gray-700 mb-2">{t('contact.form.topic', { defaultValue: 'Vấn đề bạn quan tâm' })}</label>
                                <select name="topic" value={formData.topic} onChange={handleChange} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-[#6B8E23] focus:ring-1 focus:ring-[#6B8E23] transition-colors bg-gray-50/50">
                                    <option>{t('contact.form.topics.1', { defaultValue: 'Tư vấn nhịn ăn cơ bản' })}</option>
                                    <option>{t('contact.form.topics.2', { defaultValue: 'Đăng ký khóa học chuyên sâu' })}</option>
                                    <option>{t('contact.form.topics.3', { defaultValue: 'Hợp tác / Truyền thông' })}</option>
                                    <option>{t('contact.form.topics.notListed', { defaultValue: 'Khác' })}</option>
                                </select>
                            </div>
                            <div>
                                <label className="block font-medium text-gray-700 mb-2">{t('contact.form.message', { defaultValue: 'Lời nhắn' })}</label>
                                <textarea name="message" value={formData.message} onChange={handleChange} rows={4} placeholder={t('contact.form.messagePlaceholder', { defaultValue: 'Chia sẻ thêm về tình trạng sức khỏe của bạn...' })} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-[#6B8E23] focus:ring-1 focus:ring-[#6B8E23] transition-colors bg-gray-50/50"></textarea>
                            </div>
                            <button disabled={submitting} type="submit" className="w-full py-4 px-6 bg-[#6B8E23] hover:bg-[#556B2F] text-white font-bold rounded-xl transition-colors shadow-md shadow-[#6B8E23]/20 disabled:opacity-75 disabled:cursor-not-allowed">
                                {submitting ? t('contact.form.submitting', { defaultValue: 'Đang gửi...' }) : t('contact.form.submit', { defaultValue: 'Gửi Yêu Cầu Chữa Lành' })}
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ContactUsPage;
