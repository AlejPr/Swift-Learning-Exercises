import SwiftUI
import NotificationCenter
import OSLog


@Observable
class NotificationsCenter {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "App", category: "NotificationsCenter")
    private let center = UNUserNotificationCenter.current()
    
    func requestAuthorization() async -> Bool {
        let currentSettings = await center.notificationSettings()
        
        if currentSettings.authorizationStatus == .denied {
            if let appSettings = URL(string: UIApplication.openNotificationSettingsURLString) { await UIApplication.shared.open(appSettings) }
            return false
        }
        
        //Not denied
        do {
            let res = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            switch res {
            case true: logger.info("Successfully obtained notifications authorization")
            case false: logger.info("User rejected notifications permissions")
            }
            return res
        } catch {
            logger.error("Failed to obtain notifications authorization \(error)")
            return false
        }
    }
    
    func notificationsEnabled() async -> Bool {
        return await center.notificationSettings().authorizationStatus == .authorized
    }
    
    func cancelNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func scheduleNotifications(_ timeInterval: TimeInterval) {
        
    }
    
}
