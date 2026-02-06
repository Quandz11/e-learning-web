import React from 'react';
import { useTranslation } from 'react-i18next';

const LanguageSwitcher: React.FC = () => {
    const { i18n } = useTranslation();

    const changeLanguage = (lng: string) => {
        i18n.changeLanguage(lng);
    };

    return (
        <div className="flex items-center gap-1 bg-gray-100 dark:bg-gray-800 rounded-lg p-1">
            <button
                onClick={() => changeLanguage('vi')}
                className={`px-2 py-1 rounded text-xs font-bold transition-all ${i18n.language === 'vi'
                    ? 'bg-white dark:bg-gray-700 text-primary shadow-sm'
                    : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200'
                    }`}
            >
                VI
            </button>
            <button
                onClick={() => changeLanguage('en')}
                className={`px-2 py-1 rounded text-xs font-bold transition-all ${i18n.language === 'en'
                    ? 'bg-white dark:bg-gray-700 text-primary shadow-sm'
                    : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200'
                    }`}
            >
                EN
            </button>
        </div>
    );
};

export default LanguageSwitcher;
