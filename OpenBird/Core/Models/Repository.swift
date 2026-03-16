import Foundation

struct Repository: Codable, Identifiable {
    let id: UUID
    var path: String
    var name: String
    var creatureName: String
    let color: String // hex color, set once at creation
    var dateAdded: Date
    var lastCommitDate: Date?
    var lastKnownCommitHash: String?

    init(path: String, name: String, creatureName: String, color: String = "#2699F2") {
        self.id = UUID()
        self.path = path
        self.name = name
        self.creatureName = creatureName
        self.color = color
        self.dateAdded = Date()
    }
}
