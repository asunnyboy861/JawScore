import SwiftData
import SwiftUI

@main
struct JawScoreApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([ScoreRecord.self, HabitCheckIn.self, GlowPlanRecord.self])
        do {
            container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
        } catch {
            container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
