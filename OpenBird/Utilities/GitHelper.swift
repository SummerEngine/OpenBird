import Foundation

struct CommitInfo {
    let hash: String
    let message: String
    let author: String
    let date: Date
}

enum GitHelper {
    static func latestCommit(at repoPath: String) -> CommitInfo? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["log", "-1", "--format=%H|%s|%an|%aI"]
        process.currentDirectoryURL = URL(fileURLWithPath: repoPath)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty else {
            return nil
        }

        let parts = output.split(separator: "|", maxSplits: 3).map(String.init)
        guard parts.count >= 4 else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let date = formatter.date(from: parts[3]) ?? Date()

        return CommitInfo(
            hash: parts[0],
            message: parts[1],
            author: parts[2],
            date: date
        )
    }

    static func isGitRepository(at path: String) -> Bool {
        let gitDir = (path as NSString).appendingPathComponent(".git")
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: gitDir, isDirectory: &isDir) && isDir.boolValue
    }

    static func repositoryName(at path: String) -> String {
        return URL(fileURLWithPath: path).lastPathComponent
    }
}
