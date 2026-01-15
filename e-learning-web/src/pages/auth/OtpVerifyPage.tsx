import React, { useRef, useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const OtpVerifyPage = () => {
    const { t } = useTranslation();
    const [otp, setOtp] = useState(['', '', '', '', '', '']);
    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

    useEffect(() => {
        if (inputRefs.current[0]) {
            inputRefs.current[0].focus();
        }
    }, []);

    const handleChange = (index: number, value: string) => {
        if (!/^\d*$/.test(value)) return;

        const newOtp = [...otp];
        newOtp[index] = value;
        setOtp(newOtp);

        if (value && index < 5) {
            inputRefs.current[index + 1]?.focus();
        }
    };

    const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Backspace' && !otp[index] && index > 0) {
            inputRefs.current[index - 1]?.focus();
        }
    };

    return (
        <div className="w-full h-full flex flex-col items-center justify-center">
            {/* Header Section */}
            <div className="text-center flex flex-col items-center gap-2 mb-8">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center mb-2">
                    <span className="material-symbols-outlined text-primary text-2xl">lock_person</span>
                </div>
                <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white tracking-tight">{t('auth.verifyAccount')}</h1>
                <p className="text-gray-500 dark:text-gray-400 text-base leading-relaxed max-w-sm">
                    {t('auth.codeSentTo')} <span className="font-medium text-gray-900 dark:text-gray-200">stu***@lumina.edu</span>.
                </p>
            </div>
            {/* Verification Form */}
            <form className="flex flex-col gap-8 w-full max-w-[400px]" onSubmit={(e) => e.preventDefault()}>
                {/* OTP Inputs */}
                <div className="flex justify-center gap-2 sm:gap-3 w-full">
                    {otp.map((digit, index) => (
                        <React.Fragment key={index}>
                            <input
                                ref={(el: HTMLInputElement | null) => { inputRefs.current[index] = el; }}
                                autoFocus={index === 0}
                                className="w-10 h-12 sm:w-12 sm:h-14 text-center text-xl sm:text-2xl font-bold text-gray-900 dark:text-white bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all duration-200 selection:bg-primary/20 placeholder-transparent"
                                inputMode="numeric"
                                maxLength={1}
                                placeholder="-"
                                type="text"
                                value={digit}
                                onChange={(e) => handleChange(index, e.target.value)}
                                onKeyDown={(e) => handleKeyDown(index, e)}
                            />
                            {index === 2 && (
                                <div className="flex items-center justify-center text-gray-300 dark:text-gray-600">-</div>
                            )}
                        </React.Fragment>
                    ))}
                </div>
                {/* Timer & Resend */}
                <div className="flex flex-col items-center gap-2">
                    <div className="flex items-center gap-2 text-sm font-medium text-gray-500 dark:text-gray-400 bg-background-light dark:bg-gray-800/50 py-2 px-4 rounded-full border border-transparent dark:border-gray-700">
                        <span className="material-symbols-outlined text-lg" style={{ fontSize: '18px' }}>timer</span>
                        <span className="font-mono" id="countdown">00:45</span>
                    </div>
                    <div className="text-sm">
                        <span className="text-gray-400 dark:text-gray-500">{t('auth.didntReceiveCode')}</span>
                        <button className="font-semibold text-primary dark:text-primary-400 hover:text-primary/80 dark:hover:text-primary-300 ml-1 transition-colors disabled:opacity-50 disabled:cursor-not-allowed" type="button">
                            {t('auth.resend')}
                        </button>
                    </div>
                </div>
                {/* Actions */}
                <div className="flex flex-col gap-4 mt-2">
                    <button className="w-full bg-primary hover:bg-primary/90 text-white font-medium text-base h-12 rounded-lg shadow-sm transition-all duration-200 flex items-center justify-center gap-2 group">
                        <span>{t('auth.verifyAndProceed')}</span>
                        <span className="material-symbols-outlined text-lg group-hover:translate-x-0.5 transition-transform">arrow_forward</span>
                    </button>
                    <Link className="text-sm text-center text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200 transition-colors flex items-center justify-center gap-1 group" to="/login">
                        <span className="material-symbols-outlined text-base group-hover:-translate-x-0.5 transition-transform">arrow_back</span>
                        {t('auth.backToLogin')}
                    </Link>
                </div>
            </form>
            {/* Footer Info */}
            <div className="mt-8 text-xs text-gray-400 dark:text-gray-600 text-center w-full px-4">
                <p>© 2024 LuminaLearn Inc. Secure Verification System.</p>
            </div>
        </div>
    );
};

export default OtpVerifyPage;
