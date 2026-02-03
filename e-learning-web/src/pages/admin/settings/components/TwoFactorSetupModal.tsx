import React, { useState, useEffect } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { useTranslation } from 'react-i18next';
import { authApi } from '../../../../services/authApi';

interface TwoFactorSetupModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
}

const TwoFactorSetupModal: React.FC<TwoFactorSetupModalProps> = ({ isOpen, onClose, onSuccess }) => {
    const { t } = useTranslation();
    const [step, setStep] = useState(1); // 1: QR, 2: Complete
    const [secret, setSecret] = useState('');
    const [qrUri, setQrUri] = useState('');
    const [code, setCode] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (isOpen) {
            setStep(1);
            setCode('');
            setError(null);
            fetchSetup();
        }
    }, [isOpen]);

    const fetchSetup = async () => {
        try {
            setLoading(true);
            const data = await authApi.setupTwoFactor();
            setSecret(data.secret);
            setQrUri(data.qrCodeUri);
        } catch (err: any) {
            setError('Failed to generate 2FA setup. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const handleVerify = async () => {
        try {
            setLoading(true);
            setError(null);
            await authApi.enableTwoFactor(secret, code);
            setStep(2); // Success step
            setTimeout(() => {
                onSuccess();
                onClose();
            }, 2000);
        } catch (err: any) {
            setError(err.message || 'Verification failed. Invalid code.');
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-800">
                <div className="mb-4 flex items-center justify-between">
                    <h3 className="text-xl font-bold text-gray-900 dark:text-white">
                        {step === 1 ? t('admin.settings.setup.title') : t('admin.settings.setup.titleComplete')}
                    </h3>
                    <button onClick={onClose} className="rounded-full p-2 hover:bg-gray-100 dark:hover:bg-gray-700">
                        <span className="material-symbols-outlined text-gray-500">close</span>
                    </button>
                </div>

                {step === 1 && (
                    <div className="space-y-6">
                        <div className="text-center">
                            <p className="mb-4 text-sm text-gray-500 dark:text-gray-400">
                                {t('admin.settings.setup.scanQr')}
                            </p>

                            {loading && !qrUri ? (
                                <div className="flex h-48 items-center justify-center">
                                    <span className="material-symbols-outlined animate-spin">progress_activity</span>
                                </div>
                            ) : qrUri ? (
                                <div className="flex justify-center bg-white p-4 rounded-lg border border-gray-200">
                                    <QRCodeSVG value={qrUri} size={180} />
                                </div>
                            ) : (
                                <p className="text-red-500">{t('admin.settings.setup.errorQr')}</p>
                            )}

                            <p className="mt-4 text-xs text-gray-400">
                                {t('admin.settings.setup.secretKey')}: <span className="font-mono">{secret}</span>
                            </p>
                        </div>

                        <div className="space-y-2">
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                {t('admin.settings.setup.enterCode')}
                            </label>
                            <input
                                className="w-full rounded-lg border border-gray-300 bg-gray-50 px-4 py-3 text-center text-xl tracking-widest focus:border-primary focus:ring-primary dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                placeholder="000 000"
                                maxLength={6}
                                value={code}
                                onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
                            />
                        </div>

                        {error && <p className="text-center text-sm text-red-600">{error}</p>}

                        <button
                            onClick={handleVerify}
                            disabled={code.length !== 6 || loading}
                            className="w-full rounded-lg bg-primary py-3 font-semibold text-white hover:bg-primary/90 disabled:opacity-50"
                        >
                            {loading ? t('admin.settings.setup.verifying') : t('admin.settings.setup.verifyEnable')}
                        </button>
                    </div>
                )}

                {step === 2 && (
                    <div className="py-8 text-center">
                        <div className="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-full bg-green-100 text-green-600">
                            <span className="material-symbols-outlined text-4xl">check_circle</span>
                        </div>
                        <h4 className="text-lg font-semibold text-gray-900 dark:text-white">{t('admin.settings.setup.successTitle')}</h4>
                        <p className="text-gray-500 dark:text-gray-400">
                            {t('admin.settings.setup.successDesc')}
                        </p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default TwoFactorSetupModal;
