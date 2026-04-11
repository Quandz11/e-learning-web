import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useDailyPlanner } from '../../../hooks/useDailyPlanner';
import { toast } from 'react-hot-toast';

const inputLabelClassName = 'text-[11px] font-bold uppercase tracking-[0.08em] text-slate-500 mb-1.5 block';

const PlannerMealCard: React.FC = () => {
  const { t } = useTranslation();
  const planner = useDailyPlanner();

  const [mealIngredients, setMealIngredients] = useState('');
  const [mealServings, setMealServings] = useState('');
  const [mealGoal, setMealGoal] = useState('');
  const [mealDietaryPreference, setMealDietaryPreference] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const generateMealSuggestion = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!planner.wellnessPlan?.id) return;

    const ingredients = mealIngredients.split(/[\n,]/).map((item) => item.trim()).filter(Boolean);
    if (ingredients.length === 0) {
      toast.error(t('wellness.dashboard.errors.mealIngredients', { defaultValue: 'Vui lòng nhập nguyên liệu' }));
      return;
    }

    setIsSubmitting(true);
    const toastId = toast.loading(t('wellness.dashboard.status.generatingMeal', { defaultValue: 'Đang tạo thực đơn...' }));
    try {
      await planner.generateMeal({
        ingredients,
        servings: Math.max(1, Number(mealServings || 1)),
        goal: mealGoal,
        dietaryPreference: mealDietaryPreference.trim(),
      });
      toast.success(t('wellness.dashboard.success.mealReady', { defaultValue: 'Thực đơn đã sẵn sàng!' }), { id: toastId });
    } catch (error: any) {
      toast.error(error?.message || t('common.error'), { id: toastId });
    } finally {
      setIsSubmitting(false);
    }
  };

  const suggestion = planner.mealSuggestion;

  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-5 dark:border-slate-700/60 dark:bg-slate-800">
      <div className="mb-4 inline-flex items-center gap-2 text-[15px] font-bold text-slate-900 dark:text-white">
        <div className="grid h-8 w-8 place-items-center rounded-xl bg-orange-50 text-orange-600 dark:bg-orange-900/30 dark:text-orange-500">
          <span className="material-symbols-outlined text-[18px]">restaurant_menu</span>
        </div>
        {t('wellness.dashboard.meal.title', { defaultValue: 'Thực đơn thông minh' })}
      </div>
      
      <form onSubmit={generateMealSuggestion} className="space-y-4">
        <label className="block">
          <span className={inputLabelClassName}>{t('wellness.dashboard.meal.form.ingredients', { defaultValue: 'Nguyên liệu có sẵn' })}</span>
          <textarea 
            placeholder={t('wellness.dashboard.meal.placeholders.ingredients', { defaultValue: 'VD: Gà, Bông cải xanh, Trứng...' })} 
            value={mealIngredients} 
            onChange={(e) => setMealIngredients(e.target.value)} 
            className="min-h-[80px] w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm transition-colors focus:border-orange-400 focus:bg-white focus:outline-none focus:ring-1 focus:ring-orange-400 dark:border-slate-700 dark:bg-slate-900/50 dark:focus:bg-slate-900" 
          />
        </label>
        
        <div className="grid grid-cols-2 gap-3">
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.meal.form.servings', { defaultValue: 'Khẩu phần' })}</span>
            <input 
              type="number" 
              min={1} 
              max={12} 
              placeholder={t('wellness.dashboard.meal.placeholders.servings', { defaultValue: 'VD: 2' })} 
              value={mealServings} 
              onChange={(e) => setMealServings(e.target.value)} 
              className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm transition-colors focus:border-orange-400 focus:bg-white focus:outline-none focus:ring-1 focus:ring-orange-400 dark:border-slate-700 dark:bg-slate-900/50" 
            />
          </label>
          <label className="block">
            <span className={inputLabelClassName}>{t('wellness.dashboard.meal.form.goal', { defaultValue: 'Mục tiêu ăn' })}</span>
            <input 
              placeholder={t('wellness.dashboard.meal.placeholders.goal', { defaultValue: 'VD: Tăng cơ' })} 
              value={mealGoal} 
              onChange={(e) => setMealGoal(e.target.value)} 
              className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm transition-colors focus:border-orange-400 focus:bg-white focus:outline-none focus:ring-1 focus:ring-orange-400 dark:border-slate-700 dark:bg-slate-900/50" 
            />
          </label>
        </div>
        
        <label className="block">
          <span className={inputLabelClassName}>{t('wellness.dashboard.meal.form.dietaryPreference', { defaultValue: 'Chế độ kiêng khem (Tùy chọn)' })}</span>
          <input 
            placeholder={t('wellness.dashboard.meal.placeholders.dietaryPreference', { defaultValue: 'VD: Không ăn cay, Keto...' })} 
            value={mealDietaryPreference} 
            onChange={(e) => setMealDietaryPreference(e.target.value)} 
            className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm transition-colors focus:border-orange-400 focus:bg-white focus:outline-none focus:ring-1 focus:ring-orange-400 dark:border-slate-700 dark:bg-slate-900/50" 
          />
        </label>
        
        <button 
          type="submit" 
          disabled={isSubmitting || !planner.wellnessPlan} 
          className="flex w-full items-center justify-center gap-2 rounded-xl bg-slate-900 px-4 py-3.5 text-sm font-bold text-white shadow-md shadow-slate-900/20 transition-all hover:bg-slate-800 focus:ring-2 focus:ring-slate-900 focus:ring-offset-2 disabled:opacity-50 dark:bg-slate-700 dark:hover:bg-slate-600"
        >
          {isSubmitting ? (
            <>
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white" />
              {t('wellness.dashboard.status.generatingMeal', { defaultValue: 'Đang tạo...' })}
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[18px]">auto_awesome</span>
              {t('wellness.dashboard.meal.actions.generate', { defaultValue: 'Trợ lý lên thực đơn' })}
            </>
          )}
        </button>
      </form>

      {suggestion && (
        <div className="mt-5 rounded-2xl border border-orange-200 bg-orange-50/50 p-4 dark:border-orange-900/50 dark:bg-orange-900/20">
          <div className="text-[13px] font-bold text-orange-900 dark:text-orange-300 mb-2">{t('wellness.dashboard.meal.result.title', { defaultValue: 'Thực đơn đề xuất:' })}</div>
          <div className="text-[13px] leading-relaxed text-orange-900/80 dark:text-orange-200/80 whitespace-pre-line">
            {suggestion.menu}
          </div>
          <div className="mt-4 pt-3 border-t border-orange-200/50 dark:border-orange-800/50">
            <span className="text-[11px] font-bold uppercase tracking-wider text-orange-600/70 dark:text-orange-400/70 mb-1 block">{t('wellness.dashboard.meal.result.notes', { defaultValue: 'Lưu ý dinh dưỡng:' })}</span>
            <span className="text-[12px] text-orange-900/70 dark:text-orange-200/70 italic">{suggestion.nutritionNotes}</span>
          </div>
        </div>
      )}
    </div>
  );
};

export default PlannerMealCard;
