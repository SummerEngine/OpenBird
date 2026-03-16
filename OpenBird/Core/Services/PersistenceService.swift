import Foundation

final class PersistenceService {
    static let shared = PersistenceService()

    private let baseURL: URL
    private let commitsDir: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        baseURL = appSupport.appendingPathComponent("OpenBird", isDirectory: true)
        commitsDir = baseURL.appendingPathComponent("commits", isDirectory: true)

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Ensure directories exist
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: commitsDir, withIntermediateDirectories: true)
    }

    // MARK: - Repositories

    func saveRepositories(_ repos: [Repository]) {
        let url = baseURL.appendingPathComponent("repositories.json")
        if let data = try? encoder.encode(repos) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func loadRepositories() -> [Repository] {
        let url = baseURL.appendingPathComponent("repositories.json")
        guard let data = try? Data(contentsOf: url),
              let repos = try? decoder.decode([Repository].self, from: data) else {
            return []
        }
        return repos
    }

    // MARK: - Creatures

    func saveCreatures(_ creatures: [UUID: Creature]) {
        let url = baseURL.appendingPathComponent("creatures.json")
        // UUID keys need string encoding
        let stringKeyed = Dictionary(uniqueKeysWithValues: creatures.map { ($0.key.uuidString, $0.value) })
        if let data = try? encoder.encode(stringKeyed) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func loadCreatures() -> [UUID: Creature] {
        let url = baseURL.appendingPathComponent("creatures.json")
        guard let data = try? Data(contentsOf: url),
              let stringKeyed = try? decoder.decode([String: Creature].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: stringKeyed.compactMap { key, value in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, value)
        })
    }

    // MARK: - Commits

    func appendCommit(_ commit: CommitRecord) {
        var existing = loadCommits(for: commit.repoID)
        existing.insert(commit, at: 0) // newest first
        // Keep last 500 commits per repo
        if existing.count > 500 {
            existing = Array(existing.prefix(500))
        }
        let url = commitsDir.appendingPathComponent("\(commit.repoID.uuidString).json")
        if let data = try? encoder.encode(existing) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func loadCommits(for repoID: UUID) -> [CommitRecord] {
        let url = commitsDir.appendingPathComponent("\(repoID.uuidString).json")
        guard let data = try? Data(contentsOf: url),
              let commits = try? decoder.decode([CommitRecord].self, from: data) else {
            return []
        }
        return commits
    }

    // MARK: - Quests

    func saveQuestProgress(_ progress: QuestProgress) {
        let url = baseURL.appendingPathComponent("quests.json")
        if let data = try? encoder.encode(progress) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func loadQuestProgress() -> QuestProgress {
        let url = baseURL.appendingPathComponent("quests.json")
        guard let data = try? Data(contentsOf: url),
              let progress = try? decoder.decode(QuestProgress.self, from: data) else {
            return QuestProgress()
        }
        return progress
    }
}
