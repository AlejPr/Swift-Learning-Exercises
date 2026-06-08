import SwiftUI
import SwiftData

@main
struct WaterTrackApp: App {
    
    @State var swiftDataPersistenceService = SwiftDataPersistenceService(inMemory: false)

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(swiftDataPersistenceService.container)
        .environment(NotificationsCenter())
    }
}
