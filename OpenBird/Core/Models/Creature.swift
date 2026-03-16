import Foundation

struct Creature: Codable {
    var repoID: UUID
    var happiness: Double      // 0.0 - 1.0
    var hunger: Double         // 0.0 (full) - 1.0 (starving)
    var size: Double           // 0.5 (tiny) - 2.5 (huge)
    var isAlive: Bool
    var totalCommitsFed: Int
    var lastFedDate: Date?
    var birthDate: Date

    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastStreakDate: Date?

    init(repoID: UUID) {
        self.repoID = repoID
        self.happiness = 0.8
        self.hunger = 0.0
        self.size = 0.6
        self.isAlive = true
        self.totalCommitsFed = 0
        self.birthDate = Date()
        self.currentStreak = 0
        self.longestStreak = 0
    }

    var stage: String {
        switch totalCommitsFed {
        case 0..<10: return "Seedling"
        case 10..<50: return "Sprout"
        case 50..<200: return "Buddy"
        case 200..<1000: return "Companion"
        default: return "Sage"
        }
    }

    mutating func feed() {
        guard isAlive else { return }
        hunger = max(0, hunger - 0.3)
        happiness = min(1.0, happiness + 0.2)
        size = min(2.5, size + 0.006)
        totalCommitsFed += 1
        lastFedDate = Date()
        updateStreak()
    }

    private mutating func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastDate = lastStreakDate else {
            // First ever feed
            currentStreak = 1
            longestStreak = max(longestStreak, 1)
            lastStreakDate = Date()
            return
        }

        let lastDay = calendar.startOfDay(for: lastDate)
        let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysDiff == 0 {
            // Same day - no streak change, don't update lastStreakDate
            return
        } else if daysDiff == 1 {
            // Consecutive day
            currentStreak += 1
        } else {
            // Streak broken, restart
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastStreakDate = Date()
    }

    mutating func tick() {
        guard isAlive else { return }

        // Hunger increases ~0.01 per tick (60s) = noticeable in ~2 hours
        hunger = min(1.0, hunger + 0.008)

        // Happiness decays toward inverse of hunger
        let targetHappiness = 1.0 - hunger * 0.7
        happiness += (targetHappiness - happiness) * 0.02

        // Size shrinks when hungry - noticeable over a workday
        if hunger > 0.5 {
            size = max(0.5, size - 0.002)
        }

        // Death after 30 days without feeding
        if let lastFed = lastFedDate {
            let daysSinceFed = Date().timeIntervalSince(lastFed) / 86400
            if daysSinceFed >= 30 {
                isAlive = false
                happiness = 0
            }
        } else {
            let daysSinceBirth = Date().timeIntervalSince(birthDate) / 86400
            if daysSinceBirth >= 30 {
                isAlive = false
                happiness = 0
            }
        }

        // Check streak break
        if let lastDate = lastStreakDate {
            let calendar = Calendar.current
            let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: Date())).day ?? 0
            if daysSince > 1 {
                currentStreak = 0
            }
        }
    }
}
