# Creature Jam Guide

`Jam` is a behavior layer on top of the active world, not a separate creature type.

## Rules

- Keep the same creature visuals for the current world.
- When Jam is active, creatures stop their normal pathing and play a species-specific jam animation in place.
- When Jam ends, creatures return to their normal idle behavior.

## Where To Look

- `OpenBird/Core/Protocols/GameMode.swift` defines the shared scene and creature hooks.
- `OpenBird/GameModes/Fish/` contains the fish implementation.
- `OpenBird/GameModes/Bird/` contains the bird implementation.
- `OpenBird/Views/Settings/SettingsJamTab.swift` contains the Jam settings and permission flow.

## Required Creature Hooks

Every creature node should implement these methods from `CreatureNode`:

- `startIdleBehavior(in:)`
- `playFeedAnimation()`
- `beginJamMode()`
- `endJamMode(resumeIn:)`
- `updateJam(level:beat:)`

## Expected Jam Behavior

- Store the creature's current position when Jam begins.
- Cancel movement actions so Jam does not fight the normal AI.
- Use `updateJam(level:beat:)` to react to live audio energy.
- Restore a clean idle state when Jam stops.

## Current Pattern

- Fish: stand more upright and bounce in place.
- Birds: hold a perched idle pose and bounce with wing motion.

## New Creature Checklist

- Add the new creature under the correct `GameModes/<World>/` folder.
- Keep normal movement in `startIdleBehavior(in:)`.
- Keep feed reaction in `playFeedAnimation()`.
- Add Jam start/stop handling in `beginJamMode()` and `endJamMode(resumeIn:)`.
- Use `updateJam(level:beat:)` for the music-reactive pose.
- Make sure resizing the window or toggling Jam does not leave the creature in a broken state.

## When Adding A New Creature

1. Build the normal idle movement first.
2. Build the feed reaction.
3. Add a jam pose that still looks like the same species.
4. Make sure jam works without changing worlds or swapping creature types.
5. Verify the creature returns cleanly to idle after Jam is turned off.
