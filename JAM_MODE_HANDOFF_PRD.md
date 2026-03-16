# Jam Mode Handoff PRD

## Purpose

`Jam Mode` should make `OpenBird` feel alive and musical without becoming noisy, stressful, or visually chaotic.

This document describes **what Jam should do**, **how it should feel**, and **what product outcomes matter**. It does **not** prescribe implementation details.

## Product Definition

`Jam` is a local feature layer that sits on top of the currently active world.

That means:

- `Jam` is **not** a separate world
- `Jam` is **not** a separate creature type
- `Jam` does **not** replace fish with a different avatar
- `Jam` does **not** require an account

If the user is in `Aquarium`, the same fish should jam.

If the user is in `Aviary`, the same birds should jam.

## Core User Story

As a user, I want to turn on Jam and have my creatures react to the music already playing on my computer, so the tank feels synced to my environment without needing setup beyond a permission prompt.

## Success Criteria

Jam is successful when:

- the user can understand what it is immediately
- enabling it feels simple and local
- the creatures react to music in a calm, pleasing way
- the motion feels beat-aware rather than random or jittery
- silence or low-level noise does not cause constant motion
- the feature feels like a vibe enhancer, not a visual stressor

## Non-Goals

Jam should **not**:

- react to microphone input as an intentional product behavior
- require sign-in to function locally
- create a second creature system just for music mode
- feel like a waveform visualizer glued onto the tank
- jitter constantly on every tiny amplitude change

## Desired Behavior

### Input Behavior

Jam should react to **audio the user is listening to on the computer**.

Expected user mental model:

- if Spotify, YouTube, Apple Music, or another app is playing audio, creatures react
- if the computer is quiet, creatures should stay calm
- the feature should appear to follow musical energy and beats, not raw noise

### Visual Behavior

Jam should feel:

- calm
- rhythmic
- intentional
- species-aware

Jam should not feel:

- frantic
- twitchy
- overstimulating
- random

### Motion Expectations

All visible creatures in the active world should participate for now.

Each creature type should have its own Jam personality:

- fish should feel floaty, groovy, and buoyant
- birds should feel perched, bouncy, and expressive

The motion should emphasize:

- stronger reactions on meaningful beats
- gentler motion between beats
- stable resting periods when there is no strong signal

## Permission Experience

The user should understand:

- Jam is a local feature
- OpenBird uses `Screen Recording` permission to read system audio levels on macOS
- the microphone is not intended as the product input
- nothing is uploaded or saved

The permission flow should feel:

- clear
- honest
- minimal

## UX Requirements

There should be a dedicated `Jam` settings surface.

That surface should clearly answer:

- what Jam is
- what permission is needed
- why that permission is needed
- whether Jam is currently active
- whether OpenBird is successfully reacting to audio

## Quality Bar

Before calling Jam “done”, it should meet this bar:

- looks good with normal music playback
- does not overreact to small noise
- does not feel broken when no music is playing
- feels coherent across both Aquarium and Aviary
- does not confuse users into thinking it uses the microphone on purpose

## Future Extensions

Possible future product extensions:

- per-world Jam styles
- selected-creature-only Jam mode
- sensitivity presets like `Calm`, `Balanced`, `Energetic`
- app-specific audio targeting if product value is clear
- cosmetic effects that reinforce beats without overwhelming the creatures

These are optional and should not block making the default Jam experience feel good first.

## Relevant Files

These files are the most relevant starting points for future work on Jam:

- `OpenBird/Views/Settings/SettingsJamTab.swift`
- `OpenBird/Core/Services/SystemAudioMonitorService.swift`
- `OpenBird/Core/Protocols/GameMode.swift`
- `OpenBird/GameModes/Fish/FishCreatureNode.swift`
- `OpenBird/GameModes/Fish/FishScene.swift`
- `OpenBird/GameModes/Bird/BirdCreatureNode.swift`
- `OpenBird/GameModes/Bird/BirdScene.swift`
- `OpenBird/OpenBirdApp.swift`
- `CREATURE_JAM_GUIDE.md`

## Handoff Summary

If someone new picks this up, the product goal is:

Make Jam feel like the creatures are vibing with the music the user is already playing, in a way that feels delightful, calm, and obviously intentional.
