import SpriteKit

final class FishMode: GameMode {
    let id = GameModeID.fish.rawValue
    let displayName = GameModeID.fish.displayName

    func createScene(size: CGSize) -> GameModeScene {
        return FishScene(size: size)
    }

    func createCreatureNode(for creature: Creature, name: String, color: NSColor) -> CreatureNode {
        return FishCreatureNode(creature: creature, name: name, color: color)
    }
}
