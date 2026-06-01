import Foundation
import SwiftData

@Model
final class WaterLog {
    var id: UUID
    var timestamp: Date
    var amountML: Int       // e.g. 250 for a standard glass
    var source: String      // "iPhone" | "Watch" | "Widget" | "Notification"
    
    init(id: UUID = UUID(), timestamp: Date = .now, amountML: Int, source: String) {
        self.id = id
        self.timestamp = timestamp
        self.amountML = amountML
        self.source = source
    }
}

@Model
final class UserSettings {
    var dailyGoalML: Int    // default 2000
    var reminderInterval: TimeInterval  // seconds between reminders, default 7200 (2hr)
    var remindersEnabled: Bool
    
    init(dailyGoalML: Int = 2000, reminderInterval: TimeInterval = 7200, remindersEnabled: Bool = false) {
        self.dailyGoalML = dailyGoalML
        self.reminderInterval = reminderInterval
        self.remindersEnabled = remindersEnabled
    }
}


final class SwiftDataPersistenceService {
    
    private static let appGroup: String = "group.waterTrack"
    let container: ModelContainer
    var context: ModelContext { self.container.mainContext }
    
    init(inMemory: Bool = false) {
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SwiftDataPersistenceService.appGroup)
        let storeURL = groupURL?.appendingPathComponent("WaterTrack.sqlite")
        
        let schema = Schema([
            WaterLog.self,
            UserSettings.self
        ])
        
        let config: ModelConfiguration = {
            if inMemory { return ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory) }
            return ModelConfiguration(schema: schema, url: storeURL!)
        }()
        
        do {
            container = try ModelContainer(for: schema, configurations: config)
        }
        catch { fatalError("Could not Initialize ModelContainer, \(error)") }
    }
    
}
