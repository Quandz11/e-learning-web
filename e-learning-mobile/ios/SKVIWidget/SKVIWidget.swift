import WidgetKit
import SwiftUI

private let appGroupId = "group.vn.nhinanchualanh.elearning"

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SKVIWidgetEntry {
        SKVIWidgetEntry(
            date: Date(),
            streakDays: 7,
            targetMinutes: 30,
            learnedMinutes: 25,
            activeCourseTitle: "Khóa học Nhịn ăn Chữa lành SKVI",
            activeCourseProgress: 65,
            nextLessonTitle: "Bài 5: Cơ chế Tự thực Autophagy & Re-feeding",
            nextReminderTime: "20:00"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SKVIWidgetEntry) -> ()) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SKVIWidgetEntry>) -> ()) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SKVIWidgetEntry {
        let prefs = UserDefaults(suiteName: appGroupId)
        let streak = prefs?.integer(forKey: "widget_streak_days") ?? 0
        let target = prefs?.integer(forKey: "widget_target_minutes") ?? 30
        let learned = prefs?.integer(forKey: "widget_learned_minutes") ?? 0
        let course = prefs?.string(forKey: "widget_active_course_title") ?? "Khóa học Nhịn ăn Chữa lành SKVI"
        let progress = prefs?.integer(forKey: "widget_active_course_progress") ?? 0
        let nextLesson = prefs?.string(forKey: "widget_next_lesson_title") ?? "Tiếp tục bài học hôm nay"
        let reminder = prefs?.string(forKey: "widget_next_reminder_time") ?? "20:00"

        return SKVIWidgetEntry(
            date: Date(),
            streakDays: streak > 0 ? streak : 1,
            targetMinutes: target > 0 ? target : 30,
            learnedMinutes: learned,
            activeCourseTitle: course,
            activeCourseProgress: progress,
            nextLessonTitle: nextLesson,
            nextReminderTime: reminder
        )
    }
}

struct SKVIWidgetEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let targetMinutes: Int
    let learnedMinutes: Int
    let activeCourseTitle: String
    let activeCourseProgress: Int
    let nextLessonTitle: String
    let nextReminderTime: String
}

// MARK: - Views

struct SmallWidgetView: View {
    let entry: SKVIWidgetEntry

    var percent: Double {
        guard entry.targetMinutes > 0 else { return 1.0 }
        return min(max(Double(entry.learnedMinutes) / Double(entry.targetMinutes), 0.0), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("🔥 \(entry.streakDays) ngày")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.9, green: 0.32, blue: 0.0))
                Spacer()
                Text("SKVI")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.06, green: 0.38, blue: 0.25))
            }

            Text(entry.activeCourseTitle)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.12))
                .lineLimit(1)

            Text(entry.nextLessonTitle)
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                .lineLimit(1)

            Spacer(minLength: 0)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.88, green: 0.91, blue: 0.89))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.06, green: 0.38, blue: 0.25))
                        .frame(width: max(geo.size.width * CGFloat(percent), 4), height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Mục tiêu")
                    .font(.system(size: 9))
                    .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                Spacer()
                Text("\(entry.learnedMinutes)/\(entry.targetMinutes)p")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.06, green: 0.38, blue: 0.25))
            }
        }
        .padding(12)
        .background(Color.white)
    }
}

struct MediumWidgetView: View {
    let entry: SKVIWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("▶ ĐANG HỌC")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.06, green: 0.38, blue: 0.25))
                Spacer()
                Text("🔥 Chuỗi \(entry.streakDays) ngày")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.9, green: 0.32, blue: 0.0))
            }

            Text(entry.activeCourseTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.12))
                .lineLimit(1)

            Text(entry.nextLessonTitle)
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack {
                Text("Tiến độ khóa học")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                Spacer()
                Text("\(entry.activeCourseProgress)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.06, green: 0.38, blue: 0.25))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.88, green: 0.91, blue: 0.89))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.06, green: 0.38, blue: 0.25))
                        .frame(width: max(geo.size.width * CGFloat(Double(entry.activeCourseProgress) / 100.0), 4), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Color.white)
    }
}

struct LargeWidgetView: View {
    let entry: SKVIWidgetEntry

    var percent: Int {
        guard entry.targetMinutes > 0 else { return 100 }
        return min(max(Int((Double(entry.learnedMinutes) / Double(entry.targetMinutes)) * 100), 0), 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎓 Bảng tin học tập SKVI")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.12))
                Spacer()
                Text("🔥 \(entry.streakDays) ngày")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.9, green: 0.32, blue: 0.0))
            }

            // 3-metric row
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("\(entry.learnedMinutes)p")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.38, blue: 0.25))
                    Text("Đã học")
                        .font(.system(size: 9))
                        .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(red: 0.96, green: 0.98, blue: 0.96))
                .cornerRadius(8)

                VStack(spacing: 2) {
                    Text("\(entry.targetMinutes)p")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.12))
                    Text("Mục tiêu")
                        .font(.system(size: 9))
                        .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(red: 0.96, green: 0.98, blue: 0.96))
                .cornerRadius(8)

                VStack(spacing: 2) {
                    Text("\(percent)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.38, blue: 0.25))
                    Text("Hoàn thành")
                        .font(.system(size: 9))
                        .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(red: 0.96, green: 0.98, blue: 0.96))
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.activeCourseTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.12))
                    .lineLimit(1)

                Text(entry.nextLessonTitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                    .lineLimit(1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.88, green: 0.91, blue: 0.89))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.06, green: 0.38, blue: 0.25))
                            .frame(width: max(geo.size.width * CGFloat(Double(entry.activeCourseProgress) / 100.0), 4), height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)
            }

            Spacer(minLength: 0)

            HStack {
                Text("⏰ Lịch nhắc học: \(entry.nextReminderTime)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.33, green: 0.39, blue: 0.36))
                Spacer()
                Text("HỌC NGAY ▶")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.06, green: 0.38, blue: 0.25))
            }
        }
        .padding(14)
        .background(Color.white)
    }
}

struct SKVIWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SKVIWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                LargeWidgetView(entry: entry)
            }
        }
        .widgetURL(URL(string: "skvi://open"))
    }
}

@main
struct SKVIWidget: Widget {
    let kind: String = "SKVIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SKVIWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SKVI Học Tập & Chữa Lành")
        .description("Theo dõi chuỗi học, tiến độ và lịch nhắc nhở mỗi ngày.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
