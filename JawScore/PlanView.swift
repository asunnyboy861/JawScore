import Combine
import SwiftUI
import SwiftData

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var errorText: String?
    @Published var sourceLabel: String?

    func generate(measurement: FaceMeasurement?, streak: Int, context: ModelContext) async {
        guard let measurement else {
            errorText = "Scan your face first so your plan can key off your numbers."
            return
        }
        isGenerating = true
        errorText = nil
        let startedAt = Date()
        let (content, source) = await PlanGenerator.generate(measurement: measurement, streak: streak)
        let elapsed = Date().timeIntervalSince(startedAt)
        if elapsed < AestheticConstants.planGenerationMinDurationSeconds {
            try? await Task.sleep(nanoseconds: UInt64((AestheticConstants.planGenerationMinDurationSeconds - elapsed) * 1_000_000_000))
        }
        let record = GlowPlanRecord.create(content: content, source: source.rawValue)
        context.insert(record)
        sourceLabel = source == .fms ? "On-device Apple model" : "Curated plan library"
        isGenerating = false
    }
}

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GlowPlanRecord.createdAt, order: .reverse) private var plans: [GlowPlanRecord]
    @Query(sort: \ScoreRecord.date, order: .reverse) private var records: [ScoreRecord]
    @Query private var checkIns: [HabitCheckIn]
    @StateObject private var viewModel = PlanViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @EnvironmentObject private var router: TabRouter
    @AppStorage(AppSettings.numbersOffKey) private var numbersOff = false
    @State private var deleteTarget: Date?

    private var currentPlan: GlowPlanRecord? {
        plans.first
    }

    private var streak: Int {
        StreakCalculator.streak(checkIns: checkIns)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    streakHeader
                    if let plan = currentPlan {
                        planSection(plan)
                        HabitGrid(
                            habits: plan.habits,
                            checkIns: checkIns,
                            planID: plan.id,
                            isPro: purchaseManager.isPro,
                            onToggle: { date in checkIn(date, plan: plan) },
                            onDelete: { date in deleteTarget = date }
                        )
                        .padding(16)
                        .jsCard()
                    } else {
                        emptyState
                    }
                }
                .padding(.vertical, 16)
                .appContentWidth()
                .frame(maxWidth: .infinity)
            }
            .background(Color.jsBase.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .confirmationDialog(
                "Remove this day's check-ins?",
                isPresented: Binding(
                    get: { deleteTarget != nil },
                    set: { if !$0 { deleteTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let date = deleteTarget {
                        deleteDay(date)
                    }
                    deleteTarget = nil
                }
                Button("Cancel", role: .cancel) { deleteTarget = nil }
            }
        }
    }

    private var streakHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(Color.jsOrange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(.headline)
                Text("Show up daily — small habits compound.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .jsCard()
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 44))
                .foregroundStyle(Color.jsTeal)
                .accessibilityHidden(true)
            Text("Generate My Plan")
                .font(.title3.weight(.bold))
            Text("A 4-week glow-up plan built from your scan: daily habits, the reason each one matters, and weekly milestones.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let errorText = viewModel.errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(Color.jsOrange)
                    .multilineTextAlignment(.center)
            }
            if viewModel.isGenerating {
                ProgressView("Building your plan…")
                    .tint(Color.jsTeal)
            } else {
                Button {
                    Task {
                        await viewModel.generate(
                            measurement: records.first?.measurement,
                            streak: streak,
                            context: modelContext
                        )
                    }
                } label: {
                    Text("Generate My Plan")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.jsTeal)
                .foregroundStyle(.black)
                .accessibilityLabel("Generate my glow-up plan")
                Button("Scan first") {
                    router.selection = .scan
                }
                .font(.footnote)
                .foregroundStyle(Color.jsTeal)
            }
            if let sourceLabel = viewModel.sourceLabel {
                Text("Powered by \(sourceLabel)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .jsCard()
    }

    private func planSection(_ plan: GlowPlanRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Plan")
                .font(.title3.weight(.bold))
            ForEach(Array(plan.habits.enumerated()), id: \.offset) { index, habit in
                DisclosureGroup {
                    Text(index < plan.reasons.count ? plan.reasons[index] : "Steady reps move this upward.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Label(habit, systemImage: "circle.dotted")
                        .font(.headline)
                }
                .padding(12)
                .background(Color.jsSurfaceRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityLabel("Habit \(habit), tap to see why")
            }
            Text("Weekly Milestones")
                .font(.headline)
                .padding(.top, 4)
            ForEach(Array(plan.milestones.enumerated()), id: \.offset) { index, milestone in
                HStack(alignment: .top, spacing: 8) {
                    Text("W\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.jsTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.jsTealSoft, in: Capsule())
                    Text(milestone)
                        .font(.subheadline)
                }
            }
            if let sourceLabel = viewModel.sourceLabel, plans.count == 1 {
                Text("Powered by \(sourceLabel)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .jsCard()
    }

    private func isChecked(_ habit: String, _ day: Date, plan: GlowPlanRecord) -> Bool {
        checkIns.contains { $0.habitName == habit && $0.planID == plan.id && Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func checkIn(_ date: Date, plan: GlowPlanRecord) {
        let day = Calendar.current.startOfDay(for: date)
        for habit in plan.habits where !isChecked(habit, day, plan: plan) {
            modelContext.insert(HabitCheckIn(date: day, habitName: habit, planID: plan.id))
        }
    }

    private func deleteDay(_ date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        for checkIn in checkIns where Calendar.current.isDate(checkIn.date, inSameDayAs: day) {
            modelContext.delete(checkIn)
        }
    }
}

struct HabitGrid: View {
    let habits: [String]
    let checkIns: [HabitCheckIn]
    let planID: UUID
    let isPro: Bool
    let onToggle: (Date) -> Void
    let onDelete: (Date) -> Void

    private let calendar = Calendar.current

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<AestheticConstants.habitGridDays).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("90-Day Streak Grid")
                .font(.headline)
            Text("Tap today or yesterday to check in. Long-press a day to remove it.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(days, id: \.timeIntervalSince1970) { day in
                    gridCell(day: day)
                }
            }
        }
    }

    private func completionFraction(_ day: Date) -> Double {
        guard !habits.isEmpty else { return 0 }
        let done = checkIns.filter { $0.planID == planID && calendar.isDate($0.date, inSameDayAs: day) }.count
        return Double(done) / Double(habits.count)
    }

    @ViewBuilder
    private func gridCell(day: Date) -> some View {
        let fraction = completionFraction(day)
        let isToday = calendar.isDateInToday(day)
        let isYesterday = calendar.isDateInYesterday(day)
        let editable = isPro || isToday || isYesterday
        Button {
            if editable {
                onToggle(day)
            }
        } label: {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(fraction <= 0 ? Color.jsSurfaceRaised : Color.jsOrange.opacity(0.25 + 0.75 * fraction))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(isToday ? Color.jsTeal : Color.clear, lineWidth: 1.5)
                )
                .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(!editable)
        .opacity(editable ? 1 : 0.5)
        .onLongPressGesture {
            if editable {
                onDelete(day)
            }
        }
        .accessibilityLabel(cellLabel(day: day, fraction: fraction, editable: editable))
        .accessibilityHint(editable ? "Double tap to check in" : "Available with Pro or on today and yesterday")
    }

    private func cellLabel(day: Date, fraction: Double, editable: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let percent = Int((fraction * 100).rounded())
        return "\(formatter.string(from: day)), \(percent) percent complete\(editable ? "" : ", locked")"
    }
}
