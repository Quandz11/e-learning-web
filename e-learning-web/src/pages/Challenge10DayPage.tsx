import React, { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import type { RootState } from '../store/store';

interface FeatureItem {
  icon: string;
  title: string;
  description: string;
}

interface TimelineItem {
  stage: string;
  duration: string;
  activity: string;
  target: string;
  tagClass: string;
}

interface KitItem {
  icon: string;
  title: string;
  code: string;
  description: string;
  highlighted?: boolean;
}

const Challenge10DayPage: React.FC = () => {
  const { t } = useTranslation();
  const isAuthenticated = useSelector((state: RootState) => state.auth.isAuthenticated);
  const consultationHref = isAuthenticated ? '/home#course-consultation-form' : '/#course-consultation-form';

  const featureItems: FeatureItem[] = useMemo(
    () => [
      {
        icon: 'fingerprint',
        title: t('challenge10Page.features.0.title', { defaultValue: 'Cơ chế Autophagy' }),
        description: t('challenge10Page.features.0.description', {
          defaultValue:
            'Kích hoạt khả năng tự thực của tế bào, loại bỏ protein lỗi và tái tạo cấu trúc mô mới trong 5 ngày nhịn sâu.',
        }),
      },
      {
        icon: 'bolt',
        title: t('challenge10Page.features.1.title', { defaultValue: 'Metabolic Flexibility' }),
        description: t('challenge10Page.features.1.description', {
          defaultValue:
            'Huấn luyện cơ thể chuyển đổi linh hoạt giữa đốt đường và đốt mỡ, giúp duy trì năng lượng bền bỉ suốt cả ngày.',
        }),
      },
      {
        icon: 'verified_user',
        title: t('challenge10Page.features.2.title', { defaultValue: 'Protocol bảo mật' }),
        description: t('challenge10Page.features.2.description', {
          defaultValue:
            'Sản phẩm mã hóa độc quyền kết hợp cùng sự đồng hành sát sao từ các Đại sứ Sức khỏe.',
        }),
      },
    ],
    [t]
  );

  const timelineItems: TimelineItem[] = useMemo(
    () => [
      {
        stage: t('challenge10Page.timeline.0.stage', { defaultValue: 'PRE-FAST' }),
        duration: t('challenge10Page.timeline.0.duration', { defaultValue: 'Ngày 1 - 2' }),
        activity: t('challenge10Page.timeline.0.activity', {
          defaultValue: 'Cắt giảm tinh bột xấu, ăn thuần thực vật, làm sạch đường ruột.',
        }),
        target: t('challenge10Page.timeline.0.target', { defaultValue: 'Sẵn sàng chuyển hóa' }),
        tagClass: 'bg-[#e9f5db] text-[#444]',
      },
      {
        stage: t('challenge10Page.timeline.1.stage', { defaultValue: 'DEEP FAST' }),
        duration: t('challenge10Page.timeline.1.duration', { defaultValue: 'Ngày 3 - 7' }),
        activity: t('challenge10Page.timeline.1.activity', {
          defaultValue: 'Nhịn ăn hoàn toàn. Chỉ sử dụng nước và tổ hợp MF-1, BF-X, DCT.',
        }),
        target: t('challenge10Page.timeline.1.target', { defaultValue: 'Tái tạo tế bào sâu' }),
        tagClass: 'bg-[#cfe1b9] text-[#004b23]',
      },
      {
        stage: t('challenge10Page.timeline.2.stage', { defaultValue: 'RE-FEEDING' }),
        duration: t('challenge10Page.timeline.2.duration', { defaultValue: 'Ngày 8 - 10' }),
        activity: t('challenge10Page.timeline.2.activity', {
          defaultValue: 'Ăn ra theo quy trình lỏng-đến-đặc. Kích hoạt lại enzyme tiêu hóa.',
        }),
        target: t('challenge10Page.timeline.2.target', { defaultValue: 'Hồi sinh hệ thống' }),
        tagClass: 'bg-[#ccff33] text-[#132a13]',
      },
    ],
    [t]
  );

  const kitItems: KitItem[] = useMemo(
    () => [
      {
        icon: 'science',
        title: t('challenge10Page.kit.0.title', { defaultValue: 'Mineral Flux 1.0' }),
        code: t('challenge10Page.kit.0.code', { defaultValue: 'MF-1' }),
        description: t('challenge10Page.kit.0.description', {
          defaultValue: 'Phức hợp điện giải nồng độ cao chống mệt mỏi.',
        }),
      },
      {
        icon: 'local_fire_department',
        title: t('challenge10Page.kit.1.title', { defaultValue: 'Brain Fuel X' }),
        code: t('challenge10Page.kit.1.code', { defaultValue: 'BF-X' }),
        description: t('challenge10Page.kit.1.description', {
          defaultValue: 'Dầu tinh khiết cấp năng lượng cho neuron.',
        }),
      },
      {
        icon: 'eco',
        title: t('challenge10Page.kit.2.title', { defaultValue: 'Deep Cleanse Tea' }),
        code: t('challenge10Page.kit.2.code', { defaultValue: 'DCT' }),
        description: t('challenge10Page.kit.2.description', {
          defaultValue: 'Tổ hợp thảo mộc hỗ trợ gan thải độc.',
        }),
      },
      {
        icon: 'monitoring',
        title: t('challenge10Page.kit.3.title', { defaultValue: 'Ketone Tracker' }),
        code: t('challenge10Page.kit.3.code', { defaultValue: 'KT-10' }),
        description: t('challenge10Page.kit.3.description', {
          defaultValue: 'Chỉ báo sinh hóa xác thực mức độ đốt mỡ.',
        }),
      },
      {
        icon: 'description',
        title: t('challenge10Page.kit.4.title', { defaultValue: 'The Protocol' }),
        code: t('challenge10Page.kit.4.code', { defaultValue: 'P.10' }),
        description: t('challenge10Page.kit.4.description', {
          defaultValue: 'Cẩm nang vận hành chi tiết từng giờ.',
        }),
        highlighted: true,
      },
    ],
    [t]
  );

  return (
    <div className="bg-[#f8f9fa] text-[#132a13]">
      <section
        className="bg-cover bg-center px-4 py-24 text-center text-white sm:px-6"
        style={{
          backgroundImage:
            "linear-gradient(135deg, rgba(0,75,35,0.9), rgba(19,42,19,0.8)), url('https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1350&q=80')",
        }}
      >
        <span className="mb-5 inline-block rounded-full bg-[#ccff33] px-5 py-1 text-sm font-bold text-[#132a13]">
          {t('challenge10Page.hero.badge', { defaultValue: 'PROTOCOLO RE-CODE 10' })}
        </span>
        <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl lg:text-6xl">
          {t('challenge10Page.hero.title', { defaultValue: 'Tái Thiết Lập Hệ Thống Sinh Học' })}
        </h1>
        <p className="mx-auto mt-3 max-w-3xl text-base text-white/90 sm:text-lg">
          {t('challenge10Page.hero.subtitle', {
            defaultValue: 'Quy trình 10 ngày tối ưu hóa tế bào dành riêng cho người đã thực hành 16/8',
          })}
        </p>
        <a
          href="#protocol"
          className="mt-8 inline-block rounded-full bg-[#38b000] px-8 py-4 text-sm font-extrabold text-white shadow-[0_10px_20px_rgba(56,176,0,0.3)] transition hover:-translate-y-0.5 hover:bg-[#004b23]"
        >
          {t('challenge10Page.hero.cta', { defaultValue: 'KHÁM PHÁ LỘ TRÌNH' })}
        </a>
      </section>

      <main className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:px-8">
        <section>
          <div className="mb-10 text-center">
            <h2 className="text-3xl font-bold text-[#004b23] sm:text-4xl">
              {t('challenge10Page.decode.title', { defaultValue: 'Giải mã Cơ thể - Lập trình Tương lai' })}
            </h2>
            <div className="mx-auto mt-3 h-1 w-16 bg-[#38b000]" />
          </div>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3">
            {featureItems.map((item) => (
              <article
                key={item.title}
                className="rounded-2xl bg-white p-8 text-center shadow-[0_10px_30px_rgba(0,0,0,0.05)]"
              >
                <span className="material-symbols-outlined text-5xl text-[#38b000]">{item.icon}</span>
                <h3 className="mt-4 text-xl font-bold text-[#004b23]">{item.title}</h3>
                <p className="mt-3 text-sm leading-relaxed text-[#132a13]/80">{item.description}</p>
              </article>
            ))}
          </div>
        </section>

        <section id="protocol" className="mt-16">
          <div className="mb-10 text-center">
            <h2 className="text-3xl font-bold text-[#004b23] sm:text-4xl">
              {t('challenge10Page.protocol.title', { defaultValue: 'Giao thức RE-CODE 10' })}
            </h2>
            <div className="mx-auto mt-3 h-1 w-16 bg-[#38b000]" />
          </div>

          <div className="overflow-x-auto rounded-2xl bg-white p-5 shadow-[0_10px_30px_rgba(0,0,0,0.05)] sm:p-7">
            <table className="min-w-[680px] w-full border-collapse text-left">
              <thead>
                <tr className="bg-[#004b23] text-white">
                  <th className="px-4 py-3 text-sm font-semibold">
                    {t('challenge10Page.protocol.headers.stage', { defaultValue: 'Giai đoạn' })}
                  </th>
                  <th className="px-4 py-3 text-sm font-semibold">
                    {t('challenge10Page.protocol.headers.duration', { defaultValue: 'Thời lượng' })}
                  </th>
                  <th className="px-4 py-3 text-sm font-semibold">
                    {t('challenge10Page.protocol.headers.activity', { defaultValue: 'Hoạt động cốt lõi' })}
                  </th>
                  <th className="px-4 py-3 text-sm font-semibold">
                    {t('challenge10Page.protocol.headers.target', { defaultValue: 'Trạng thái mục tiêu' })}
                  </th>
                </tr>
              </thead>
              <tbody>
                {timelineItems.map((item) => (
                  <tr key={item.stage} className="border-b border-slate-100">
                    <td className="px-4 py-4 text-sm">
                      <span className={`rounded px-2 py-1 text-xs font-bold ${item.tagClass}`}>{item.stage}</span>
                    </td>
                    <td className="px-4 py-4 text-sm">{item.duration}</td>
                    <td className="px-4 py-4 text-sm">{item.activity}</td>
                    <td className="px-4 py-4 text-sm">{item.target}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <section className="mt-16 overflow-hidden rounded-[28px] bg-[#132a13] px-6 py-10 text-white sm:px-8 sm:py-14">
          <h2 className="text-3xl font-bold text-[#ccff33]">
            {t('challenge10Page.kitTitle', { defaultValue: 'Biological Reset Kit (RE-CODE 10)' })}
          </h2>
          <p className="mt-3 max-w-3xl text-sm text-white/80 sm:text-base">
            {t('challenge10Page.kitDescription', {
              defaultValue:
                'Hệ thống công cụ hỗ trợ được thiết kế để duy trì sự an toàn và hiệu suất tối đa trong suốt 10 ngày.',
            })}
          </p>

          <div className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
            {kitItems.map((item) => (
              <article
                key={item.title}
                className={`rounded-2xl border p-4 ${
                  item.highlighted
                    ? 'border-[#ccff33] bg-[#ccff33] text-[#132a13]'
                    : 'border-white/15 bg-white/5 text-white'
                }`}
              >
                <span className="material-symbols-outlined text-3xl">{item.icon}</span>
                <h3 className="mt-2 text-base font-bold">{item.title}</h3>
                <p className={`mt-1 text-xs ${item.highlighted ? 'text-[#132a13]/80' : 'text-white/70'}`}>
                  {t('challenge10Page.codeLabel', { defaultValue: 'Code' })}: {item.code}
                </p>
                <p className={`mt-2 text-xs leading-relaxed ${item.highlighted ? 'font-semibold text-[#132a13]' : 'text-white/80'}`}>
                  {item.description}
                </p>
              </article>
            ))}
          </div>
        </section>

        <section className="mt-10 flex items-start gap-3 rounded-xl border-l-4 border-[#ffc107] bg-[#fff3cd] p-5 text-sm text-[#5f4b00] sm:text-base">
          <span className="material-symbols-outlined mt-0.5 text-2xl text-[#ffc107]">warning</span>
          <p>
            <strong>{t('challenge10Page.warning.title', { defaultValue: 'Tiêu chuẩn gia nhập:' })}</strong>{' '}
            {t('challenge10Page.warning.body', {
              defaultValue:
                'Để đảm bảo an toàn, thử thách này BẮT BUỘC dành cho người đã thực hành nhịn ăn gián đoạn (IF) từ 4 tuần trở lên. Nếu bạn chưa có kinh nghiệm, vui lòng chọn lộ trình Prepare 16/8 trước.',
            })}
          </p>
        </section>

        <section className="mt-12 rounded-2xl bg-white p-7 text-center shadow-[0_10px_30px_rgba(0,0,0,0.06)] sm:p-10">
          <h2 className="text-2xl font-bold text-[#132a13] sm:text-3xl">
            {t('challenge10Page.cta.title', { defaultValue: 'Sẵn sàng để "Lập trình" lại cơ thể?' })}
          </h2>
          <p className="mt-2 text-sm text-[#132a13]/70 sm:text-base">
            {t('challenge10Page.cta.subtitle', { defaultValue: 'Chọn phương thức bắt đầu phù hợp với bạn' })}
          </p>

          <div className="mt-6 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <a
              href={consultationHref}
              className="inline-flex w-full items-center justify-center rounded-full border-2 border-[#004b23] px-7 py-3 text-sm font-bold text-[#004b23] transition hover:bg-[#004b23] hover:text-white sm:w-auto"
            >
              {t('challenge10Page.cta.surveyButton', { defaultValue: 'LÀM BÀI KHẢO SÁT SỨC KHỎE' })}
            </a>
            <Link
              to="/courses"
              className="inline-flex w-full items-center justify-center rounded-full bg-[#38b000] px-7 py-3 text-sm font-bold text-white shadow-[0_8px_18px_rgba(56,176,0,0.35)] transition hover:bg-[#004b23] sm:w-auto"
            >
              {t('challenge10Page.cta.joinButton', { defaultValue: 'THAM GIA THỬ THÁCH NGAY' })}
            </Link>
          </div>

          <div className="mt-6">
            <Link to="/ambassador#register" className="text-sm font-medium text-[#004b23] underline underline-offset-2">
              {t('challenge10Page.cta.oldStudentLink', {
                defaultValue: 'Bạn là học viên cũ? Đăng ký mua lẻ Bộ Kit tại đây',
              })}
            </Link>
          </div>
        </section>
      </main>
    </div>
  );
};

export default Challenge10DayPage;