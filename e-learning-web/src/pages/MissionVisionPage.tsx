import React from 'react';
import { useTranslation } from 'react-i18next';

const MissionVisionPage: React.FC = () => {
    const { t } = useTranslation();

    return (
        <div className="min-h-screen bg-[#f0f4f3] text-[#0f2a24] relative z-0 py-20 overflow-hidden">
            {/* Mesh Background adapted to match Privacy Policy */}
            <div className="absolute inset-0 -z-10 opacity-20" style={{
                backgroundImage: `
                    radial-gradient(circle at 10% 20%, rgba(46, 204, 113, 0.15) 0%, transparent 40%),
                    radial-gradient(circle at 90% 80%, rgba(197, 160, 89, 0.15) 0%, transparent 40%)
                `
            }}></div>

            <div className="container mx-auto max-w-5xl px-5">
                <span className="block text-[#c5a059] uppercase tracking-[5px] font-bold text-sm mb-3">
                    nhinanchualanh.vn
                </span>
                <h1 className="text-4xl md:text-5xl lg:text-6xl font-black leading-tight mb-16 tracking-tight text-[#0f2a24]">
                    Tầm Vóc & <br />
                    <span className="text-[#2ecc71] drop-shadow-sm">Trách Nhiệm Xã Hội</span>
                </h1>

                <div className="grid grid-cols-1 md:grid-cols-[1.2fr_0.8fr] gap-[2px] bg-gray-200 border border-gray-200 rounded-3xl overflow-hidden shadow-lg mb-24">
                    <div className="p-8 md:p-14 bg-white/95 backdrop-blur-sm">
                        <h2 className="text-3xl font-extrabold mb-6 text-[#c5a059]">
                            {t('mission.vision.title', { defaultValue: 'Tầm Nhìn 2030' })}
                        </h2>
                        <p className="text-lg text-gray-700 leading-relaxed">
                            {t('mission.vision.desc1', { defaultValue: 'Trở thành định chế uy tín hàng đầu Việt Nam về ' })}
                            <strong className="text-[#0f2a24]">{t('mission.vision.desc2', { defaultValue: 'Y học tự thân' })}</strong>
                            {t('mission.vision.desc3', { defaultValue: '. Chúng tôi kiến tạo một tương lai nơi mỗi người dân đều sở hữu tri thức để tự làm chủ sức khỏe, chuyển hóa thân tâm và chấm dứt sự lệ thuộc không cần thiết vào hóa dược.' })}
                        </p>
                    </div>

                    <div className="p-8 md:p-14 bg-[#f9fbfa]">
                        <h2 className="text-3xl font-extrabold mb-6 text-[#c5a059]">
                            {t('mission.mission.title', { defaultValue: 'Sứ Mệnh' })}
                        </h2>
                        <p className="text-lg text-gray-700 leading-relaxed">
                            {t('mission.mission.desc1', { defaultValue: 'Đánh thức "Vị bác sĩ nội tại" thông qua phương pháp nhịn ăn khoa học. Chúng tôi phụng sự vì một thế hệ người Việt ' })}
                            <strong className="text-[#0f2a24]">{t('mission.mission.desc2', { defaultValue: 'Thân nhẹ - Tâm an - Trí sáng' })}</strong>
                            {t('mission.mission.desc3', { defaultValue: ', đưa cơ thể quay về trạng thái cân bằng nguyên bản.' })}
                        </p>
                    </div>
                </div>

                <div className="text-center mt-12 mb-12">
                    <h2 className="text-3xl md:text-4xl font-black text-[#0f2a24]">
                        {t('mission.community.title', { defaultValue: 'Phát Triển Cộng Đồng' })}
                    </h2>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8">
                    <div className="bg-white p-8 border border-gray-100 rounded-2xl shadow-sm hover:border-[#2ecc71] hover:bg-[#2ecc71]/5 hover:-translate-y-1 transition-all duration-300">
                        <h3 className="text-xl font-bold text-[#2ecc71] mb-4">
                            {t('mission.community.card1.title', { defaultValue: 'Phổ Cập Tri Thức' })}
                        </h3>
                        <p className="text-base text-gray-600 leading-relaxed">
                            {t('mission.community.card1.desc', { defaultValue: 'Số hóa và chia sẻ miễn phí các nghiên cứu khoa học về Autophagy (tự thực bào), giúp cộng đồng tiếp cận phương pháp nhịn ăn an toàn, bài bản.' })}
                        </p>
                    </div>
                    <div className="bg-white p-8 border border-gray-100 rounded-2xl shadow-sm hover:border-[#2ecc71] hover:bg-[#2ecc71]/5 hover:-translate-y-1 transition-all duration-300">
                        <h3 className="text-xl font-bold text-[#2ecc71] mb-4">
                            {t('mission.community.card2.title', { defaultValue: 'An Sinh Y Tế' })}
                        </h3>
                        <p className="text-base text-gray-600 leading-relaxed">
                            {t('mission.community.card2.desc', { defaultValue: 'Chủ động giảm tải gánh nặng cho hệ thống y tế bằng cách hướng dẫn người dân tự phục hồi các bệnh lý chuyển hóa từ giai đoạn khởi phát.' })}
                        </p>
                    </div>
                    <div className="bg-white p-8 border border-gray-100 rounded-2xl shadow-sm hover:border-[#2ecc71] hover:bg-[#2ecc71]/5 hover:-translate-y-1 transition-all duration-300">
                        <h3 className="text-xl font-bold text-[#2ecc71] mb-4">
                            {t('mission.community.card3.title', { defaultValue: 'Lối Sống Bền Vững' })}
                        </h3>
                        <p className="text-base text-gray-600 leading-relaxed">
                            {t('mission.community.card3.desc', { defaultValue: 'Lan tỏa văn hóa "Biết đủ" và tiết chế. Nhịn ăn để khỏe mạnh hơn, đồng thời giảm thiểu dấu chân tiêu dùng, bảo vệ tài nguyên môi trường.' })}
                        </p>
                    </div>
                </div>

                <div className="mt-20 text-center border-t border-[#c5a059]/30 pt-10">
                    <h4 className="text-2xl md:text-3xl font-bold italic text-[#c5a059]">
                        {t('mission.slogan', { defaultValue: '"Sức khỏe của bạn là sứ mệnh của chúng tôi."' })}
                    </h4>
                </div>
            </div>
        </div>
    );
};

export default MissionVisionPage;
