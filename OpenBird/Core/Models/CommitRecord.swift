import Foundation

struct CommitRecord: Codable, Identifiable {
    let id: String          // commit hash
    let repoID: UUID
    let message: String
    let author: String
    let date: Date
}
