import SpriteKit

final class JamMode: GameMode {
    let id = GameModeID.jam.rawValue
    let displayName = GameModeID.jam.displayName

    func createScene(size: CGSize) -> GameModeScene {
        JamScene(size: size)
    }

    func createCreatureNode(for creature: Creature, name: String, color: NSColor) -> CreatureNode {
        JamCreatureNode(creature: creature, name: name, color: color)
    }
}
