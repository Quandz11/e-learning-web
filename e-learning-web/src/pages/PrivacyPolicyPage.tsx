import React from 'react';
import { useTranslation } from 'react-i18next';

const PrivacyPolicyPage: React.FC = () => {
    const { t } = useTranslation();
    
    return (
        <div className="min-h-screen bg-[#f0f4f3] text-[#0f2a24] relative z-0 overflow-hidden py-20">
            {/* Mesh Background */}
            <div className="absolute inset-0 -z-10 opacity-15" style={{
                backgroundImage: `
                    radial-gradient(at 0% 0%, hsla(164,72%,16%,1) 0, transparent 50%), 
                    radial-gradient(at 100% 0%, hsla(145,63%,42%,1) 0, transparent 50%), 
                    radial-gradient(at 100% 100%, hsla(158,54%,95%,1) 0, transparent 50%), 
                    radial-gradient(at 0% 100%, hsla(160,84%,12%,1) 0, transparent 50%)
                `,
                backgroundColor: '#f0f7f4'
            }}></div>

            <div className="container mx-auto max-w-4xl px-5">
                <h1 className="text-center text-3xl md:text-5xl font-extrabold mb-12 bg-gradient-to-br from-[#0f2a24] to-[#2ecc71] bg-clip-text text-transparent">
                    {t('privacy.title', { defaultValue: 'Chính Sách & Pháp Lý' })}
                </h1>

                <div className="bg-white/85 backdrop-blur-md border border-white/40 p-6 sm:p-10 rounded-[30px] shadow-sm mb-8">
                    <h2 className="text-xl md:text-2xl font-extrabold flex items-center border-l-4 border-[#2ecc71] pl-4 mb-5">
                        {t('privacy.terms.title', { defaultValue: '1. ĐIỀU KHOẢN SỬ DỤNG' })}
                    </h2>
                    <div className="text-base text-gray-700 leading-relaxed space-y-4">
                        <p>{t('privacy.terms.desc', { defaultValue: 'Bằng việc truy cập website và đăng ký các khóa học tại nhinanchualanh.vn, bạn đồng ý tuân thủ các quy định sau:' })}</p>
                        <ul className="list-disc pl-5 space-y-2">
                            <li>{t('privacy.terms.item1', { defaultValue: 'Bạn phải từ 18 tuổi trở lên hoặc có sự giám sát của người bảo hộ hợp pháp.' })}</li>
                            <li><strong>{t('privacy.terms.item2.bold', { defaultValue: 'Bản quyền nội dung:' })}</strong> {t('privacy.terms.item2.text', { defaultValue: 'Toàn bộ video, bài viết và công thức thanh lọc là tài sản trí tuệ của chúng tôi. Nghiêm cấm mọi hành vi sao chép, phát tán hoặc kinh doanh lại khi chưa có văn bản đồng ý.' })}</li>
                            <li>{t('privacy.terms.item3', { defaultValue: 'Mỗi tài khoản học viên chỉ dành cho một người sử dụng, không chia sẻ thông tin đăng nhập.' })}</li>
                        </ul>
                    </div>
                </div>

                <div className="bg-white/85 backdrop-blur-md border border-white/40 p-6 sm:p-10 rounded-[30px] shadow-sm mb-8">
                    <h2 className="text-xl md:text-2xl font-extrabold flex items-center border-l-4 border-[#2ecc71] pl-4 mb-5">
                        {t('privacy.policy.title', { defaultValue: '2. CHÍNH SÁCH BẢO MẬT (NĐ 13/2023/NĐ-CP)' })}
                    </h2>
                    <div className="text-base text-gray-700 leading-relaxed space-y-4">
                        <p>{t('privacy.policy.desc', { defaultValue: 'Chúng tôi tôn trọng quyền riêng tư của bạn và cam kết bảo mật dữ liệu theo tiêu chuẩn mới nhất:' })}</p>
                        <ul className="list-disc pl-5 space-y-2">
                            <li><strong>{t('privacy.policy.item1.bold', { defaultValue: 'Dữ liệu thu thập:' })}</strong> {t('privacy.policy.item1.text', { defaultValue: 'Họ tên, SĐT, Email và thông tin sức khỏe cá nhân nhằm mục đích tư vấn lộ trình phù hợp.' })}</li>
                            <li><strong>{t('privacy.policy.item2.bold', { defaultValue: 'Cam kết:' })}</strong> {t('privacy.policy.item2.text', { defaultValue: 'Không cung cấp thông tin cho bên thứ ba vì mục đích quảng cáo.' })}</li>
                            <li><strong>{t('privacy.policy.item3.bold', { defaultValue: 'Quyền của bạn:' })}</strong> {t('privacy.policy.item3.text', { defaultValue: 'Bạn có quyền yêu cầu truy xuất, đính chính hoặc xóa vĩnh viễn dữ liệu cá nhân khỏi hệ thống của chúng tôi bằng cách liên hệ qua Email hỗ trợ.' })}</li>
                        </ul>
                    </div>
                </div>

                <div className="bg-white/85 backdrop-blur-md border border-white/40 p-6 sm:p-10 rounded-[30px] shadow-sm mb-8">
                    <h2 className="text-xl md:text-2xl font-extrabold flex items-center border-l-4 border-[#2ecc71] pl-4 mb-5">
                        {t('privacy.refund.title', { defaultValue: '3. CHÍNH SÁCH HOÀN PHÍ & KHIẾU NẠI' })}
                    </h2>
                    <div className="text-base text-gray-700 leading-relaxed space-y-4">
                        <div className="bg-[#2ecc71]/10 border border-dashed border-[#2ecc71] rounded-2xl p-5 my-5">
                            <strong>{t('privacy.refund.special.bold', { defaultValue: 'Điều kiện đặc biệt:' })}</strong> {t('privacy.refund.special.text', { defaultValue: 'Chúng tôi chỉ thực hiện hoàn phí 100% trong trường hợp học viên đã hoàn thành ít nhất 80% thời lượng khóa học (bao gồm bài học online và các buổi hướng dẫn qua Zoom) nhưng không đạt được kết quả chuyển hóa như cam kết.' })}
                        </div>
                        <p><strong>{t('privacy.refund.process', { defaultValue: 'Quy trình khiếu nại:' })}</strong></p>
                        <ol className="list-decimal pl-5 space-y-2">
                            <li>Gửi yêu cầu tới <strong>troly@nhinanchualanh.vn</strong> kèm minh chứng học tập.</li>
                            <li>Ban điều hành thẩm định và phản hồi trong vòng 03 ngày làm việc.</li>
                            <li>Hoàn tiền qua tài khoản ngân hàng trong vòng 07-10 ngày nếu hồ sơ hợp lệ.</li>
                        </ol>
                    </div>
                </div>

                <div className="bg-white/85 backdrop-blur-md border border-white/40 p-6 sm:p-10 rounded-[30px] shadow-sm mb-8">
                    <h2 className="text-xl md:text-2xl font-extrabold flex items-center border-l-4 border-[#2ecc71] pl-4 mb-5">
                        {t('privacy.disclaimer.title', { defaultValue: '4. MIỄN TRỪ TRÁCH NHIỆM Y KHOA' })}
                    </h2>
                    <div className="text-base text-gray-700 leading-relaxed space-y-4">
                        <p>{t('privacy.disclaimer.desc', { defaultValue: 'Phương pháp nhịn ăn chữa lành là hành trình hỗ trợ cơ thể tự phục hồi qua lối sống. Chúng tôi khẳng định:' })}</p>
                        <ul className="list-disc pl-5 space-y-2">
                            <li>{t('privacy.disclaimer.item1', { defaultValue: 'Thông tin tại đây không thay thế cho lời khuyên, chẩn đoán hoặc điều trị từ bác sĩ chuyên khoa.' })}</li>
                            <li>{t('privacy.disclaimer.item2', { defaultValue: 'Học viên cần khai báo trung thực bệnh lý nền. Chúng tôi miễn trừ trách nhiệm đối với các rủi ro phát sinh do học viên tự ý thực hiện sai quy trình hoặc che giấu các tình trạng bệnh lý chống chỉ định.' })}</li>
                            <li>{t('privacy.disclaimer.item3', { defaultValue: 'Kết quả cuối cùng phụ thuộc vào cơ địa và mức độ kỷ luật thực hành của từng cá nhân.' })}</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default PrivacyPolicyPage;
