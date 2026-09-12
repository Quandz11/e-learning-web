package vn.nhinanchualanh.e_learning_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MediumCourseWidgetProvider : HomeWidgetProvider() {

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
                val views = RemoteViews(context.packageName, R.layout.widget_course_resume).apply {
                    val streak = safeGetInt(widgetData, "widget_streak_days", 7)
                    val courseProgress = safeGetInt(widgetData, "widget_active_course_progress", 65)
                    val course = safeGetString(widgetData, "widget_active_course_title", "Khóa học Nhịn ăn Chữa lành SKVI")
                    val nextLesson = safeGetString(widgetData, "widget_next_lesson_title", "Bài 5: Cơ chế Tự thực Autophagy & Re-feeding")

                    setTextViewText(R.id.tv_streak, "🔥 Chuỗi $streak ngày")
                    setTextViewText(R.id.tv_course, course)
                    setTextViewText(R.id.tv_next_lesson, nextLesson)
                    setTextViewText(R.id.tv_course_percent, "$courseProgress%")
                    setProgressBar(R.id.pb_course, 100, courseProgress.coerceIn(0, 100), false)

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
