import SwiftUI

struct AddRepositoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPath: String = ""
    @State private var repoName: String = ""
    @State private var creatureName: String = ""
    @State private var selectedColor: String = "#2699F2"
    @State private var customColor: Color = .blue
    @State private var errorMessage: String?

    var onAdd: ((Repository) -> Void)?

    private let colorPresets: [(name: String, hex: String)] = [
        ("Ocean", "#2699F2"),
        ("Coral", "#F25C54"),
        ("Emerald", "#2ECC71"),
        ("Sunset", "#F39C12"),
        ("Violet", "#9B59B6"),
        ("Flamingo", "#E91E8C"),
        ("Slate", "#607D8B"),
        ("Gold", "#FFD700"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Repository")
                .font(.headline)

            // Repository path
            HStack {
                TextField("Repository path", text: $selectedPath)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)

                Button("Browse...") {
                    pickFolder()
                }
            }

            if !repoName.isEmpty {
                HStack {
                    Text("Repository:")
                        .foregroundColor(.secondary)
                    Text(repoName)
                        .fontWeight(.medium)
                    Spacer()
                }
            }

            // Friend name
            TextField("Name your friend", text: $creatureName)
                .textFieldStyle(.roundedBorder)

            // Color picker - permanent choice
            VStack(alignment: .leading, spacing: 6) {
                Text("Choose a color (permanent)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(colorPresets, id: \.hex) { preset in
                        colorSwatch(preset: preset)
                    }

                    // Custom color picker
                    ColorPicker("", selection: $customColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 28, height: 28)
                        .help("Custom color")
                        .onChange(of: customColor) { newColor in
                            selectedColor = newColor.toHex()
                        }
                }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    addRepository()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedPath.isEmpty || creatureName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a git repository"

        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path
            if GitHelper.isGitRepository(at: path) {
                selectedPath = path
                repoName = GitHelper.repositoryName(at: path)
                if creatureName.isEmpty {
                    creatureName = repoName
                }
                errorMessage = nil
            } else {
                errorMessage = "Not a git repository or worktree"
                selectedPath = ""
                repoName = ""
            }
        }
    }

    @ViewBuilder
    private func colorSwatch(preset: (name: String, hex: String)) -> some View {
        let isSelected = selectedColor == preset.hex
        let swatchColor = Color(nsColor: NSColor.fromHex(preset.hex))
        Circle()
            .fill(swatchColor)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(isSelected ? Color.white : Color.clear, lineWidth: 2))
            .overlay(Circle().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1).padding(2))
            .onTapGesture { selectedColor = preset.hex }
            .help(preset.name)
    }

    private func addRepository() {
        guard !selectedPath.isEmpty, !creatureName.isEmpty else { return }

        let repo = Repository(
            path: selectedPath,
            name: repoName,
            creatureName: creatureName.trimmingCharacters(in: .whitespaces),
            color: selectedColor
        )
        onAdd?(repo)
        dismiss()
    }

}
