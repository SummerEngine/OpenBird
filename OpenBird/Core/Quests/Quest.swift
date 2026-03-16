import Foundation

enum QuestRequirement: String, Codable {
    case totalCommits
    case commitsInDay
    case streakDays
    case repoCount
    case creatureSize
}

struct Quest: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let requirement: QuestRequirement
    let targetValue: Int
    let rewardDescription: String

    static let allQuests: [Quest] = [
        Quest(
            id: "hello_world",
            title: "Hello World",
            description: "Make your first commit with a tracked repo",
            requirement: .totalCommits,
            targetValue: 1,
            rewardDescription: "Your little friend wakes up"
        ),
        Quest(
            id: "growing_up",
            title: "Growing Up",
            description: "Reach 10 total commits",
            requirement: .totalCommits,
            targetValue: 10,
            rewardDescription: "Your friend grows into a Sprout"
        ),
        Quest(
            id: "busy_day",
            title: "Busy Day",
            description: "Make 10 commits in a single day",
            requirement: .commitsInDay,
            targetValue: 10,
            rewardDescription: "That was a productive day"
        ),
        Quest(
            id: "good_habit",
            title: "Good Habit",
            description: "Commit 3 days in a row",
            requirement: .streakDays,
            targetValue: 3,
            rewardDescription: "Consistency looks good on you"
        ),
        Quest(
            id: "on_a_roll",
            title: "On a Roll",
            description: "Keep a 7-day commit streak going",
            requirement: .streakDays,
            targetValue: 7,
            rewardDescription: "A whole week of showing up"
        ),
        Quest(
            id: "old_friends",
            title: "Old Friends",
            description: "Reach 100 total commits",
            requirement: .totalCommits,
            targetValue: 100,
            rewardDescription: "You and your friend go way back"
        ),
        Quest(
            id: "the_more_the_merrier",
            title: "The More The Merrier",
            description: "Track 5 repositories",
            requirement: .repoCount,
            targetValue: 5,
            rewardDescription: "A little community"
        ),
        Quest(
            id: "daily_ritual",
            title: "Daily Ritual",
            description: "Keep a 30-day commit streak",
            requirement: .streakDays,
            targetValue: 30,
            rewardDescription: "This is just who you are now"
        ),
        Quest(
            id: "golden_friend",
            title: "Golden Friend",
            description: "Reach 1,000 total commits",
            requirement: .totalCommits,
            targetValue: 1000,
            rewardDescription: "Your bird unlocks its epic golden form"
        ),
        Quest(
            id: "legendary_flock",
            title: "Legendary Flock",
            description: "Reach 10,000 total commits",
            requirement: .totalCommits,
            targetValue: 10000,
            rewardDescription: "Your friend becomes a legend"
        ),
    ]
}

struct QuestProgress: Codable {
    var completedQuestIDs: Set<String>
    var dailyCommitCounts: [String: Int]

    init() {
        self.completedQuestIDs = []
        self.dailyCommitCounts = [:]
    }
}
