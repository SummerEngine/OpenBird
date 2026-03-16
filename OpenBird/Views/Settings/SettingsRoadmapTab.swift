import SwiftUI

struct SettingsRoadmapTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Roadmap")
                    .font(.headline)
                    .padding(.bottom, 4)

                ideaRow("bird", "More Worlds", "Expand beyond aquarium and aviary into new habitats with their own art, behaviors, and commit reactions.")
                ideaRow("waveform.path.ecg", "Jam Packs", "Different dance floors, glow rigs, and animation styles for Jam Mode.")
                ideaRow("cursorarrow.click.2", "Click Actions", "Bind what happens when you click a friend. Open a URL, launch your editor to the latest commit, open Claude Code.")
                ideaRow("message", "Talk to Your Friends", "Send messages to friends via MCP. They relay prompts to Cursor, Claude Code, or any connected agent.")
                ideaRow("network", "Orchestrator Mode", "Your friends become workers. Assign tasks, watch them build. Like Warcraft peons for your codebase.")
                ideaRow("cube", "3D Rendering", "Switch from 2D SpriteKit to SceneKit or Metal for a 3D terrarium/vivarium experience.")
                ideaRow("paintpalette", "Customization", "Custom colors, species based on primary language, name plates, accessories.")
                ideaRow("speaker.wave.2", "Sound Packs", "Different sound effects per game mode. Aquarium bubbles, bird chirps, synth pops, orc grunts.")
                ideaRow("globe", "Leaderboard", "Compare your feeding streaks with friends. Longest-living friend wins.")
                ideaRow("arrow.triangle.branch", "Branch Awareness", "Friends react differently to main vs feature branches. Merge = celebration.")
                ideaRow("person.2", "Multi-user", "See teammates' friends in a shared pond. Social coding visualization.")
                ideaRow("arrow.up.circle", "Evolution", "Friends evolve through stages based on commit milestones. Visual transformations at each tier.")
                ideaRow("tshirt", "Wearables", "Earn cosmetic items for your friends by completing quests. Hats, accessories, effects.")
            }
            .padding(20)
        }
    }

    private func ideaRow(_ icon: String, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
