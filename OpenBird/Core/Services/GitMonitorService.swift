import Foundation
import Combine

@MainActor
final class GitMonitorService: ObservableObject {
    static let shared = GitMonitorService()

    @Published var repositories: [Repository] = []
    @Published var latestCommit: (repo: Repository, commit: CommitRecord)?

    private var streams: [UUID: FSEventStreamRef] = [:]
    private var contexts: [UUID: Unmanaged<RepoContext>] = [:]
    private let queue = DispatchQueue(label: "com.openbird.fsevents", qos: .utility)

    private init() {}

    func startWatching(_ repo: Repository) {
        guard let info = GitHelper.repositoryInfo(at: repo.path) else { return }

        // Use Unmanaged for proper memory management
        let context = RepoContext(repoID: repo.id, path: repo.path)
        let unmanaged = Unmanaged.passRetained(context)

        var streamContext = FSEventStreamContext(
            version: 0,
            info: unmanaged.toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = info.watchPaths as CFArray
        guard let stream = FSEventStreamCreate(
            nil,
            fsEventsCallback,
            &streamContext,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.3,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        ) else {
            unmanaged.release()
            return
        }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        streams[repo.id] = stream
        contexts[repo.id] = unmanaged
    }

    func stopWatching(_ repoID: UUID) {
        guard let stream = streams.removeValue(forKey: repoID) else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)

        // Release the retained RepoContext
        contexts.removeValue(forKey: repoID)?.release()
    }

    func stopAll() {
        for id in Array(streams.keys) {
            stopWatching(id)
        }
    }

    func checkForNewCommit(repoID: UUID, path: String) {
        guard let repo = repositories.first(where: { $0.id == repoID }) else { return }

        let repoPath = path
        let lastKnownCommitHash = repo.lastKnownCommitHash

        Task.detached { [repoID, repoPath, lastKnownCommitHash] in
            guard let commitInfo = GitHelper.latestCommit(at: repoPath) else { return }
            guard commitInfo.hash != lastKnownCommitHash else { return }

            await MainActor.run {
                let service = GitMonitorService.shared
                guard var updatedRepo = service.repositories.first(where: { $0.id == repoID }) else { return }
                guard commitInfo.hash != updatedRepo.lastKnownCommitHash else { return }

                updatedRepo.lastKnownCommitHash = commitInfo.hash
                updatedRepo.lastCommitDate = commitInfo.date

                if let idx = service.repositories.firstIndex(where: { $0.id == repoID }) {
                    service.repositories[idx] = updatedRepo
                }

                let record = CommitRecord(
                    id: commitInfo.hash,
                    repoID: repoID,
                    message: commitInfo.message,
                    author: commitInfo.author,
                    date: commitInfo.date
                )

                service.latestCommit = (repo: updatedRepo, commit: record)
                PersistenceService.shared.appendCommit(record)
                PersistenceService.shared.saveRepositories(service.repositories)
                CreatureLifecycleService.shared.feedCreature(repoID: repoID, commit: record)
            }
        }
    }

    func addRepository(_ repo: Repository) {
        repositories.append(repo)
        startWatching(repo)
        PersistenceService.shared.saveRepositories(repositories)

        let creature = Creature(repoID: repo.id)
        CreatureLifecycleService.shared.creatures[repo.id] = creature
        CreatureLifecycleService.shared.saveCreatures()

        if let commitInfo = GitHelper.latestCommit(at: repo.path) {
            var updated = repo
            updated.lastKnownCommitHash = commitInfo.hash
            updated.lastCommitDate = commitInfo.date
            if let idx = repositories.firstIndex(where: { $0.id == repo.id }) {
                repositories[idx] = updated
                PersistenceService.shared.saveRepositories(repositories)
            }
        }
    }

    func removeRepository(_ repoID: UUID) {
        stopWatching(repoID)
        repositories.removeAll { $0.id == repoID }
        PersistenceService.shared.saveRepositories(repositories)
        CreatureLifecycleService.shared.creatures.removeValue(forKey: repoID)
        CreatureLifecycleService.shared.saveCreatures()
    }

    func loadAndStartWatching() {
        repositories = PersistenceService.shared.loadRepositories()
        for repo in repositories {
            if GitHelper.repositoryInfo(at: repo.path) != nil {
                startWatching(repo)
            }
        }
    }
}

// MARK: - FSEvents Context

final class RepoContext {
    let repoID: UUID
    let path: String

    init(repoID: UUID, path: String) {
        self.repoID = repoID
        self.path = path
    }
}

// MARK: - FSEvents Callback

private func fsEventsCallback(
    _ stream: ConstFSEventStreamRef,
    _ info: UnsafeMutableRawPointer?,
    _ numEvents: Int,
    _ eventPaths: UnsafeMutableRawPointer,
    _ eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    _ eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let info = info else { return }
    let context = Unmanaged<RepoContext>.fromOpaque(info).takeUnretainedValue()

    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
    let relevant = paths.contains { path in
        path.contains("/refs/heads/") ||
        path.hasSuffix("/HEAD") ||
        path.contains("/logs/") ||
        path.contains("/COMMIT_EDITMSG")
    }

    guard relevant else { return }

    let repoID = context.repoID
    let repoPath = context.path

    DispatchQueue.main.async {
        GitMonitorService.shared.checkForNewCommit(repoID: repoID, path: repoPath)
    }
}
