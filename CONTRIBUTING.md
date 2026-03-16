# Contributing to OpenBird

Thanks for wanting to contribute. Here's how to get started.

## Setup

1. Fork the repository
2. Clone your fork
3. Open `OpenBird.xcodeproj` in Xcode 15+
4. Build and run (Cmd+R)

## Making Changes

- Create a branch from `main` for your work
- Keep commits focused -- one logical change per commit
- Test your changes by running the app and verifying the aquarium behaves correctly
- Make sure the project builds without warnings

## Pull Requests

- Open a PR against `main`
- Describe what you changed and why
- Include a screenshot or GIF if your change affects the UI or aquarium rendering

## Architecture

OpenBird uses a protocol-based `GameMode` system. The current mode is `Fish` (the aquarium). If you want to add a new visualization mode:

1. Create a new directory under `GameModes/YourMode/`
2. Implement `GameMode`, `GameModeScene`, and `GameModeCreatureNode`
3. Wire it up in `OpenBirdApp.swift`

### Key services

- **GitMonitorService** -- watches repos for commits via FSEvents
- **CreatureLifecycleService** -- manages hunger, happiness, growth, death
- **PersistenceService** -- reads/writes JSON to `~/Library/Application Support/OpenBird/`
- **QuestService** -- tracks achievement progress

## Code Style

- Match existing patterns in the codebase
- Use Swift conventions (camelCase, etc.)
- No external dependencies -- keep it pure Swift/SwiftUI/SpriteKit

## Reporting Issues

Open an issue on GitHub with:
- What you expected to happen
- What actually happened
- macOS version and any relevant logs from Console.app

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
