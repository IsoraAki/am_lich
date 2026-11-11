import SwiftUI
import WidgetKit

// Keep the palette and daily shuffle aligned with calendar_colors.dart.
private let dayColors: [UInt32] = [0x2C6E68, 0x4D5F9E, 0x92516E, 0xAD5039, 0x527448, 0x715690]

private struct LunarEntry: TimelineEntry {
    let date: Date
    let day: Int
    let month: Int
    let leap: Bool
    let auspicious: Bool
    let solarLabel: String
    let colorIndex: Int

    var accent: Color {
        let hex = dayColors[colorIndex]
        return Color(
            red: Double((hex >> 16) & 255) / 255,
            green: Double((hex >> 8) & 255) / 255,
            blue: Double(hex & 255) / 255
        )
    }
}

private struct LunarProvider: TimelineProvider {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return value
    }

    private func entry(_ date: Date) -> LunarEntry {
        let parts = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let utc = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = parts.year
        components.month = parts.month
        components.day = parts.day
        let epochDay = Int(utc.date(from: components)!.timeIntervalSince1970 / 86400)
        let url = Bundle.main.url(forResource: "widget_months", withExtension: "csv")
        let content = url.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        let row = content.split(separator: "\n")
            .map { $0.split(separator: ",").compactMap { Int($0) } }
            .last { $0.count == 3 && $0[0] <= epochDay }
        let supported = (1900...2199).contains(parts.year!)
        let day = supported ? row.map { epochDay - $0[0] + 1 } ?? 0 : 0
        let month = row?[1] ?? 1
        let branch = (epochDay + 2440589) % 12
        let spirit = ((branch - 2 * (month - 1)) % 12 + 12) % 12
        let weekdays = ["Chủ nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"]
        let label = "\(weekdays[parts.weekday! - 1]) · \(parts.day!)/\(parts.month!)/\(parts.year!)"
        let shuffle = (epochDay * 37) ^ (epochDay >> 3) ^ (epochDay >> 5)
        let colorIndex = ((shuffle % dayColors.count) + dayColors.count) % dayColors.count
        return LunarEntry(
            date: date, day: day, month: month, leap: row?[2] == 1,
            auspicious: [0, 1, 4, 5, 7, 10].contains(spirit), solarLabel: label,
            colorIndex: colorIndex
        )
    }

    func placeholder(in context: Context) -> LunarEntry { entry(Date()) }

    func getSnapshot(in context: Context, completion: @escaping (LunarEntry) -> Void) {
        completion(entry(Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunarEntry>) -> Void) {
        let now = Date()
        let start = calendar.startOfDay(for: now)
        let entries = (0..<8).map { offset in
            entry(offset == 0 ? now : calendar.date(byAdding: .day, value: offset, to: start)!)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

private struct LunarWidgetView: View {
    let entry: LunarEntry

    var body: some View {
        VStack(spacing: 4) {
            Text("ÂM LỊCH")
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .opacity(0.9)
            Text(entry.day == 0 ? "—" : String(format: "%02d", entry.day))
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.5)
            Text(entry.day == 0 ? "Hỗ trợ 1900–2199" : "Tháng \(entry.month)\(entry.leap ? " nhuận" : "")")
                .font(.system(size: 13, weight: .medium))
            Text(entry.auspicious ? "Hoàng đạo" : "Hắc đạo")
                .font(.system(size: 10))
                .opacity(0.9)
            Text(entry.solarLabel)
                .font(.system(size: 9))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(entry.accent, for: .widget)
        .widgetURL(URL(string: "amlich://today"))
    }
}

@main
struct LunarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LunarWidget", provider: LunarProvider()) { entry in
            LunarWidgetView(entry: entry)
        }
        .configurationDisplayName("Âm Lịch")
        .description("Ngày âm lịch Việt Nam và ngày hoàng đạo, hắc đạo.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
