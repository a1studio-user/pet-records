import Foundation
import UserNotifications

enum SupabaseConfiguration {
    static var projectURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !value.isEmpty else { return nil }
        return URL(string: value)
    }

    static var publishableKey: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
              !value.isEmpty else { return nil }
        return value
    }

    static var isConfigured: Bool { projectURL != nil && publishableKey != nil }
}

enum NotificationService {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func schedule(record: LifeRecord, at date: Date) {
        Task {
            guard await requestAuthorization() else { return }
            let content = UNMutableNotificationContent()
            content.title = "宠刻提醒"
            content.body = "你为这条记录设置的时间到了：\(record.title)"
            content.sound = .default
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: record.id.uuidString, content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    static func cancel(recordID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [recordID.uuidString])
    }
}
