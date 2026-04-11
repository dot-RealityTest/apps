# BreakPoint - Features

## Core Feature: Doom's Moment

Single-action context capture that turns your current machine state into a structured Markdown handoff.

---

## Activation Methods

| Method | Action | Use Case |
|--------|--------|----------|
| **Left-Click** | Click menu bar icon | Fast trigger |
| **Global Hotkey** | `Cmd + Shift + Escape` | System-wide trigger |
| **Right-Click** | Open context menu, then choose `Doom's Moment` | Quick actions + status |

---

## Context Gathering

BreakPoint combines these sources:

### Screen Capture
- frontmost app
- running apps
- window titles
- clipboard text
- screenshot OCR

### Local Knowledge Graph
- local project context
- extracted concepts, technologies, and entities

### Pieces OS Long-Term Memory
- recent workstream events
- workstream summaries

Current behavior note:
- Pieces OS is required for the current Doom's Moment capture flow
- if Pieces QGPT is unavailable during generation, BreakPoint falls back to Ollama for the final text output

---

## Generation Modes

### Normal
Balanced structured handoff.

### ADHD
Short, fast, scannable output.

### Code Mode
Technical, developer-focused output with paths, commands, and code context.

### Extra
Most detailed non-code handoff.

`Extra` is biased toward stronger Markdown structure, including:
- `## Executive Summary`
- `## Active Projects`
- `## Priority Stack`
- `## Decisions, Risks, and Open Loops`
- `## Phone-Ready Tasks`
- `## Resume Plan`
- `## Learn & Explore`
- `## Hashtags`

---

## Export System

BreakPoint supports three export presets:
- `File`
- `Notes`
- `File + Notes`

Behavior:
- `File`: save Markdown only
- `Notes`: save to Apple Notes only
- `File + Notes`: do both

File output uses:
- `DoomsMoment_YYYY-MM-DD_HH-mm-ss.md`

Current configured export directory in the active app setup:
- `/Users/kika_hub/Documents/dooms`

---

## Apple Notes Export

Apple Notes export is still supported, but it is no longer implicitly always-on in the docs model. It now depends on the selected export preset.

Implementation details:
- Markdown converted into Notes-friendly HTML
- AppleScript automation through `/usr/bin/osascript`
- existing Notes helper action in the right-click menu

---

## Menu Bar UI

### Icon States
| State | Appearance | Behavior |
|-------|-----------|----------|
| **Idle** | Light icon | Ready state |
| **Generating** | Alternating black/white custom icons | Animated while thinking |

### Status Popover
| State | Visual |
|-------|--------|
| **Idle** | simple prompt |
| **Generating** | pink loading popover with app icon chip |
| **Success** | success card, and for file output a kawaii bomb GIF pop |
| **Error** | red failure state |

### Right-Click Menu
Includes:
- mode label
- export label
- Pieces label
- Doom's Moment
- Open Latest Doom's Moment
- Reveal Export Folder
- Open Doom Moments in Notes
- Copy Last Output Path
- Properties
- Close App

Latest-file actions are disabled when the selected export preset does not create files.

---

## Settings

Stored through `AppSettings` and persisted with `UserDefaults`.

| Setting | Default |
|---------|---------|
| **Generation Mode** | `Normal` |
| **Export Preset** | `File + Notes` |
| **Export Directory** | `~/BreakPointSnapshots` fallback, user-configurable |
| **Ollama Base URL** | `http://127.0.0.1:11434` |
| **Ollama Model** | `llama3.2` |
| **Pieces Base URL** | `http://localhost:39300` |
| **Use Pieces OS** | Enabled |
| **Search Tags** | empty |

Settings UI highlights:
- Ollama model dropdown loaded from the configured Ollama instance
- refresh action for available Ollama models
- configurable Pieces base URL
- custom search tags field that feeds the generated hashtag section

---

## Technical Highlights

- macOS menu bar utility
- global hotkey via Carbon Events
- OCR via Vision
- AI fallback chain: Pieces QGPT -> Ollama
- structured Markdown enforcement for generated content
- automatic hashtags plus user-defined search tags for generated files and notes
- dynamic right-click menu state
- safer menu/popover presentation handling
