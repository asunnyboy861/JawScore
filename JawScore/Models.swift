import Combine
import Foundation
import SwiftData
import SwiftUI

@Model
final class ScoreRecord {
    var id: UUID
    var date: Date
    var quality: Int
    var overall: Double
    var band: Double
    var metrics: Data

    init(id: UUID = UUID(), date: Date, quality: Int, overall: Double, band: Double, metrics: Data) {
        self.id = id
        self.date = date
        self.quality = quality
        self.overall = overall
        self.band = band
        self.metrics = metrics
    }

    var measurement: FaceMeasurement? {
        try? JSONDecoder().decode(FaceMeasurement.self, from: metrics)
    }

    var result: ScoreResult? {
        guard let measurement else { return nil }
        return ScoringEngine.score(measurement, quality: quality)
    }

    static func create(from measurement: FaceMeasurement, quality: Int, date: Date = Date()) -> ScoreRecord {
        let result = ScoringEngine.score(measurement, quality: quality)
        let data = (try? JSONEncoder().encode(measurement)) ?? Data()
        return ScoreRecord(date: date, quality: quality, overall: result.overall, band: result.band, metrics: data)
    }
}

@Model
final class HabitCheckIn {
    var id: UUID
    var date: Date
    var habitName: String
    var planID: UUID

    init(id: UUID = UUID(), date: Date, habitName: String, planID: UUID) {
        self.id = id
        self.date = date
        self.habitName = habitName
        self.planID = planID
    }
}

@Model
final class GlowPlanRecord {
    var id: UUID
    var createdAt: Date
    var habitsJSON: Data
    var reasonsJSON: Data
    var milestonesJSON: Data
    var sourcePlan: String

    init(id: UUID = UUID(), createdAt: Date, habitsJSON: Data, reasonsJSON: Data, milestonesJSON: Data, sourcePlan: String) {
        self.id = id
        self.createdAt = createdAt
        self.habitsJSON = habitsJSON
        self.reasonsJSON = reasonsJSON
        self.milestonesJSON = milestonesJSON
        self.sourcePlan = sourcePlan
    }

    var habits: [String] {
        (try? JSONDecoder().decode([String].self, from: habitsJSON)) ?? []
    }

    var reasons: [String] {
        (try? JSONDecoder().decode([String].self, from: reasonsJSON)) ?? []
    }

    var milestones: [String] {
        (try? JSONDecoder().decode([String].self, from: milestonesJSON)) ?? []
    }

    static func create(content: GlowPlanContent, source: String, date: Date = Date()) -> GlowPlanRecord {
        GlowPlanRecord(
            createdAt: date,
            habitsJSON: (try? JSONEncoder().encode(content.habits)) ?? Data(),
            reasonsJSON: (try? JSONEncoder().encode(content.reasons)) ?? Data(),
            milestonesJSON: (try? JSONEncoder().encode(content.milestones)) ?? Data(),
            sourcePlan: source
        )
    }
}

enum FreeScanCounter {
    static let appGroupID = "group.com.zzoutuo.JawScore"
    private static let dayStampKey = "freeScanDayStamp"
    private static let countKey = "freeScanCount"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func startOfToday(_ now: Date = Date()) -> Date {
        Calendar.current.startOfDay(for: now)
    }

    static func scansToday(now: Date = Date()) -> Int {
        let store = defaults
        let stamp = store.double(forKey: dayStampKey)
        guard stamp > 0, Date(timeIntervalSince1970: stamp) >= startOfToday(now) else { return 0 }
        return store.integer(forKey: countKey)
    }

    static func canScan(isPro: Bool, now: Date = Date()) -> Bool {
        isPro || scansToday(now: now) < AestheticConstants.freeScansPerDay
    }

    static func recordScan(now: Date = Date()) {
        let store = defaults
        let stamp = startOfToday(now).timeIntervalSince1970
        if store.double(forKey: dayStampKey) != stamp {
            store.set(stamp, forKey: dayStampKey)
            store.set(1, forKey: countKey)
        } else {
            store.set(store.integer(forKey: countKey) + 1, forKey: countKey)
        }
    }
}

enum AppSettings {
    static let onboardingKey = "hasCompletedOnboarding"
    static let numbersOffKey = "numbersOff"
    static let breakUntilKey = "breakUntilTimestamp"

    static func isOnBreak(now: Date = Date()) -> Bool {
        let stamp = UserDefaults.standard.double(forKey: breakUntilKey)
        return stamp > now.timeIntervalSince1970
    }

    static func startBreak(now: Date = Date()) {
        let until = now.addingTimeInterval(Double(AestheticConstants.breakDurationDays) * 24 * 60 * 60)
        UserDefaults.standard.set(until.timeIntervalSince1970, forKey: breakUntilKey)
    }

    static func endBreak() {
        UserDefaults.standard.set(0.0, forKey: breakUntilKey)
    }

    static var breakUntilDate: Date? {
        let stamp = UserDefaults.standard.double(forKey: breakUntilKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }
}

enum StreakCalculator {
    static func streak(checkIns: [HabitCheckIn], today: Date = Date()) -> Int {
        let calendar = Calendar.current
        var days = Set<TimeInterval>()
        for checkIn in checkIns {
            days.insert(calendar.startOfDay(for: checkIn.date).timeIntervalSince1970)
        }
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = calendar.startOfDay(for: today)
        if !days.contains(cursor.timeIntervalSince1970) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }
        while days.contains(cursor.timeIntervalSince1970) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}

@MainActor
final class TabRouter: ObservableObject {
    @Published var selection: AppTab = .scan
}

enum AppTab: Hashable {
    case scan
    case plan
    case trends
}
