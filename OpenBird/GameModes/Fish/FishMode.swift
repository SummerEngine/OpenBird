import SpriteKit

final class FishMode: GameMode {
    let id = "fish"
    let displayName = "Aquarium"

    func createScene(size: CGSize) -> GameModeScene {
        return FishScene(size: size)
    }

    func createCreatureNode(for creature: Creature, name: String, color: NSColor) -> CreatureNode {
        return FishCreatureNode(creature: creature, name: name, color: color)
    }
}
