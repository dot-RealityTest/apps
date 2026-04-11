# BreakPoint

**Your emergency button for context preservation.**

BreakPoint is a macOS menu bar app that captures your current computer state and turns it into a structured Doom's Moment you can reopen later on desktop or in Apple Notes.

Press `Cmd + Shift + Escape` and BreakPoint will gather screen context, local project context, and Pieces memory, then generate a structured Markdown handoff in your selected mode.

---

## What It Does

BreakPoint is built for moments when you need to step away without losing momentum.

It captures:
- frontmost app and open window titles
- running apps
- clipboard text
- on-screen OCR text
- local knowledge graph context
- Pieces workstream memory

Then it generates a Doom's Moment in one of four modes:
- `Normal`
- `ADHD`
- `Code Mode`
- `Extra`

---

## Quick Start

### Prerequisites

| Dependency | Required | Purpose |
|-----------|----------|---------|
| **macOS** | Yes | Menu bar app |
| **Ollama** | Yes | AI generation and fallback |
| **Pieces OS** | Yes | Required for current Doom's Moment context capture + LTM |

### Setup

```bash
brew install ollama
ollama pull llama3.2
ollama serve
```

Then open `BreakPoint.app` and look for the icon in the menu bar.

---

## Triggering a Doom's Moment

You can trigger generation in three ways:
- `Cmd + Shift + Escape`
- left-click the menu bar icon
- right-click the menu bar icon, then choose `Doom's Moment`

Left-click is the fast path. Right-click opens the quick actions menu.

---

## Output Destinations

BreakPoint now supports export presets instead of always exporting to both places.

Available presets:
- `File`
- `Notes`
- `File + Notes`

Current file output is saved in the configured export directory. In the current app setup, recent files are being written to:
- `/Users/kika_hub/Documents/dooms`

Markdown filenames use this format:
- `DoomsMoment_YYYY-MM-DD_HH-mm-ss.md`

Apple Notes export remains available and creates a formatted note using the existing Notes pipeline.

---

## Generation Modes

| Mode | Best For |
|------|----------|
| **Normal** | Balanced structured handoff |
| **ADHD** | Fast, short, scannable reading |
| **Code Mode** | Technical handoff with file paths, commands, and code context |
| **Extra** | Deep, detailed non-code handoff with richer structure |

### Normal
Structured general-purpose handoff with priorities, projects, action items, and notes.

### ADHD
Short, punchy lines optimized for quick reading and low-friction re-entry.

### Code Mode
Technical output that can include file paths, function names, commands, architecture notes, and debugging context.

### Extra
Most detailed non-code mode. The app now pushes AI toward a richer Markdown structure with sections like:
- Executive Summary
- Active Projects
- Priority Stack
- Decisions, Risks, and Open Loops
- Phone-Ready Tasks
- Resume Plan
- Learn & Explore
- Hashtags

---

## Menu Bar Behavior

### Icon states
- **Idle:** light icon
- **Generating:** animated black/white icon swap while thinking

### Popover states
- `Generating...` now uses pink styling with the app icon in a compact chip
- successful file generations use the kawaii bomb artwork only in the success popover
- success messages now include the actual save destination more clearly

### Right-click menu
The context menu is rebuilt dynamically and includes:
- current mode status
- current export preset status
- Pieces connection status
- `Doom's Moment`
- `Open Latest Doom's Moment`
- `Reveal Export Folder`
- `Open Doom Moments in Notes`
- `Copy Last Output Path`
- `Properties`
- `Close App`

Latest-file actions are disabled when the active export preset does not create a file.

---

## Configuration

Open settings from:
- right-click menu bar icon > `Properties`

Main settings:
- generation mode
- export preset
- export folder
- Ollama base URL
- Ollama model dropdown
- Pieces base URL
- Pieces toggle
- search tags for generated output

Defaults in code:
- generation mode: `Normal`
- export preset: `File + Notes`
- Ollama base URL: `http://127.0.0.1:11434`
- Ollama model: `llama3.2`
- Pieces base URL: `http://localhost:39300`
- search tags: empty by default

---

## Architecture

```text
BreakPoint/
├── BreakPointApp.swift
├── MenuBarController.swift
├── PopoverView.swift
├── PropertiesView.swift
├── AppSettings.swift
├── Models.swift
├── DoomsMomentService.swift
├── ContextCapture.swift
├── PiecesOSService.swift
├── OllamaService.swift
├── AppleNotesService.swift
└── Assets.xcassets/
```

Key services:
- `DoomsMomentService`: context -> prompt -> generate -> export
- `ContextCapture`: app/window/clipboard/OCR capture
- `PiecesOSService`: Pieces availability + workstream data + QGPT
- `OllamaService`: local model generation
- `AppleNotesService`: Notes export automation

Generation behavior:
- BreakPoint gathers context through Pieces OS and local capture first
- if Pieces QGPT is slow or unavailable, generation falls back to Ollama
- Ollama model selection is available directly from Properties via the local model list
- custom search tags are merged into the final `## Hashtags` section so both files and Notes stay easier to find later

---

## Notes

Current app behavior differs from older docs in a few important ways:
- there are now **4** generation modes, not 3
- export is now preset-based, not always-on Notes sync
- right-click menu behavior is more advanced and dynamic
- menu bar generation styling uses the updated icon animation and pink loading state
- Pieces base URL is configurable from Properties
- Ollama model selection is now dropdown-based instead of freeform-only
- user-defined search tags can be added to generated output

---

## Docs

- **[FEATURES.md](./FEATURES.md)** - feature reference
- **[HOWTO.md](./HOWTO.md)** - setup, usage, and troubleshooting
- **[RELEASE_NOTES.md](./RELEASE_NOTES.md)** - GitHub release notes and distribution summary
