import Foundation
import Combine

@MainActor
final class CreatureLifecycleService: ObservableObject {
    static let shared = CreatureLifecycleService()

    @Published var creatures: [UUID: Creature] = [:]
    @Published var lastFeedEvent: (repoID: UUID, commit: CommitRecord)?

    private var timer: Timer?

    private init() {}

    func start() {
        creatures = PersistenceService.shared.loadCreatures().mapValues { creature in
            var normalized = creature
            normalized.normalizeForCurrentBalance()
            return normalized
        }
        saveCreatures()

        // Tick every 60 seconds for hunger decay
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        saveCreatures()
    }

    func feedCreature(repoID: UUID, commit: CommitRecord) {
        guard var creature = creatures[repoID], creature.isAlive else { return }
        creature.feed()
        creatures[repoID] = creature
        lastFeedEvent = (repoID: repoID, commit: commit)
        saveCreatures()

        // Update quests
        let repoCount = GitMonitorService.shared.repositories.count
        QuestService.shared.onCommit(creatures: creatures, repoCount: repoCount)
    }

    func tick() {
        var changed = false
        for (id, var creature) in creatures {
            let oldHunger = creature.hunger
            creature.tick()
            if creature.hunger != oldHunger {
                creatures[id] = creature
                changed = true
            }
        }
        if changed {
            saveCreatures()
        }
    }

    func saveCreatures() {
        PersistenceService.shared.saveCreatures(creatures)
    }
}
