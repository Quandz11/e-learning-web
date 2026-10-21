package vn.nhinanchualanh.e_learning_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class LearningWidgetProvider : HomeWidgetProvider() {

    private fun safeGetInt(prefs: SharedPreferences?, key: String, defaultVal: Int): Int {
        if (prefs == null) return defaultVal
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

    private fun safeGetString(prefs: SharedPreferences?, key: String, defaultVal: String): String {
        if (prefs == null) return defaultVal
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
                val views = RemoteViews(context.packageName, R.layout.widget_learning_streak).apply {
                    val streak = safeGetInt(widgetData, "widget_streak_days", 0)
                    val learned = safeGetInt(widgetData, "widget_learned_minutes", 0)
                    val target = safeGetInt(widgetData, "widget_target_minutes", 30)
                    val course = safeGetString(widgetData, "widget_active_course_title", "Nhịn Ăn Chữa Lành")
                    val nextLesson = safeGetString(widgetData, "widget_next_lesson_title", "Bắt đầu học hôm nay")

                    val percent = if (target > 0) ((learned.toDouble() / target.toDouble()) * 100).toInt().coerceIn(0, 100) else 100

                    setTextViewText(R.id.tv_streak, "🔥 $streak ngày")
                    setTextViewText(R.id.tv_progress, "$learned/${target}p")
                    setTextViewText(R.id.tv_course, course)
                    setTextViewText(R.id.tv_next_lesson, nextLesson)
                    setProgressBar(R.id.pb_goal, 100, percent, false)

                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
