import Foundation
import Combine

@MainActor
final class QuestService: ObservableObject {
    static let shared = QuestService()

    @Published var progress: QuestProgress
    @Published var lastCompletedQuest: Quest?

    private init() {
        self.progress = PersistenceService.shared.loadQuestProgress()
    }

    func onCommit(creatures: [UUID: Creature], repoCount: Int) {
        let today = Self.dateKey(Date())
        progress.dailyCommitCounts[today, default: 0] += 1

        // Clean old daily counts (keep last 60 days)
        let cutoff = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
        let cutoffKey = Self.dateKey(cutoff)
        progress.dailyCommitCounts = progress.dailyCommitCounts.filter { $0.key >= cutoffKey }

        // Check all quests
        for quest in Quest.allQuests where !progress.completedQuestIDs.contains(quest.id) {
            if isQuestComplete(quest, creatures: creatures, repoCount: repoCount) {
                progress.completedQuestIDs.insert(quest.id)
                lastCompletedQuest = quest
            }
        }

        save()
    }

    private func isQuestComplete(_ quest: Quest, creatures: [UUID: Creature], repoCount: Int) -> Bool {
        switch quest.requirement {
        case .totalCommits:
            let total = creatures.values.reduce(0) { $0 + $1.totalCommitsFed }
            return total >= quest.targetValue

        case .commitsInDay:
            let today = Self.dateKey(Date())
            return (progress.dailyCommitCounts[today] ?? 0) >= quest.targetValue

        case .streakDays:
            let maxStreak = creatures.values.map { $0.longestStreak }.max() ?? 0
            let currentMax = creatures.values.map { $0.currentStreak }.max() ?? 0
            return max(maxStreak, currentMax) >= quest.targetValue

        case .repoCount:
            return repoCount >= quest.targetValue

        case .creatureSize:
            let maxSize = creatures.values.map { $0.size }.max() ?? 0
            return maxSize >= Double(quest.targetValue)
        }
    }

    // Progress for a quest (0.0 to 1.0) and display string
    func questProgress(_ quest: Quest, creatures: [UUID: Creature], repoCount: Int) -> (fraction: Double, label: String) {
        if progress.completedQuestIDs.contains(quest.id) {
            return (1.0, "Complete")
        }

        let current: Int
        let target = quest.targetValue

        switch quest.requirement {
        case .totalCommits:
            current = creatures.values.reduce(0) { $0 + $1.totalCommitsFed }
        case .commitsInDay:
            let today = Self.dateKey(Date())
            current = progress.dailyCommitCounts[today] ?? 0
        case .streakDays:
            let currentMax = creatures.values.map { $0.currentStreak }.max() ?? 0
            current = currentMax
        case .repoCount:
            current = repoCount
        case .creatureSize:
            current = Int(creatures.values.map { $0.size }.max() ?? 0)
        }

        let fraction = min(1.0, Double(current) / Double(max(1, target)))
        return (fraction, "\(current)/\(target)")
    }

    private func save() {
        PersistenceService.shared.saveQuestProgress(progress)
    }

    private static func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var activeQuests: [Quest] {
        Quest.allQuests.filter { !progress.completedQuestIDs.contains($0.id) }
    }

    var completedQuests: [Quest] {
        Quest.allQuests.filter { progress.completedQuestIDs.contains($0.id) }
    }
}
