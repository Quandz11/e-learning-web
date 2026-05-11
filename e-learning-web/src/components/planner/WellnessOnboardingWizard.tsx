import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import type { OnboardingFormData, OnboardingStep } from '../../types/planner';
import { WELLNESS_GOAL_PRESETS, FASTING_DURATION_PRESETS } from '../../types/planner';

interface WellnessOnboardingWizardProps {
  onComplete: (data: OnboardingFormData) => Promise<void>;
  isSubmitting?: boolean;
  isPaidFeature?: boolean;
  isUnlocked?: boolean;
  packages?: WellnessCheckoutPackage[];
}

const STEPS: OnboardingStep[] = [1, 2, 3, 4];

const WellnessOnboardingWizard: React.FC<WellnessOnboardingWizardProps> = ({ 
  onComplete, 
  isSubmitting,
  isPaidFeature = false,
  isUnlocked = false,
  packages = []
}) => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const isVi = i18n.resolvedLanguage?.startsWith('vi');
  
  const [currentStep, setCurrentStep] = useState<OnboardingStep>(1);
  const [formData, setFormData] = useState<OnboardingFormData>({
    wellnessGoal: 'weight_loss',
    fastingDuration: '24h',
    fastingStartDate: new Date().toISOString().split('T')[0],
    wellnessPackageCode: packages.length > 0 ? packages[0].code : '',
  });
  const [error, setError] = useState<string | null>(null);

  // Auto-select first package if list updates and nothing selected
  React.useEffect(() => {
    if (packages.length > 0 && !formData.wellnessPackageCode) {
      setFormData(prev => ({ ...prev, wellnessPackageCode: packages[0].code }));
    }
  }, [packages, formData.wellnessPackageCode]);

  const updateField = <K extends keyof OnboardingFormData>(key: K, value: OnboardingFormData[K]) => {
    setFormData((prev) => ({ ...prev, [key]: value }));
    if (error) setError(null);
  };

  const validateStep = (): boolean => {
    switch (currentStep) {
      case 1:
        if (!formData.wellnessGoal) {
          setError(isVi ? 'Vui lòng chọn mục tiêu của bạn' : 'Please select your goal');
          return false;
        }
        return true;
      case 2:
        if (!formData.fastingDuration) {
          setError(isVi ? 'Vui lòng chọn thời gian nhịn ăn' : 'Please select fasting duration');
          return false;
        }
        return true;
      case 3:
        if (!formData.fastingStartDate) {
          setError(isVi ? 'Vui lòng chọn ngày bắt đầu' : 'Please select start date');
          return false;
        }
        return true;
      case 4:
        if (isPaidFeature && !formData.wellnessPackageCode) {
          setError(isVi ? 'Vui lòng chọn gói dịch vụ' : 'Please select a package');
          return false;
        }
        return true;
      default:
        return true;
    }
  };

  const handleNext = () => {
    if (!validateStep()) return;
    if (currentStep < 4) {
      setCurrentStep((prev) => (prev + 1) as OnboardingStep);
    }
  };

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => (prev - 1) as OnboardingStep);
    }
  };

  const handleSubmit = async () => {
    if (!validateStep()) return;
    
    if (isPaidFeature && !isUnlocked) {
      // Redirect to checkout with the selected wellness package
      const params = new URLSearchParams();
      const selectedPackage = formData.wellnessPackageCode || (packages.length > 0 ? packages[0].code : 'PERSONALIZED');
      params.set('wellnessPackage', selectedPackage);
      
      // Store onboarding choices in sessionStorage so we can apply them after payment
      sessionStorage.setItem('pending_wellness_onboarding', JSON.stringify({
        ...formData,
        wellnessPackageCode: selectedPackage
      }));
      
      navigate(`/checkout?${params.toString()}`);
      return;
    }

    try {
      await onComplete(formData);
    } catch (err: any) {
      setError(err?.message || t('common.error'));
    }
  };

  const stepConfig = [
    { icon: '🎯', titleVi: 'Mục tiêu của bạn', titleEn: 'Your Goal', descVi: 'Chọn mục tiêu sức khỏe bạn muốn đạt được', descEn: 'Choose the health goal you want to achieve' },
    { icon: '⏳', titleVi: 'Thời gian nhịn ăn', titleEn: 'Fasting Duration', descVi: 'Chọn gói nhịn ăn phù hợp với thể trạng', descEn: 'Choose a fasting preset that fits your condition' },
    { icon: '📅', titleVi: 'Ngày bắt đầu', titleEn: 'Start Date', descVi: 'Khi nào bạn muốn bắt đầu lộ trình?', descEn: 'When do you want to start the roadmap?' },
    { 
      icon: isPaidFeature ? '💳' : '✨', 
      titleVi: isPaidFeature ? 'Kích hoạt lộ trình' : 'Sẵn sàng chưa?', 
      titleEn: isPaidFeature ? 'Activate Roadmap' : 'Ready?', 
      descVi: isPaidFeature ? 'Lộ trình cá nhân hóa là tính năng trả phí. Hãy kích hoạt để bắt đầu.' : 'Chúng tôi sẽ cá nhân hóa lộ trình dựa trên lựa chọn của bạn', 
      descEn: isPaidFeature ? 'Personalized roadmap is a premium feature. Activate to start.' : 'We will personalize the roadmap based on your choices' 
    },
  ];

  const currentConfig = stepConfig[currentStep - 1];

  return (
    <div className="mx-auto max-w-lg">
      {/* Progress dots */}
      <div className="mb-8 flex items-center justify-center gap-2">
        {STEPS.map((step) => (
          <div
            key={step}
            className={`h-2 rounded-full transition-all duration-300 ${
              step === currentStep
                ? 'w-8 bg-emerald-500'
                : step < currentStep
                  ? 'w-2 bg-emerald-300'
                  : 'w-2 bg-slate-200 dark:bg-slate-700'
            }`}
          />
        ))}
      </div>

      {/* Step header */}
      <div className="mb-6 text-center">
        <span className="mb-3 inline-block text-4xl">{currentConfig.icon}</span>
        <h2 className="text-2xl font-bold text-slate-900 dark:text-white">
            {isVi ? currentConfig.titleVi : currentConfig.titleEn}
        </h2>
        <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
            {isVi ? currentConfig.descVi : currentConfig.descEn}
        </p>
      </div>

      {/* Error */}
      {error && (
        <div className="mb-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:border-red-800/50 dark:bg-red-900/20 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Step content */}
      <div className="mb-8 space-y-4">
        {currentStep === 1 && (
          <div className="grid gap-3">
            {WELLNESS_GOAL_PRESETS.map((preset) => (
              <button
                key={preset.value}
                onClick={() => updateField('wellnessGoal', preset.value)}
                className={`flex items-start gap-4 rounded-2xl border p-4 text-left transition-all duration-200 ${
                  formData.wellnessGoal === preset.value
                    ? 'border-emerald-300 bg-emerald-50 shadow-sm dark:border-emerald-700/50 dark:bg-emerald-900/30'
                    : 'border-slate-200 bg-white hover:border-slate-300 dark:border-slate-700 dark:bg-slate-800'
                }`}
              >
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-white text-2xl shadow-sm dark:bg-slate-700">
                  {preset.icon}
                </span>
                <div>
                  <h3 className={`font-bold ${formData.wellnessGoal === preset.value ? 'text-emerald-900 dark:text-emerald-400' : 'text-slate-900 dark:text-white'}`}>
                    {isVi ? preset.titleVi : t(preset.labelKey)}
                  </h3>
                  <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                    {isVi ? preset.descVi : 'Personalized plan for your goal'}
                  </p>
                </div>
                {formData.wellnessGoal === preset.value && (
                  <span className="material-symbols-outlined ml-auto text-emerald-600">check_circle</span>
                )}
              </button>
            ))}
          </div>
        )}

        {currentStep === 2 && (
          <div className="grid grid-cols-2 gap-3">
            {FASTING_DURATION_PRESETS.map((preset) => (
              <button
                key={preset.value}
                onClick={() => updateField('fastingDuration', preset.value)}
                className={`group relative flex flex-col items-center justify-center rounded-2xl border p-5 transition-all duration-200 ${
                  formData.fastingDuration === preset.value
                    ? 'border-emerald-300 bg-emerald-50 shadow-sm dark:border-emerald-700/50 dark:bg-emerald-900/30'
                    : 'border-slate-200 bg-white hover:border-slate-300 dark:border-slate-700 dark:bg-slate-800'
                }`}
              >
                <span className={`text-2xl font-black ${formData.fastingDuration === preset.value ? 'text-emerald-700 dark:text-emerald-400' : 'text-slate-900 dark:text-white'}`}>
                  {preset.label}
                </span>
                <span className="mt-1 text-[10px] font-bold uppercase tracking-widest text-slate-400">
                   Preset
                </span>
                {preset.annotationVi && (
                  <span className="mt-2 text-[10px] font-medium text-slate-500 opacity-0 transition-opacity group-hover:opacity-100 dark:text-slate-400">
                    {isVi ? preset.annotationVi : 'Health focus'}
                  </span>
                )}
                {formData.fastingDuration === preset.value && (
                  <>
                    {preset.annotationVi && (
                      <span className="mt-2 text-[10px] font-bold text-emerald-600 dark:text-emerald-400">
                        {isVi ? preset.annotationVi : 'Health focus'}
                      </span>
                    )}
                    <div className="mt-3 h-1.5 w-1.5 rounded-full bg-emerald-500" />
                  </>
                )}
              </button>
            ))}
          </div>
        )}

        {currentStep === 3 && (
          <div className="space-y-6">
            <div className="rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800">
               <label className="mb-2 block text-sm font-bold text-slate-700 dark:text-slate-300">
                  {isVi ? 'Ngày bắt đầu' : 'Start Date'}
               </label>
               <input 
                 type="date"
                 className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 font-medium focus:border-emerald-500 focus:outline-none dark:border-slate-600 dark:bg-slate-700"
                 value={formData.fastingStartDate}
                 onChange={(e) => updateField('fastingStartDate', e.target.value)}
                 min={new Date().toISOString().split('T')[0]}
               />
            </div>
            <div className="rounded-2xl bg-amber-50 p-4 dark:bg-amber-900/20">
               <div className="flex gap-3 text-amber-800 dark:text-amber-300">
                  <span className="material-symbols-outlined shrink-0">info</span>
                  <p className="text-xs leading-relaxed font-medium">
                     {isVi 
                       ? 'Lộ trình sẽ được tính toán tự động dựa trên thời điểm bạn bắt đầu. Bạn có thể điều chỉnh sau nếu cần.' 
                       : 'The roadmap will be automatically calculated based on your start date. You can adjust it later if needed.'}
                  </p>
               </div>
            </div>
          </div>
        )}

        {currentStep === 4 && (
          <div className="text-center py-4">
             <div className={`mx-auto mb-6 flex h-24 w-24 items-center justify-center rounded-full ${isPaidFeature ? 'bg-cyan-100 text-cyan-600 dark:bg-cyan-900/30' : 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30'}`}>
                <span className="material-symbols-outlined text-5xl">{isPaidFeature ? 'shopping_cart' : 'person'}</span>
             </div>
             <h3 className="text-xl font-bold text-slate-900 dark:text-white">
                {isPaidFeature 
                  ? (isVi ? 'Kích hoạt tính năng' : 'Activate Premium') 
                  : (isVi ? 'Tuyệt vời!' : 'Excellent!')}
             </h3>
             <p className="mt-2 text-sm text-slate-500 dark:text-slate-400 px-6">
                {isPaidFeature 
                  ? (isVi 
                      ? 'Lộ trình của bạn đã được chuẩn bị xong. Vui lòng thanh toán để mở khóa và bắt đầu ngay hôm nay.' 
                      : 'Your roadmap is ready. Please proceed to payment to unlock and start today.')
                  : (isVi 
                      ? 'Chúng tôi đã sẵn sàng để tạo lộ trình cá nhân hóa cho bạn. Hãy bắt đầu hành trình cải thiện sức khỏe ngay bây giờ.' 
                      : 'We are ready to create your personalized roadmap. Let\'s start your health improvement journey now.')}
             </p>
             
             {isPaidFeature && (
               <div className="mt-6 space-y-3 text-left">
                  <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 px-2">
                    {isVi ? 'Chọn gói dịch vụ' : 'Select Package'}
                  </h4>
                  {packages.length > 0 ? (
                    <div className="grid gap-3">
                      {packages.map(pkg => (
                        <button
                          key={pkg.code}
                          onClick={() => updateField('wellnessPackageCode', pkg.code)}
                          className={`flex flex-col rounded-2xl border-2 p-4 transition-all ${
                            formData.wellnessPackageCode === pkg.code
                              ? 'border-cyan-500 bg-cyan-50 dark:border-cyan-400 dark:bg-cyan-900/20'
                              : 'border-slate-100 bg-white hover:border-slate-200 dark:border-slate-700 dark:bg-slate-800'
                          }`}
                        >
                          <div className="flex items-center justify-between">
                            <span className="font-bold text-slate-900 dark:text-white">{pkg.name}</span>
                            <span className="text-sm font-bold text-cyan-600 dark:text-cyan-400">
                              {new Intl.NumberFormat(isVi ? 'vi-VN' : 'en-US', { style: 'currency', currency: 'VND' }).format(pkg.priceVnd)}
                            </span>
                          </div>
                          <p className="mt-1 text-xs text-slate-500 dark:text-slate-400 line-clamp-1">{pkg.description}</p>
                          <div className="mt-2 flex items-center gap-2 text-[10px] font-bold text-slate-400">
                            <span className="material-symbols-outlined text-[14px]">timer</span>
                            {pkg.durationDays} {isVi ? 'ngày' : 'days'}
                          </div>
                        </button>
                      ))}
                    </div>
                  ) : (
                    <div className="rounded-2xl bg-slate-100 p-4 text-center dark:bg-slate-800">
                       <p className="text-xs text-slate-500">{isVi ? 'Đang tải danh sách gói...' : 'Loading packages...'}</p>
                    </div>
                  )}
               </div>
             )}
          </div>
        )}
      </div>

      {/* Navigation buttons */}
      <div className="flex gap-3">
        {currentStep > 1 && (
          <button
            onClick={handleBack}
            className="flex-1 rounded-xl border border-slate-200 py-3.5 text-sm font-semibold text-slate-700 transition-all hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
          >
            {isVi ? 'Quay lại' : 'Back'}
          </button>
        )}
        {currentStep < 4 ? (
          <button
            onClick={handleNext}
            className="flex-1 rounded-xl bg-emerald-600 py-3.5 text-sm font-bold text-white shadow-md shadow-emerald-600/20 transition-all hover:bg-emerald-700 active:scale-[0.98]"
          >
            {isVi ? 'Tiếp tục' : 'Next'}
          </button>
        ) : (
          <button
            onClick={handleSubmit}
            disabled={isSubmitting}
            className={`flex-1 rounded-xl py-3.5 text-sm font-bold text-white shadow-md transition-all active:scale-[0.98] disabled:opacity-50 flex items-center justify-center gap-2 ${
              isPaidFeature 
                ? 'bg-cyan-600 shadow-cyan-600/20 hover:bg-cyan-700' 
                : 'bg-emerald-600 shadow-emerald-600/20 hover:bg-emerald-700'
            }`}
          >
            {isSubmitting ? (
              <>
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                <span>{isVi ? 'Đang xử lý...' : 'Processing...'}</span>
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-lg">{isPaidFeature ? 'payments' : 'auto_awesome'}</span>
                <span>
                  {isPaidFeature 
                    ? (isVi ? 'Thanh toán & Bắt đầu' : 'Pay & Start') 
                    : (isVi ? 'Bắt đầu ngay' : 'Start Now')}
                </span>
              </>
            )}
          </button>
        )}
      </div>
    </div>
  );
};

export default WellnessOnboardingWizard;
