import SpriteKit

final class BirdMode: GameMode {
    let id = GameModeID.bird.rawValue
    let displayName = GameModeID.bird.displayName

    func createScene(size: CGSize) -> GameModeScene {
        BirdScene(size: size)
    }

    func createCreatureNode(for creature: Creature, name: String, color: NSColor) -> CreatureNode {
        BirdCreatureNode(creature: creature, name: name, color: color)
    }
}
