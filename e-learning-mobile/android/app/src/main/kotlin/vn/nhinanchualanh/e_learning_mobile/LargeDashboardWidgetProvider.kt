package vn.nhinanchualanh.e_learning_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class LargeDashboardWidgetProvider : HomeWidgetProvider() {

    private fun safeGetInt(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
        return try {
            prefs.getInt(key, defaultVal)
        } catch (_: Exception) {
            try {
                prefs.getString(key, null)?.toIntOrNull() ?: defaultVal
            } catch (_: Exception) {
                defaultVal
            }
        }
    }

    private fun safeGetString(prefs: SharedPreferences, key: String, defaultVal: String): String {
        return try {
            prefs.getString(key, defaultVal) ?: defaultVal
        } catch (_: Exception) {
            defaultVal
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_study_dashboard).apply {
                    val streak = safeGetInt(widgetData, "widget_streak_days", 7)
                    val learned = safeGetInt(widgetData, "widget_learned_minutes", 25)
                    val target = safeGetInt(widgetData, "widget_target_minutes", 30)
                    val courseProgress = safeGetInt(widgetData, "widget_active_course_progress", 65)
                    val course = safeGetString(widgetData, "widget_active_course_title", "Lập trình Flutter nâng cao")
                    val nextLesson = safeGetString(widgetData, "widget_next_lesson_title", "Bài 5: State Management với Riverpod")
                    val reminderTime = safeGetString(widgetData, "widget_next_reminder_time", "20:00")

                    val percent = if (target > 0) ((learned.toDouble() / target.toDouble()) * 100).toInt().coerceIn(0, 100) else 100

                    setTextViewText(R.id.tv_streak, "🔥 $streak ngày")
                    setTextViewText(R.id.tv_learned_val, "${learned}p")
                    setTextViewText(R.id.tv_target_val, "${target}p")
                    setTextViewText(R.id.tv_goal_percent, "$percent%")
                    setTextViewText(R.id.tv_course, course)
                    setTextViewText(R.id.tv_next_lesson, nextLesson)
                    setTextViewText(R.id.tv_reminder, "⏰ Lịch nhắc học: $reminderTime")
                    setProgressBar(R.id.pb_course, 100, courseProgress.coerceIn(0, 100), false)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
