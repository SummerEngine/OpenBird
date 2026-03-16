import Foundation

struct CommitInfo {
    let hash: String
    let message: String
    let author: String
    let date: Date
}

struct GitRepositoryInfo {
    let gitDir: String
    let commonDir: String

    var watchPaths: [String] {
        Array(Set([gitDir, commonDir])).sorted()
    }
}

enum GitHelper {
    static func repositoryInfo(at path: String) -> GitRepositoryInfo? {
        let gitPath = (path as NSString).appendingPathComponent(".git")
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: gitPath, isDirectory: &isDirectory) else {
            return nil
        }

        if isDirectory.boolValue {
            return GitRepositoryInfo(gitDir: gitPath, commonDir: gitPath)
        }

        guard let pointer = try? String(contentsOfFile: gitPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
              pointer.hasPrefix("gitdir:") else {
            return nil
        }

        let rawGitDir = pointer.replacingOccurrences(of: "gitdir:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let gitDirURL = URL(fileURLWithPath: rawGitDir, relativeTo: URL(fileURLWithPath: path))
            .standardizedFileURL
        let gitDir = gitDirURL.path
        let commonDir = resolvedCommonDir(from: gitDir) ?? gitDir

        return GitRepositoryInfo(gitDir: gitDir, commonDir: commonDir)
    }

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
        repositoryInfo(at: path) != nil
    }

    static func repositoryName(at path: String) -> String {
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private static func resolvedCommonDir(from gitDir: String) -> String? {
        let commonDirFile = (gitDir as NSString).appendingPathComponent("commondir")
        guard let relativeCommonDir = try? String(contentsOfFile: commonDirFile, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !relativeCommonDir.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: relativeCommonDir, relativeTo: URL(fileURLWithPath: gitDir))
            .standardizedFileURL
            .path
    }
}
