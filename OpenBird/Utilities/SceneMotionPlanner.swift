import CoreGraphics
import Foundation

final class SceneMotionPlanner {
    private var slots: [CGPoint] = []
    private var assignments: [ObjectIdentifier: Int] = [:]
    private let minimumSeparationSquared: CGFloat

    init(minimumSeparation: CGFloat) {
        minimumSeparationSquared = minimumSeparation * minimumSeparation
    }

    func updateSlots(_ newSlots: [CGPoint], subjects: [(id: ObjectIdentifier, position: CGPoint)]) {
        slots = deduplicated(newSlots)
        guard !slots.isEmpty else {
            assignments.removeAll()
            return
        }

        let validIDs = Set(subjects.map(\.id))
        assignments = assignments.filter { validIDs.contains($0.key) && $0.value < slots.count }

        var rebuiltAssignments: [ObjectIdentifier: Int] = [:]
        var usedSlots = Set<Int>()

        for subject in subjects {
            if let bestIndex = bestSlotIndex(
                near: subject.position,
                occupied: usedSlots,
                excluding: nil
            ) {
                rebuiltAssignments[subject.id] = bestIndex
                usedSlots.insert(bestIndex)
            }
        }

        assignments = rebuiltAssignments
    }

    func reserveSlot(for subject: AnyObject, near preferredPoint: CGPoint, avoidCurrent: Bool = true) -> CGPoint? {
        guard !slots.isEmpty else { return nil }

        let id = ObjectIdentifier(subject)
        let currentIndex = assignments[id]
        var occupied = Set(assignments.values)
        if let currentIndex {
            occupied.remove(currentIndex)
        }

        if let nextIndex = bestSlotIndex(
            near: preferredPoint,
            occupied: occupied,
            excluding: avoidCurrent ? currentIndex : nil
        ) {
            assignments[id] = nextIndex
            return slots[nextIndex]
        }

        if let currentIndex, slots.indices.contains(currentIndex) {
            return slots[currentIndex]
        }

        guard let fallbackIndex = bestSlotIndex(
            near: preferredPoint,
            occupied: [],
            excluding: nil
        ) else {
            return nil
        }

        assignments[id] = fallbackIndex
        return slots[fallbackIndex]
    }

    func releaseSlot(for subject: AnyObject) {
        assignments.removeValue(forKey: ObjectIdentifier(subject))
    }

    private func bestSlotIndex(
        near point: CGPoint,
        occupied: Set<Int>,
        excluding excludedIndex: Int?
    ) -> Int? {
        let candidateIndexes = slots.indices.filter { index in
            guard index != excludedIndex else { return false }
            return !occupied.contains(index)
        }

        let spacedIndexes = candidateIndexes.filter { index in
            occupied.allSatisfy { occupiedIndex in
                squaredDistance(from: slots[index], to: slots[occupiedIndex]) >= minimumSeparationSquared
            }
        }

        let pool = !spacedIndexes.isEmpty
            ? spacedIndexes
            : (!candidateIndexes.isEmpty ? candidateIndexes : slots.indices.filter { $0 != excludedIndex })

        return pool.min { lhs, rhs in
            let lhsDistance = squaredDistance(from: slots[lhs], to: point)
            let rhsDistance = squaredDistance(from: slots[rhs], to: point)
            return lhsDistance < rhsDistance
        }
    }

    private func squaredDistance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }

    private func deduplicated(_ points: [CGPoint]) -> [CGPoint] {
        var seen = Set<String>()
        var result: [CGPoint] = []

        for point in points {
            let key = "\(Int(point.x.rounded())):\(Int(point.y.rounded()))"
            if seen.insert(key).inserted {
                result.append(point)
            }
        }

        return result
    }
}
